
import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ios_push_notification_plugin/ios_push_notification_plugin.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/constants/pref_key.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'notification_receiver.dart';

StreamSubscription? apnsStreamSubscription;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("Handling a background message: ${message.messageId}");
}

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

/// Push notification initialize
void initCloudMessage() async {
  if (Platform.isIOS) {
    // Get the device token from the native
    final token = await IosPushNotificationPlugin().readApnsToken() ?? '';
    logger.i('APNS: Read device token: $token');
    CloudEnvironmentManager().updateDeviceToken(token);
    // Start listening the push notifications
    apnsStreamSubscription = IosPushNotificationPlugin()
        .pushNotificationStream
        .listen((data) {
          Map<String, dynamic> transfer = Map.from(data);
          logger.d('APNS: Receive push notification, data: $transfer');
          pushNotificationHandler(transfer);
    });
    // Ask users notification authorization
    IosPushNotificationPlugin().requestAuthorization().then((grant) {
      logger.i('APNS: User authorization result: $grant');
    });
    logger.i('APNS token back: ${(await SharedPreferences.getInstance()).getString(linksysPrefDeviceToken)}');
    return;
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (!kIsWeb) {
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
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
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
              android: AndroidNotificationDetails(channel.id, channel.name,
                  channelDescription: channel.description,
                  icon: 'launch_foreground')));
    } else if (notification == null) { // Silent message
      pushNotificationHandler(message.data);
    }
  });
  final token = await FirebaseMessaging.instance.getToken();
  logger.i('FCM Token: $token');
  CloudEnvironmentManager().updateDeviceToken(token ?? '');
}