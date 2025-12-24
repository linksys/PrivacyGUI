/// Demo Provider Overrides
///
/// Minimal overrides for Demo application. Most providers use their
/// original implementation and get data through DemoRouterRepository.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/demo/jnap/demo_router_repository.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart';

/// Demo provider overrides for the Demo application.
///
/// These overrides replace **only the essential** providers:
/// - RouterRepository: Uses DemoRouterRepository to intercept all JNAP calls
/// - Auth: Always logged in
/// - Connectivity: Always online
/// - Polling: Initializes with empty state (data loaded via DemoRouterRepository)
///
/// All other providers use their **original implementation** and get data
/// through the DemoRouterRepository -> JnapMockRegistry -> demo_cache_data.json
/// pipeline.
class DemoProviders {
  /// Returns all provider overrides needed for demo mode.
  static List<Override> get allOverrides => [
        // 1. Auth: Always logged in
        authProvider.overrideWith(() => _DemoAuthNotifier()),

        // 2. Connectivity: Always online
        connectivityProvider.overrideWith(() => _DemoConnectivityNotifier()),

        // 3. Router Repository: Intercept JNAP traffic
        routerRepositoryProvider
            .overrideWith((ref) => DemoRouterRepository(ref)),

        // 4. Polling: Auto-start
        pollingProvider.overrideWith(() => _DemoPollingNotifier()),

        // 5. Geolocation: Bypass cloud service call
        geolocationProvider.overrideWith(() => _DemoGeolocationNotifier()),
      ];
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
