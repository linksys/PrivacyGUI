import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/route/route.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:moab_poc/util/storage.dart';
import 'firebase_options.dart';

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
    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.e('Uncaught Flutter Error:\n', details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      if (kReleaseMode) { // Only exit app on release mode
        exit(1);
      }
    };
    runApp(const NavigatorDemo());
  }, (Object error, StackTrace stack) {
    logger.e('Uncaught Error:\n', error);
    FirebaseCrashlytics.instance.recordError(error, stack);
    if (kReleaseMode) { // Only exit app on release mode
      exit(1);
    }
  });
}

class NavigatorDemo extends StatefulWidget {
  const NavigatorDemo({Key? key}) : super(key: key);

  @override
  State<NavigatorDemo> createState() => _NavigatorDemoState();
}

class _NavigatorDemoState extends State<NavigatorDemo>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.app_title,
      theme: MoabTheme.AuthModuleLightModeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: MoabRouterDelegate(),
      routeInformationParser: MoabRouteInformationParser(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.v('didChangeAppLifecycleState: ${state.name}');
  }
}
