import 'dart:convert';

import 'package:flutter/foundation.dart';
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
/// if (GlobalConfig.device.supportIPv6) { ... }
/// if (GlobalConfig.theme.source != null) { ... }
/// ```
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

  // === Dynamic config (runtime initialization) ===

  static DeviceConfig? _device;

  /// Device capability config.
  ///
  /// Empty before login, initialized via [initDevice] after login.
  static DeviceConfig get device => _device ?? DeviceConfig.empty();

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

  // === Device config management ===

  /// Initialize device config (call after login).
  ///
  /// In RA mode, [info] comes from the remote device being controlled.
  static void initDevice(DeviceCapability info) {
    _device = DeviceConfig._(info);
    _notifyListeners();
  }

  /// Clear device config (call on logout).
  static void clearDevice() {
    _device = null;
    _notifyListeners();
  }

  // === Reactive UI updates ===

  static final _changeNotifier = _ConfigChangeNotifier();

  /// Listen to config changes (for ListenableBuilder).
  ///
  /// ```dart
  /// ListenableBuilder(
  ///   listenable: GlobalConfig.changes,
  ///   builder: (context, _) => ...,
  /// )
  /// ```
  static Listenable get changes => _changeNotifier;

  static void _notifyListeners() {
    _changeNotifier._notify();
  }
}

// =============================================================================
// RemoteConfig
// =============================================================================

/// Remote mode configuration and restrictions.
///
/// Centralizes all UI and feature restrictions for Remote Assistance mode.
/// Access via [GlobalConfig.remote].
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

  /// Whether to allow Dashboard editing
  bool get allowDashboardEdit => !isActive;

  /// Whether to show preset selection dialog
  bool get showPresetDialog => !isActive;

  // === Feature restrictions ===

  /// Whether to allow config changes
  bool get allowConfigChanges => !isActive;

  /// Whether to show advanced settings
  bool get showAdvancedSettings => !isActive;

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

// =============================================================================
// DeviceConfig
// =============================================================================

/// Device capability configuration.
///
/// Initialized at runtime from TR-181 or login API after device connection.
/// Access via [GlobalConfig.device].
class DeviceConfig {
  final DeviceCapability? _info;

  DeviceConfig._(this._info);
  DeviceConfig.empty() : _info = null;

  /// Whether device info is available (only after login)
  bool get isAvailable => _info != null;

  // === Device capabilities (from TR-181 or API) ===

  /// Whether IPv6 is supported
  bool get supportIPv6 => _info?.supportIPv6 ?? false;

  /// Whether Mesh is supported
  bool get supportMesh => _info?.supportMesh ?? false;

  /// Whether Guest Network is supported
  bool get supportGuestNetwork => _info?.supportGuestNetwork ?? false;

  /// Maximum SSID count
  int get maxSSIDCount => _info?.maxSSIDCount ?? 3;

  // === Combined checks (device capability + mode restrictions) ===

  /// Whether to show IPv6 settings
  bool get showIPv6Settings =>
      isAvailable && supportIPv6 && !GlobalConfig.remote.isActive;

  /// Whether to show Mesh settings
  bool get showMeshSettings =>
      isAvailable && supportMesh && !GlobalConfig.remote.isActive;

  /// Whether to show Guest Network settings
  bool get showGuestNetworkSettings =>
      isAvailable && supportGuestNetwork && !GlobalConfig.remote.isActive;
}

/// Device information (from TR-181 or login API).
class DeviceCapability {
  final bool supportIPv6;
  final bool supportMesh;
  final bool supportGuestNetwork;
  final int maxSSIDCount;

  const DeviceCapability({
    this.supportIPv6 = false,
    this.supportMesh = false,
    this.supportGuestNetwork = false,
    this.maxSSIDCount = 3,
  });

  DeviceCapability copyWith({
    bool? supportIPv6,
    bool? supportMesh,
    bool? supportGuestNetwork,
    int? maxSSIDCount,
  }) {
    return DeviceCapability(
      supportIPv6: supportIPv6 ?? this.supportIPv6,
      supportMesh: supportMesh ?? this.supportMesh,
      supportGuestNetwork: supportGuestNetwork ?? this.supportGuestNetwork,
      maxSSIDCount: maxSSIDCount ?? this.maxSSIDCount,
    );
  }
}

// =============================================================================
// Internal
// =============================================================================

/// Internal ChangeNotifier to prevent external manipulation
class _ConfigChangeNotifier extends ChangeNotifier {
  void _notify() => notifyListeners();
}
