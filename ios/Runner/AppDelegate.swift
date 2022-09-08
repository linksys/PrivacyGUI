import UIKit
import Flutter
import NetworkExtension
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var currentDeviceToken: String?
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      FirebaseApp.configure()
      UNUserNotificationCenter.current().delegate = self
      UIApplication.shared.registerForRemoteNotifications()
      
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

      let deviceTokenChannel = FlutterMethodChannel(name: "moab.notification/device.token",
                                                    binaryMessenger: controller.binaryMessenger)
      deviceTokenChannel.setMethodCallHandler { [weak self] call, result in
          guard call.method == "readDeviceToken" else {
              result(FlutterMethodNotImplemented)
              return
          }
          if let deviceToken = self?.currentDeviceToken {
              result(deviceToken)
          } else {
              result(FlutterError(code: "Failed", message: "Device token is nil", details: nil))
          }
      }
      
      let notificationAuthChannel = FlutterMethodChannel(name: "moab.notification/authorization",
                                                         binaryMessenger: controller.binaryMessenger)
      notificationAuthChannel.setMethodCallHandler{ [weak self] call, result in
          guard call.method == "requestNotificationAuthorization" else {
              result(FlutterMethodNotImplemented)
              return
          }
          self?.requestNotificationAuthorization(result: result)
      }
      
      let notificationContentChannel = FlutterEventChannel(name: "moab.notification/payload", binaryMessenger: controller.binaryMessenger)
      notificationContentChannel.setStreamHandler(NotificationContentStreamHandler())

      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("AppDelegate: Register APNs succeeded")
        let tokenComponents = deviceToken.map{ data in String(format: "%02.2hhx", data)}
        currentDeviceToken = tokenComponents.joined()
    }
    
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Register APNs failed: \(error.localizedDescription)")
    }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("AppDelegate: willPresent notification: userInfo=\(notification.request.content.userInfo)")
        // Do nothing unless the user taps the notification to open the app
        completionHandler(UNNotificationPresentationOptions.banner)
    }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("AppDelegate: didReceive response: userInfo=\(userInfo)")

        if let payload = userInfo["aps"] as? [String: Any] {
            NotificationCenter.default.post(
                name: NSNotification.Name("ReceiveAPNsPayloadNotification"),
                object: nil,
                userInfo: ["data": payload])
        }
        completionHandler()
    }
    
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("AppDelegate: didReceiveRemoteNotification: userInfo=\(userInfo)")

        if let _ = userInfo["aps"] {
            if let payload = userInfo["data"] as? [String: Any] {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ReceiveAPNsPayloadNotification"),
                    object: nil,
                    userInfo: ["data": payload])
            }
        }
        completionHandler(UIBackgroundFetchResult.noData)
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

class NotificationContentStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sendEvent(_:)),
            name: NSNotification.Name("ReceiveAPNsPayloadNotification"),
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
        guard let userInfo = notification.userInfo, let data = userInfo["data"] else {
            return
        }
        eventSink(data)
    }
}
