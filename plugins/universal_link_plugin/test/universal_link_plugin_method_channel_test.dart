import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_link_plugin/universal_link_plugin_method_channel.dart';

void main() {
  MethodChannelUniversalLinkPlugin platform = MethodChannelUniversalLinkPlugin();
  const MethodChannel channel = MethodChannel('universal_link_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
