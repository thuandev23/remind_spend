import CryptoKit
import Flutter
import Foundation
import UIKit
import UserNotifications

/// iOS counterpart of Android's NativeBridgePlugin.
/// Handles the same MethodChannel and EventChannel contracts so the Flutter
/// BridgeService works identically on both platforms.
///
/// Registration: call `register(with:)` from AppDelegate after
/// GeneratedPluginRegistrant.register(). Hold a strong reference to the
/// returned instance for the app's lifetime.
final class IOSBridgePlugin: NSObject {

    static let methodChannelName  = "com.example.remind_spend/transaction_bridge"
    static let eventChannelName   = "com.example.remind_spend/permission_status"
    static let txEventChannelName = "com.example.remind_spend/transaction_events"

    private let keychainQueue: KeychainQueue
    private var txEventSink: FlutterEventSink?

    init(keychainQueue: KeychainQueue = .shared) {
        self.keychainQueue = keychainQueue
    }

    /// Wires up all channels. Must be called once, on the main thread.
    func register(with messenger: FlutterBinaryMessenger) {
        let method = FlutterMethodChannel(
            name: Self.methodChannelName,
            binaryMessenger: messenger
        )
        method.setMethodCallHandler(handle)

        let event = FlutterEventChannel(
            name: Self.eventChannelName,
            binaryMessenger: messenger
        )
        event.setStreamHandler(self)

        let txEvent = FlutterEventChannel(
            name: Self.txEventChannelName,
            binaryMessenger: messenger
        )
        txEvent.setStreamHandler(txEventStreamHandler)

        registerDarwinObserver()
    }

    // Listens for cross-process signal posted by LogTransactionIntent after enqueue.
    // CFNotificationCenter callbacks are C functions — bridge via an Unmanaged pointer.
    private func registerDarwinObserver() {
        let name = "com.example.remind_spend.new_transaction" as CFString
        // passUnretained is safe: AppDelegate holds a strong reference for app lifetime.
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            selfPtr,
            { _, observer, _, _, _ in
                guard let ptr = observer else { return }
                let plugin = Unmanaged<IOSBridgePlugin>.fromOpaque(ptr).takeUnretainedValue()
                plugin.notifyNewTransaction()
            },
            name, nil, .deliverImmediately
        )
    }

    private lazy var txEventStreamHandler: TxEventStreamHandler = {
        TxEventStreamHandler { [weak self] sink in
            self?.txEventSink = sink
        }
    }()

    private func notifyNewTransaction() {
        DispatchQueue.main.async { [weak self] in
            self?.txEventSink?("new_transaction")
        }
    }

    // MARK: - MethodChannel handler

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "getAndClearQueue":
            handleGetAndClearQueue(result: result)

        case "checkPermissionStatus":
            // iOS sandbox: App Intents are always available — no listener permission needed.
            result("not_applicable")

        case "requestPermission":
            // "Request permission" on iOS = guide user to install the Shortcut.
            openShortcutsApp(result: result)

        case "getManufacturerInfo":
            result([
                "manufacturer": "Apple",
                "model": UIDevice.current.model,
                "type": "ios"
            ])

        case "checkBatteryOptimization":
            result(true)   // iOS has no battery-kill mechanism like MIUI/OneUI

        case "mockTransaction":
            handleMockTransaction(result: result)

        case "simulateBankNotification":
            handleSimulateBankNotification(call: call, result: result)

        case "sendLocalNotification":
            handleSendLocalNotification(call: call, result: result)

        case "requestLocalNotificationPermission":
            handleRequestLocalNotificationPermission(result: result)

        case "requestBatteryOptimizationWhitelist":
            result(nil)    // no-op

        case "clearIdempotencyCache":
            result(nil)    // no-op: Shortcuts deduplication is handled at the OS level

        case "updateRegexConfig":
            handleUpdateRegexConfig(call: call, result: result)

        case "getLastExtensionError":
            let err = UserDefaults(suiteName: "group.com.example.remind_spend")?
                .string(forKey: "last_extension_error")
            result(err)

        case "getLastReceivedText":
            let text = UserDefaults(suiteName: "group.com.example.remind_spend")?
                .string(forKey: "last_received_text")
            result(text)

        case "debugKeychainPeek":
            handleDebugKeychainPeek(result: result)

        case "detectInstalledFinanceApps":
            handleDetectInstalledFinanceApps(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Private

    private func handleGetAndClearQueue(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { result([]) }
                return
            }
            do {
                let items = try self.keychainQueue.dequeueAll()
                NSLog("[RemindSpend] getAndClearQueue: found \(items.count) items in KeychainQueue")
                let maps: [[String: Any]] = items.map { tx in
                    [
                        "id":           tx.id,
                        "package_name": tx.bankId,   // iOS has no package name; reuse bankId
                        "bank_id":      tx.bankId,
                        "amount_vnd":   tx.amountVnd,
                        "sign":         tx.sign,
                        "timestamp_ms": tx.timestampMs,
                        "created_at":   tx.createdAt,
                        "raw_content":  tx.rawContent as Any
                    ]
                }
                DispatchQueue.main.async { result(maps) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "KEYCHAIN_ERROR",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    private func handleMockTransaction(result: @escaping FlutterResult) {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let mock = TransactionPayload(
            id: "mock-\(UUID().uuidString.prefix(8))",
            bankId: "VCB",
            amountVnd: 1234567,
            sign: "credit",
            rawContent: "VCB: +1,234,567VND; SD: 10,000,000VND; Noi dung: Test thong bao tu Antigravity",
            timestampMs: now,
            createdAt: now
        )
        do {
            try keychainQueue.enqueue(mock)
            notifyNewTransaction()
            result(true)
        } catch {
            result(FlutterError(code: "MOCK_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // Mirrors LogTransactionIntent.perform() exactly — runs messageText through
    // BankRegexParser, builds payload with real idempotency key, enqueues to
    // KeychainQueue. Use this for debug testing instead of mockTransaction.
    private func handleSimulateBankNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let messageText = call.arguments as? String, !messageText.isEmpty else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "messageText must be a non-empty string", details: nil))
            return
        }
        guard let parsed = BankRegexParser.parse(text: messageText) else {
            result(FlutterError(code: "PARSE_FAILED", message: "Message did not match any known bank pattern", details: nil))
            return
        }
        let nowMs = Int64(Date().timeIntervalSince1970 * 1_000)
        let payload = TransactionPayload(
            id: idempotencyKey(bankId: parsed.bankId, amount: parsed.amountVnd, timestampMs: nowMs),
            bankId: parsed.bankId,
            amountVnd: parsed.amountVnd,
            sign: parsed.sign,
            rawContent: messageText,
            timestampMs: nowMs,
            createdAt: nowMs
        )
        do {
            try keychainQueue.enqueue(payload)
            notifyNewTransaction()
            result(true)
        } catch {
            result(FlutterError(code: "KEYCHAIN_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // SHA256(bankId_amount_⌊timestampMs/5000⌋) — mirrors Android NotificationProcessor
    private func idempotencyKey(bankId: String, amount: Int64, timestampMs: Int64) -> String {
        let window = timestampMs / 5_000
        let input  = Data("\(bankId)_\(amount)_\(window)".utf8)
        let digest = SHA256.hash(data: input)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Debug only: peek at KeychainQueue in two modes:
    //   withGroup  — uses App Group (what production code does)
    //   noGroup    — reads same item key without any access group
    // Returns "withGroup" and "noGroup" counts + statuses so we can tell
    // whether the App Group entitlement is actually shared between targets.
    // Saves dynamic regex rules to App Group UserDefaults so the extension
    // can read them in LogTransactionIntent.perform() at runtime.
    private func handleUpdateRegexConfig(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let rules = call.arguments as? [[String: Any]] else {
            result(nil)
            return
        }
        let defaults = UserDefaults(suiteName: "group.com.example.remind_spend")
        if let data = try? JSONSerialization.data(withJSONObject: rules) {
            defaults?.set(data, forKey: "dynamic_regex_rules")
            NSLog("[RemindSpend] updateRegexConfig: saved \(rules.count) rules to App Group UserDefaults")
        }
        result(nil)
    }

    private func handleDebugKeychainPeek(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .utility).async {
            let withGroup = KeychainQueue(accessGroup: "group.com.example.remind_spend",
                                          itemKey: "pending_transactions")
            let noGroup   = KeychainQueue(accessGroup: nil,
                                          itemKey: "pending_transactions")

            func probe(_ q: KeychainQueue) -> [String: Any] {
                do {
                    let items = try q.peek()
                    return ["count": items.count, "status": 0, "error": ""]
                } catch KeychainError.unexpectedStatus(let s) {
                    return ["count": -1, "status": Int(s), "error": "OSStatus \(s)"]
                } catch {
                    return ["count": -1, "status": -1, "error": error.localizedDescription]
                }
            }

            let r: [String: Any] = [
                "withGroup": probe(withGroup),
                "noGroup":   probe(noGroup)
            ]
            DispatchQueue.main.async { result(r) }
        }
    }

    private func handleRequestLocalNotificationPermission(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "NOTIF_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(granted)
                }
            }
        }
    }

    // 1. Tách biệt Data Model ra khỏi Business Logic
    private struct FinanceApp {
        let id: String
        let schemes: [String]
        
        static let supported: [FinanceApp] = [
            FinanceApp(id: "momo", schemes: ["momo"]),
            FinanceApp(id: "zalopay", schemes: ["zalopay"]),
            FinanceApp(id: "vcb", schemes: ["vietcombank", "vcbdigibank", "vcb"]),
            FinanceApp(id: "mb", schemes: ["mbbank", "mbmobile", "mb"]),
            FinanceApp(id: "bidv", schemes: ["bidvsmartbanking", "bidv"]),
            FinanceApp(id: "tcb", schemes: ["techcombank", "tcb", "fastmobile"]),
            FinanceApp(id: "vpb", schemes: ["vpbankneo", "vpbank"]),
            FinanceApp(id: "agr", schemes: ["agribankmobile", "agribank", "vba"]),
            FinanceApp(id: "tpb", schemes: ["tpbank", "tpbdigital"]),
            FinanceApp(id: "scb", schemes: ["sacombankpay", "sacombank"]),
            FinanceApp(id: "acb", schemes: ["acbapp", "acbonline", "acb"]),
            FinanceApp(id: "vtb", schemes: ["vietinbankipay", "vietinbank", "vtb"]),
        ]
    }

    // 2. Checks which finance apps are installed via canOpenURL.
    // Schemes must be declared in LSApplicationQueriesSchemes in Info.plist.
    private func handleDetectInstalledFinanceApps(result: @escaping FlutterResult) {
        // 3. Đảm bảo Thread-Safety cho UIApplication API
        DispatchQueue.main.async {
            let detected = FinanceApp.supported.compactMap { app -> String? in
                for scheme in app.schemes {
                    if let url = URL(string: "\(scheme)://"), UIApplication.shared.canOpenURL(url) {
                        return app.id
                    }
                }
                return nil
            }
            result(detected)
        }
    }

    private func openShortcutsApp(result: @escaping FlutterResult) {
        let url = ShortcutInstaller.installURL
        guard UIApplication.shared.canOpenURL(url) else {
            result(false)
            return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
            result(opened)
        }
    }

    private func handleSendLocalNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Title or Body is missing", details: nil))
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                result(FlutterError(code: "NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(true)
            }
        }
    }
}

// MARK: - FlutterStreamHandler

extension IOSBridgePlugin: FlutterStreamHandler {

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        // Emit the current (permanent) status immediately; no further events.
        events("not_applicable")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

// MARK: - TxEventStreamHandler

private class TxEventStreamHandler: NSObject, FlutterStreamHandler {
    private let onSinkChanged: (FlutterEventSink?) -> Void

    init(onSinkChanged: @escaping (FlutterEventSink?) -> Void) {
        self.onSinkChanged = onSinkChanged
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        onSinkChanged(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        onSinkChanged(nil)
        return nil
    }
}
