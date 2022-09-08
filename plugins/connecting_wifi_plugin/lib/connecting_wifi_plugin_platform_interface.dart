import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'connecting_wifi_plugin_method_channel.dart';

abstract class ConnectingWifiPluginPlatform extends PlatformInterface {
  /// Constructs a ConnectingWifiPluginPlatform.
  ConnectingWifiPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ConnectingWifiPluginPlatform _instance = MethodChannelConnectingWifiPlugin();

  /// The default instance of [ConnectingWifiPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelConnectingWifiPlugin].
  static ConnectingWifiPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ConnectingWifiPluginPlatform] when
  /// they register themselves.
  static set instance(ConnectingWifiPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> connectToWiFi({required String ssid, required String password, String security = "OPEN"}) async {
    throw UnimplementedError('connectToWiFi() has not been implemented.');
  }

  // Android only
  Future<bool> isAndroidVersionUnderTen() async {
    throw UnimplementedError('isAndroidVersionUnderTen() has not been implemented.');
  }

  // Android only
  Future<bool> isAndroidTenAndSupportEasyConnect() async {
    throw UnimplementedError('isAndroidTenAndSupportEasyConnect() has not been implemented.');
  }
}
