import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/app.dart';
import 'package:privacy_gui/providers/logger_observer.dart';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // if (kIsWeb) {
  //   usePathUrlStrategy();
  // }
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // SemanticsBinding.instance.ensureSemantics();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Storage.init();
  await initLog();

  checkFirstLaunch();

  ///
  initErrorHandler();

  container.read(linksysCacheManagerProvider);

  BuildConfig.load();
  initBetterActions();
  if (!kIsWeb) {
    HttpOverrides.global = MyHTTPOverrides();
  }
  runApp(_app());
}

checkFirstLaunch() {
  /// For iOS, Secure storage restores issue
  SharedPreferences.getInstance().then((prefs) {
    final isAppFirstLaunch = prefs.getBool(pAppFirstLaunch) ?? true;
    if (!isAppFirstLaunch) {
      return;
    }
    const FlutterSecureStorage().deleteAll();
    prefs.setBool(pAppFirstLaunch, false);
  });
}

initErrorHandler() {
  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e('Uncaught Flutter Error:\n', error: details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Uncaught Error:\n', error: error, stackTrace: stack);
    logger.e(stack.toString());
    return true;
  };
}

final container = ProviderContainer();

Widget _app() {
  return ProviderScope(
    observers: [
      ProviderLogger(),
    ],
    child: const LinksysApp(),
  );
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
