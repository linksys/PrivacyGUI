import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/core/usp/services/session_auth_gate.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/models/sse_connection_state.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/models/core_subscription_state.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/framework/mode/bridge_config.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
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
    // What a 401 does is the gate's (#1666); the bridge asks it and acts.
    gate: ref.read(sessionAuthGateProvider),
    // Null locally, and the client throws on any read that needs it. Nothing
    // local calls one: the only caller is #1580's page, whose entry point the
    // local surface does not offer.
    remoteReads: config.remoteReads,
  );

  return bridge;
});

/// Who answers "does this 401 end the session?" (#1666) — see
/// [SessionAuthGate]. USP commands, the heartbeat refresh, the session
/// restore, the bridge's REST and SSE requests and the Remote Assistance
/// session poll all ask it.
///
/// Built once and never rebuilt: it reads, never watches, so the session epoch
/// it keeps lasts as long as the app. The mode's answer comes from
/// `CredentialStrategy.authBehavior`, which is fixed for the build. Built at
/// boot, through the coordinator, so it is live before any page is: a 401 can
/// arrive before the dashboard shell has mounted (PnP, or a Remote Assistance
/// session still on its way in).
///
/// **It ends the session here**, in the one file under `lib/core/` still
/// allowed to sign the user out — `session_teardown_call_sites_test.dart`
/// declares it as such. A 401 can arrive before any page is mounted, so turning
/// it into a report the way #1323 phase 5 did the three connection exits would
/// fail open; #1323 carries that reasoning.
///
/// Under Remote Assistance this lands on the confirm view's "Session Ended"
/// screen — the same screen an operator who finished on purpose sees. That is a
/// decision, not an oversight: Austin's call on 2026-09-09 was not to tell the
/// two apart, so it is a closed question and not pending work. Reopening it
/// costs a stored end cause the route redirect can read, plus new copy in 26
/// locales; #1529 records the decision and what it would take.
///
/// The cause is spelled out: [EndCause.sessionLost] is what makes
/// `SessionStrategy.end` skip `endSessionForCA` under Remote Assistance, and
/// that is correct, not merely conservative — the credential has just been
/// rejected, so asking Guardian to close the session with it would be a call
/// it cannot honour.
final sessionAuthGateProvider = Provider<SessionAuthGate>((ref) {
  return SessionAuthGate(
    authBehavior: ref.read(appModeProfileProvider).credential.authBehavior,
    endSession: () {
      logger.w('[USP][Auth]: Session credential rejected — logging out');
      unawaited(
        ref.read(authProvider.notifier).logout(cause: EndCause.sessionLost),
      );
    },
  );
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

  final profile = ref.watch(appModeProfileProvider);
  final SseOperationStrategy strategy = profile.transport.sseStrategy(bridge);

  final manager = SseManager(usp: usp, bridge: bridge, strategy: strategy);

  // Wire proactive token refresh on SSE heartbeat (Local mode only)
  // Strategy's heartbeatConfig.authCheckEnabled controls whether this runs
  final authCoordinator = ref.read(uspAuthCoordinatorProvider);
  manager.onHeartbeatAuth = () => authCoordinator.ensureAuth();

  // What a 401 on a USP command or a heartbeat refresh does is
  // [sessionAuthGateProvider]'s (#1666), which the coordinator attaches to the
  // client. It used to be wired here, with a guard that lived as long as this
  // build — and locally this provider is built once per tab, so every forced
  // logout after the first one did nothing.

  ref.onDispose(manager.dispose);

  return manager;
});

/// Whether the session's core subscriptions are registered, as a [Stream].
///
/// The same bridge as [sseConnectionStateProvider], for the same reason: the
/// manager holds a [ValueNotifier] and the UI wants a provider. With no manager
/// there is nothing to wait for, so it answers ready rather than pending — a
/// dialog waiting on a demo build would never close.
final sseCoreSubscriptionsProvider =
    StreamProvider<CoreSubscriptionState>((ref) {
  final manager = ref.watch(sseManagerProvider);
  if (manager == null) {
    return Stream.value(const CoreSubscriptionsReady(registered: 0, failed: 0));
  }

  final controller = StreamController<CoreSubscriptionState>();
  void listener() => controller.add(manager.coreSubscriptions.value);

  manager.coreSubscriptions.addListener(listener);
  controller.add(manager.coreSubscriptions.value);

  ref.onDispose(() {
    manager.coreSubscriptions.removeListener(listener);
    controller.close();
  });

  return controller.stream;
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
  final awaiter = SseOperationAwaiter(manager, usp);
  // #1578: the awaiter registers a stream-opened listener on the manager, so it has
  // something to give back.
  ref.onDispose(awaiter.dispose);
  return awaiter;
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
  if (usp == null) return;

  // Whether the client holds this mode's credential is the mode's question —
  // see [CredentialStrategy.holdsCredential] for why the wasm client's own
  // `isAuthenticated` is the wrong one to ask under Remote Assistance. Read,
  // not watched: the profile is fixed for the build, and the client is already
  // watched above.
  if (!ref.read(appModeProfileProvider).credential.holdsCredential(usp)) {
    return;
  }

  final bridge = ref.watch(uspBridgeClientProvider);
  if (bridge == null) return;

  // Step 0: Health check — best-effort and non-fatal, in **both** modes.
  // If the bridge is busy (504) or slow, we still attempt SSE connection
  // because SseConnectionManager has its own retry/backoff logic.
  //
  // **This used to be skipped remotely, on a premise that was false.** #1474 phase 3
  // left the read alone and recorded the reason as the remote table's `health` entry
  // being invented. Guardian's own OpenAPI spec (received 2026-09-17) serves that
  // path, byte for byte as we declare it, so the `if` was compensating for nothing
  // and the endpoint table was right all along. #1576 deleted the gate; the same
  // premise is gone from `remote_transport_strategy.dart` and from
  // `bridge_endpoints_test.dart`, and `usp_health_claim_test.dart` scans for its
  // *absence* rather than for the new call — a scan for the call passes green with
  // the wrong comment beside it, which is how one docstring became four.
  //
  // It is still not a mode *cause*: both transports have a health endpoint, so
  // there is nothing here for a strategy member to answer.
  //
  // `RequestKind.bestEffort` because nothing depends on the answer: a 401 here
  // is caught below like any other failure, and deciding on it would have ended
  // the session from a call whose result is ignored (bb7d394ae). Whether the
  // token is really dead is for the connect and the first read, which report it
  // as they always have.
  try {
    await bridge
        .health(kind: RequestKind.bestEffort)
        .timeout(const Duration(seconds: 5));
    logger.d('[SSE]: Bridge health check passed');
  } catch (e) {
    logger.w('[SSE]: Bridge health check failed: $e — continuing');
  }

  // Connect SSE only — core subscriptions are registered by the dashboard
  // orchestrator AFTER domain providers settle. This prevents subscription
  // POST requests from competing with data GET requests on the bridge,
  // which causes 503 errors due to the single-threaded OBUSPA backend.
  await manager.connect();

  logger.d('[SSE]: Complete — SSE connected, '
      'core subscriptions deferred to orchestrator after domain ready');
});
