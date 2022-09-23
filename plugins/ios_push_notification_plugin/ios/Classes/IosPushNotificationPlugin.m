#import "IosPushNotificationPlugin.h"
#if __has_include(<ios_push_notification_plugin/ios_push_notification_plugin-Swift.h>)
#import <ios_push_notification_plugin/ios_push_notification_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ios_push_notification_plugin-Swift.h"
#endif

@implementation IosPushNotificationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftIosPushNotificationPlugin registerWithRegistrar:registrar];
}
@end
