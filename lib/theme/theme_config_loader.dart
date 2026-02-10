import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Theme source enumeration.
enum ThemeSource {
  /// Resolve by priority (default).
  normal,

  /// Force use CI/CD environment variable.
  cicd,

  /// Force use remote API.
  network,

  /// Force use assets file.
  assets,

  /// Force use built-in default.
  defaultTheme
}

/// Theme configuration loader.
///
/// Loads the correct [ThemeJsonConfig] based on environment overrides
/// or device model number.
///
/// Use [ThemeConfigLoader.forTesting] to inject dependencies in tests.
class ThemeConfigLoader {
  final ThemeSource _forcedSource;
  final String _themeJsonEnv;
  final String _themeNetworkUrl;
  final String _themeAssetPath;

  /// Model-to-suffix mapping for device-specific themes.
  static const Map<String, String> _modelSuffixMap = {
    'TB-': '_tb',
    'CF-': '_cf',
    'DU-': '_du',
  };

  // Dart define environment variables (compile-time constants)
  static const _envThemeSource =
      String.fromEnvironment('THEME_SOURCE', defaultValue: 'normal');
  static const _envThemeJson =
      String.fromEnvironment('THEME_JSON', defaultValue: '');
  static const _envThemeAssetPath = String.fromEnvironment('THEME_ASSET_PATH',
      defaultValue: 'assets/theme.json');
  static const _envThemeNetworkUrl =
      String.fromEnvironment('THEME_NETWORK_URL', defaultValue: '');

  /// Production constructor. Reads settings from compile-time environment.
  ThemeConfigLoader()
      : _forcedSource = _parseSource(_envThemeSource),
        _themeJsonEnv = _envThemeJson,
        _themeNetworkUrl = _envThemeNetworkUrl,
        _themeAssetPath = _envThemeAssetPath;

  /// Test constructor. Allows injecting all dependencies.
  @visibleForTesting
  ThemeConfigLoader.forTesting({
    required ThemeSource forcedSource,
    String themeJsonEnv = '',
    String themeNetworkUrl = '',
    String themeAssetPath = 'assets/theme.json',
  })  : _forcedSource = forcedSource,
        _themeJsonEnv = themeJsonEnv,
        _themeNetworkUrl = themeNetworkUrl,
        _themeAssetPath = themeAssetPath;

  static ThemeSource _parseSource(String value) =>
      switch (value.toLowerCase()) {
        'cicd' => ThemeSource.cicd,
        'network' => ThemeSource.network,
        'assets' => ThemeSource.assets,
        'default' => ThemeSource.defaultTheme,
        _ => ThemeSource.normal,
      };

  /// Loads theme configuration.
  ///
  /// When an environment override is active, uses the override source.
  /// Otherwise, loads device-specific theme based on [modelNumber].
  Future<ThemeJsonConfig> load({String modelNumber = ''}) async {
    if (!_shouldUseDeviceTheme()) {
      logger.i(
          '[ThemeConfigLoader]: Using theme override (source: $_forcedSource)');
      return _resolveOverride();
    }

    logger
        .d('[ThemeConfigLoader]: Loading device theme for model: $modelNumber');
    return _resolveDeviceTheme(modelNumber);
  }

  /// Returns true if device-specific theme should be used (no overrides).
  bool _shouldUseDeviceTheme() {
    return _forcedSource == ThemeSource.normal &&
        _themeJsonEnv.isEmpty &&
        _themeNetworkUrl.isEmpty;
  }

  // ========== Override Resolution ==========

  Future<ThemeJsonConfig> _resolveOverride() async {
    return switch (_forcedSource) {
      ThemeSource.cicd => ThemeJsonConfig.fromJsonString(_themeJsonEnv),
      ThemeSource.network => await _tryLoadFromNetwork(_themeNetworkUrl) ??
          ThemeJsonConfig.defaultConfig(),
      ThemeSource.assets =>
        await _tryLoadFromAssets() ?? ThemeJsonConfig.defaultConfig(),
      ThemeSource.defaultTheme => ThemeJsonConfig.defaultConfig(),
      ThemeSource.normal => await _resolveByPriority(),
    };
  }

  Future<ThemeJsonConfig> _resolveByPriority() async {
    // 1. CI/CD
    if (_themeJsonEnv.isNotEmpty) {
      return ThemeJsonConfig.fromJsonString(_themeJsonEnv);
    }

    // 2. Network (Reserved)
    if (_themeNetworkUrl.isNotEmpty) {
      final networkConfig = await _tryLoadFromNetwork(_themeNetworkUrl);
      if (networkConfig != null) return networkConfig;
    }

    // 3. Assets
    final assetsConfig = await _tryLoadFromAssets();
    if (assetsConfig != null) return assetsConfig;

    // 4. Default
    return ThemeJsonConfig.defaultConfig();
  }

  Future<ThemeJsonConfig?> _tryLoadFromAssets() async {
    try {
      return await ThemeJsonConfig.fromAssets(_themeAssetPath);
    } catch (_) {
      return null;
    }
  }

  Future<ThemeJsonConfig?> _tryLoadFromNetwork(String url) async {
    if (url.isEmpty) return null;

    try {
      // Placeholder for actual network request
      return null;
    } catch (_) {
      return null;
    }
  }

  // ========== Device Theme Resolution ==========

  Future<ThemeJsonConfig> _resolveDeviceTheme(String modelNumber) async {
    if (modelNumber.isEmpty) {
      logger.d('[ThemeConfigLoader]: No model number, using default theme');
      return ThemeJsonConfig.defaultConfig();
    }

    // Find matching suffix
    String? suffix;
    for (final entry in _modelSuffixMap.entries) {
      if (modelNumber.toUpperCase().contains(entry.key)) {
        suffix = entry.value;
        break;
      }
    }

    if (suffix == null) {
      logger.d(
          '[ThemeConfigLoader]: No theme mapping for $modelNumber, using default');
      return ThemeJsonConfig.defaultConfig();
    }

    // Construct theme path: assets/theme/theme{suffix}.json
    final themePath = 'assets/theme/theme$suffix.json';

    try {
      logger.i(
          '[ThemeConfigLoader]: Loading theme for $modelNumber from $themePath');
      final theme = await ThemeJsonConfig.fromAssets(themePath);
      logger
          .i('[ThemeConfigLoader]: Theme loaded successfully for $modelNumber');
      return theme;
    } catch (e) {
      logger.e('[ThemeConfigLoader]: Failed to load theme from $themePath',
          error: e);
      return ThemeJsonConfig.defaultConfig();
    }
  }
}
