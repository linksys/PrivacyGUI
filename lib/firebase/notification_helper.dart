import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ios_push_notification_plugin/ios_push_notification_plugin.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:linksys_app/core/utils/logger.dart';
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
  } else {
    await _initCloudMessageMobile();
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

  final token = await getToken()
      .then((token) {
    onGet(token);
  }).onError((error, stackTrace) {
    logger.d('[Notification][WEB] get Token Error: $error');
    // retry once
    _initCloudMessageWeb(onGet);
  });
  return token;
}

/// Mobile Push notification initialize
Future _initCloudMessageMobile() async {
  if (Platform.isIOS) {
    // Get the device token from the native
    final token = await IosPushNotificationPlugin().readApnsToken();
    if (token != null) {
      (await SharedPreferences.getInstance()).setString(pDeviceToken, token);
    }
    logger.i('APNS: Read device token: $token');
    // Start listening the push notifications
    apnsStreamSubscription =
        IosPushNotificationPlugin().pushNotificationStream.listen((data) {
      Map<String, dynamic> transfer = Map.from(data);
      logger.d('APNS: Receive push notification, data: $transfer');
      pushNotificationHandler(transfer);
    });
    // Ask users notification authorization
    IosPushNotificationPlugin().requestAuthorization().then((grant) {
      logger.i('APNS: User authorization result: $grant');
    });
    logger.i(
        'APNS token back: ${(await SharedPreferences.getInstance()).getString(pDeviceToken)}');
    return;
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (Platform.isAndroid) {
    channel = const AndroidNotificationChannel(
        'high_importance_channel', 'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high);
  }
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true);
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    logger.d('Got a message while in the foreground!');
    logger.d('Message data: ${message.data}');
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
          ),
        ),
      );
    } else if (notification == null) {
      // Silent message
      pushNotificationHandler(message.data);
    }
  });

  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    (await SharedPreferences.getInstance()).setString(pDeviceToken, token);
  }
  logger.i('Mobile FCM Token: $token');
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
