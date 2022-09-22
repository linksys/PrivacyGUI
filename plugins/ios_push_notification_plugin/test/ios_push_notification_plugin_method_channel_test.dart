import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_push_notification_plugin/ios_push_notification_plugin_method_channel.dart';

void main() {
  MethodChannelIosPushNotificationPlugin platform = MethodChannelIosPushNotificationPlugin();
  const MethodChannel channel = MethodChannel('ios_push_notification_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return 'MOCK APNS TOKEN';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('readApnsToken', () async {
    expect(await platform.readApnsToken(), 'MOCK APNS TOKEN');
  });
}
