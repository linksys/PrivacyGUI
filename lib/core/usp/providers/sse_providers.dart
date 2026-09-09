import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/framework/mode/bridge_config.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// How this build's transport is described — the mode-dependent half of
/// [uspBridgeClientProvider], split out so a test can read it.
///
/// The answer comes from `TransportStrategy.bridgeConfig`, so there is no `if`
/// here. Before #1474 phase 3 the five arguments below were chosen by an inline
/// `if (GlobalConfig.remote.isActive)` and handed straight to a constructor that
/// the VM stub *discards* — no getters, nothing to assert on — so the difference
/// between talking to the router and talking to Guardian was unobservable from a
/// unit test. This provider is that observation point.
///
/// Null means "no transport yet", which is a real state in Remote Assistance: the
/// mode is known at build time but the Guardian session only arrives with the
/// agent's link. See `RemoteTransportStrategy.bridgeConfig`.
final bridgeConfigProvider = Provider<BridgeConfig?>((ref) {
  final transport = ref.watch(appModeProfileProvider).transport;
  // `ref` is forwarded rather than resolved here: the remote answer watches
  // `remoteAssistanceProvider`, so the dependency has to be registered against
  // this provider. That is why the contract takes a Ref instead of being a getter.
  return transport.bridgeConfig(ref);
});

/// Provides [UspBridgeClient] instance — depends on [UspClient].
///
/// A pure assembler since #1474 phase 3: which endpoints, host, token and auth
/// behaviour to use is [bridgeConfigProvider]'s answer, and this provider only
/// builds the client and wires its auth-failure callback. `endpoints: local` /
/// `baseUrl: null` is exactly what the omitted arguments used to mean —
/// `_endpoints = endpoints ?? BridgeEndpoints.local` and
/// `_baseUrl => _overrideBaseUrl ?? _usp.baseUrl` — so naming them changes
/// nothing but makes the local case as inspectable as the remote one.
final uspBridgeClientProvider = Provider<UspBridgeClient?>((ref) {
  final usp = ref.watch(uspClientProvider);
  if (usp == null) return null;

  final config = ref.watch(bridgeConfigProvider);
  if (config == null) return null;

  final bridge = UspBridgeClient(
    usp,
    endpoints: config.endpoints,
    // Remotely, the same host as the Guardian session REST API — NOT the app's
    // own origin. Locally null, which the client reads as "same origin".
    baseUrl: config.baseUrl,
    authToken: config.authToken,
    clientTypeId: config.clientTypeId,
    authBehavior: config.authBehavior,
  );

  // W-1 fix: wire auth failure to logout (both modes)
  //
  // TODO(#1529): the one place under `lib/core/` still allowed to sign the user
  // out, and `session_teardown_call_sites_test.dart` declares it as such. A 401
  // can arrive before any page is mounted, so converting it to a report the way
  // phase 5 did the three connection exits would fail open. #1529 owns the
  // replacement — under Remote Assistance this currently ends a support session
  // with no explanation and nothing to sign back in to.
  bridge.onAuthFailed = () {
    logger.w('[USP][Auth]: Session expired — triggering logout');
    ref.read(authProvider.notifier).logout();
  };

  return bridge;
});

/// Singleton [SseManager] provider — NOT autoDispose.
///
/// Lives for the entire authenticated session. Composes:
/// - [SseConnectionManager] — SSE stream lifecycle
/// - [SseSubscriptionRegistry] — OBUSPA + bridge subscription tracking
/// - [SseEventRouter] — event demux by subscription_id
///
/// Uses `LocalSseStrategy` or `RemoteSseStrategy` based on mode — reached
/// *through* the transport since #1474 phase 3, not by its own `if`.
///
/// The strategy itself is unchanged; only who picks it moved. "Which subscription
/// dance" is a consequence of "which path": the Guardian proxy rejects duplicate
/// subscription IDs and scopes them to the stream, the on-router bridge is
/// idempotent. Asking the transport keeps that consequence expressed as one, so a
/// third transport cannot arrive with a matching SSE discipline nobody wired up.
final sseManagerProvider = Provider<SseManager?>((ref) {
  final usp = ref.watch(uspClientProvider);
  final bridge = ref.watch(uspBridgeClientProvider);
  if (usp == null || bridge == null) return null;

  final SseOperationStrategy strategy =
      ref.watch(appModeProfileProvider).transport.sseStrategy(bridge);

  final manager = SseManager(usp: usp, bridge: bridge, strategy: strategy);

  // Wire proactive token refresh on SSE heartbeat (Local mode only)
  // Strategy's heartbeatConfig.authCheckEnabled controls whether this runs
  final authCoordinator = ref.read(uspAuthCoordinatorProvider);
  manager.onHeartbeatAuth = () => authCoordinator.ensureAuth();

  // Wire force logout — shared guard prevents duplicate triggers
  //
  // TODO(#1529): the same waiver as `bridge.onAuthFailed` above, reached from the
  // auth coordinator and the client instead of the bridge. The log line says
  // "navigating to login", which has no counterpart in Remote Assistance.
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
  //
  // #1474 phase 3 deliberately left this read alone, taking the file from 3 mode
  // reads to 1. It is not a mode *cause*: it exists because
  // `BridgeEndpoints.remote()`'s `health` path is a fabrication — Guardian has no
  // such endpoint — so this `if` is compensating for a wrong endpoint table, and
  // the fix is to delete that path, not to give the mode a strategy member for
  // "does my transport have a health check". That is transport-layer cleanup
  // outside this epic; wrapping it in a strategy first would freeze the
  // fabrication into a contract.
  if (!GlobalConfig.remote.isActive) {
    try {
      await bridge.health().timeout(const Duration(seconds: 5));
      logger.d('[SSE]: Bridge health check passed');
    } catch (e) {
      logger.w('[SSE]: Bridge health check failed: $e — continuing');
    }
  }

  // Connect SSE only — core subscriptions are registered by the dashboard
  // orchestrator AFTER domain providers settle. This prevents subscription
  // POST requests from competing with data GET requests on the bridge,
  // which causes 503 errors due to the single-threaded OBUSPA backend.
  await manager.connect();

  logger.d('[SSE]: Complete — SSE connected, '
      'core subscriptions deferred to orchestrator after domain ready');
});
