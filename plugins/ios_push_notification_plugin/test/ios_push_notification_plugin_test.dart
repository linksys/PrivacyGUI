import 'package:flutter_test/flutter_test.dart';
import 'package:ios_push_notification_plugin/ios_push_notification_plugin.dart';
import 'package:ios_push_notification_plugin/ios_push_notification_plugin_platform_interface.dart';
import 'package:ios_push_notification_plugin/ios_push_notification_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIosPushNotificationPluginPlatform
    with MockPlatformInterfaceMixin
    implements IosPushNotificationPluginPlatform {

  @override
  Stream get pushNotificationStream => throw UnimplementedError();

  @override
  Future<String?> readApnsToken() => Future.value('MOCK APNS TOKEN');

  @override
  Future<bool> requestAuthorization() => Future(() => true);
}

void main() {
  final IosPushNotificationPluginPlatform initialPlatform = IosPushNotificationPluginPlatform.instance;

  test('$MethodChannelIosPushNotificationPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIosPushNotificationPlugin>());
  });

  test('readApnsToken', () async {
    IosPushNotificationPlugin iosPushNotificationPlugin = IosPushNotificationPlugin();
    MockIosPushNotificationPluginPlatform fakePlatform = MockIosPushNotificationPluginPlatform();
    IosPushNotificationPluginPlatform.instance = fakePlatform;

    expect(await iosPushNotificationPlugin.readApnsToken(), 'MOCK APNS TOKEN');
  });
}
