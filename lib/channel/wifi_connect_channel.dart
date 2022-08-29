import 'dart:developer';

import 'package:flutter/services.dart';

class NativeConnectWiFiChannel {
  static const _platform =
  MethodChannel('com.linksys.native.channel.wifi.connect');

  // Singleton
  static final NativeConnectWiFiChannel _singleton =
  NativeConnectWiFiChannel._internal();

  factory NativeConnectWiFiChannel() {
    return _singleton;
  }

  NativeConnectWiFiChannel._internal();

  connectToWiFi({required String ssid, required String password, String security = "OPEN"}) async {
    return await _platform
        .invokeMethod('connectToWiFi', {'ssid': ssid, 'password': password, 'security': security});
  }

  isAndroidVersionUnderTen() async {
    return await _platform.invokeMethod('checkAndroidVersionUnderTen');
  }

  isAndroidTenAndSupportEasyConnect() async {
    return await _platform.invokeMethod('isAndroidTenAndSupportEasyConnect');
  }
}
