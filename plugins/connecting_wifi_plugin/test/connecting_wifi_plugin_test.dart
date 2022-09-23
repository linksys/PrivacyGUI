import 'package:flutter_test/flutter_test.dart';
import 'package:connecting_wifi_plugin/connecting_wifi_plugin.dart';
import 'package:connecting_wifi_plugin/connecting_wifi_plugin_platform_interface.dart';
import 'package:connecting_wifi_plugin/connecting_wifi_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockConnectingWifiPluginPlatform
    with MockPlatformInterfaceMixin
    implements ConnectingWifiPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> connectToWiFi({required String ssid, required String password, String security = "OPEN"}) => Future.value(true);

  @override
  Future<bool> isAndroidTenAndSupportEasyConnect() => Future.value(true);

  @override
  Future<bool> isAndroidVersionUnderTen() => Future.value(true);
}

void main() {
  final ConnectingWifiPluginPlatform initialPlatform = ConnectingWifiPluginPlatform.instance;

  test('$MethodChannelConnectingWifiPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelConnectingWifiPlugin>());
  });

  test('connectToWiFi', () async {
    ConnectingWifiPlugin connectingWifiPlugin = ConnectingWifiPlugin();
    MockConnectingWifiPluginPlatform fakePlatform = MockConnectingWifiPluginPlatform();
    ConnectingWifiPluginPlatform.instance = fakePlatform;

    expect(await connectingWifiPlugin.connectToWiFi(ssid: 'ssid', password: 'password'), true);
  });
}
