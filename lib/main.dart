import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:linksys_moab/bloc/account/cubit.dart';
import 'package:linksys_moab/bloc/app_lifecycle/cubit.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/connectivity/cubit.dart';
import 'package:linksys_moab/bloc/content_filter/cubit.dart';
import 'package:linksys_moab/bloc/device/cubit.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/security/bloc.dart';
import 'package:linksys_moab/design/themes.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/notification/notification_helper.dart';
import 'package:linksys_moab/repository/account/cloud_account_repository.dart';
import 'package:linksys_moab/repository/authenticate/impl/cloud_auth_repository.dart';
import 'package:linksys_moab/repository/config/environment_repository.dart';
import 'package:linksys_moab/repository/subscription/subscription_repository.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_moab/util/storage.dart';
import 'bloc/setup/bloc.dart';
import 'bloc/subscription/subscription_cubit.dart';
import 'firebase_options.dart';
import 'bloc/otp/otp_cubit.dart';
import 'repository/authenticate/impl/fake_local_auth_repository.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'route/model/_model.dart';

import 'security/security_profile_manager.dart';

void main() {
  // enableFlutterDriverExtension();
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

Widget _app() {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider(
          create: (context) => CloudAuthRepository(MoabHttpClient())),
      RepositoryProvider(create: (context) => FakeLocalAuthRepository()),
      RepositoryProvider(
          create: (context) => MoabEnvironmentRepository(MoabHttpClient())),
      RepositoryProvider(create: (context) => CloudAccountRepository()),
      RepositoryProvider(create: (context) => SubscriptionRepository())
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
      BlocProvider(create: (BuildContext context) => SetupBloc()),
      BlocProvider(create: (BuildContext context) => OtpCubit()),
      BlocProvider(create: (BuildContext context) => ProfilesCubit()),
      BlocProvider(create: (BuildContext context) => DeviceCubit()),
      BlocProvider(
          create: (BuildContext context) =>
              AccountCubit(repository: context.read<CloudAccountRepository>())),
      BlocProvider(create: (BuildContext context) => ContentFilterCubit()),
      BlocProvider(create: (BuildContext context) => SecurityBloc()),
      BlocProvider(
          create: (BuildContext context) => SubscriptionCubit(
              repository: context.read<SubscriptionRepository>()))
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
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    logger.d('Moab App init state: ${describeIdentity(this)}');
    _initAuth();
    _intIAP();
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
    _subscription.cancel();
    apnsStreamSubscription?.cancel();
    releaseErrorResponseStream();
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

  _intIAP() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailList) {
      _listenToPurchaseUpdated(purchaseDetailList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (Object error) {});
    context.read<SubscriptionCubit>().loadingProducts();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          logger.e('subscription error : ${purchaseDetails.error!.toString()}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          logger.d('subscription cubit purchaseDetails : ${purchaseDetails.purchaseID}');
          _deliverProduct(purchaseDetails);
        }
      }
    });
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) {
    context
        .read<SubscriptionCubit>()
        .updatePurchaseToken(purchaseToken: purchaseDetails.purchaseID);
  }
}
