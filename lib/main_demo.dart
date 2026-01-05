import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:privacy_gui/theme/theme_config_loader.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import 'demo/data/demo_cache_data.dart';
import 'demo/demo_app.dart';
import 'demo/providers/demo_overrides.dart';

/// Demo mode entry point.
///
/// This entry point creates a fully functional demo version of the app
/// that uses mock data instead of real network connections. It's perfect for:
///
/// - **UI Demonstrations**: Show the app to stakeholders without a real router
/// - **Design Reviews**: Let designers see real UI implementations
/// - **Sales Presentations**: Demo features without network dependencies
/// - **Training**: Help new users learn the interface
///
/// ## Build Commands
///
/// ```bash
/// # Run locally
/// flutter run -d chrome --target=lib/main_demo.dart
///
/// # Build for web deployment
/// flutter build web --target=lib/main_demo.dart --base-href /PrivacyGUI-Demo/
/// ```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize better actions for JNAP
  initBetterActions();

  // Load environment variables (for AWS credentials)
  try {
    await dotenv.load(fileName: 'env.template');
  } catch (e) {
    debugPrint('No .env file found, using defaults');
  }

  // Load demo cache data
  await DemoCacheDataLoader.instance.load();

  // Load theme configuration (no network needed)
  final themeConfig = await ThemeConfigLoader.load();

  // Setup dependencies with demo-specific configuration
  _demoDependencySetup(themeConfig: themeConfig);

  runApp(
    ProviderScope(
      overrides: DemoProviders.allOverrides,
      child: const DemoLinksysApp(),
    ),
  );
}

/// Sets up dependencies for demo mode.
///
/// This is a simplified version of the production `dependencySetup` that
/// skips network-related services and uses mock implementations.
void _demoDependencySetup({ThemeJsonConfig? themeConfig}) {
  // Register mock service helper
  if (!getIt.isRegistered<ServiceHelper>()) {
    getIt.registerSingleton<ServiceHelper>(_DemoServiceHelper());
  }

  final config = themeConfig ?? ThemeJsonConfig.defaultConfig();

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

/// Demo service helper that intelligently reports support based on available mock data.
class _DemoServiceHelper extends ServiceHelper {
  final _loader = DemoCacheDataLoader.instance;

  bool _hasData(String keyword) {
    if (!_loader.isLoaded) return false;
    return _loader.cachedActions.any((url) => url.contains(keyword));
  }

  @override
  bool isSupportGuestNetwork([List<String>? services]) =>
      _hasData('GetGuestRadioSettings') || _hasData('GetGuestNetworkSettings');

  @override
  bool isSupportLedMode([List<String>? services]) =>
      _hasData('GetLedNightModeSetting');

  @override
  bool isSupportLedBlinking([List<String>? services]) => true;

  @override
  bool isSupportVPN([List<String>? services]) =>
      _hasData('GetVPNUser') || _hasData('GetVPNGateway');

  @override
  bool isSupportHealthCheck([List<String>? services]) =>
      _hasData('GetHealthCheckResults');

  @override
  bool isSupportClientDeauth([List<String>? services]) => true;

  @override
  bool isSupportAutoOnboarding([List<String>? services]) => true;

  @override
  bool isSupportMLO([List<String>? services]) => _hasData('GetMLOSettings');

  @override
  bool isSupportDFS([List<String>? services]) => _hasData('GetDFSSettings');

  @override
  bool isSupportAirtimeFairness([List<String>? services]) =>
      _hasData('GetAirtimeFairnessSettings');

  @override
  bool isSupportNodeFirmwareUpdate([List<String>? services]) => true;
}
