import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/app.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/providers/logger_observer.dart';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:privacy_gui/theme/theme_config_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The main entry point for the Flutter application.
///
/// This function orchestrates the initialization of the app, including:
/// - Ensuring Flutter bindings are initialized.
/// - Preserving the native splash screen.
/// - Initializing storage and checking for the first launch.
/// - Setting up global error handlers.
/// - Loading build configurations and initializing JNAP actions.
/// - Overriding HTTP client behavior for non-web platforms.
/// - Setting up dependency injection using GetIt.
/// - Finally, running the main application widget.
void main() async {
  // if (kIsWeb) {
  //   usePathUrlStrategy();
  // }
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // TODO Revisit again until Flutter SDK 3.27.x
  // https://github.com/flutter/engine/commit/35af5fe80e0212caff4b34b583232d833b5a2596
  //
  if (defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.android) {
    SemanticsBinding.instance.ensureSemantics();
  }
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Storage.init();

  // Load environment variables for FAQ Agent (AWS Bedrock)
  // Create assets/.env with AWS credentials (copy from gen_ui_client)
  try {
    await dotenv.load(fileName: 'assets/.env');
    debugPrint('FAQ Agent: .env loaded successfully');
  } catch (e) {
    debugPrint('Warning: Could not load .env file for FAQ Agent: $e');
    debugPrint('FAQ Agent will use direct search instead of AI.');
  }

  if (kDebugMode) {
    print(await getPackageInfo());
  }

  checkFirstLaunch();

  ///
  initErrorHandler();

  container.read(linksysCacheManagerProvider);

  BuildConfig.load();
  initBetterActions();
  if (!kIsWeb) {
    HttpOverrides.global = MyHTTPOverrides();
  }

  // GetIt
  final themeConfig = await ThemeConfigLoader.load();
  dependencySetup(themeConfig: themeConfig);

  runApp(app());
}

/// Checks if this is the first time the app is being launched and performs cleanup if so.
///
/// On the first launch, this function clears all data from [FlutterSecureStorage].
/// This is particularly important on iOS to handle issues with keychain data
/// persisting after an app uninstall. It then sets a flag in [SharedPreferences]
/// to indicate that the first launch has occurred.
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

/// Initializes global error handlers for the application.
///
/// This function sets up handlers for both uncaught framework errors (via
/// `FlutterError.onError`) and other uncaught Dart errors (via
/// `PlatformDispatcher.instance.onError`). All caught exceptions are logged
/// using the global [logger].
initErrorHandler() {
  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e('Uncaught Flutter Error:\n', error: details);
    logger.e('Uncaught Flutter Error:\n', error: details.exception);
    logger.e('Uncaught Flutter Error:\n', error: details.exceptionAsString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Uncaught Error:\n', error: error, stackTrace: stack);
    logger.e(stack.toString());
    return true;
  };
}

/// A global [ProviderContainer] instance.
///
/// This container holds the state of all providers in the app.
final container = ProviderContainer();

/// Constructs the root widget of the application.
///
/// This function wraps the main [LinksysApp] widget with a [ProviderScope],
/// making Riverpod providers available throughout the widget tree. It also
/// adds a [ProviderLogger] to observe provider state changes.
///
/// Returns the root [Widget] for the app.
Widget app() {
  return ProviderScope(
    observers: [
      ProviderLogger(),
    ],
    child: const LinksysApp(),
  );
}

/// A custom [HttpOverrides] class to handle bad SSL certificates.
///
/// This override is used on mobile platforms to bypass SSL certificate validation
/// errors, which can occur when communicating with local routers that use
/// self-signed certificates.
///
/// **Warning:** This should only be used in controlled environments and accepts
/// all certificates, which is insecure for general web browsing.
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
