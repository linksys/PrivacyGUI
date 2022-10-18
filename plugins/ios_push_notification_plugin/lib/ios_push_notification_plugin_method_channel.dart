import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_push_notification_plugin_platform_interface.dart';

/// An implementation of [IosPushNotificationPluginPlatform] that uses method channels.
class MethodChannelIosPushNotificationPlugin extends IosPushNotificationPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ios_push_notification_plugin');
  @visibleForTesting
  final eventChannel = const EventChannel('ios_push_notification_plugin/stream');
  
  @override
  Future<String?> readApnsToken() {
    return methodChannel.invokeMethod('readDeviceToken');
  }
  @override
  Future<bool> requestAuthorization() async {
    return await methodChannel.invokeMethod('requestNotificationAuthorization');
  }
  @override
  Stream<dynamic> get pushNotificationStream => eventChannel.receiveBroadcastStream();

}
