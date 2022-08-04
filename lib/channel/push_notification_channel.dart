
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:moab_poc/util/logger.dart';

class PushNotificationChannel {
//TODO: Move to another place
  static const notificationAuthChannel =
      MethodChannel('otp.view/notification.auth');
  static const deviceTokenChannel = MethodChannel('otp.view/device.token');
  static const notificationContentChannel =
      EventChannel('moab.dev/notification.payload');

  // Singleton
  static final PushNotificationChannel _singleton =
      PushNotificationChannel._internal();

  factory PushNotificationChannel() {
    return _singleton;
  }

  PushNotificationChannel._internal();

  Future<String> readDeviceToken() async {
    if (Platform.isIOS) {
      return await deviceTokenChannel.invokeMethod('readDeviceToken');
    }
    return '';
  }

  Future<bool> grantNotificationAuth() async {
    if (Platform.isIOS) {
      final isGrant = await notificationAuthChannel
          .invokeMethod('requestNotificationAuthorization');
      logger.i('Is Grant: $isGrant');
      return isGrant;
    } else {
      return false;
    }
  }

  Stream listenPushNotification() {
    if (Platform.isIOS) {
      return notificationContentChannel.receiveBroadcastStream();
    } else {
      throw UnsupportedError('Not soupported');
    }
  }
}
