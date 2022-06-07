import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/route/route.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'firebase_options.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
// FlutterLocalNotificationsPlugin();
// AndroidNotificationChannel? channel;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');
  String? token = await FirebaseMessaging.instance.getToken();
  String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
  print('Token:: FCM:${token ?? ''}, APNS:${apnsToken ?? ''}');

  // if (Platform.isIOS) {
  //   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  // } else if (Platform.isAndroid) {
  //
  //   channel = const AndroidNotificationChannel(
  //     'moab_main_channel', // id
  //     'High Importance Notifications', // title
  //     description: 'This channel is used for important notifications.', // description
  //     importance: Importance.max,
  //   );
  //
  //   const AndroidInitializationSettings initializationSettingsAndroid =
  //   AndroidInitializationSettings('@mipmap/ic_launcher');
  //   const InitializationSettings initializationSettings = InitializationSettings(
  //     android: initializationSettingsAndroid,
  //   );
  //   await flutterLocalNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  //       ?.createNotificationChannel(channel!);
  //   await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // }

  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   print('Got a message whilst in the foreground!');
  //   print('Message data: ${message.data}');
  //   print('Message notification: ${message.notification}');
  //
  //   if (message.notification != null) {
  //     print('Message also contained a notification: ${message.notification}');
  //   }
  //
  //   // If `onMessage` is triggered with a notification, construct our own
  //   // local notification to show to users using the created channel.
  //   RemoteNotification? notification = message.notification;
  //   AndroidNotification? android = message.notification?.android;
  //   if (notification != null && android != null) {
  //     flutterLocalNotificationsPlugin.show(
  //         notification.hashCode,
  //         notification.title,
  //         notification.body,
  //         NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             channel!.id,
  //             channel!.name,
  //             channelDescription: channel!.description,
  //             icon: android.smallIcon,
  //             // other properties...
  //           ),
  //         ));
  //   }
  // });
  runApp(const NavigatorDemo());
}

class NavigatorDemo extends StatelessWidget {
  const NavigatorDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.app_title,
      theme: MoabTheme.setupModuleLightModeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: SetupRouterDelegate(),
      routeInformationParser: SetupRouteInformationParser(),
    );
  }
}
