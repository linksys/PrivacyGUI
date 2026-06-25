import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_local_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_remote_strategy.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// Provides [UspBridgeClient] instance — depends on [UspClient].
///
/// In Remote Assistance mode, uses Guardian proxy endpoints.
/// In local mode, uses on-router usp-bridge endpoints.
final uspBridgeClientProvider = Provider<UspBridgeClient?>((ref) {
  final usp = ref.watch(uspClientProvider);
  if (usp == null) return null;

  if (GlobalConfig.remote.isActive) {
    final raState = ref.watch(remoteAssistanceProvider);
    final config = raState.config;
    if (config == null) return null;
    final endpoints = BridgeEndpoints.remote(config.sessionId);
    return UspBridgeClient(
      usp,
      endpoints: endpoints,
      authToken: config.temporaryAccessToken,
      clientTypeId: config.clientTypeId,
    );
  }

  return UspBridgeClient(usp);
});

/// Singleton [SseManager] provider — NOT autoDispose.
///
/// Lives for the entire authenticated session. Composes:
/// - [SseConnectionManager] — SSE stream lifecycle
/// - [SseSubscriptionRegistry] — OBUSPA + bridge subscription tracking
/// - [SseEventRouter] — event demux by subscription_id
///
/// Uses [LocalSseStrategy] or [RemoteSseStrategy] based on mode.
final sseManagerProvider = Provider<SseManager?>((ref) {
  final usp = ref.watch(uspClientProvider);
  final bridge = ref.watch(uspBridgeClientProvider);
  if (usp == null || bridge == null) return null;

  // Select strategy based on mode
  final SseOperationStrategy strategy = GlobalConfig.remote.isActive
      ? RemoteSseStrategy(bridge)
      : LocalSseStrategy(bridge);

  final manager = SseManager(usp: usp, bridge: bridge, strategy: strategy);

  // Wire proactive token refresh on SSE heartbeat (Local mode only)
  // Strategy's heartbeatConfig.authCheckEnabled controls whether this runs
  final authCoordinator = ref.read(uspAuthCoordinatorProvider);
  manager.onHeartbeatAuth = () => authCoordinator.ensureAuth();

  // Wire force logout — shared guard prevents duplicate triggers
  bool logoutTriggered = false;
  void forceLogout() {
    if (logoutTriggered) return;
    logoutTriggered = true;
    logger.w('[USP][Auth]: Force logout triggered — navigating to login');
    ref.read(authProvider.notifier).logout();
  }

  authCoordinator.onForceLogout = forceLogout;
  usp.onForceLogout = forceLogout;

  ref.onDispose(() {
    authCoordinator.onForceLogout = null;
    usp.onForceLogout = null;
    manager.dispose();
  });

  return manager;
});

/// Reactive SSE connection state as a [Stream].
///
/// Converts the [ValueNotifier] in [SseConnectionManager] to a Riverpod
/// stream for UI consumption (e.g., connection indicator badge).
final sseConnectionStateProvider = StreamProvider<SseConnectionState>((ref) {
  final manager = ref.watch(sseManagerProvider);
  if (manager == null) {
    return Stream.value(SseConnectionState.disconnected);
  }

  final controller = StreamController<SseConnectionState>();
  void listener() {
    controller.add(manager.connection.connectionState.value);
  }

  manager.connection.connectionState.addListener(listener);
  // Emit initial value
  controller.add(manager.connection.connectionState.value);

  ref.onDispose(() {
    manager.connection.connectionState.removeListener(listener);
    controller.close();
  });

  return controller.stream;
});

/// Provides [SseOperationAwaiter] for async Operate commands (Ping, Traceroute).
///
/// Returns null if USP or SSE manager is not available.
final sseOperationAwaiterProvider = Provider<SseOperationAwaiter?>((ref) {
  final manager = ref.watch(sseManagerProvider);
  final usp = ref.watch(uspClientProvider);
  if (manager == null || usp == null) return null;
  return SseOperationAwaiter(manager, usp);
});

/// Provides [NetworkDiagnosticsExecutor] — typed wrapper for TR-181 network
/// diagnostic Operate commands (Ping, TraceRoute, NSLookup, Download, Upload,
/// UDPEcho, ServerSelection) with SSE OperationComplete waiting and
/// ref-counted shared subscriptions via [DiagnosticScope].
final networkDiagnosticsExecutorProvider =
    Provider<NetworkDiagnosticsExecutor?>((ref) {
  final awaiter = ref.watch(sseOperationAwaiterProvider);
  if (awaiter == null) return null;
  final throttler = ref.watch(bridgeRequestThrottlerProvider);
  return NetworkDiagnosticsExecutor(awaiter, throttler);
});

/// Bootstrap provider — connects SSE and registers core subscriptions.
///
/// Watch this from the app shell to trigger SSE connection after login.
/// Core subscriptions are "always-on" while the app is connected.
final sseBootstrapProvider = FutureProvider<void>((ref) async {
  final manager = ref.watch(sseManagerProvider);
  if (manager == null) return;

  final usp = ref.watch(uspClientProvider);
  if (usp == null || !usp.isAuthenticated) return;

  final bridge = ref.watch(uspBridgeClientProvider);
  if (bridge == null) return;

  // Step 0: Health check — best-effort, non-fatal (local mode only).
  // If the bridge is busy (504) or slow, we still attempt SSE connection
  // because SseConnectionManager has its own retry/backoff logic.
  // Skip in Remote mode — Guardian proxy has no health endpoint.
  if (!GlobalConfig.remote.isActive) {
    try {
      await bridge.health().timeout(const Duration(seconds: 5));
      logger.d('[USP][SSE][Bootstrap]: Bridge health check passed');
    } catch (e) {
      logger.w(
          '[USP][SSE][Bootstrap]: Bridge health check failed: $e — continuing');
    }
  }

  // Connect SSE only — core subscriptions are registered by the dashboard
  // orchestrator AFTER domain providers settle. This prevents subscription
  // POST requests from competing with data GET requests on the bridge,
  // which causes 503 errors due to the single-threaded OBUSPA backend.
  await manager.connect();

  logger.d('[USP][SSE][Bootstrap]: Complete — SSE connected, '
      'core subscriptions deferred to orchestrator after domain ready');
});
