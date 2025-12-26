/// USP Demo Mode Entry Point
///
/// This entry point creates a demo version of the app that connects to
/// the USP Simulator via gRPC instead of using mock data.
///
/// ## Prerequisites
///
/// Before running, ensure the following are started:
/// 1. Docker infrastructure: `melos run infra:start`
///
/// ## Build Commands
///
/// ```bash
/// # Run locally (connect to localhost:8090)
/// flutter run -d chrome --target=lib/main_usp_demo.dart
///
/// # With custom host/port
/// flutter run -d chrome --target=lib/main_usp_demo.dart --dart-define=USP_HOST=192.168.1.100 --dart-define=USP_PORT=8090
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:usp_client_core/usp_client_core.dart';
import 'package:privacy_gui/core/usp/usp_mapper_repository.dart';
import 'package:privacy_gui/core/usp/capabilities/capability_registry.dart';
import 'package:privacy_gui/core/usp/capabilities/repositories/capability_repository.dart';
import 'package:privacy_gui/core/usp/capabilities/repositories/usp_capability_repository.dart';
import 'package:privacy_gui/core/usp/capabilities/repositories/local_capability_repository.dart';
import 'package:privacy_gui/core/usp/capabilities/models/device_feature.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:privacy_gui/theme/theme_config_loader.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import 'demo/demo_app.dart';
import 'demo/data/demo_cache_data.dart';
import 'demo/providers/demo_overrides.dart';

/// Global gRPC service instance (initialized before app starts)
late final UspGrpcClientService _grpcService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize JNAP actions (same as main_demo.dart)
  initBetterActions();

  // Get connection config from environment or use defaults
  const config = UspConnectionConfig(
    host: String.fromEnvironment('USP_HOST', defaultValue: 'localhost'),
    port: int.fromEnvironment('USP_PORT', defaultValue: 8090),
  );

  // Initialize gRPC service and connect
  _grpcService = UspGrpcClientService();

  debugPrint('🔌 USP Demo: Connecting to ${config.host}:${config.port}...');

  // Capability repository to be initialized
  late final CapabilityRepository capabilityRepo;

  try {
    await _grpcService.connect(config);
    debugPrint('✅ USP Demo: Connected to Simulator');

    // Initialize Capabilities
    try {
      capabilityRepo = UspCapabilityRepository(_grpcService);
      await capabilityRepo.initialize();
    } catch (e) {
      debugPrint(
          '⚠️ USP Demo: Capability discovery failed, using fallback: $e');
      capabilityRepo = LocalCapabilityRepository();
      await capabilityRepo.initialize();
    }
  } catch (e) {
    debugPrint('⚠️ USP Demo: Connection failed: $e');
    debugPrint('⚠️ USP Demo: Make sure Simulator and Envoy are running');
    // Fallback to local capabilities
    capabilityRepo = LocalCapabilityRepository();
    await capabilityRepo.initialize();
  }

  // Load demo cache data for fallback (same as main_demo.dart)
  // This provides complete mock data for JNAP actions not mapped to TR-181
  await DemoCacheDataLoader.instance.load();

  // Load theme configuration (same as main_demo.dart)
  final themeConfig = await ThemeConfigLoader.load();
  _uspDemoDependencySetup(
      capabilityRepo: capabilityRepo, themeConfig: themeConfig);

  runApp(
    ProviderScope(
      overrides: _buildUspOverrides(capabilityRepo),
      child: const DemoLinksysApp(),
    ),
  );
}

/// Build provider overrides for USP demo mode.
///
/// Uses DemoProviders' auth/connectivity/polling/geolocation overrides
/// but replaces RouterRepository with USP implementation.
List<Override> _buildUspOverrides(CapabilityRepository capabilityRepo) {
  // Explicitly use the same demo overrides for auth bypass
  // but replace routerRepositoryProvider with USP version
  return [
    // Use DemoProviders' auth, connectivity, polling, geolocation
    ...DemoProviders.allOverrides,

    // Capability repository
    capabilityRepositoryProvider.overrideWithValue(capabilityRepo),

    // Override with USP RouterRepository (this takes precedence)
    routerRepositoryProvider.overrideWith(
      (ref) => UspMapperRepository(ref, _grpcService),
    ),
  ];
}

/// Setup dependencies for USP demo mode.
///
/// Same as _demoDependencySetup in main_demo.dart but with USP-specific ServiceHelper.
void _uspDemoDependencySetup({
  required CapabilityRepository capabilityRepo,
  ThemeJsonConfig? themeConfig,
}) {
  // Register USP-specific service helper
  if (!getIt.isRegistered<ServiceHelper>()) {
    getIt.registerSingleton<ServiceHelper>(
        _UspDemoServiceHelper(capabilityRepo));
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

/// Service helper for USP demo mode.
///
/// Reports all features as supported since we don't know what the
/// Simulator supports until we query it.
class _UspDemoServiceHelper extends ServiceHelper {
  final CapabilityRepository _capabilityRepo;

  _UspDemoServiceHelper(this._capabilityRepo);

  @override
  bool isSupportGuestNetwork([List<String>? services]) =>
      _capabilityRepo.hasFeature(DeviceFeature.guestNetwork);

  @override
  bool isSupportLedMode([List<String>? services]) => true;

  @override
  bool isSupportLedBlinking([List<String>? services]) => true;

  @override
  bool isSupportVPN([List<String>? services]) => false;

  @override
  bool isSupportHealthCheck([List<String>? services]) =>
      _capabilityRepo.hasFeature(DeviceFeature.diagnostics);

  @override
  bool isSupportClientDeauth([List<String>? services]) => true;

  @override
  bool isSupportAutoOnboarding([List<String>? services]) => true;

  @override
  bool isSupportMLO([List<String>? services]) =>
      _capabilityRepo.hasFeature(DeviceFeature.wifi5Hz);

  @override
  bool isSupportDFS([List<String>? services]) =>
      _capabilityRepo.hasFeature(DeviceFeature.wifi5Hz);

  @override
  bool isSupportAirtimeFairness([List<String>? services]) => true;

  @override
  bool isSupportNodeFirmwareUpdate([List<String>? services]) => true;
}
