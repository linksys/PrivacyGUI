import Flutter
import UIKit
import NetworkExtension

public class SwiftConnectingWifiPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.linksys.native.channel.wifi.connect", binaryMessenger: registrar.messenger())
    let instance = SwiftConnectingWifiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if call.method == "connectToWiFi" {
          guard let args = call.arguments as? [String : Any] else {return}
          let ssid = args["ssid"] as? String
          let password = args["password"] as? String
          if #available(iOS 11.0, *) {
              self.connectToWiFi(result: result, ssid: ssid!, password: password!)
          } else {
              // Fallback on earlier versions
          }
      } else {
          
      }
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
