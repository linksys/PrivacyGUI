#import "ConnectingWifiPlugin.h"
#if __has_include(<connecting_wifi_plugin/connecting_wifi_plugin-Swift.h>)
#import <connecting_wifi_plugin/connecting_wifi_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "connecting_wifi_plugin-Swift.h"
#endif

@implementation ConnectingWifiPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftConnectingWifiPlugin registerWithRegistrar:registrar];
}
@end
