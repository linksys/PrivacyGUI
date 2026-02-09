import 'package:flutter/foundation.dart';
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
/// Responsible for loading the correct [ThemeJsonConfig] based on priority or forced settings.
class ThemeConfigLoader {
  ThemeConfigLoader._();

  // Dart define environment variables
  static const _themeSourceEnv =
      String.fromEnvironment('THEME_SOURCE', defaultValue: 'normal');
  static const _themeJsonEnv =
      String.fromEnvironment('THEME_JSON', defaultValue: '');
  static const _themeAssetPath = String.fromEnvironment('THEME_ASSET_PATH',
      defaultValue: 'assets/theme.json');
  static const _themeNetworkUrl =
      String.fromEnvironment('THEME_NETWORK_URL', defaultValue: '');

  /// Gets the currently enforced source setting.
  static ThemeSource get forcedSource =>
      switch (_themeSourceEnv.toLowerCase()) {
        'cicd' => ThemeSource.cicd,
        'network' => ThemeSource.network,
        'assets' => ThemeSource.assets,
        'default' => ThemeSource.defaultTheme,
        _ => ThemeSource.normal,
      };

  /// Check if device-specific theme should be used.
  ///
  /// Returns `false` if any environment override is set (forcedSource != normal,
  /// or THEME_JSON/THEME_NETWORK_URL is not empty).
  ///
  /// Returns `true` if no override exists and device-specific theme should be used.
  static bool shouldUseDeviceTheme() {
    return forcedSource == ThemeSource.normal &&
        _themeJsonEnv.isEmpty &&
        _themeNetworkUrl.isEmpty;
  }

  /// Single entry point: Loads theme configuration.
  static Future<ThemeJsonConfig> load() async {
    return resolve(
      forcedSource: forcedSource,
      themeJsonEnv: _themeJsonEnv,
      themeNetworkUrl: _themeNetworkUrl,
      assetLoader: _tryLoadFromAssets,
    );
  }

  /// Exposed for testing: Resolve theme config based on inputs.
  @visibleForTesting
  static Future<ThemeJsonConfig> resolve({
    required ThemeSource forcedSource,
    required String themeJsonEnv,
    required String themeNetworkUrl,
    required Future<ThemeJsonConfig?> Function() assetLoader,
  }) async {
    return switch (forcedSource) {
      ThemeSource.cicd => ThemeJsonConfig.fromJsonString(themeJsonEnv),
      ThemeSource.network => await _tryLoadFromNetwork(themeNetworkUrl) ??
          ThemeJsonConfig.defaultConfig(),
      ThemeSource.assets =>
        await assetLoader() ?? ThemeJsonConfig.defaultConfig(),
      ThemeSource.defaultTheme => ThemeJsonConfig.defaultConfig(),
      ThemeSource.normal => await _resolveByPriority(
          themeJsonEnv: themeJsonEnv,
          themeNetworkUrl: themeNetworkUrl,
          assetLoader: assetLoader,
        ),
    };
  }

  /// Priority resolution logic.
  static Future<ThemeJsonConfig> _resolveByPriority({
    required String themeJsonEnv,
    required String themeNetworkUrl,
    required Future<ThemeJsonConfig?> Function() assetLoader,
  }) async {
    // 1. CI/CD
    if (themeJsonEnv.isNotEmpty) {
      return ThemeJsonConfig.fromJsonString(themeJsonEnv);
    }

    // 2. Network (Reserved)
    if (themeNetworkUrl.isNotEmpty) {
      final networkConfig = await _tryLoadFromNetwork(themeNetworkUrl);
      if (networkConfig != null) return networkConfig;
    }

    // 3. Assets
    final assetsConfig = await assetLoader();
    if (assetsConfig != null) return assetsConfig;

    // 4. Default
    return ThemeJsonConfig.defaultConfig();
  }

  static Future<ThemeJsonConfig?> _tryLoadFromAssets() async {
    try {
      return await ThemeJsonConfig.fromAssets(_themeAssetPath);
    } catch (_) {
      return null;
    }
  }

  // ========== Network Support (Reserved) ==========

  static Future<ThemeJsonConfig?> _tryLoadFromNetwork(String url) async {
    if (url.isEmpty) return null;

    try {
      // Placeholder for actual network request
      // final response = await http.get(Uri.parse(url));
      // if (response.statusCode == 200) {
      //   return ThemeJsonConfig.fromJsonString(response.body);
      // }
      return null;
    } catch (_) {
      return null;
    }
  }
}
