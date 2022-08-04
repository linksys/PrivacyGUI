import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moab_poc/bloc/app_lifecycle/cubit.dart';
import 'package:moab_poc/bloc/auth/bloc.dart';
import 'package:moab_poc/bloc/auth/event.dart';
import 'package:moab_poc/bloc/connectivity/cubit.dart';
import 'package:moab_poc/channel/push_notification_channel.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/network/http/http_client.dart';
import 'package:moab_poc/repository/authenticate/impl/cloud_auth_repository.dart';
import 'package:moab_poc/repository/config/environment_repository.dart';
import 'package:moab_poc/route/route.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/util/storage.dart';
import 'bloc/setup/bloc.dart';
import 'firebase_options.dart';
import 'repository/authenticate/impl/fake_auth_repository.dart';
import 'repository/authenticate/impl/fake_local_auth_repository.dart';
import 'package:moab_poc/route/model/model.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("Handling a background message: ${message.messageId}");
}

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Storage.init();
    logger.v('App Start');
    await initLog();
    logger.d('Start to init Firebase Core');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.d('Done for init Firebase Core');
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
    initCloudMessage();
    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.e('Uncaught Flutter Error:\n', details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      if (kReleaseMode) {
        // Only exit app on release mode
        exit(1);
      }
    };
    runApp(_app());
  }, (Object error, StackTrace stack) {
    logger.e('Uncaught Error:\n', error);
    FirebaseCrashlytics.instance.recordError(error, stack);
    if (kReleaseMode) {
      // Only exit app on release mode
      exit(1);
    }
  });
}

void initCloudMessage() async {
  if (Platform.isIOS) {
    final token = await PushNotificationChannel().readDeviceToken();
    logger.i('APNS Token: $token');
    return;
  }
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
    print('Got a message while in the foreground!');
    print('Message data: ${message.data}');
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
                  icon: 'launch_background')));
    }
  });
  final token = await FirebaseMessaging.instance.getToken();
  logger.i('FCM Token: $token');
}

Widget _app() {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider(create: (context) => CloudAuthRepository(MoabHttpClient())),
      RepositoryProvider(create: (context) => FakeLocalAuthRepository()),
      RepositoryProvider(
          create: (context) => MoabEnvironmentRepository(MoabHttpClient()))
    ],
    child: MultiBlocProvider(providers: [
      BlocProvider(
        create: (BuildContext context) => NavigationCubit([HomePath()]),
      ),
      BlocProvider(
        create: (BuildContext context) => AuthBloc(
          repo: context.read<CloudAuthRepository>(),
          localRepo: context.read<FakeLocalAuthRepository>(),
        ),
      ),
      BlocProvider(create: (BuildContext context) => ConnectivityCubit()),
      BlocProvider(create: (BuildContext context) => AppLifecycleCubit()),
      BlocProvider(create: (BuildContext context) => SetupBloc())
    ], child: const MoabApp()),
  );
}

class MoabApp extends StatefulWidget {
  const MoabApp({Key? key}) : super(key: key);

  @override
  State<MoabApp> createState() => _MoabAppState();
}

class _MoabAppState extends State<MoabApp> with WidgetsBindingObserver {
  late ConnectivityCubit _cubit;

  @override
  void initState() {
    logger.d('Moab App init state: ${describeIdentity(this)}');
    _initAuth();
    WidgetsBinding.instance.addObserver(this);
    _cubit = context.read<ConnectivityCubit>();
    _cubit.start();
    _cubit.forceUpdate();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('Moab App build: ${describeIdentity(this)}');
    return MaterialApp.router(
      onGenerateTitle: (context) => getAppLocalizations(context).app_title,
      theme: MoabTheme.AuthModuleLightModeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: MoabRouterDelegate(context.read<NavigationCubit>()),
      routeInformationParser: MoabRouteInformationParser(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.v('didChangeAppLifecycleState: ${state.name}');
    context.read<AppLifecycleCubit>().update(state);
  }

  _initAuth() {
    context.read<AuthBloc>().add(InitAuth());
  }
}
