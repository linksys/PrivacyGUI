import UIKit
import Flutter
import NetworkExtension
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var deviceToken: String?
    var notificationContent: Dictionary<String, Any>?
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      FirebaseApp.configure()
      UNUserNotificationCenter.current().delegate = self
      UIApplication.shared.registerForRemoteNotifications()
      
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      
      let connectWiFiChannel = FlutterMethodChannel(name: "com.linksys.native.channel.wifi.connect",
                                                    binaryMessenger: controller.binaryMessenger)
      connectWiFiChannel.setMethodCallHandler({
        [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        
          if call.method == "connectToWiFi" {
              guard let args = call.arguments as? [String : Any] else {return}
              let ssid = args["ssid"] as? String
              let password = args["password"] as? String
              if #available(iOS 11.0, *) {
                  self?.connectToWiFi(result: result, ssid: ssid!, password: password!)
              } else {
                  // Fallback on earlier versions
              }
          }
      })
      
      let deviceTokenChannel = FlutterMethodChannel(name: "otp.view/device.token",
                                                    binaryMessenger: controller.binaryMessenger)
      deviceTokenChannel.setMethodCallHandler { [weak self] call, result in
          guard call.method == "readDeviceToken" else {
              result(FlutterMethodNotImplemented)
              return
          }
          if let deviceToken = self?.deviceToken {
              result(deviceToken)
          } else {
              result(FlutterError(code: "Failed", message: "Device token is nil", details: nil))
          }
      }
      
      let notificationContentChannel = FlutterEventChannel(name: "moab.dev/notification.payload", binaryMessenger: controller.binaryMessenger)
      notificationContentChannel.setStreamHandler(NotificationContentStreamHandler())
      
      let notificationAuthChannel = FlutterMethodChannel(name: "otp.view/notification.auth",
                                                         binaryMessenger: controller.binaryMessenger)
      notificationAuthChannel.setMethodCallHandler{ [weak self] call, result in
          guard call.method == "requestNotificationAuthorization" else {
              result(FlutterMethodNotImplemented)
              return
          }
          self?.requestNotificationAuthorization(result: result)
      }
      
      let universalLinkChannel = FlutterEventChannel(name: "com.linksys.moab/universal_link",
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
        if url.host!.contains("devvelopcloud.com") {  //TODO: Depend on the real URL
            NotificationCenter.default.post(
                name: NSNotification.Name("UniversalLinkActivityNotification"),
                object: nil,
                userInfo: ["url": url.absoluteString])
        }
        
        return false
    }
    
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("AppDelegate: Register APNs succeeded")
        let tokenComponents = deviceToken.map{ data in String(format: "%02.2hhx", data)}
        self.deviceToken = tokenComponents.joined()
    }
    
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Register APNs failed: \(error.localizedDescription)")
    }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        self.notificationContent = userInfo["aps"] as? Dictionary<String, Any>
        if let payload = notificationContent {
            NotificationCenter.default.post(
                name: NSNotification.Name("ApnsPayloadNotification"),
                object: nil,
                userInfo: ["content": payload])
        }
        print("AppDelegate: willPresent notification: userInfo=\(notification.request.content.userInfo)")
        completionHandler(UNNotificationPresentationOptions.banner)
    }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        self.notificationContent = userInfo["aps"] as? Dictionary<String, Any>
        if let payload = notificationContent {
            NotificationCenter.default.post(
                name: NSNotification.Name("ApnsPayloadNotification"),
                object: nil,
                userInfo: ["content": payload])
        }
        print("AppDelegate: didReceive response: userInfo=\(userInfo)")
        completionHandler()
    }
    
    private func requestNotificationAuthorization(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { grant, error in
            if let _ = error {
                result(FlutterError(code: "Failed", message: error.debugDescription, details: nil))
            } else {
                result(grant)
            }
        }
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
        guard let userInfo = notification.userInfo, let url = userInfo["url"] else { // TODO
            return
        }
        eventSink(url)
    }
    
}

class NotificationContentStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sendEvent(_:)),
            name: NSNotification.Name("ApnsPayloadNotification"),
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
        guard let userInfo = notification.userInfo, let content = userInfo["content"] else {
            return
        }
        eventSink(content)
    }
}
