import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/page/apps/providers/apps_capability_provider.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Fixed-state notifier for firewall golden tests.
///
/// Returns a pre-configured state from build() and no-ops all mutation methods.
class _FixedFirewallNotifier extends UspFirewallNotifier {
  final FirewallFeatureState _fixedState;

  _FixedFirewallNotifier(this._fixedState);

  @override
  FirewallFeatureState build() {
    // Return fixed state directly — no data provider listening, no fetch.
    return _fixedState;
  }

  @override
  Future<(FirewallSettings?, FirewallStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    // No-op: return (null, null) to indicate no changes.
    return (null, null);
  }

  @override
  Future<void> performSave() async {
    // No-op: golden tests don't save.
  }

  @override
  void updateSetting(FirewallUIModel Function(FirewallUIModel) updater) {
    // No-op: golden tests capture static states.
  }
}

/// Centralized provider mocks for golden tests.
///
/// Usage:
/// ```dart
/// final mockSetup = (MockRegistry mock) {
///   mock.common();
///   mock.firewall(FirewallFeatureState(...));
/// };
/// ```
class MockRegistry {
  final List<Override> _overrides = [];

  /// Common provider overrides shared across all views.
  ///
  /// Sets up:
  /// - GetIt singletons (dark/light ThemeData) required by GeneralSettingsWidget
  /// - authProvider — returns unauthenticated state (hides login-only UI)
  /// - appsCapabilityProvider — returns false (hides Apps button in TopBar)
  void common() {
    _ensureGetItDefaults();

    // authProvider: unauthenticated — hides logout, ToS, apps icon in TopBar
    _overrides.add(
      authProvider.overrideWith(() => _FixedAuthNotifier()),
    );

    // appsCapabilityProvider: false — hides Apps icon in TopBar
    _overrides.add(
      appsCapabilityProvider.overrideWith((ref) => false),
    );
  }

  /// Override firewall provider with a fixed state.
  void firewall(FirewallFeatureState state) {
    _overrides.add(
      uspFirewallProvider.overrideWith(() => _FixedFirewallNotifier(state)),
    );
  }

  /// Build the list of provider overrides for ProviderScope.
  List<Override> build() => List.unmodifiable(_overrides);

  /// Ensures GetIt has default singletons registered.
  ///
  /// Registers ThemeJsonConfig, light ThemeData, and dark ThemeData —
  /// required by GeneralSettingsWidget, UspTopBar, and buildDemoThemeData.
  /// Safe to call multiple times — checks isRegistered before registering.
  static void _ensureGetItDefaults() {
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
}

/// Fixed auth notifier that returns an unauthenticated state.
class _FixedAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() => Future.value(AuthState.empty());
}
