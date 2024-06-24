import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/firebase/analytics.dart';
import 'package:privacy_gui/app.dart';
import 'package:privacy_gui/firebase/notification_helper.dart';
import 'package:privacy_gui/firebase/notification_provider.dart';
import 'package:privacy_gui/providers/logger_observer.dart';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

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

  // await initFirebase();

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
    // if (!kIsWeb) {
    //   FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    // }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Uncaught Error:\n', error: error, stackTrace: stack);
    logger.e(stack.toString());
    // if (!kIsWeb) {
    //   FirebaseCrashlytics.instance.recordError(error, stack);
    // }
    return true;
  };
}

Future initFirebase() async {
  try {
    logger.d('Start to init Firebase Core');
    final appConst = await PackageInfo.fromPlatform();
    await Firebase.initializeApp(
      options: appConst.appName.endsWith('ee')
          ? DefaultFirebaseOptions.iosEE
          : DefaultFirebaseOptions.currentPlatform,
    );

    await initAnalyticsDefault();
    // await initCloudMessage();
    logger.d('Done for init Firebase Core');
  } catch (e) {
    logger.e('Init Firebase Core failed', error: e);
  }
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
