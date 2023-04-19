import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/app_lifecycle/cubit.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/connectivity/connectivity_provider.dart';
import 'package:linksys_moab/bloc/device/cubit.dart';
import 'package:linksys_moab/bloc/internet_check/cubit.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/wifi_setting/_wifi_setting.dart';
import 'package:linksys_moab/bloc/security/bloc.dart';
import 'package:linksys_moab/constants/build_config.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/linksys_http_client.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/notification/notification_helper.dart';
import 'package:linksys_moab/provider/provider_observer.dart';
import 'package:linksys_moab/repository/account/cloud_account_repository.dart';
import 'package:linksys_moab/repository/authenticate/impl/cloud_auth_repository.dart';
import 'package:linksys_moab/repository/linksys_cloud_repository.dart';
import 'package:linksys_moab/repository/networks/cloud_networks_repository.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/repository/subscription/subscription_repository.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/storage.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'bloc/setup/bloc.dart';
import 'bloc/subscription/subscription_cubit.dart';
import 'firebase_options.dart';
import 'bloc/otp/otp_cubit.dart';

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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      RepositoryProvider(
          create: (context) => CloudAuthRepository(MoabHttpClient())),

      RepositoryProvider(create: (context) => CloudAccountRepository()),
      RepositoryProvider(create: (context) => routerRepository),
      RepositoryProvider(create: (context) => CloudNetworksRepository()),

      RepositoryProvider(create: (context) => SubscriptionRepository()),
      RepositoryProvider(create: (context) => cloudRepository),
    ],
    child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (BuildContext context) => AuthBloc(
              repo: context.read<CloudAuthRepository>(),
              cloudRepo: context.read<LinksysCloudRepository>(),
              routerRepo: context.read<RouterRepository>(),
            ),
          ),
          BlocProvider(create: (BuildContext context) => AppLifecycleCubit()),
          BlocProvider(
            create: (BuildContext context) => OtpCubit(
              repository: context.read<LinksysCloudRepository>(),
            ),
          ),
          BlocProvider(
              create: (BuildContext context) => SetupBloc(
                  routerRepository: context.read<RouterRepository>())),
          BlocProvider(
              create: (BuildContext context) =>
                  ProfilesCubit(context.read<RouterRepository>())),
          BlocProvider(
              create: (BuildContext context) => DeviceCubit(
                  routerRepository: context.read<RouterRepository>())),
          BlocProvider(
              create: (BuildContext context) =>
                  NodeCubit(context.read<RouterRepository>())),
          BlocProvider(
              create: (BuildContext context) => AccountCubit(
                  repository: context.read<LinksysCloudRepository>())),
          BlocProvider(create: (BuildContext context) => SecurityBloc()),
          BlocProvider(
              create: (BuildContext context) => SubscriptionCubit(
                  repository: context.read<SubscriptionRepository>())),
          BlocProvider(
              create: (BuildContext context) => NetworkCubit(
                    networksRepository: context.read<CloudNetworksRepository>(),
                    cloudRepository: context.read<LinksysCloudRepository>(),
                    routerRepository: context.read<RouterRepository>(),
                  )),
          BlocProvider(
              create: (BuildContext context) => InternetCheckCubit(
                  routerRepository: context.read<RouterRepository>())),
          BlocProvider(
              create: (BuildContext context) => WifiSettingCubit(
                  routerRepository: context.read<RouterRepository>())),
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
  // late ConnectivityCubit _cubit;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    // logger.d('Moab App init state: ${describeIdentity(this)}');
    _initAuth();
    _intIAP();

    WidgetsBinding.instance.addObserver(this);
    // _cubit = context.read<ConnectivityCubit>();
    // _cubit.init();
    // _cubit.forceUpdate().then((value) => _initAuth());
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
    _subscription.cancel();
    apnsStreamSubscription?.cancel();
    releaseErrorStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // logger.d('Moab App build: ${describeIdentity(this)}');
    return MaterialApp.router(
      onGenerateTitle: (context) => getAppLocalizations(context).app_title,
      theme: ThemeData.light().copyWith(
          backgroundColor: ConstantColors.gray98,
          scaffoldBackgroundColor: ConstantColors.gray98),
      darkTheme: ThemeData.dark().copyWith(
        backgroundColor: ConstantColors.raisinBlock,
        scaffoldBackgroundColor: ConstantColors.raisinBlock,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: ref.read(routerDelegateProvider),
      routeInformationParser: LinksysRouteInformationParser(),
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

  _intIAP() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseList) {
      context.read<SubscriptionCubit>().onPurchaseUpdated(purchaseList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (Object error) {});
  }
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
