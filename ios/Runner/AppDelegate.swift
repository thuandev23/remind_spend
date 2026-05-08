import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    // Retained for the app's lifetime — FlutterMethodChannel holds only a weak reference.
    private var bridgePlugin: IOSBridgePlugin?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // super.application starts the Flutter engine and creates the window.
        // IOSBridgePlugin must be registered after this call so that
        // window?.rootViewController is already a FlutterViewController.
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        if let controller = window?.rootViewController as? FlutterViewController {
            let plugin = IOSBridgePlugin()
            plugin.register(with: controller.binaryMessenger)
            bridgePlugin = plugin
        }

        return result
    }
}
