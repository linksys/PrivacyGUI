import Flutter
import UIKit

public class SwiftUniversalLinkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    fileprivate var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
      
    let channel = FlutterMethodChannel(name: "universal_link_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftUniversalLinkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
      let eventChannel = FlutterEventChannel(name: "com.linksys.moab/universal_link", binaryMessenger: registrar.messenger())
      eventChannel.setStreamHandler(instance)
      registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
        
    // Universal Links
    public func application(
      _ application: UIApplication,
      continue userActivity: NSUserActivity,
      restorationHandler: @escaping ([Any]) -> Void) -> Bool {
      switch userActivity.activityType {
        case NSUserActivityTypeBrowsingWeb:
          guard let url = userActivity.webpageURL else {
            return false
          }
          handleLink(url: url)
          return false
        default: return false
      }
    }
    
    public func onListen(
      withArguments arguments: Any?,
      eventSink events: @escaping FlutterEventSink) -> FlutterError? {

      self.eventSink = events
      return nil
    }
      
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
      self.eventSink = nil
      return nil
    }

    fileprivate func handleLink(url: URL) -> Void {
      let link = url.absoluteString

      print("iOS handleLink: \(link)")
      
      guard let _eventSink = eventSink else {
        return
      }

      _eventSink(link)
    }
}
