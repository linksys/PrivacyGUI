import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'notification_receiver.dart';

StreamSubscription? apnsStreamSubscription;
StreamSubscription? tokenStreamSubscription;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("Handling a background message: ${message.messageId}");
}

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

///
Future initCloudMessage(void Function(String? token) onGet) async {
  if (kIsWeb) {
    await _initCloudMessageWeb(onGet);
  }
}

/// Request Notification Permission
Future requestNotificationPermission() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  return FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
}

Future<String?> getToken() {
  return FirebaseMessaging.instance.getToken(
      vapidKey:
          'BFSsxlFG5VQ5j1S99weYRQa12vmH9h1AL888jUgrLrNjKegy6MwB0_EJ9yoLs1Znfc3oizB0RNOTqdbg8T4GV88');
}

/// Web Push notification initialize
Future<String?> _initCloudMessageWeb(void Function(String? token) onGet) async {
  logger.d('[Notification][WEB] init and check permission.');
  NotificationSettings newSettings = await requestNotificationPermission();
  logger
      .d('[Notification][WEB] permission - ${newSettings.authorizationStatus}');

  if (newSettings.authorizationStatus != AuthorizationStatus.authorized) {
    return null;
  }

  await Future.delayed(const Duration(seconds: 1));
  logger.d('[Notification][WEB] Get Token.');

  final token = await getToken().then((token) {
    onGet(token);
  }).onError((error, stackTrace) {
    logger.d('[Notification][WEB] get Token Error: $error');
    // retry once
    _initCloudMessageWeb(onGet);
  });
  return token;
}

///
Future removeCloudMessage() {
  logger.d('[Notification] Remove Token.');
  return FirebaseMessaging.instance
      .deleteToken()
      .then((_) => SharedPreferences.getInstance())
      .then((prefs) {
    prefs.remove(pDeviceToken);
  }).onError((error, stackTrace) async {
    (await SharedPreferences.getInstance()).remove(pDeviceToken);
  });
}
