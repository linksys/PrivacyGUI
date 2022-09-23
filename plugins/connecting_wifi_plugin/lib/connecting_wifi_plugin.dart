
import 'connecting_wifi_plugin_platform_interface.dart';

class ConnectingWifiPlugin {
  Future<String?> getPlatformVersion() {
    return ConnectingWifiPluginPlatform.instance.getPlatformVersion();
  }

  Future<bool> connectToWiFi({required String ssid, required String password, String security = "OPEN"}) {
    return ConnectingWifiPluginPlatform.instance.connectToWiFi(ssid: ssid, password: password, security: security);
  }

  Future<bool> isAndroidVersionUnderTen() {
    return  ConnectingWifiPluginPlatform.instance.isAndroidVersionUnderTen();
  }

  Future<bool> isAndroidTenAndSupportEasyConnect() {
    return ConnectingWifiPluginPlatform.instance.isAndroidTenAndSupportEasyConnect();
  }
}
