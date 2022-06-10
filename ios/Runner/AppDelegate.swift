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
      
      let universalLinkChannel = FlutterEventChannel(name: "otp.code.input.view/deeplink",
                                                     binaryMessenger: controller.binaryMessenger)
      universalLinkChannel.setStreamHandler(UniversalLinkStreamHandler())

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
    
    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        guard let url = userActivity.webpageURL,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              userActivity.activityType == NSUserActivityTypeBrowsingWeb else { return false }
        
        print("Universal link: \(url)")
        if components.path.contains("otp") {  //TODO: Depend on the real URL
            for item in components.queryItems ?? [] {
                if item.name == "code", let code = item.value {  //TODO: Depend on the real URL
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UniversalLinkActivityNotification"),
                        object: nil,
                        userInfo: ["code": code])
                }
            }
        }
        
        return false
    }
}

class UniversalLinkStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sendEvent(_:)),
            name: NSNotification.Name("UniversalLinkActivityNotification"),
            object: nil
        )
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
    
    @objc func sendEvent(_ notification: NSNotification) {
        guard let eventSink = eventSink else {
            return
        }
        guard let userInfo = notification.userInfo, let code = userInfo["code"] else {
            return
        }
        eventSink(code)
    }
    
}
