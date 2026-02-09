import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/theme/theme_config_loader.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:privacy_gui/utils.dart';

/// Device-specific theme configuration provider.
///
/// Integrates two theme loading strategies with priority:
/// 1. **forcedSource** (Priority): Used for CI/CD, test environments to override theme source
/// 2. **Device theme** (Normal): Loads theme based on modelNumber from sessionProvider
///
/// When forcedSource is not normal, uses ThemeConfigLoader.load() to load forced theme.
/// When forcedSource is normal, loads device-specific theme via BrandUtils based on modelNumber.
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
/// 1. **forcedSource** (Environment Variables):
///    - `THEME_SOURCE=cicd` → Uses `THEME_JSON` environment variable
///    - `THEME_SOURCE=network` → Loads from `THEME_NETWORK_URL`
///    - `THEME_SOURCE=assets` → Forces load from `THEME_ASSET_PATH`
///    - `THEME_SOURCE=default` → Uses built-in default theme
///
/// 2. **Device Theme** (Normal Mode):
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
  // Check for forced theme source (CI/CD, testing)
  final forcedSource = ThemeConfigLoader.forcedSource;

  // Priority 1: Use forced source if set (environment variable override)
  if (forcedSource != ThemeSource.normal) {
    logger.i('[DeviceThemeConfig] Using forcedSource: $forcedSource');
    return ThemeConfigLoader.load();
  }

  // Priority 2: Device-specific theme based on model number
  final modelNumber = ref.watch(
    sessionProvider.select((state) => state.modelNumber),
  );

  logger.d('[DeviceThemeConfig] Loading device theme for model: $modelNumber');

  // Load device theme via BrandUtils (reuses brand asset mapping logic)
  final themeConfig = await BrandUtils.getDeviceTheme(modelNumber);

  logger.i('[DeviceThemeConfig] Device theme loaded for $modelNumber');

  return themeConfig;
});
