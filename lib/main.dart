import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/cache/linksys_cache_manager.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/page/dashboard/view/dashboard_menu_view.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/connectivity/connectivity_provider.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/notification/notification_helper.dart';
import 'package:linksys_app/provider/logger_observer.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/core/utils/storage.dart';
import 'package:linksys_app/provider/smart_device_provider.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/theme_data.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'route/router_provider.dart';
import 'util/analytics.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  // enableFlutterDriverExtension();
  // runZonedGuarded(() async {
  //
  // }, (Object error, StackTrace stack) {
  //   logger.e('Uncaught Error:\n', error, stack);
  //   logger.e(stack.toString());
  //   FirebaseCrashlytics.instance.recordError(error, stack);
  //   // if (kReleaseMode) {
  //   //   // Only exit app on release mode
  //   //   exit(1);
  //   // }
  //   exit(1);
  // });
  if (!kIsWeb) {
    HttpOverrides.global = MyHTTPOverrides();
  } else {
    usePathUrlStrategy();
  }
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Storage.init();
  logger.v('App Start');
  await initLog();
////
  SharedPreferences.getInstance().then((prefs) {
    final isAppFirstLaunch = prefs.getBool(pAppFirstLaunch) ?? true;
    if (!isAppFirstLaunch) {
      return;
    }
    const FlutterSecureStorage().deleteAll();
    prefs.setBool(pAppFirstLaunch, false);
  });
////

  logger.d('Start to init Firebase Core');
  final appConst = await PackageInfo.fromPlatform();
  await Firebase.initializeApp(
    options: appConst.appName.endsWith('ee')
        ? DefaultFirebaseOptions.iosEE
        : DefaultFirebaseOptions.currentPlatform,
  );
  await initAnalyticsDefault();
  // if (!kReleaseMode) {
  //   MqttLogger.loggingOn = true;
  // }
  logger.d('Done for init Firebase Core');
  initCloudMessage();
  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e('Uncaught Flutter Error:\n', error: details);
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
    // if (kReleaseMode) {
    //   // Only exit app on release mode
    //   exit(1);
    // }
    // exit(1);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Uncaught Error:\n', error: error, stackTrace: stack);
    logger.e(stack.toString());
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
    // if (kReleaseMode) {
    //   // Only exit app on release mode
    //   exit(1);
    // }
    // exit(1);
    return true;
  };
  container.read(linksysCacheManagerProvider);
  BuildConfig.load();
  initBetterActions();
  runApp(
    ProviderScope(
      observers: [ProviderLogger()],
      child: _app(),
    ),
  );
}

final container = ProviderContainer();

Widget _app() {
  return ProviderScope(
    observers: [
      Logger(),
    ],
    // parent: container,
    child: const MoabApp(),
  );
}

class MoabApp extends ConsumerStatefulWidget {
  const MoabApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MoabApp> createState() => _MoabAppState();
}

class _MoabAppState extends ConsumerState<MoabApp> with WidgetsBindingObserver {
  @override
  void initState() {
    // _initAuth();
    _intIAP();

    WidgetsBinding.instance.addObserver(this);

    super.initState();

    final connectivity = ref.read(connectivityProvider.notifier);
    connectivity.start();
    connectivity.forceUpdate().then((value) => _initAuth());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(connectivityProvider.notifier).stop();
    apnsStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(smartDeviceProvider.notifier).init();
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => getAppLocalizations(context).app_title,
      theme: linksysLightThemeData,
      darkTheme: linksysDarkThemeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => Container(
        color: Theme.of(context).colorScheme.shadow,
        child: AppResponsiveTheme(child: _build(child ?? Center())),
      ),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }

  Widget _build(Widget child) {
    return LayoutBuilder(builder: ((context, constraints) {
      final isDone = ref
          .watch(deviceManagerProvider.select((value) => value.deviceList))
          .isNotEmpty;
      if (constraints.maxWidth > 768 && isDone) {
        return Row(
          children: [
            SizedBox(
              width: 320,
              child: const DashboardMenuView(),
            ),
            Expanded(child: Container(child: child)),
          ],
        );
      } else {
        return child;
      }
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.v('didChangeAppLifecycleState: ${state.name}');
    if (state == AppLifecycleState.resumed) {
      ref.read(connectivityProvider.notifier).forceUpdate().then((_) {
        ref.read(pollingProvider.notifier).startPolling();
      });
    } else if (state == AppLifecycleState.paused) {
      ref.read(pollingProvider.notifier).stopPolling();
    }
  }

  _initAuth() {
    ref.read(authProvider.notifier).init().then((_) {
      logger.d('init auth finish');
      FlutterNativeSplash.remove();
    });
  }

  _intIAP() {}
}

class MyHTTPOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // logger.d('cert:: issuer:${cert.issuer}, subject:${cert.subject}');
        return true;
      };
  }
}

class Logger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('''
{
  "provider": "${provider.name ?? provider.runtimeType}",
  "newValue": "$newValue"
}''');
  }
}
