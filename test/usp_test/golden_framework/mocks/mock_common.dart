import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/page/apps/providers/apps_capability_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Common provider overrides shared across all golden tests.
///
/// Sets up:
/// - GetIt singletons (ThemeJsonConfig, dark/light ThemeData)
/// - authProvider — returns unauthenticated state
/// - appsCapabilityProvider — returns false
List<Override> commonOverrides() {
  _ensureGetItDefaults();
  return [
    authProvider.overrideWith(() => _FixedAuthNotifier()),
    appsCapabilityProvider.overrideWith((ref) => false),
  ];
}

/// Ensures GetIt has default singletons registered.
///
/// Registers ThemeJsonConfig, light ThemeData, and dark ThemeData —
/// required by GeneralSettingsWidget, UspTopBar, and buildDemoThemeData.
/// Safe to call multiple times.
void _ensureGetItDefaults() {
  final getIt = GetIt.instance;
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
}

class _FixedAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() => Future.value(AuthState.empty());
}
