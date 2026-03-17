/// Demo Provider Overrides
///
/// Minimal overrides for Demo application. Most providers use their
/// original implementation and get data through DemoRouterRepository.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/protocol/protocol_resolver.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/demo/jnap/demo_router_repository.dart';
import 'package:privacy_gui/demo/usp/demo_usp_data_loader.dart';
import 'package:privacy_gui/demo/usp/demo_usp_service.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/usp/providers/sse_providers.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'demo_router_provider.dart';

/// Demo provider overrides for the Demo application.
///
/// These overrides replace **only the essential** providers:
/// - RouterRepository: Uses DemoRouterRepository to intercept all JNAP calls
/// - Auth: Always logged in
/// - Connectivity: Always online
/// - Polling: Initializes with empty state (data loaded via DemoRouterRepository)
/// - PnP: Bypasses auto-configuration checks to skip setup wizard
///
/// All other providers use their **original implementation** and get data
/// through the DemoRouterRepository -> JnapMockRegistry -> demo_cache_data.json
/// pipeline.
class DemoProviders {
  /// Returns all provider overrides needed for demo mode.
  static List<Override> get allOverrides {
    final demoUsp = DemoUspService(DemoUspDataLoader.instance);
    return [
      // 1. Auth: Always logged in
      authProvider.overrideWith(() => _DemoAuthNotifier()),

      // 2. Connectivity: Always online
      connectivityProvider.overrideWith(() => _DemoConnectivityNotifier()),

      // 3. Router Repository: Intercept JNAP traffic
      routerRepositoryProvider
          .overrideWith((ref) => DemoRouterRepository(ref)),

      // 4. Polling: Auto-start
      pollingProvider.overrideWith(() => _DemoPollingNotifier()),

      // 5. Router: Wrap with ShellRoute for Theme Panel Overlay
      routerProvider.overrideWithProvider(demoRouterProvider),

      // 6. Geolocation: Bypass cloud service call
      geolocationProvider.overrideWith(() => _DemoGeolocationNotifier()),

      // 7. PnP: Bypass setup wizard
      pnpProvider.overrideWith(() => _DemoPnpNotifier()),

      // --- USP Provider overrides ---

      // 8. USP Service: Mock data from demo_usp_data.json
      uspServiceProvider.overrideWith((ref) => demoUsp),

      // 9. SSE Bootstrap: No-op (no SSE in demo)
      sseBootstrapProvider.overrideWith((ref) async {}),

      // 10. SSE Manager: Null (no SSE in demo)
      sseManagerProvider.overrideWith((ref) => null),

      // 11. USP Bridge Client: Null (no bridge in demo)
      uspBridgeClientProvider.overrideWith((ref) => null),

      // 12. Protocol Resolver: Force USP-only mode → routes to /uspDashboard
      protocolResolverProvider.overrideWith((ref) =>
          ProtocolResolver(demoUsp, ProtocolPreference.uspOnly)),

      // 13. USP Auth Coordinator: Uses DemoUspService (always authenticated)
      uspAuthCoordinatorProvider.overrideWith((ref) =>
          UspAuthCoordinator(demoUsp, const FlutterSecureStorage())),
    ];
  }
}

class _DemoGeolocationNotifier extends GeolocationNotifier {
  @override
  Future<GeolocationState> build() async {
    debugPrint('🌍 Demo: Using mock geolocation');
    return const GeolocationState(
        name: 'Linksys ISP',
        city: 'Irvine',
        region: 'California',
        country: 'United States',
        regionCode: 'CA',
        countryCode: 'US',
        continentCode: 'NA');
  }
}

// ============================================================================
// Demo Notifier Implementations - Only for core behavior, not data
// ============================================================================

/// Demo auth notifier that simulates logged-in state
class _DemoAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async {
    debugPrint('🔐 Demo: Auth initialized with local login');
    return AuthState(
      loginType: LoginType.local,
      localPassword: 'demo-password',
    );
  }

  @override
  Future<AuthState?> init() async {
    debugPrint('🔐 Demo: Auth init called - preserving local login');
    // In demo mode, we ignore storage and always return the local login state
    final demoState = AuthState(
      loginType: LoginType.local,
      localPassword: 'demo-password',
    );
    state = AsyncValue.data(demoState);
    return demoState;
  }

  @override
  Future<dynamic> localLogin(
    String password, {
    bool guardError = true,
    bool pnp = false,
  }) async {
    debugPrint('🔐 Demo: Local login called');
    state = AsyncValue.data(AuthState(
      loginType: LoginType.local,
      localPassword: password,
    ));
  }

  @override
  Future<void> logout() async {
    debugPrint('🔐 Demo: Logout called');
    state = AsyncValue.data(AuthState(loginType: LoginType.none));
  }
}

/// Demo connectivity notifier that simulates online state
class _DemoConnectivityNotifier extends ConnectivityNotifier {
  @override
  ConnectivityState build() {
    debugPrint('📶 Demo: Connectivity initialized as online');
    return const ConnectivityState(
      hasInternet: true,
      connectivityInfo: ConnectivityInfo(
        routerType: RouterType.behindManaged,
        gatewayIp: '192.168.1.1',
      ),
    );
  }
}

/// Demo polling notifier - uses parent's logic with DemoRouterRepository
class _DemoPollingNotifier extends PollingNotifier {
  @override
  FutureOr<CoreTransactionData> build() {
    debugPrint('🔄 Demo: Polling notifier initialized');

    // Auto-start polling after build
    Future.microtask(() {
      debugPrint('🔄 Demo: Auto-starting polling...');
      startPolling();
    });

    // Return empty initial state - data will be loaded when polling starts
    return const CoreTransactionData(
      lastUpdate: 0,
      isReady: false,
      data: {},
    );
  }
}

/// Demo PnP notifier - bypasses setup wizard checks
class _DemoPnpNotifier extends PnpNotifier {
  @override
  Future<AutoConfigurationUIModel?> autoConfigurationCheck() async {
    debugPrint('🔌 Demo: Bypassing auto-configuration check');
    return const AutoConfigurationUIModel(isSupported: false);
  }

  @override
  Future<bool> isRouterPasswordSet() async {
    // Return true to simulate that the router is already configured
    return true;
  }

  @override
  Future fetchDeviceInfo([bool clearCurrentSN = true]) async {
    // Just call super, but wrap in try-catch to be safe,
    // although DemoRouterRepository should handle it.
    try {
      await super.fetchDeviceInfo(clearCurrentSN);
    } catch (e) {
      debugPrint('🔌 Demo: fetchDeviceInfo suppressed error: $e');
    }
  }
}
