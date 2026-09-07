import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/theme/theme_source.dart';

/// Global configuration entry point.
///
/// Provides unified static access from any layer (including low-level code
/// without ref/context). Configuration sources (highest to lowest priority):
///
/// 1. CI/CD JSON (assets/config/app_config.json)
/// 2. BuildConfig (compile-time dart-define)
/// 3. Default values
///
/// Usage:
/// ```dart
/// if (GlobalConfig.remote.mascotEnabled) { ... }
/// if (GlobalConfig.feature.enableThemeStudio) { ... }
/// if (GlobalConfig.theme.source != null) { ... }
/// ```
///
/// Everything here is static config: compile-time flags plus the CI/CD JSON.
/// There is deliberately no runtime tier. #1474 phase 8 deleted a
/// `DeviceConfig`/`DeviceCapability` one — 117 lines whose `initDevice()` was
/// never called from anywhere, so `showIPv6Settings` and its two siblings read
/// `false` even in a local build. Device capability belongs in a provider that
/// something actually watches, not in a static the login path forgot to
/// populate.
class GlobalConfig {
  GlobalConfig._();

  // === Static config (compile-time + CI/CD JSON) ===

  /// Remote mode restrictions
  static final remote = RemoteConfig._();

  /// Feature flags
  static final feature = FeatureConfig._();

  /// Theme configuration (optional, from CI/CD JSON)
  static final theme = ThemeConfig._();

  /// UI configuration
  static final ui = UIConfig._();

  // === Initialization ===

  /// Load configuration (call in main.dart).
  ///
  /// Loads app config from assets/config/app_config.json.
  /// Falls back to BuildConfig defaults if file doesn't exist.
  static Future<void> load() async {
    await _loadAppConfig();
  }

  static Future<void> _loadAppConfig() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/config/app_config.json');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final featureJson = json['feature'] as Map<String, dynamic>? ?? {};
      feature._loadFromJson(featureJson);

      final themeJson = json['theme'] as Map<String, dynamic>?;
      theme._loadFromJson(themeJson);
    } catch (e) {
      // JSON doesn't exist or parse failed, use defaults
      feature._loadFromJson({});
      theme._loadFromJson(null);
    }
  }
}

// =============================================================================
// RemoteConfig
// =============================================================================

/// Remote mode configuration and restrictions.
///
/// Access via [GlobalConfig.remote].
///
/// **Not** a table of per-mode policy flags, and #1474 phase 8 shrank it to make
/// that true. `allowDashboardEdit`, `allowConfigChanges` and
/// `showAdvancedSettings` were removed with zero consumers each: well named,
/// documented, centralised, and never read. That is the failure mode of per-mode
/// *data*, and it is why #1474 rejected a `UiCapabilities` table: an unread bool
/// cannot be seen to be wrong.
///
/// Measured 2026-09-07, one of the three named a policy in force and the other
/// two named a policy #1474 has decided **against** — so this is not three gates
/// awaiting an implementation.
///
/// `allowDashboardEdit` duplicated a live gate. `usp_sliver_dashboard_view.dart`
/// passes `isRemoteMode` to `DashboardHeaderBar`, whose `if (!isRemoteMode)` drops
/// the `dashboard-edit` action, and the Settings → "Change" entry exists only
/// inside `if (isEditMode)`. Editing really is unreachable in RA.
///
/// `allowConfigChanges` was the wrong *shape*, not merely unread. It says "no
/// writes in RA"; #1496 decided per operation, and reboot and cloud-OTA upgrade
/// stay **allowed** — a blanket flag would have blocked the two remote support
/// most needs. What that phase blocks is narrower: factory reset
/// (`credentialLoss`) and local firmware upload (`transportLoss`).
///
/// `showAdvancedSettings` hides a surface, which is the shape #1474 rules out:
/// "a concept the remote mode does not have is expressed by its strategy not
/// using it, not by a flag that hides UI". Advanced settings is not a concept
/// remote lacks — the agent needs it — and no phase of the epic hides it. #1497's
/// seven surfaces are exactly the seven existing `isActive` reads under
/// `lib/page/` + `lib/components/`; `usp_menu_view.dart` is not among them and has
/// no RA condition by design.
///
/// One real gap survives, and it belongs to #1496 rather than to a flag here:
/// `lib/page/admin/` and `lib/page/firmware_update/` contain **zero** mode reads,
/// while an RA session holds a full-capability `UspClient` aimed at the Guardian
/// `/actions/usp` proxy. Nothing on this side stops a destructive operation today.
///
/// So a new member here needs a consumer in the same change, and
/// `test/config/global_config_dead_member_test.dart` enforces that rather than
/// leaving it to this paragraph.
class RemoteConfig {
  RemoteConfig._();

  /// Whether remote mode is active (compile-time determined)
  bool get isActive => BuildConfig.isRemote();

  // === UI restrictions ===

  /// Whether the mascot is enabled at all — gates BOTH the dashboard overlay
  /// and its General Settings toggle, so the two never diverge (a visible
  /// toggle for a hidden mascot would be a dead control).
  ///
  /// Disabled in remote assistance mode and in E2E mock builds (deterministic
  /// rendering). The user's own on/off preference is a separate axis
  /// (`appSettings.showMascot`) applied on top of this.
  bool get mascotEnabled => !isActive && !BuildConfig.e2eMock;

  /// Whether to show preset selection dialog
  bool get showPresetDialog => !isActive;

  // === Dashboard ===

  /// Forced dashboard preset in remote mode
  UspDashboardPreset? get forcedPreset =>
      isActive ? UspDashboardPreset.remote : null;
}

// =============================================================================
// FeatureConfig
// =============================================================================

/// Feature flags configuration.
///
/// Supports CI/CD override via JSON. Access via [GlobalConfig.feature].
class FeatureConfig {
  FeatureConfig._();

  late bool _enableThemeStudio = BuildConfig.enableThemeStudio;
  late bool _enableTestConsole = BuildConfig.enableTestConsole;
  late bool _enableBetaFeatures = false;

  /// Whether Theme Studio is enabled
  bool get enableThemeStudio => _enableThemeStudio;

  /// Whether test console is enabled
  bool get enableTestConsole => _enableTestConsole;

  /// Whether beta features are enabled
  bool get enableBetaFeatures => _enableBetaFeatures;

  /// Load from JSON, using BuildConfig defaults for missing fields
  void _loadFromJson(Map<String, dynamic> json) {
    _enableThemeStudio =
        json['enableThemeStudio'] as bool? ?? BuildConfig.enableThemeStudio;
    _enableTestConsole =
        json['enableTestConsole'] as bool? ?? BuildConfig.enableTestConsole;
    _enableBetaFeatures = json['enableBetaFeatures'] as bool? ?? false;
  }
}

// =============================================================================
// ThemeConfig
// =============================================================================

/// Theme configuration from CI/CD JSON.
///
/// When present in app_config.json, ThemeConfigLoader will use these values
/// instead of dart-define environment variables. Access via [GlobalConfig.theme].
///
/// JSON structure:
/// ```json
/// {
///   "theme": {
///     "source": "cicd",
///     "config": {
///       "style": "flat",
///       "seedColor": "#6750A4",
///       "colors": { "light": {...}, "dark": {...} },
///       "overrides": {...}
///     },
///     "networkUrl": "https://...",
///     "assetPath": "assets/theme/custom.json"
///   }
/// }
/// ```
class ThemeConfig {
  ThemeConfig._();

  bool _isConfigured = false;
  ThemeSource? _source;
  Map<String, dynamic>? _config;
  String? _networkUrl;
  String? _assetPath;

  /// Whether theme config was provided in JSON
  bool get isConfigured => _isConfigured;

  /// Theme source override (null = use dart-define or default)
  ThemeSource? get source => _source;

  /// Inline theme config object (for ThemeSource.cicd)
  Map<String, dynamic>? get config => _config;

  /// Network URL to fetch theme (for ThemeSource.network)
  String? get networkUrl => _networkUrl;

  /// Asset path for theme file (for ThemeSource.assets)
  String? get assetPath => _assetPath;

  void _loadFromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      _isConfigured = false;
      _source = null;
      _config = null;
      _networkUrl = null;
      _assetPath = null;
      return;
    }

    _isConfigured = true;

    final sourceStr = json['source'] as String?;
    _source = sourceStr != null ? _parseSource(sourceStr) : null;

    _config = json['config'] as Map<String, dynamic>?;
    _networkUrl = json['networkUrl'] as String?;
    _assetPath = json['assetPath'] as String?;
  }

  static ThemeSource? _parseSource(String value) =>
      switch (value.toLowerCase()) {
        'cicd' => ThemeSource.cicd,
        'network' => ThemeSource.network,
        'assets' => ThemeSource.assets,
        'default' => ThemeSource.defaultTheme,
        'normal' => ThemeSource.normal,
        _ => null,
      };
}

// =============================================================================
// UIConfig
// =============================================================================

/// UI configuration constants.
///
/// Access via [GlobalConfig.ui].
class UIConfig {
  UIConfig._();

  // === Breakpoints ===

  /// Mobile breakpoint
  int get mobileBreakpoint => 600;

  /// Tablet breakpoint
  int get tabletBreakpoint => 900;

  /// Desktop breakpoint
  int get desktopBreakpoint => 1200;

  // === Animation ===

  /// Default animation duration
  Duration get defaultAnimationDuration => const Duration(milliseconds: 300);

  /// Fast animation duration
  Duration get fastAnimationDuration => const Duration(milliseconds: 150);
}
