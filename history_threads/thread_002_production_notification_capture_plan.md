# Thread 002 — Production Plan: Bank Notification Capture

**Ngày:** 2026-05-09
**Chủ đề:** Hoàn thiện tính năng lấy data thông báo ngân hàng để lưu trên app (Android + iOS)

---

## Đánh giá hiện trạng

### Những gì đã có (Sprint 1–5)

| Thành phần | Trạng thái |
|---|---|
| Android `BankNotificationListener` (NotificationListenerService) | ✅ Chạy 24/7, event-driven |
| Android `NotificationProcessor` + regex parse | ✅ Hoạt động |
| Android Room DB (SQLCipher) + idempotency | ✅ Hoạt động |
| Android `NativeBridgePlugin` MethodChannel | ✅ Hoạt động |
| Android `WorkManager` background pull (1h/lần) | ✅ Đã schedule |
| iOS `LogTransactionIntent` AppIntent + KeychainQueue | ✅ Hoạt động |
| iOS Shortcuts 1-tap install flow | ✅ Hoạt động |
| Flutter `PullService` + Drift DB | ✅ Hoạt động |
| Remote regex config | ✅ Có cơ sở hạ tầng |
| Flutter Transaction List UI | ✅ Hoạt động |

### Những gì còn thiếu để lên prod

```
❌ Local notification khi phát hiện giao dịch mới (Android + iOS)
❌ Chỉ detect "debit" — thiếu credit/incoming
❌ Thiếu ngân hàng: Agribank, BIDV, VietinBank, TPBank, VPBank, SHB...
❌ TestNotificationReceiver còn trong release build
❌ AppDelegate.swift còn mock transaction hardcode
❌ iOS thiếu UIBackgroundModes → BGProcessingTask không chạy
❌ Chưa test real device MIUI/OneUI (hay bị ROM kill service)
❌ Onboarding chưa đủ hướng dẫn cho MIUI/OneUI users
❌ Không có cơ chế phát hiện khi Shortcuts bị xóa (iOS)
```

---

## Kiến trúc mục tiêu

```
ANDROID
───────
Bank app notification
    │
    ▼ (ngay lập tức, 24/7)
BankNotificationListener.onNotificationPosted()
    │
    ├─► LocalNotificationHelper.show()   ← THÊM MỚI
    │       "VCB: -250,000đ"
    │
    ▼
NotificationProcessor.process()
    │   parse regex → build TransactionPayload
    ▼
Room DB pending_transactions
    │
    ├─► App foreground: PullService (ngay lập tức)
    └─► App đóng:      WorkManager (≤1h fallback)
    │
    ▼
Drift DB → Stream → UI

iOS
───
SMS từ ngân hàng
    │
    ▼ (Shortcuts Personal Automation)
LogTransactionIntent.perform()
    │
    ├─► UNUserNotificationCenter.show()  ← THÊM MỚI
    │       "VCB: -250,000đ"
    │
    ▼
KeychainQueue (App Group)
    │
    ├─► App foreground: PullService (ngay lập tức)
    └─► App đóng:      BGProcessingTask
    │
    ▼
Drift DB → Stream → UI
```

---

## Sprint Plan

### Sprint 6 — Local Notification (Android + iOS)
**Mục tiêu:** Người dùng thấy giao dịch ngay khi phát sinh, kể cả app đóng.
**Ưu tiên: CAO NHẤT** — đây là tính năng core user-facing.

#### Android

**A6.1** — Tạo `LocalNotificationHelper.kt`
```kotlin
// android/.../notification/LocalNotificationHelper.kt
object LocalNotificationHelper {
    const val CHANNEL_ID = "bank_transactions"

    fun createChannel(context: Context) { ... }

    fun show(context: Context, bankId: String, amount: Long, sign: String) {
        val title = bankId.uppercase()
        val body  = "${if (sign == "debit") "-" else "+"}${formatAmount(amount)}đ"
        // NotificationCompat.Builder → NotificationManagerCompat.notify()
    }
}
```

**A6.2** — Gọi trong `NotificationProcessor` sau khi enqueue thành công
```kotlin
if (rowId != -1L) {
    LocalNotificationHelper.show(context, rule.bankId, amount, rule.sign)
}
```

**A6.3** — Request `POST_NOTIFICATIONS` permission (Android 13+) trong onboarding

**A6.4** — Tạo notification channel khi app khởi động

#### iOS

**I6.1** — Thêm `UNUserNotificationCenter` request trong onboarding flow

**I6.2** — Gọi `UNUserNotificationCenter.current().add()` trong `LogTransactionIntent.perform()` sau khi enqueue
```swift
let content = UNMutableNotificationContent()
content.title = parsed.bankId.uppercased()
content.body  = "\(parsed.sign == "debit" ? "-" : "+")\(formatAmount(parsed.amountVnd))đ"
let request = UNNotificationRequest(identifier: payload.id, content: content, trigger: nil)
UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
```

**Deliverables:**
- [ ] `LocalNotificationHelper.kt`
- [ ] Notification channel tạo khi app start
- [ ] POST_NOTIFICATIONS trong onboarding (Android 13+)
- [ ] Local notification iOS trong AppIntent
- [ ] Test: broadcast ADB → notification xuất hiện trong 2 giây

---

### Sprint 7 — Mở rộng ngân hàng + Fix sign detection
**Mục tiêu:** Cover đủ top 10 ngân hàng VN, phát hiện cả credit/incoming.

#### Ngân hàng cần thêm

| Bank | Package Android | Đặc điểm SMS |
|---|---|---|
| BIDV | `com.bidv.smartbanking` | "GD: -X,XXX VND" |
| VietinBank | `com.vietinbank.ipay` | "So tien: X,XXX VND" |
| Agribank | `com.agribank.ewallet` | "So du: X,XXX VND" |
| TPBank | `vn.tpb.business` | "GD: -XXXXX VND" |
| VPBank | `com.vpbank.vpbankneo` | "-X,XXX,XXX VND" |
| SHB | `vn.shb.mobile` | "Chi: X,XXX VND" |

#### Fix sign detection

Hiện tại toàn bộ rule hardcode `sign = "debit"`. Cần tách thành từng pattern riêng:

```kotlin
// Thay vì 1 rule với 1 sign:
BankRule(bankId = "vcb", sign = "debit", patterns = [...])

// Cần mỗi pattern có sign riêng:
data class BankPattern(val regex: String, val sign: String)

BankRule(bankId = "vcb", patterns = listOf(
    BankPattern("GD: ?-([0-9,.]+) ?VND",   "debit"),
    BankPattern("GD: ?\\+([0-9,.]+) ?VND",  "credit"),
    BankPattern("TK .* \\+([0-9,.]+)VND",   "credit"),  // incoming transfer
))
```

**Deliverables:**
- [ ] Thêm 6 ngân hàng vào `RegexConfigLoader.hardcodedRules`
- [ ] Refactor `BankPattern` tách `sign` ra khỏi `BankRule`
- [ ] Cập nhật iOS `BankRegexParser` tương ứng
- [ ] Test mỗi bank với ít nhất 2 SMS format (debit + credit)
- [ ] Update `_bankName()` trong Flutter UI cho tất cả bank mới

---

### Sprint 8 — Reliability trên Custom ROM
**Mục tiêu:** App hoạt động ổn định trên Xiaomi (MIUI) và Samsung (OneUI).

**A8.1** — Tách `BankNotificationListener` sang process riêng
```xml
<!-- AndroidManifest.xml -->
<service
    android:name=".service.BankNotificationListener"
    android:process=":notification"   ← THÊM
    ...>
```
Lợi ích: khi Flutter process bị kill, service vẫn sống trong process riêng.

**Lưu ý quan trọng:** Khi service chạy process riêng, không dùng được singleton Room DB instance. Phải tạo DB instance mới trong process đó.

**A8.2** — Cải thiện onboarding cho MIUI/OneUI

Phát hiện ROM type qua `ManufacturerInfo` → hiện hướng dẫn đặc thù:
- MIUI: "Vào Security → Manage apps → Remind Spend → Autostart → Bật"
- OneUI: "Vào Settings → Apps → Remind Spend → Battery → Unrestricted"

**A8.3** — `BankNotificationListener.onListenerConnected()` callback

Log thời điểm service kết nối lại sau khi bị kill — dữ liệu để đánh giá reliability:
```kotlin
override fun onListenerConnected() {
    super.onListenerConnected()
    AppLogger.info(TAG, "Listener connected at ${System.currentTimeMillis()}")
    // Trigger pull bất cứ notification nào bị miss trong lúc service chết
    serviceScope.launch { triggerFlutterPull() }
}
```

**Deliverables:**
- [ ] Separate process cho service
- [ ] Onboarding screen MIUI/OneUI hướng dẫn cụ thể
- [ ] `onListenerConnected()` log + recovery pull
- [ ] Test matrix: Xiaomi (MIUI 14), Samsung (OneUI 6), stock Android

---

### Sprint 9 — iOS Reliability
**Mục tiêu:** iOS hoạt động ổn định hơn, phát hiện khi Shortcuts bị mất.

**I9.1** — Fix `UIBackgroundModes` trong `Info.plist`
```xml
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
    <string>fetch</string>
</array>
```

**I9.2** — Phát hiện Shortcuts đã bị xóa

Hiện không có cách detect trực tiếp. Giải pháp gián tiếp:
- Lưu `last_shortcut_triggered_at` vào UserDefaults mỗi khi `LogTransactionIntent.perform()` chạy
- Khi app mở, nếu `last_shortcut_triggered_at` quá cũ (>7 ngày) → hiện banner "Kiểm tra Shortcuts automation"

**I9.3** — Xóa mock transaction khỏi `AppDelegate.swift`
```swift
// XÓA đoạn này:
let mock = TransactionPayload(id: "init-mock-...", ...)
try? KeychainQueue.shared.enqueue(mock)
```

**I9.4** — `simulateBankNotification` bridge method cho iOS debug

Thêm vào `IOSBridgePlugin` method chạy full pipeline qua `BankRegexParser` (thay thế mock hardcode hiện tại) để test mà không cần Shortcuts.

**Deliverables:**
- [ ] UIBackgroundModes fix
- [ ] `last_shortcut_triggered_at` tracking + stale warning UI
- [ ] Xóa mock hardcode khỏi AppDelegate
- [ ] `simulateBankNotification(smsText:)` bridge method
- [ ] Test BGProcessingTask trên real iPhone

---

### Sprint 10 — Production Cleanup
**Mục tiêu:** Sẵn sàng submit store.

**A10.1** — Ẩn `TestNotificationReceiver` khỏi release build
```xml
<!-- Chỉ include trong debug -->
<!-- Dùng build variant hoặc: -->
android:enabled="false"  <!-- override trong release manifest -->
```

**A10.2** — `mockTransaction` Android — hiện là `notImplemented()`, xóa khỏi Dart side hoặc thêm implementation thật cho debug

**A10.3** — ProGuard / R8 rules cho SQLCipher, Drift, WorkManager

**A10.4** — Privacy manifest (iOS 17+) — khai báo `NSPrivacyAccessedAPITypes`

**A10.5** — Google Play: chuẩn bị "Prominent Disclosure" cho `BIND_NOTIFICATION_LISTENER_SERVICE`
- Phải hiện dialog giải thích trước khi dẫn user vào Settings
- Đây là yêu cầu bắt buộc của Google Play policy

**A10.6** — App Store: review notes giải thích AppIntent + Shortcuts flow

**Deliverables:**
- [ ] TestNotificationReceiver chỉ trong debug build
- [ ] Prominent Disclosure dialog trước khi request notification listener
- [ ] ProGuard rules
- [ ] Privacy manifest iOS
- [ ] Store listing draft (cả hai store)

---

## Thứ tự ưu tiên

```
Sprint 6  ← LÀM NGAY (local notification — user-facing nhất)
Sprint 7  ← Tiếp theo (bank coverage — trực tiếp ảnh hưởng utility)
Sprint 9  ← Song song với Sprint 7 (iOS cleanup nhanh)
Sprint 8  ← Sau (cần device thật để test)
Sprint 10 ← Cuối cùng trước khi submit
```

---

## Quyết định cần làm rõ trước Sprint 8

1. **iOS strategy**: Tiếp tục Shortcuts approach (cho power user) hay bổ sung manual input fallback?
2. **Backend regex**: Có server để host remote config không, hay dùng hardcode tier-3 cho v1?
3. **Minimum Android version**: Hiện `minSdk` là bao nhiêu? Ảnh hưởng đến `POST_NOTIFICATIONS` handling.
4. **Release target**: Android-first hay đồng thời cả hai platform?
