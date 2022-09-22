
import 'dart:io';

import 'ios_push_notification_plugin_platform_interface.dart';

class IosPushNotificationPlugin {
  Future<String?> readApnsToken() {
    return IosPushNotificationPluginPlatform.instance.readApnsToken();
  }
  Future<bool> requestAuthorization() {
    return IosPushNotificationPluginPlatform.instance.requestAuthorization();
  }

  Stream<dynamic> get pushNotificationStream => IosPushNotificationPluginPlatform.instance.pushNotificationStream;
}
