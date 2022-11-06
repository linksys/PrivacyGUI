import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/app_lifecycle/cubit.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/connectivity/cubit.dart';
import 'package:linksys_moab/bloc/content_filter/cubit.dart';
import 'package:linksys_moab/bloc/device/cubit.dart';
import 'package:linksys_moab/bloc/internet_check/cubit.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/config/cloud_environment_manager.dart';
import 'package:linksys_moab/bloc/security/bloc.dart';
import 'package:linksys_moab/design/themes.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/notification/notification_helper.dart';
import 'package:linksys_moab/repository/account/cloud_account_repository.dart';
import 'package:linksys_moab/repository/authenticate/impl/cloud_auth_repository.dart';
import 'package:linksys_moab/repository/config/environment_repository.dart';
import 'package:linksys_moab/repository/networks/cloud_networks_repository.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/storage.dart';
import 'bloc/setup/bloc.dart';
import 'firebase_options.dart';
import 'bloc/otp/otp_cubit.dart';
import 'repository/authenticate/impl/router_auth_repository.dart';
import 'repository/authenticate/otp_repository.dart';
import 'route/model/_model.dart';

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
    if (kReleaseMode) {
      // Only exit app on release mode
      exit(1);
    }
    // exit(1);

  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Uncaught Error:\n', error, stack);
    logger.e(stack.toString());
    FirebaseCrashlytics.instance.recordError(error, stack);
    if (kReleaseMode) {
      // Only exit app on release mode
      exit(1);
    }
    // exit(1);
    return true;
  };
  initBetterActions();
  runApp(_app());
}

Widget _app() {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider(
          create: (context) => CloudAuthRepository(MoabHttpClient())),
      RepositoryProvider(
          create: (context) => RouterAuthRepository(MoabHttpClient())),
      RepositoryProvider(
          create: (context) => MoabEnvironmentRepository(MoabHttpClient())),
      RepositoryProvider(create: (context) => CloudAccountRepository()),
      RepositoryProvider(create: (context) => RouterRepository()),
      RepositoryProvider(create: (context) => CloudNetworksRepository()),
      RepositoryProvider(create: (context) => OtpRepository(httpClient: MoabHttpClient())),
    ],
    child: MultiBlocProvider(providers: [
      BlocProvider(
        create: (BuildContext context) => NavigationCubit([HomePath()]),
      ),
      BlocProvider(
        create: (BuildContext context) => AuthBloc(
          repo: context.read<CloudAuthRepository>(),
          routerRepo: context.read<RouterRepository>(),
        ),
      ),
      BlocProvider(
          create: (BuildContext context) => ConnectivityCubit(
                routerRepository: context.read<RouterRepository>(),
              )),
      BlocProvider(create: (BuildContext context) => AppLifecycleCubit()),
      BlocProvider(create: (BuildContext context) => OtpCubit(otpRepository: context.read<OtpRepository>())),
      BlocProvider(create: (BuildContext context) => SetupBloc(routerRepository: context.read<RouterRepository>())),
      BlocProvider(create: (BuildContext context) => ProfilesCubit()),
      BlocProvider(create: (BuildContext context) => DeviceCubit(routerRepository: context.read<RouterRepository>())),
      BlocProvider(
          create: (BuildContext context) =>
              AccountCubit(repository: context.read<CloudAccountRepository>())),
      BlocProvider(create: (BuildContext context) => ContentFilterCubit()),
      BlocProvider(create: (BuildContext context) => SecurityBloc()),
      BlocProvider(
          create: (BuildContext context) => NetworkCubit(networksRepository: context.read<CloudNetworksRepository>(),
                routerRepository: context.read<RouterRepository>(),
              )),
      BlocProvider(
          create: (BuildContext context) => InternetCheckCubit(
              routerRepository: context.read<RouterRepository>())),
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

    WidgetsBinding.instance.addObserver(this);
    _cubit = context.read<ConnectivityCubit>();
    _cubit.init();
    _cubit.forceUpdate().then((value) => _initAuth());
    super.initState();
    FlutterNativeSplash.remove();

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.stop();
    apnsStreamSubscription?.cancel();
    releaseErrorResponseStream();
    CloudEnvironmentManager().release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('Moab App build: ${describeIdentity(this)}');
    return MaterialApp.router(
      onGenerateTitle: (context) => getAppLocalizations(context).app_title,
      theme: MoabTheme.mainLightModeData,
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
