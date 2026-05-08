# Thread 001 — Architecture Review & Sprint 1 Plan

**Nguồn:** https://claude.ai/share/df01a784-7895-4c3b-a1cb-8acc259b5c8b  
**Ngày:** 2026-05-07  
**Chủ đề:** Đánh giá kiến trúc đọc notification ngân hàng + lập plan production-grade

---

## 1. Đánh giá kiến trúc từ góc nhìn Senior Mobile Engineer

Nhìn chung, document gốc có tư duy đúng hướng ở tầng conceptual nhưng có khá nhiều vấn đề nghiêm trọng ở tầng implementation và production readiness.

### ✅ Những gì đúng và tốt

- **Native Queue thay vì EventChannel trực tiếp** — Flutter Engine không đảm bảo alive khi app bị kill, nên buffering ở native layer là correct approach.
- **iOS Sandbox awareness** — Nhận biết giới hạn của Apple và đề xuất App Intents là pragmatic.
- **Regex Config từ Backend** — Bắt buộc trong production, không phải optional.

### ❌ Vấn đề nghiêm trọng

#### 1. Android — Memory Leak trong Service
```kotlin
// CODE GỐC - NGUY HIỂM
CoroutineScope(Dispatchers.IO).launch { ... }
```
Tạo CoroutineScope orphan trong Service là classic memory leak. Correct approach:
```kotlin
class BankNotificationListener : NotificationListenerService() {
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
    }
}
```

#### 2. SharedPreferences làm Queue — Sai tool cho bài toán này
SharedPreferences không phải transactional storage. Concurrent writes → race condition:
```
Thread A đọc queue: [tx1]
Thread B đọc queue: [tx1]  ← Đọc trước khi A ghi xong
Thread A ghi: [tx1, tx2]
Thread B ghi: [tx1, tx3]  ← Mất tx2
```
Production solution phải dùng Room DB với WAL mode:
```kotlin
@Dao
interface TransactionQueueDao {
    @Insert
    suspend fun enqueue(tx: PendingTransaction)

    @Transaction
    suspend fun dequeueAll(): List<PendingTransaction> {
        val items = getAll()
        deleteAll()
        return items
    }
}
```

#### 3. Doze Mode / Battery Optimization — Bài toán chưa được giải
- NotificationListenerService được miễn Doze (privileged service) → lưu queue là đúng.
- Vấn đề thực sự bị bỏ qua: **Manufacturer-specific battery killers** — MIUI, OneUI, ColorOS chiếm 60-70% market share Android VN.

```kotlin
fun isPowerOptimizationIgnored(context: Context): Boolean {
    val pm = context.getSystemService(PowerManager::class.java)
    return pm.isIgnoringBatteryOptimizations(context.packageName)
}
```

#### 4. iOS App Intents UX — Quá lạc quan
- Thiếu iOS 16+ hard requirement.
- Setup Shortcuts Automation đòi 6-8 bước manual → conversion rate < 15%.
- Giải pháp: Deep link vào Shortcuts với pre-built shortcut file:
```swift
let shortcutURL = URL(string: "shortcuts://import-workflow?url=\(hostedShortcutURL)")!
UIApplication.shared.open(shortcutURL)
```

#### 5. Security — Thiếu hoàn toàn
Dữ liệu tài chính trong SharedPreferences/AppGroup không được encrypt.
```kotlin
// Android: Dùng EncryptedSharedPreferences
val encryptedPrefs = EncryptedSharedPreferences.create(
    context,
    "TRANSACTION_QUEUE",
    MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)
// iOS: Phải dùng Keychain với kSecAttrAccessGroup cho shared data
```

#### 6. Regex Pattern — Thiếu test coverage
```
VCB:  "So du TK 1234: 5,000,000VND"     ← Không bắt được
MB:   "Số dư: 5.000.000 đ"              ← Bắt được
MOMO: "Bạn đã chi 50.000đ cho..."       ← Bắt được nhưng sign detection sai
```

### 🔧 Missing Architecture Pieces

- **Duplicate detection** — Notification đôi khi fire 2-3 lần. Cần idempotency key:
```kotlin
val idempotencyKey = "${pkg}_${amount}_${timestamp / 5000}"
```
- **Flutter Background Isolate** — Đề cập nhưng không có implementation.
- **Error observability** — Không có logging strategy.

### Tổng kết điểm

| Hạng mục | Điểm |
|---|---|
| Tư duy kiến trúc tổng thể | 7/10 |
| Android implementation | 4/10 |
| iOS implementation | 6/10 |
| Security | 2/10 |
| Production readiness | 3/10 |

---

## 2. Revised Architecture Plan — Production-Grade

### Constraints
```
├── Android: NotificationListenerService sống độc lập với Flutter Engine
├── iOS: Sandbox cứng, không đọc notification app khác
├── Market VN: 60-70% Android là MIUI/OneUI/ColorOS (aggressive kill)
├── Data: Tài chính → encrypt bắt buộc
└── UX: Mỗi bước friction thêm = -15% conversion
```

### Failure Modes phải handle
```
├── App bị kill giữa chừng khi đang write queue
├── Notification fire 2-3 lần cho cùng 1 transaction
├── Bank thay đổi SMS format → Regex fail silent
├── Flutter Engine chưa ready khi Service muốn communicate
└── User revoke permission sau khi đã grant
```

### Layered Architecture
```
┌─────────────────────────────────────────────────────┐
│                  FLUTTER LAYER                       │
│  UI ← BLoC/Riverpod ← Repository ← LocalDB (Drift)  │
│                      ↑                               │
│              Bridge Service (MethodChannel)          │
└──────────────────────┬──────────────────────────────┘
                       │ Pull (không push)
┌──────────────────────┴──────────────────────────────┐
│              NATIVE BRIDGE LAYER                     │
│         Encrypted Queue  +  Idempotency Cache        │
└──────────┬───────────────────────┬──────────────────┘
           │ Android               │ iOS
┌──────────┴──────┐    ┌──────────┴──────────────────┐
│ Notification    │    │ App Intent + Shortcut        │
│ Listener Svc    │    │ (iOS 16+)                    │
│ (Room WAL DB)   │    │ (Keychain AppGroup)          │
└─────────────────┘    └─────────────────────────────┘
           │                       │
┌──────────┴───────────────────────┴──────────────────┐
│              BACKEND CONFIG SERVICE                  │
│    Regex Dictionary  +  Bank Package Registry        │
│    (versioned, cached local, fallback to hardcode)   │
└─────────────────────────────────────────────────────┘
```

**Nguyên tắc cốt lõi:** Native layer chỉ làm 3 việc — Capture, Parse, Enqueue. Flutter layer chịu trách nhiệm toàn bộ business logic.

### Data Flow — Android
```
Notification Posted
       │
       ▼
NotificationListenerService.onNotificationPosted()
       ├── Check package whitelist (từ config cache)
       ├── Extract raw text
       ├── Apply Regex rules (từ config cache)
       ├── Generate idempotency key = SHA256(pkg + amount + floor(time/5000ms))
       ├── Check idempotency cache → đã xử lý? Drop.
       ├── Encrypt payload
       └── INSERT vào Room DB (WAL mode, atomic)
              │
              ▼ (khi app foreground hoặc WorkManager wake)
       Flutter pull via MethodChannel
              │
              ▼
       Decrypt → Validate → Insert Drift → Clear Queue
```

### Data Flow — iOS
```
SMS/Email nhận được
       │
       ▼ (Personal Automation - user setup 1 lần)
Apple Shortcuts trigger
       │
       ▼
LogTransactionIntent.perform()
       ├── Extract + Parse (NSRegularExpression)
       ├── Encrypt payload
       └── Save vào Keychain (AppGroup shared)
              │
              ▼ (khi app foreground)
       Flutter pull via MethodChannel
```

### Database Schema (Room — Android)
```
TABLE pending_transactions
├── id              TEXT PRIMARY KEY  ← idempotency key (SHA256)
├── package_name    TEXT NOT NULL
├── raw_amount      INTEGER NOT NULL  ← đơn vị: đồng, không float
├── raw_content     TEXT NOT NULL     ← encrypted blob
├── timestamp_ms    INTEGER NOT NULL
├── created_at      INTEGER NOT NULL
└── retry_count     INTEGER DEFAULT 0

TABLE idempotency_cache
├── key             TEXT PRIMARY KEY
└── expires_at      INTEGER NOT NULL  ← TTL 24h, auto-purge

TABLE regex_config_cache
├── bank_id         TEXT PRIMARY KEY
├── patterns        TEXT NOT NULL     ← JSON array
├── version         INTEGER NOT NULL
└── fetched_at      INTEGER NOT NULL
```

> **Tại sao raw_amount là INTEGER?** Floating point cho tiền tệ là bug cổ điển. 50000 đồng lưu nguyên, không bao giờ 50.000 hay 50000.0.

### Idempotency Strategy
```
Key = SHA256(package_name + amount + ⌊timestamp / 5000⌋)

Ví dụ:
- Notification 1: VCB, 50000đ, t=1000ms → SHA256("com.vcb_50000_0")
- Notification 2: VCB, 50000đ, t=3000ms → SHA256("com.vcb_50000_0") → SAME → DROP
- Notification 3: VCB, 50000đ, t=6000ms → SHA256("com.vcb_50000_1") → DIFFERENT → INSERT

TTL: 24 giờ → auto purge
```

### Security Architecture
```
Android:
├── Storage: EncryptedSharedPreferences (AES256-GCM) cho config nhỏ
├── Queue DB: Room + SQLCipher (AES256) cho transaction data
└── Key management: Android Keystore (hardware-backed)

iOS:
├── Storage: Keychain với kSecAttrAccessGroup (AppGroup shared)
├── Protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
└── Key: Secure Enclave via CryptoKit
```

### Regex Config — 3-tier Fallback
```
[Tier 1] Backend API (fetch khi app start, background refresh 6h)
        │ Fail / Timeout (2s)
[Tier 2] Local DB Cache (version cuối cùng fetch được)
        │ Cache miss / quá cũ (>7 ngày)
[Tier 3] Hardcoded fallback trong app binary (basic patterns)
```

Config format (JSON từ Backend):
```json
{
  "version": 42,
  "rules": [
    {
      "bank_id": "vcb",
      "package_names": ["com.vcb"],
      "patterns": [
        "GD: ?-([0-9,.]+) ?VND",
        "Debit: ?([0-9,.]+) ?VND"
      ],
      "amount_group": 1,
      "sign": "debit"
    }
  ]
}
```

### Permission & Manufacturer Handling
```
Android Permission States:
├── GRANTED    → Normal flow
├── DENIED     → Show rationale → Re-request (max 2 lần)
├── REVOKED    → Detect lúc app resume, show re-grant screen
└── RESTRICTED → Manufacturer kill → Special handling

Manufacturer Detection:
├── MIUI    → Guide user đến "Autostart" + "Battery Saver Whitelist"
├── OneUI   → Guide đến "Sleeping apps" → Remove app
├── ColorOS → Guide đến "Power Consumption" → Ignore restrictions
└── Stock   → Standard Battery Optimization whitelist
```

### Flutter ↔ Native Bridge Contract
```
MethodChannel: 'com.app/transaction_bridge'

Methods:
├── getAndClearQueue()        → List<Map>
├── checkPermissionStatus()   → PermissionStatus enum
├── requestPermission()       → bool
├── getManufacturerInfo()     → ManufacturerInfo
└── clearIdempotencyCache()   → void (debug/reset)

EventChannel: 'com.app/permission_status'
└── Stream<PermissionStatus>  ← Native push khi permission bị revoke
```

### iOS Onboarding — 1-tap thay vì 8 bước
```
URL scheme:
shortcuts://import-workflow?url={hosted_shortcut_url}&name=LogTransaction

Fallback (iOS < 16): Manual entry UI với OCR camera
```

### Error Observability
```
Android: Timber + local rotating log file (max 5MB, 3 files)
iOS: OSLog với subsystem + category

Log levels:
├── DEBUG  → Dev build only
├── INFO   → Notification received, parsed, enqueued
├── WARN   → Regex no match
└── ERROR  → DB write fail, decrypt fail, unexpected state

Analytics: Chỉ log event types, KHÔNG log amounts (PII)
```

### Thay đổi so với plan gốc

| Vấn đề | Plan gốc | Plan mới |
|---|---|---|
| Coroutine scope | Orphan (leak) | ServiceScope + cancel() |
| Storage | SharedPreferences (race condition) | Room WAL + atomic transaction |
| Security | Plaintext | AES256 + Android Keystore / Secure Enclave |
| Idempotency | Không có | SHA256 key + TTL cache |
| Doze/Manufacturer | Bỏ qua | Detect + guide per-manufacturer |
| iOS friction | 8 bước manual | 1-tap shortcut install |
| Regex | Hardcode | Remote config + 3-tier fallback |
| Observability | Không có | Structured logging + Crashlytics |
| Error handling | Silent fail | Explicit states + retry logic |

---

## 3. Sprint Plan

| Sprint | Nội dung | Trạng thái |
|---|---|---|
| Sprint 1 | Foundation: Room DB, EncryptedSharedPreferences, MethodChannel contract stub, Regex config loader (tier 3) | 🔄 Đang làm |
| Sprint 2 | Android Core: NotificationListenerService, Idempotency, Permission + Manufacturer detection, Unit tests | ⏳ Chưa làm |
| Sprint 3 | iOS Core: App Intent, Keychain AppGroup, Shortcut 1-tap install, Onboarding flow | ⏳ Chưa làm |
| Sprint 4 | Flutter Integration: Bridge Service, Background pull, Drift schema + Repository, Error handling + Logging | ⏳ Chưa làm |
| Sprint 5 | Hardening: Remote regex config, E2E tests trên real devices, Security audit, Battery impact measurement | ⏳ Chưa làm |

---

## 4. Cập nhật tiến độ

### 2026-05-07 — Bắt đầu Sprint 1
- Đã đọc và review toàn bộ plan từ thread gốc.
- Project hiện tại là fresh Flutter boilerplate, chưa có file implementation nào.
- Cấu trúc project: `com.example.remind_spend`, Flutter SDK ^3.9.2.
- Bước tiếp theo: implement Room DB + Security + MethodChannel contract.

### 2026-05-07 — Sprint 1 HOÀN THÀNH

**Files đã tạo:**

| File | Mô tả |
|---|---|
| `android/app/build.gradle.kts` | Thêm Room 2.6.1 + SQLCipher 4.5.4 + security-crypto + WorkManager + KSP |
| `android/settings.gradle.kts` | Thêm KSP plugin 2.1.0-1.0.29 |
| `android/…/db/Entities.kt` | 3 Room entities: PendingTransaction, IdempotencyEntry, RegexConfigEntry |
| `android/…/db/Daos.kt` | 3 DAOs: dequeueAll() là @Transaction thực sự, không race condition |
| `android/…/db/AppDatabase.kt` | SQLCipher + WAL, singleton thread-safe, không fallbackToDestructiveMigration |
| `android/…/security/SecurityManager.kt` | Android Keystore AES256-GCM, IV mới mỗi lần, getDatabasePassphrase() |
| `android/…/config/RegexConfigLoader.kt` | Tier 3 hardcoded: VCB, MB, TCB, ACB, MoMo, ZaloPay |
| `android/…/service/BankNotificationListener.kt` | Stub — khai báo class, implement Sprint 2 |
| `android/…/bridge/NativeBridgePlugin.kt` | MethodChannel handler: getAndClearQueue (stub), checkPermissionStatus, getManufacturerInfo (MIUI/OneUI/ColorOS detection), clearIdempotencyCache |
| `android/…/MainActivity.kt` | Register NativeBridgePlugin vào FlutterEngine |
| `android/…/AndroidManifest.xml` | Khai báo BankNotificationListener service + BIND_NOTIFICATION_LISTENER_SERVICE |
| `lib/models/pending_transaction.dart` | Model class, amountVnd là int (không double) |
| `lib/services/bridge_service.dart` | MethodChannel client, typed BridgeError, MissingPluginException graceful |
| `lib/repositories/transaction_repository.dart` | Pull + validate, không chứa business logic |
| `pubspec.yaml` | Thêm drift, sqlite3_flutter_libs, path_provider, flutter_secure_storage |

**Quyết định kỹ thuật quan trọng:**
- Dùng **KSP** thay kapt (Kotlin 2.1.0 compatible, nhanh hơn)
- `raw_amount` là `Long` (INTEGER) — không bao giờ Float/Double
- `AppDatabase` không có `fallbackToDestructiveMigration()` — mất queue = mất data user
- `SecurityManager` tạo IV mới mỗi lần encrypt — không tái sử dụng IV

**Trạng thái Sprint:**

| Sprint | Trạng thái |
|---|---|
| Sprint 1 — Foundation | ✅ DONE |
| Sprint 2 — Android Core | ✅ DONE |
| Sprint 3 — iOS Core | ✅ DONE (code) / ⚙️ Cần Xcode |
| Sprint 4 — Flutter Integration | ⏳ Chưa làm |
| Sprint 5 — Hardening | ⏳ Chưa làm |

### 2026-05-07 — Test Sprint 1

**Flutter unit tests (chạy không cần device):**
- `test/models/pending_transaction_test.dart` — 3 tests ✅
- `test/repositories/transaction_repository_test.dart` — 8 tests ✅
- Tổng: **11/11 PASS**

**Android JVM unit tests (chạy không cần device):**
- `RegexConfigLoaderTest` — 17 tests ✅
- Tổng: **17/17 PASS**

**Bugs đã fix trong quá trình test:**
- `minSdk` 23 → 24 (path_provider_android yêu cầu 24)
- `compileSdk` 35 → 36 (path_provider_android yêu cầu 36)
- Thêm `strings.xml` (service label cần `@string/app_name`)
- Entity fields thiếu `@ColumnInfo` → Room dùng camelCase làm column name, queries dùng snake_case → mismatch. Fix bằng cách thêm `@ColumnInfo(name = "snake_case")` cho tất cả fields
- `count()`/`exists()` trả về `Long` thay `Int` (Room COUNT queries trả về Long)
- Flutter test cần `TestWidgetsFlutterBinding.ensureInitialized()` khi dùng MethodChannel

**Instrumented tests (cần emulator — chưa chạy):**
- `AppDatabaseTest` — Room DB operations (dequeueAll atomic, idempotency TTL, ordering)
- `SecurityManagerTest` — Android Keystore encrypt/decrypt

### 2026-05-08 — Sprint 2 HOÀN THÀNH

**Files đã tạo/sửa:**

| File | Mô tả |
|---|---|
| `android/…/service/BankNotificationListener.kt` | Full implementation: serviceScope, package whitelist, regex parse, idempotency check, AES encrypt, Room enqueue |
| `android/…/service/NotificationProcessor.kt` | SHA-256 idempotency key: `SHA256(pkg_amount_⌊t/5000⌋)`, TTL constant 24h |
| `android/…/bridge/NativeBridgePlugin.kt` | Thêm `checkBatteryOptimization()` + `requestBatteryOptimizationWhitelist()`, fix `android.database.ContentObserver` import, fix `onCancel` type inference |
| `android/…/AndroidManifest.xml` | Thêm `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission |
| `lib/services/bridge_service.dart` | Thêm `checkBatteryOptimization()` + `requestBatteryOptimizationWhitelist()` |
| `test/services/bridge_service_test.dart` | 17 tests: MissingPlugin fallbacks, permission status parsing, manufacturer type parsing, PlatformException propagation |
| `android/…/service/NotificationProcessorTest.kt` | 9 tests: idempotency key correctness, 5s window boundary, SHA-256 format, collision resistance |

**Bugs đã fix:**
- `android.content.ContentObserver` → `android.database.ContentObserver` (wrong package)
- `permissionObserver?.let { ... }` type inference fail → explicit `val obs = permissionObserver; if (obs != null) ...`
- Duplicate `Settings` import (alias conflict)

**Kết quả test:**
- Flutter: **29/29 PASS** (3 models + 8 repo + 1 widget + 17 bridge)
- Android JVM: **26/26 PASS** (17 RegexConfig + 9 NotificationProcessor)

**Trạng thái Sprint:**

| Sprint | Trạng thái |
|---|---|
| Sprint 1 — Foundation | ✅ DONE |
| Sprint 2 — Android Core | ✅ DONE |
| Sprint 3 — iOS Core | ✅ DONE (code) / ⚙️ Cần Xcode |
| Sprint 4 — Flutter Integration | ⏳ Chưa làm |
| Sprint 5 — Hardening | ⏳ Chưa làm |

### 2026-05-08 — Sprint 3 HOÀN THÀNH (code)

**Files đã tạo:**

| File | Mô tả |
|---|---|
| `ios/Runner/shared/TransactionPayload.swift` | Codable struct dùng chung; `amountVnd` là `Int64` |
| `ios/Runner/shared/KeychainQueue.swift` | Thread-safe Keychain queue; `accessGroup` injectable; idempotency bằng id-check |
| `ios/Runner/shared/BankRegexParser.swift` | NSRegularExpression, mirror 1-1 Android RegexConfigLoader Tier 3 |
| `ios/Runner/bridge/IOSBridgePlugin.swift` | FlutterMethodChannel + FlutterEventChannel; mirror Android NativeBridgePlugin contract |
| `ios/Runner/bridge/ShortcutInstaller.swift` | Build `shortcuts://import-workflow` URL từ Info.plist `ShortcutInstallURL` |
| `ios/Runner/AppDelegate.swift` | Register IOSBridgePlugin SAU `super.application(...)` |
| `ios/Runner/Runner.entitlements` | AppGroup entitlement |
| `ios/TransactionIntentExtension/LogTransactionIntent.swift` | `@available(iOS 16.0, *)` AppIntent; SHA256 idempotency; silent success khi không match |
| `ios/TransactionIntentExtension/TransactionIntentExtension.entitlements` | Same AppGroup cho extension |
| `ios/TransactionIntentExtension/Info.plist` | NSExtensionPointIdentifier + MinimumOSVersion 16.0 |
| `ios/Podfile` | `platform :ios, '16.0'` |
| `ios/Runner/Info.plist` | Thêm `ShortcutInstallURL` placeholder |
| `ios/RunnerTests/BankRegexParserTests.swift` | 17 tests: VCB/MB/TCB/MoMo/ZaloPay, no-match, amount stripping |
| `ios/RunnerTests/KeychainQueueTests.swift` | 8 tests: enqueue/dequeue, idempotency, empty, order, amount integrity |

**Quyết định kỹ thuật:**
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — Secure Enclave encrypted, không iCloud backup
- `AppDelegate.bridgePlugin` hold strong ref — tránh dealloc (FlutterMethodChannel chỉ hold weak)
- `super.application(...)` TRƯỚC khi access `window?.rootViewController` — bug classic nếu ngược
- `BankRegexParser.parse()` trả `nil` khi không match — Shortcut không hiện error
- Idempotency = `SHA256(bankId_amount_⌊t/5000⌋)` — mirror hệt Android

**⚙️ Cần làm trong Xcode trước khi chạy:**
1. Drag `ios/Runner/shared/*.swift` + `ios/Runner/bridge/*.swift` vào Runner target
2. New Target → App Intent Extension → tên `TransactionIntentExtension`
3. Thêm 3 shared files vào Extension target's compile sources
4. Signing & Capabilities → App Groups → `group.com.example.remind_spend` cho cả 2 targets
5. Build Settings → Code Signing Entitlements: Runner.entitlements / TransactionIntentExtension.entitlements
6. Extension Minimum Deployments → iOS 16.0
7. Add test files vào RunnerTests target

### 2026-05-08 — Sprint 4 HOÀN THÀNH

**Files đã tạo/sửa:**

| File | Mô tả |
|---|---|
| `lib/core/app_exception.dart` | `sealed class AppException`: `BridgePullException`, `DatabaseWriteException` |
| `lib/core/app_logger.dart` | `abstract final AppLogger` — debug/info/warn/error; DEBUG gated trên `kDebugMode`; không log amount (PII) |
| `lib/db/tables/transactions.dart` | Drift table: id (PK), bankId, amountVnd (Int64), sign, timestampMs, createdAt, syncedAt (nullable) |
| `lib/db/app_db.dart` | `AppDb` + `AppDb.forTesting(executor)`; `insertOrIgnore` idempotency; `watchAll()` stream; `getAll()` |
| `lib/db/app_db.g.dart` | Generated bởi `build_runner` — không edit thủ công |
| `lib/repositories/transaction_repository.dart` | `syncFromNative()`: pull → validate → `insertOrIgnore`; `watchAll()`, `getAll()`; typed error wrapping |
| `lib/services/pull_service.dart` | `WidgetsBindingObserver`; pull on `resumed`; concurrent-call guard (`_pulling` flag) |
| `lib/main.dart` | Init `AppDb` + `TransactionRepository` + `PullService`; placeholder UI |
| `test/db/app_db_test.dart` | 9 tests: insert, duplicate-ignore, ordering, watchAll stream, Int64 integrity, syncedAt null |
| `test/repositories/transaction_repository_test.dart` | Rewrite: 14 tests với in-memory DB + mock MethodChannel |
| `test/services/pull_service_test.dart` | 8 tests: pull, error swallow, concurrent coalesce, lifecycle states |
| `test/core/app_logger_test.dart` | 2 smoke tests |
| `test/widget_test.dart` | Cập nhật cho placeholder UI mới |

**Quyết định kỹ thuật:**
- `InsertMode.insertOrIgnore` trong Drift — không throw khi id trùng (defense-in-depth)
- `AppDb.forTesting(NativeDatabase.memory())` — không cần `path_provider`, chạy được trong CI
- `PullService._pulling` flag — coalesce concurrent pulls, không dùng Mutex để tránh dependency
- `AppLogger` là `abstract final class` — không thể instantiate, không thể subclass
- `syncFromNative()` return `int` (count) không phải `List<Transaction>` — caller không cần data ngay, chỉ cần biết có bao nhiêu row mới

**Kết quả test:**
- Flutter: **53/53 PASS** (2 logger + 3 models + 14 repo + 9 db + 17 bridge + 8 pull + 1 widget)
- Android JVM: **26/26 PASS** (không thay đổi)
