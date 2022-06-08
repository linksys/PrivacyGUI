import UIKit
import Flutter
import NetworkExtension
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      FirebaseApp.configure()
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let connectWiFiChannel = FlutterMethodChannel(name: "com.linksys.native.channel.wifi.connect",
                                                binaryMessenger: controller.binaryMessenger)
      connectWiFiChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        
          if call.method == "connectToWiFi" {
              guard let args = call.arguments as? [String : Any] else {return}
              let ssid = args["ssid"] as? String
              let password = args["password"] as? String
              if #available(iOS 11.0, *) {
                  self.connectToWiFi(result: result, ssid: ssid!, password: password!)
              } else {
                  // Fallback on earlier versions
              }
          }
      })

      GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    @available(iOS 11.0, *)
    private func connectToWiFi(result: @escaping FlutterResult, ssid: String, password: String) {
        let hotspotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
                hotspotConfig.joinOnce = false
        NEHotspotConfigurationManager.shared.apply(hotspotConfig) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                result(false)
            } else {
                print("No error, you can check the connection")
                result(true)
            }
        }
    }
}
