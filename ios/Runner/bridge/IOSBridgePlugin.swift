import Flutter
import Foundation
import UIKit

/// iOS counterpart of Android's NativeBridgePlugin.
/// Handles the same MethodChannel and EventChannel contracts so the Flutter
/// BridgeService works identically on both platforms.
///
/// Registration: call `register(with:)` from AppDelegate after
/// GeneratedPluginRegistrant.register(). Hold a strong reference to the
/// returned instance for the app's lifetime.
final class IOSBridgePlugin: NSObject {

    static let methodChannelName = "com.example.remind_spend/transaction_bridge"
    static let eventChannelName  = "com.example.remind_spend/permission_status"

    private let keychainQueue: KeychainQueue

    init(keychainQueue: KeychainQueue = .shared) {
        self.keychainQueue = keychainQueue
    }

    /// Wires up both channels. Must be called once, on the main thread.
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

        case "requestBatteryOptimizationWhitelist":
            result(nil)    // no-op

        case "clearIdempotencyCache":
            result(nil)    // no-op: Shortcuts deduplication is handled at the OS level

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
                let maps: [[String: Any]] = items.map { tx in
                    [
                        "id":           tx.id,
                        "package_name": tx.bankId,   // iOS has no package name; reuse bankId
                        "bank_id":      tx.bankId,
                        "amount_vnd":   tx.amountVnd,
                        "sign":         tx.sign,
                        "timestamp_ms": tx.timestampMs,
                        "created_at":   tx.createdAt
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
            result(true)
        } catch {
            result(FlutterError(code: "MOCK_ERROR", message: error.localizedDescription, details: nil))
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
