import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/recovery_plan.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// The recovery probe, wired to this mode's answers.
///
/// Since #1323 this resolves nothing itself. The old body read the bridge, the
/// auth coordinator and the fingerprint store and handed all three to the
/// service — which is what forced the `bridge!`: the provider is not autoDispose,
/// so it was built once while a session existed and re-read after one ended,
/// where `uspBridgeClientProvider` is legitimately null. The strategies resolve
/// what they need, when they need it, through the forwarded [Ref].
final recoveryProbeServiceProvider = Provider<RecoveryProbeService>((ref) {
  final profile = ref.watch(appModeProfileProvider);
  return RecoveryProbeService(
    ref: ref,
    transport: profile.transport,
    credential: profile.credential,
  );
});

final appConnectionStateProvider =
    NotifierProvider<AppConnectionStateNotifier, AppConnectionState>(
  AppConnectionStateNotifier.new,
);

class AppConnectionStateNotifier extends Notifier<AppConnectionState> {
  // Trigger recovery after 2 failures (~3-5s) instead of waiting for all 5
  // retries to exhaust (~6 min with 504 timeouts on each attempt).
  static const _reconnectFailureThreshold = 2;

  Timer? _probeTimer;
  Timer? _cooldownTimer;
  bool _sseSuspended = false;
  RecoveryContext? _recoveryContext;
  RecoveryPlan? _recoveryPlan;
  ProbeResult? _lastProbeResult;
  int _consecutiveFailures = 0;

  /// Number of consecutive `unreachable` probe results in the current waiting
  /// session. Resets when probe recovers or the notifier leaves the waiting
  /// state. Surfaced for UIs that want to switch from "please wait" to
  /// "please confirm WiFi" copy after sustained unreachability.
  int get consecutiveFailures => _consecutiveFailures;

  /// Most recent [ProbeResult] from the recovery probe loop, or `null` if
  /// no probe has run since the last reset.
  ProbeResult? get lastProbeResult => _lastProbeResult;

  /// The current recovery context, or `null` if not in recovery.
  RecoveryContext? get recoveryContext => _recoveryContext;

  @override
  AppConnectionState build() {
    final sseManager = ref.read(sseManagerProvider);
    sseManager?.onReconnectFailed = _onSseReconnectFailed;

    ref.listen(sseConnectionStateProvider, (_, next) {
      final sseState = next.valueOrNull;
      _sseSuspended = sseState == SseConnectionState.suspended;
    });

    ref.listen(authProvider, (_, next) {
      if (next.isLoading) return;
      final isLoggedIn = next.value?.isLoggedIn ?? false;
      if (!isLoggedIn) {
        _probeTimer?.cancel();
        _probeTimer = null;
        _cooldownTimer?.cancel();
        _cooldownTimer = null;
        state = AppConnectionState.loggedOut;
      } else if (state == AppConnectionState.loggedOut) {
        // Re-login within the same session (no page reload). The app uses a
        // single app-lifetime ProviderContainer, so build() — which seeds the
        // initial `authenticated` — does not re-run on re-login, and this
        // provider is never invalidated. Without restoring `authenticated`
        // here the state stays stuck at `loggedOut`, and every dashboard
        // polling notifier (traffic analysis, system monitor) that gates its
        // timer on `== authenticated` silently stops — the Network Health and
        // Traffic Monitor surfaces show no data until a full page reload.
        //
        // Only transition out of `loggedOut`; never override
        // `waitingForRecovery`, which owns its own exit path via _runProbe().
        state = AppConnectionState.authenticated;
      }
    });

    ref.onDispose(() {
      _probeTimer?.cancel();
      _cooldownTimer?.cancel();
      sseManager?.onReconnectFailed = null;
    });

    return AppConnectionState.authenticated;
  }

  /// Stop, disconnect SSE and start probing — unless this mode has nothing to
  /// recover from.
  ///
  /// Returns whether the app is now (or already was) waiting. `false` means the
  /// disruption does not interrupt *this* mode's path to the router, so there is
  /// no waiting state, no probe loop, and callers must not show a waiting
  /// surface: `showRecoveryDialog` would otherwise open a spinner that nothing
  /// ever pops, because the state it waits for a transition *into* is the state
  /// the app is already in.
  ///
  /// The one case that measures this way today is Remote Assistance plus
  /// `operationalWifiChange` — see `RemoteProximityStrategy.planFor`. Locally
  /// every trigger returns true, which is why this is a widened return type
  /// rather than a behaviour change.
  bool enterWaiting({required RecoveryContext context}) {
    if (state == AppConnectionState.waitingForRecovery) return true;

    final plan =
        ref.read(appModeProfileProvider).proximity.planFor(context.trigger);
    if (!plan.needsRecovery) {
      logger.i('[Connection] ${context.trigger} does not interrupt this '
          'mode\'s path to the router — not entering recovery');
      return false;
    }

    logger.i('[Connection] Entering waitingForRecovery '
        '(trigger: ${context.trigger}, cooldown: ${context.cooldown}, '
        'healthOnly: ${context.healthOnly}, plan: $plan)');

    _recoveryContext = context;
    _recoveryPlan = plan;
    _consecutiveFailures = 0;
    _lastProbeResult = null;
    state = AppConnectionState.waitingForRecovery;

    // Disconnect SSE immediately
    ref.read(sseManagerProvider)?.disconnect();

    // Start probe loop after cooldown
    if (context.cooldown == Duration.zero) {
      _startProbeLoop();
    } else {
      _cooldownTimer = Timer(context.cooldown, _startProbeLoop);
    }

    return true;
  }

  void _onSseReconnectFailed(int attempt) {
    if (attempt >= _reconnectFailureThreshold &&
        state == AppConnectionState.authenticated) {
      logger.i('[Connection] SSE reconnect failed $attempt times '
          '— auto-entering recovery');
      enterWaiting(context: RecoveryContext.natural);
    }
  }

  void reportConnectivityFailure() {
    if (state != AppConnectionState.authenticated) return;
    if (!_sseSuspended) return;

    logger.i('[Connection] Natural trigger: SSE suspended + polling failure');
    enterWaiting(context: RecoveryContext.natural);
  }

  void exitToLogout() {
    _probeTimer?.cancel();
    _probeTimer = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _recoveryContext = null;
    _recoveryPlan = null;
    _consecutiveFailures = 0;
    _lastProbeResult = null;
    state = AppConnectionState.loggedOut;
    logger.i('[Connection] Manual exit to loggedOut');
    ref.read(authProvider.notifier).logout();
  }

  /// Force an immediate probe attempt regardless of the periodic timer.
  /// Used by recovery dialogs that surface a manual "Retry now" affordance —
  /// e.g. when the user's device may have switched to a different WiFi during
  /// router reboot and they have just reconnected.
  Future<void> retryNow() async {
    if (state != AppConnectionState.waitingForRecovery) return;
    logger.i('[Connection] retryNow() — manual probe trigger');
    await _runProbe();
  }

  void _startProbeLoop() {
    _probeTimer?.cancel();
    _runProbe();
    // Cadence comes from the plan, not from a constant here: locally it is the
    // same 10 seconds this line used to hard-code; remotely the probe crosses a
    // cloud proxy and polls at the same 30 seconds the Guardian session poll
    // already uses. See `RemoteProximityStrategy`.
    final interval =
        _recoveryPlan?.probeInterval ?? const Duration(seconds: 10);
    _probeTimer = Timer.periodic(interval, (_) => _runProbe());
  }

  Future<void> _runProbe() async {
    if (state != AppConnectionState.waitingForRecovery) {
      _probeTimer?.cancel();
      return;
    }

    final probeService = ref.read(recoveryProbeServiceProvider);
    final result = await probeService.probe(
      healthOnly: _recoveryContext?.healthOnly ?? false,
    );
    _lastProbeResult = result;

    switch (result) {
      case ProbeResult.unreachable:
        _consecutiveFailures++;
        break;
      case ProbeResult.recovered:
        _consecutiveFailures = 0;
        _probeTimer?.cancel();
        _probeTimer = null;
        final trigger = _recoveryContext?.trigger;
        _recoveryContext = null;
        _recoveryPlan = null;
        if (trigger == RecoveryTrigger.operationalFactoryReset) {
          logger.i('[Connection] Recovered (factoryReset) — logging out');
          state = AppConnectionState.loggedOut;
          ref.read(authProvider.notifier).logout();
        } else {
          state = AppConnectionState.authenticated;
          logger.i('[Connection] Recovered — reconnecting SSE');
          ref.read(sseManagerProvider)?.connect();
        }
        break;
      case ProbeResult.serialMismatch:
        _recoveryContext = null;
        _recoveryPlan = null;
        _probeTimer?.cancel();
        _probeTimer = null;
        state = AppConnectionState.loggedOut;
        logger.w('[Connection] Serial mismatch — force logout');
        ref.read(authProvider.notifier).logout();
        break;
    }
  }
}
