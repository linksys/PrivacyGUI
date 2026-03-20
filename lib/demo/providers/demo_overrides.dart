/// Demo Provider Overrides
///
/// Minimal overrides for Demo application. Most providers use their
/// original implementation with USP mock data via DemoUspService.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/protocol/protocol_resolver.dart';
import 'package:privacy_gui/demo/usp/demo_usp_data_loader.dart';
import 'package:privacy_gui/demo/usp/demo_usp_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/usp/providers/sse_providers.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'demo_router_provider.dart';

/// Demo provider overrides for the Demo application.
///
/// These overrides replace **only the essential** providers:
/// - Auth: Always logged in
/// - Router: Wrap with ShellRoute for Theme Panel Overlay
/// - USP Service: Mock data from demo_usp_data.json
class DemoProviders {
  /// Returns all provider overrides needed for demo mode.
  static List<Override> get allOverrides {
    final demoUsp = DemoUspService(DemoUspDataLoader.instance);
    return [
      // 1. Auth: Always logged in
      authProvider.overrideWith(() => _DemoAuthNotifier()),

      // 2. Router: Wrap with ShellRoute for Theme Panel Overlay
      routerProvider.overrideWithProvider(demoRouterProvider),

      // 3. Geolocation: Bypass cloud service call
      geolocationProvider.overrideWith(() => _DemoGeolocationNotifier()),

      // --- USP Provider overrides ---

      // 4. USP Service: Mock data from demo_usp_data.json
      uspServiceProvider.overrideWith((ref) => demoUsp),

      // 5. SSE Bootstrap: No-op (no SSE in demo)
      sseBootstrapProvider.overrideWith((ref) async {}),

      // 6. SSE Manager: Null (no SSE in demo)
      sseManagerProvider.overrideWith((ref) => null),

      // 7. USP Bridge Client: Null (no bridge in demo)
      uspBridgeClientProvider.overrideWith((ref) => null),

      // 8. Protocol Resolver: Force USP-only mode
      protocolResolverProvider.overrideWith(
          (ref) => ProtocolResolver(demoUsp, ProtocolPreference.uspOnly)),

      // 9. USP Auth Coordinator: Uses DemoUspService (always authenticated)
      uspAuthCoordinatorProvider.overrideWith(
          (ref) => UspAuthCoordinator(demoUsp, const FlutterSecureStorage())),
    ];
  }
}

class _DemoGeolocationNotifier extends GeolocationNotifier {
  @override
  Future<GeolocationState> build() async {
    debugPrint('Demo: Using mock geolocation');
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
// Demo Notifier Implementations
// ============================================================================

/// Demo auth notifier that simulates logged-in state
class _DemoAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async {
    debugPrint('Demo: Auth initialized with local login');
    return AuthState(
      loginType: LoginType.local,
      localPassword: 'demo-password',
    );
  }

  @override
  Future<AuthState?> init() async {
    debugPrint('Demo: Auth init called - preserving local login');
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
    debugPrint('Demo: Local login called');
    state = AsyncValue.data(AuthState(
      loginType: LoginType.local,
      localPassword: password,
    ));
  }

  @override
  Future<void> logout() async {
    debugPrint('Demo: Logout called');
    state = AsyncValue.data(AuthState(loginType: LoginType.none));
  }
}

