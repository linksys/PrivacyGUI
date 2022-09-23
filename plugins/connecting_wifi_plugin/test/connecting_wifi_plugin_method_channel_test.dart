import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connecting_wifi_plugin/connecting_wifi_plugin_method_channel.dart';

void main() {
  MethodChannelConnectingWifiPlugin platform = MethodChannelConnectingWifiPlugin();
  const MethodChannel channel = MethodChannel('com.linksys.native.channel.wifi.connect');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if(methodCall.method == 'connectToWiFi') {
        return true;
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('connectToWiFi', () async {
    expect(await platform.connectToWiFi(ssid: 'ssid', password: 'password'), true);
  });
}
