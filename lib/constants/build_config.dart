import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CloudEnvironment {
  // dev,
  qa,
  prod;

  static CloudEnvironment? get(String name) {
    return values.firstWhereOrNull((element) => element.name == name);
  }
}

enum ForceCommand {
  local,
  remote,
  none;

  static ForceCommand reslove(String type) {
    logger.d('[Config]: Force - $type');
    if (type == 'local') {
      return ForceCommand.local;
    } else if (type == 'remote') {
      return ForceCommand.remote;
    } else {
      return ForceCommand.none;
    }
  }
}

class BuildConfig {
  static const String cloudEnv =
      String.fromEnvironment('cloud_env', defaultValue: 'qa');
  static const bool isEnableEnvPicker =
      bool.fromEnvironment('enable_env_picker', defaultValue: true);

  static ForceCommand forceCommandType = ForceCommand.reslove(
      const String.fromEnvironment('force', defaultValue: 'none'));
  static bool showColumnOverlay =
      const bool.fromEnvironment('overlay', defaultValue: false);
  static const bool caLogin = bool.fromEnvironment('ca', defaultValue: false);
  static const bool customLayout =
      bool.fromEnvironment('custom_layout', defaultValue: false);

  static const bool enableThemeStudio =
      bool.fromEnvironment('theme_studio', defaultValue: false);
  static const bool enableTestConsole =
      bool.fromEnvironment('test_console', defaultValue: false);

  /// E2E test build flag (umbrella). Set `--dart-define=E2E_MOCK=true` when
  /// building the web app for the Playwright E2E suite, where the USP bridge
  /// is mocked at the browser JS boundary. Gates behaviors that cannot
  /// establish or that add non-deterministic setup overhead under the mock:
  /// - SSE init is skipped and the connection is treated as online, so the
  ///   "connecting/reconnecting/suspended" banner never renders (P0-1).
  /// - The first-run preset (onboarding) dialog auto-popup is suppressed (P0-2).
  /// Defaults false → production behavior is unchanged.
  /// See e2e/docs/FLUTTER-SIDE-REQUESTS.md.
  static const bool e2eMock =
      bool.fromEnvironment('E2E_MOCK', defaultValue: false);

  /// Skip PnP auto-trigger.
  /// Set `--dart-define=skip_pnp=true` to skip during development.
  static const bool skipPnp =
      bool.fromEnvironment('skip_pnp', defaultValue: false);

  static const int refreshTimeInterval =
      int.fromEnvironment('refresh_time', defaultValue: 60);
  static const copyRightYear = int.fromEnvironment('year', defaultValue: 2025);

  /// Advanced Visual Effects Switch (Bitmask)
  ///
  /// Controls advanced rendering effects for UI components (e.g., AppSurface).
  /// These flags are aligned with the definitions in [AppThemeConfig].
  ///
  /// Bit Definitions:
  /// - Bit 0 (1): Directional Shadow (Depth)
  /// - Bit 1 (2): Gradient Border (Detail)
  /// - Bit 2 (4): Background Blur (Filter)
  /// - Bit 3 (8): Noise Texture (Texture)
  /// - Bit 4 (16): Dynamic Shimmer (Motion)
  ///
  /// Examples:
  /// - `0`  = All off (Best performance)
  /// - `7`  = First three on (1+2+4) -> Shadow + Border + Blur
  /// - `31` = All on (Max Quality)
  ///
  /// Enable at build time: `flutter run --dart-define=liquid_glass=31`
  static const int liquidGlassEffects =
      int.fromEnvironment('liquid_glass', defaultValue: 0);

  // Visual Effect Convenience Getters
  static bool get enableShadows => (liquidGlassEffects & 1) != 0;
  static bool get enableGradientBorder => (liquidGlassEffects & 2) != 0;
  static bool get enableBlur => (liquidGlassEffects & 4) != 0;
  static bool get enableNoiseTexture => (liquidGlassEffects & 8) != 0;
  static bool get enableShimmer => (liquidGlassEffects & 16) != 0;

  @pragma('vm:entry-point')
  static Future<void> load() async {
    logger.d('[Config]: load build configuration');
    final prefs = await SharedPreferences.getInstance();
    final envStr = prefs.getString(pCloudEnv);
    cloudEnvTarget = CloudEnvironment.get(envStr ?? '') ?? cloudEnvTarget;
    logger.d('[Config]: Cloud Env: $cloudEnvTarget');

    // For non-Web platforms (iOS/Android): determine force mode from bundle ID
    // Web uses String.fromEnvironment('force') set at compile time
    //
    // iOS: Bundle ID is set via PRODUCT_BUNDLE_IDENTIFIER in xcconfig
    //   - Local: com.linksys.privacygui.local
    //   - Remote: com.linksys.privacygui.remote
    //
    // Android: Application ID should be configured in build.gradle with flavors:
    //   flavorDimensions "mode"
    //   productFlavors {
    //       local { applicationIdSuffix ".local" }
    //       remote { applicationIdSuffix ".remote" }
    //   }
    if (!kIsWeb) {
      final packageInfo = await PackageInfo.fromPlatform();
      final bundleId = packageInfo.packageName;
      if (bundleId.endsWith('.local')) {
        forceCommandType = ForceCommand.local;
      }
      // Otherwise, keep ForceCommand.none (default)
      logger.d(
          '[Config]: Non-Web platforms: Force command type: $forceCommandType');
    }
  }

  static bool isLocal() {
    return forceCommandType == ForceCommand.local;
  }

  static bool isRemote() {
    return forceCommandType == ForceCommand.remote;
  }
}

bool showDebugPanel = !kReleaseMode && !kIsWeb;

CloudEnvironment cloudEnvTarget = CloudEnvironment.values
    .firstWhere((element) => element.name == BuildConfig.cloudEnv);
Map<String, dynamic> get cloudEnvironmentConfig =>
    kCloudEnvironmentMap[cloudEnvTarget];

Future<String> getVersion() async {
  final version = await getBuildNumber();
  return version ??
      await PackageInfo.fromPlatform().then((value) => value.version);
}

Future<String?> getBuildNumber() async {
  String? buildNumber;
  final json = await rootBundle
      .loadString('assets/resources/versions.json', cache: false)
      .then((value) => jsonDecode(value))
      .onError((error, stackTrace) => null);
  if (json != null) {
    buildNumber = json['version'] as String?;
  }
  return buildNumber;
}
