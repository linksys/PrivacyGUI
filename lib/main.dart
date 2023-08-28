import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/bloc/app_lifecycle/cubit.dart';
import 'package:linksys_app/core/cache/linksys_cache_manager.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/connectivity/connectivity_provider.dart';
import 'package:linksys_app/bloc/device/cubit.dart';
import 'package:linksys_app/bloc/network/cubit.dart';
import 'package:linksys_app/bloc/node/cubit.dart';
import 'package:linksys_app/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_app/constants/build_config.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/notification/notification_helper.dart';
import 'package:linksys_app/provider/logger_observer.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/core/utils/storage.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'firebase_options.dart';
import 'route/router_provider.dart';
import 'util/analytics.dart';

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
  HttpOverrides.global = MyHTTPOverrides();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Storage.init();
  logger.v('App Start');
  await initLog();
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
    logger.e('Uncaught Flutter Error:\n', details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    // if (kReleaseMode) {
    //   // Only exit app on release mode
    //   exit(1);
    // }
    // exit(1);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Uncaught Error:\n', error, stack);
    logger.e(stack.toString());
    FirebaseCrashlytics.instance.recordError(error, stack);
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
  final routerRepository = container.read(routerRepositoryProvider);
  final cloudRepository = container.read(cloudRepositoryProvider);

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider(create: (context) => routerRepository),
      RepositoryProvider(create: (context) => cloudRepository),
    ],
    child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (BuildContext context) => AppLifecycleCubit()),
          BlocProvider(
              create: (BuildContext context) => DeviceCubit(
                  routerRepository: context.read<RouterRepository>())),
          BlocProvider(
              create: (BuildContext context) =>
                  NodeCubit(context.read<RouterRepository>())),
          BlocProvider(
              create: (BuildContext context) => NetworkCubit(
                    cloudRepository: context.read<LinksysCloudRepository>(),
                    routerRepository: context.read<RouterRepository>(),
                  )),
          BlocProvider(
              create: (BuildContext context) => WifiSettingCubit(
                    cloudRepository: context.read<LinksysCloudRepository>(),
                    routerRepository: context.read<RouterRepository>(),
                  )),
        ],
        child: ProviderScope(
          observers: [Logger()],
          parent: container,
          child: const MoabApp(),
        )),
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

    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // _cubit.stop();
    ref.read(connectivityProvider.notifier).stop();
    apnsStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => getAppLocalizations(context).app_title,
      theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: ConstantColors.gray98,
          colorScheme:
              const ColorScheme.light(background: ConstantColors.gray98)),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: ConstantColors.raisinBlock,
        colorScheme:
            const ColorScheme.dark(background: ConstantColors.raisinBlock),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // routerDelegate: ref.read(routerDelegateProvider),
      // routeInformationParser: LinksysRouteInformationParser(),
      builder: (context, child) =>
          AppResponsiveTheme(child: child ?? const Center()),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.v('didChangeAppLifecycleState: ${state.name}');
    context.read<AppLifecycleCubit>().update(state);
  }

  _initAuth() {
    // context.read<AuthBloc>().add(InitAuth());
    ref.read(authProvider.notifier).init();
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
