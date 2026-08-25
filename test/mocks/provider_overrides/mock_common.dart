import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/page/apps/providers/apps_capability_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Common provider overrides shared across all golden tests — and, since #1361 moved
/// this file out of `test/golden_test/`, across the widget tests and the overflow gate
/// that were already importing it from there.
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
/// required by GeneralSettingsWidget, UspTopBar, and buildStudioThemeData.
/// Safe to call multiple times.
void _ensureGetItDefaults() {
  final getIt = GetIt.instance;

  if (!getIt.isRegistered<ThemeJsonConfig>()) {
    getIt.registerSingleton<ThemeJsonConfig>(_defaultConfig);
  }

  if (!getIt.isRegistered<ThemeData>(instanceName: 'lightThemeData')) {
    getIt.registerSingleton<ThemeData>(
      _defaultConfig.createLightTheme(),
      instanceName: 'lightThemeData',
    );
  }

  if (!getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
    getIt.registerSingleton<ThemeData>(
      _defaultConfig.createDarkTheme(),
      instanceName: 'darkThemeData',
    );
  }
}

/// Parsed once per test process, and only if a guard above actually needs it —
/// a top-level `final` initialises lazily, on first read.
///
/// It used to be a local built before the three `isRegistered` guards, so every
/// `commonOverrides()` call parsed the whole JSON config and then, in the normal
/// case, dropped it: the gate calls this once per cell, so a sweep paid for it
/// thousands of times to register nothing. Same instance for all three
/// registrations, which is what the singletons were already promising.
final _defaultConfig = ThemeJsonConfig.defaultConfig();

class _FixedAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() => Future.value(AuthState.empty());
}
