import Flutter
import UIKit

@available(iOS 14.0, *)
public class SwiftIosPushNotificationPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, FlutterApplicationLifeCycleDelegate, UNUserNotificationCenterDelegate {
    fileprivate var eventSink: FlutterEventSink?
    fileprivate var currentDeviceToken: String?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ios_push_notification_plugin", binaryMessenger: registrar.messenger())
        let instance = SwiftIosPushNotificationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let notificationContentChannel = FlutterEventChannel(name: "ios_push_notification_plugin/stream", binaryMessenger: registrar.messenger())
        notificationContentChannel.setStreamHandler(instance)
        registrar.addApplicationDelegate(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "readDeviceToken" {
            if let deviceToken = currentDeviceToken {
                result(deviceToken)
            } else {
                result(FlutterError(code: "Failed", message: "Device token is nil", details: nil))
            }
        } else if call.method == "requestNotificationAuthorization" {
            self.requestNotificationAuthorization(result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sendEvent(_:)),
            name: NSNotification.Name("ReceiveAPNsPayloadNotification"),
            object: nil
        )
        eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
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
    public func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any]
    ) -> Bool {
        print("AppDelegate: didFinishLaunchingWithOptions")
        UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = self
        return false
    }
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("AppDelegate: Register APNs succeeded! \(deviceToken)")
        let tokenComponents = deviceToken.map{ data in String(format: "%02.2hhx", data)}
        currentDeviceToken = tokenComponents.joined()
        print("AppDelegate: APNs token: \(String(describing: currentDeviceToken))")

    }
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Register APNs failed: \(error.localizedDescription)")
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        print("AppDelegate: didReceiveRemoteNotification: userInfo=\(userInfo)")

        if let _ = userInfo["aps"] {
            if let payload = userInfo["data"] as? [String: Any] {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ReceiveAPNsPayloadNotification"),
                    object: nil,
                    userInfo: ["data": payload])
                return true
            }
        }
        completionHandler(UIBackgroundFetchResult.noData)
        return false
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
    
    /*  Called when the application is in the foreground. We get a UNNotification object that contains the UNNotificationRequest request. In the body of the method, you need to make a completion handler call with a set of options to notify UNNotificationPresentationOptions
     */
    @available(iOS 14.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("AppDelegate: willPresent notification: userInfo=\(notification.request.content.userInfo)")
        // Do nothing unless the user taps the notification to open the app
        completionHandler(UNNotificationPresentationOptions.banner)
    }
    
    /*  Used to select a tap action for notification. You get a UNNotificationResponse object that contains an actionIdentifier to define an action. The system identifiers UNNotificationDefaultActionIdentifier and UNNotificationDismissActionIdentifier are used when you need to open the application by tap on a notification or close a notification with a swipe.
     */
    @available(iOS 14.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
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
    
}
