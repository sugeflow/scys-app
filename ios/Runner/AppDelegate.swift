import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  static var navigationChannel: FlutterMethodChannel?
  static var selectNativeTab: ((Int) -> Void)?
  static var setNativeTabBarVisible: ((Bool) -> Void)?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    Self.navigationChannel = FlutterMethodChannel(
      name: "me.suge.scys/navigation",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    Self.navigationChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "setSelectedTab":
        guard let index = call.arguments as? Int else {
          result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
          return
        }
        DispatchQueue.main.async {
          Self.selectNativeTab?(index)
          result(nil)
        }
      case "setTabBarVisible":
        guard let isVisible = call.arguments as? Bool else {
          result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
          return
        }
        DispatchQueue.main.async {
          Self.setNativeTabBarVisible?(isVisible)
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
