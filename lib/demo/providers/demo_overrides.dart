/// Demo Provider Overrides
///
/// Minimal overrides for Demo application. Most providers use their
/// original implementation with USP mock data via DemoUspTransport (plugged
/// into the real UspClient through UspClient.withTransport).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/demo/usp/demo_usp_data_loader.dart';
import 'package:privacy_gui/demo/usp/demo_usp_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_token_storage.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';
import 'demo_router_provider.dart';
import 'demo_package_widget_loader.dart';

/// Demo provider overrides for the Demo application.
///
/// These overrides replace **only the essential** providers:
/// - Auth: Always logged in
/// - Router: Wrap with ShellRoute for Theme Panel Overlay
/// - USP Service: Mock data from demo_usp_data.json
class DemoProviders {
  /// Returns all provider overrides needed for demo mode.
  static List<Override> get allOverrides {
    // Demo data flows through the real UspClient via the transport seam
    // (P3/P4): DemoUspTransport swaps the router for an in-memory loader while
    // UspClient still owns coercion, wildcard back-fill, and polling subscribe.
    final demoUsp =
        UspClient.withTransport(DemoUspTransport(DemoUspDataLoader.instance));
    return [
      // 1. Auth: Always logged in
      authProvider.overrideWith(() => _DemoAuthNotifier()),

      // 2. Router: Wrap with ShellRoute for Theme Panel Overlay
      routerProvider.overrideWithProvider(demoRouterProvider),

      // 3. Geolocation: Bypass cloud service call
      geolocationProvider.overrideWith(() => _DemoGeolocationNotifier()),

      // --- USP Provider overrides ---

      // 4. USP Service: Mock data from demo_usp_data.json
      uspClientProvider.overrideWith((ref) => demoUsp),

      // 5. SSE Bootstrap: No-op (no SSE in demo)
      sseBootstrapProvider.overrideWith((ref) async {}),

      // 6. SSE Manager: Null (no SSE in demo)
      sseManagerProvider.overrideWith((ref) => null),

      // 7. USP Bridge Client: Null (no bridge in demo)
      uspBridgeClientProvider.overrideWith((ref) => null),

      // 8. USP Auth Coordinator: Uses the demo UspClient (always authenticated)
      uspAuthCoordinatorProvider.overrideWith(
          (ref) => UspAuthCoordinator(demoUsp, UspTokenStorage())),

      // 9. Package Widget Loader: Use demo templates from assets
      packageWidgetLoaderProvider.overrideWith(() => DemoPackageWidgetLoader()),
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

/// Demo auth notifier — starts unauthenticated so PnP flow runs first.
///
/// - [build] returns [LoginType.none] (initial state before PnP).
/// - [init] returns [LoginType.local] (simulates stored credentials found).
/// - After PnP completes, [localLogin] sets state to [LoginType.local].
class _DemoAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async {
    debugPrint('Demo: Auth initialized as none (PnP flow will run)');
    return AuthState(loginType: LoginType.none);
  }

  @override
  Future<AuthState?> init() async {
    debugPrint('Demo: Auth init called - preserving local login');
    // Use AsyncValue.guard to match base class pattern — the `await` ensures
    // the state assignment happens after a microtask boundary, avoiding the
    // "Tried to modify a provider while the widget tree was building" error
    // when init() is called from go_router redirect during build phase.
    state = await AsyncValue.guard(
        () async => AuthState(loginType: LoginType.local));
    return state.value;
  }

  @override
  Future<dynamic> localLogin(
    String password, {
    bool guardError = true,
  }) async {
    debugPrint('Demo: Local login called');
    state = AsyncValue.data(AuthState(loginType: LoginType.local));
  }

  @override
  Future<void> logout() async {
    debugPrint('Demo: Logout called');
    state = AsyncValue.data(AuthState(loginType: LoginType.none));
  }
}
