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

  connectToWiFi(String ssid, String password) async {
    try {
      return await _platform
          .invokeMethod('connectToWiFi', {'ssid': ssid, 'password': password});
    } on PlatformException catch (e) {
      log(e.message ?? "");
      return false;
    }
  }
}
