import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

/// A global instance of [GetIt] used as a service locator for dependency injection.
///
/// This instance is used to register and retrieve singleton objects, such as
/// services or theme data, from anywhere in the application.
final getIt = GetIt.instance;

/// Sets up the application's dependencies by registering them with [GetIt].
///
/// This function is called once at application startup to initialize and
/// register all singleton services and objects that need to be globally
/// accessible. Currently, it registers:
/// - Default light/dark [ThemeData] (used by some UI widgets).
///
/// Theme configuration loading is handled by `themeConfigProvider` (Riverpod).
void dependencySetup() {
  // Register default ThemeData for UI widgets that read from GetIt
  // (e.g., top_bar.dart, general_settings_widget.dart)
  final config = ThemeJsonConfig.defaultConfig();

  if (!getIt.isRegistered<ThemeJsonConfig>()) {
    getIt.registerSingleton<ThemeJsonConfig>(config);
  }

  if (!getIt.isRegistered<ThemeData>(instanceName: 'lightThemeData')) {
    getIt.registerSingleton<ThemeData>(
      config.createLightTheme(),
      instanceName: 'lightThemeData',
    );
  }

  if (!getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
    getIt.registerSingleton<ThemeData>(
      config.createDarkTheme(),
      instanceName: 'darkThemeData',
    );
  }

  // Register UspClient on Web platform only
  if (kIsWeb && !getIt.isRegistered<UspClient>()) {
    if (canUseAppOriginUspClient()) {
      try {
        getIt.registerSingleton<UspClient>(UspClient(
          Uri.base.origin,
        ));
        logger.d('[DI]: UspClient registered (Web)');
      } catch (e) {
        logger.w('[DI]: UspClient registration failed: $e');
      }
    } else {
      logger.d('[DI]: UspClient boot registration skipped — Remote build, '
          'the client is built from the Remote Assistance session config');
    }
  }
}

/// Whether a boot-time [UspClient] may be built against the app's own origin.
///
/// True for Local (and unforced) builds: the app is served by the router itself,
/// so `Uri.base.origin` IS the USP host.
///
/// False for Remote Assistance builds: there the app is served from static
/// hosting and USP is reached through the Guardian API on a different host. A
/// boot client would therefore point at a host that answers no USP request, and
/// because [uspClientProvider] caches whatever GetIt held when it was FIRST read
/// — during `authProvider.init()`, long before a session exists — that wrong
/// client is what every consumer keeps. Leaving the slot empty makes
/// `RemoteAssistanceNotifier.activate()` the only thing that can ever create the
/// client, so no consumer can capture a pre-session instance.
@visibleForTesting
bool canUseAppOriginUspClient() => !BuildConfig.isRemote();
