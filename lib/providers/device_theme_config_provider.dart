import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/theme/theme_config_loader.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:privacy_gui/utils.dart';

/// Device-specific theme configuration provider.
///
/// Integrates two theme loading strategies with priority:
/// 1. **Environment Override** (Priority): Used for CI/CD, test environments
/// 2. **Device Theme** (Normal): Loads theme based on modelNumber from sessionProvider
///
/// Environment override is triggered when ANY of these conditions are met:
/// - `THEME_SOURCE` is not "normal" (e.g., cicd, network, assets, default)
/// - `THEME_JSON` environment variable is not empty
/// - `THEME_NETWORK_URL` environment variable is not empty
///
/// When no override exists, loads device-specific theme via BrandUtils based on modelNumber.
///
/// ## Usage Examples:
///
/// ### Normal Mode (Device-based theme):
/// ```dart
/// // In app.dart
/// final themeAsync = ref.watch(deviceThemeConfigProvider);
/// return themeAsync.when(
///   data: (theme) => MaterialApp(theme: theme.createLightTheme()),
///   loading: () => LoadingScreen(),
///   error: (e, st) => ErrorScreen(),
/// );
/// ```
///
/// ### CI/CD Override:
/// ```bash
/// # Force specific theme via environment variable
/// flutter run --dart-define=THEME_SOURCE=cicd --dart-define=THEME_JSON='{"style":"flat",...}'
/// ```
///
/// ## Theme Loading Priority:
/// 1. **Environment Override** (Any of these triggers ThemeConfigLoader):
///    - `THEME_SOURCE=cicd` → Uses `THEME_JSON` environment variable
///    - `THEME_SOURCE=network` → Loads from `THEME_NETWORK_URL`
///    - `THEME_SOURCE=assets` → Forces load from `THEME_ASSET_PATH`
///    - `THEME_SOURCE=default` → Uses built-in default theme
///    - `THEME_JSON` not empty (even if `THEME_SOURCE=normal`)
///    - `THEME_NETWORK_URL` not empty (even if `THEME_SOURCE=normal`)
///
/// 2. **Device Theme** (No override present):
///    - Watches `sessionProvider.modelNumber`
///    - Maps model number to theme file via BrandUtils
///    - Example: 'TB-6W' → assets/theme_tb.json
///    - Falls back to default theme if mapping not found
///
/// ## Reactive Behavior:
/// - Automatically reloads theme when sessionProvider.modelNumber changes
/// - Supports runtime theme switching (e.g., logging into different router models)
/// - Uses Riverpod's FutureProvider for async loading and caching
///
/// ## Error Handling:
/// - Returns default theme if loading fails
/// - Logs warnings/errors for debugging
/// - Never throws exceptions to ensure app stability
final deviceThemeConfigProvider = FutureProvider<ThemeJsonConfig>((ref) async {
  // Priority 1: Check if any theme override exists (environment variables)
  // This includes: THEME_SOURCE != normal, THEME_JSON not empty, THEME_NETWORK_URL not empty
  if (!ThemeConfigLoader.shouldUseDeviceTheme()) {
    logger.i('[DeviceThemeConfig]: Using theme override from environment');
    return ThemeConfigLoader.load();
  }

  // Priority 2: Device-specific theme based on model number
  final modelNumber = ref.watch(
    sessionProvider.select((state) => state.modelNumber),
  );

  logger.d('[DeviceThemeConfig]: Loading device theme for model: $modelNumber');

  // Load device theme via BrandUtils (reuses brand asset mapping logic)
  final themeConfig = await BrandUtils.getDeviceTheme(modelNumber);

  logger.i('[DeviceThemeConfig]: Device theme loaded for $modelNumber');

  return themeConfig;
});
