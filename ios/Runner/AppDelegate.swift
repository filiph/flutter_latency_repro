import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var metalChannel: FlutterMethodChannel?
    private var metalViewController: DirectMetalViewController?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller = window?.rootViewController as! FlutterViewController

        metalChannel = FlutterMethodChannel(name: "metal_renderer", binaryMessenger: controller.binaryMessenger)
        metalChannel?.setMethodCallHandler(handleMetalChannelCall)

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func handleMetalChannelCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let controller = window?.rootViewController as! FlutterViewController

        switch call.method {
        case "pushMetalRenderer":
            metalViewController = DirectMetalViewController()
            if let args = call.arguments as? [String: Any] {
                metalViewController?.configure(with: args)
            }
            controller.present(metalViewController!, animated: false, completion: nil)
            result(nil)

        case "updateSpriteData":
            if let args = call.arguments as? [String: Any] {
                metalViewController?.updateSprites(args)
            }
            result(nil)

        case "popMetalRenderer":
            metalViewController?.dismiss(animated: false, completion: nil)
            metalViewController = nil
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
