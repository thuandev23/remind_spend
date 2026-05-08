import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {

    // Retained for the app's lifetime — FlutterMethodChannel holds only a weak reference.
    private var bridgePlugin: IOSBridgePlugin?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Register Workmanager
        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }
        WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "com.example.remind_spend.bgPull")

        // super.application starts the Flutter engine and creates the window.
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        if let controller = window?.rootViewController as? FlutterViewController {
            let plugin = IOSBridgePlugin()
            plugin.register(with: controller.binaryMessenger)
            bridgePlugin = plugin
            
            // Mock a transaction for testing right now
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            let mock = TransactionPayload(
                id: "init-mock-\(UUID().uuidString.prefix(4))",
                bankId: "VCB",
                amountVnd: 500000,
                sign: "credit",
                rawContent: "VCB: +500,000VND; Test tu dong khi mo app",
                timestampMs: now,
                createdAt: now
            )
            try? KeychainQueue.shared.enqueue(mock)
        }

        return result
    }
}
