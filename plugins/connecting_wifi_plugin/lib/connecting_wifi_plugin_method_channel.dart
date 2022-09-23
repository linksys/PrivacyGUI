import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'connecting_wifi_plugin_platform_interface.dart';

/// An implementation of [ConnectingWifiPluginPlatform] that uses method channels.
class MethodChannelConnectingWifiPlugin extends ConnectingWifiPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.linksys.native.channel.wifi.connect');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> connectToWiFi({required String ssid, required String password, String security = "OPEN"}) async {
    return await methodChannel
        .invokeMethod('connectToWiFi', {'ssid': ssid, 'password': password, 'security': security});
  }

  // Android only
  @override
  Future<bool> isAndroidVersionUnderTen() async {
    return await methodChannel.invokeMethod('checkAndroidVersionUnderTen');
  }

  // Android only
  @override
  Future<bool> isAndroidTenAndSupportEasyConnect() async {
    return await methodChannel.invokeMethod('isAndroidTenAndSupportEasyConnect');
  }
}
