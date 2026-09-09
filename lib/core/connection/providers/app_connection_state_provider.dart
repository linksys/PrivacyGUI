import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/recovery_plan.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
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

  /// The session exit this notifier has *decided on* and is waiting for the page
  /// layer to carry out. See [takePendingSessionExit].
  EndCause? _pendingSessionExit;

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

  /// Read-and-clear the session exit this notifier has decided on, if any.
  ///
  /// **This is how `lib/core/` stops ending the user's session itself.** All three
  /// of this file's exits — the manual one, a router that came back
  /// factory-reset, a router that came back with a different serial — used to
  /// finish with a bare `ref.read(authProvider.notifier).logout()`, which put the
  /// decision to sign a person out, the RA-teardown-by-cause that
  /// `SessionStrategy.end` owns, and the navigation that follows from it, inside a
  /// provider under `lib/core/`. Now each one sets the state and the cause and
  /// stops; `UspDashboardShell` is the single consumer and the only place that
  /// calls `logout()`. Pinned by `session_teardown_call_sites_test.dart`.
  ///
  /// **Not the four-variant `RecoveryOutcome` #1323 sketched**, because three of
  /// those variants already exist. "Recovered" and "still waiting" are
  /// [AppConnectionState.authenticated] and
  /// [AppConnectionState.waitingForRecovery] — values this notifier's own state
  /// already publishes to the same listener that would read the sealed type. Only
  /// "must end the session" carried information nothing else did, and its whole
  /// payload is the [EndCause] `AuthNotifier.logout` takes. A sealed hierarchy
  /// with one live variant would have been ceremony around this field, and the
  /// other three would have been a second spelling of the state — two sources for
  /// one fact, which is the defect the epic spent nine phases removing.
  ///
  /// **One-shot, and that is correctness rather than tidiness.**
  /// [AppConnectionState.loggedOut] is reachable two ways: this notifier deciding
  /// the session is over, and [build]'s `authProvider` listener observing that it
  /// already *is* over — a logout someone else initiated. Only the first sets the
  /// field, so a consumer keying off the state transition alone would call
  /// `logout()` a second time on the path where auth had just finished one.
  /// Clearing on read is also what stops a cause that has been acted on from
  /// being replayed by an unrelated later transition.
  EndCause? takePendingSessionExit() {
    final cause = _pendingSessionExit;
    _pendingSessionExit = null;
    return cause;
  }

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
    // Cleared alongside the rest of the per-wait bookkeeping. A pending exit that
    // nobody consumed belongs to a wait that is over; carrying it into this one
    // would let a stale cause be taken on the next transition to `loggedOut`.
    _pendingSessionExit = null;
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

  /// Give up on recovery: stop probing and report that the session is over.
  ///
  /// Does not sign the user out — it reports, via [takePendingSessionExit], and
  /// the page layer acts. The `logout()` that used to be this method's last line
  /// is the one `lib/core/` is no longer allowed to make.
  ///
  /// [EndCause.userRequested] rather than the [EndCause.sessionLost] that bare
  /// `logout()` defaulted to. Not a behaviour change: the only caller is
  /// `ReturnToLoginAction`, which only `LocalSurface.sessionExitAction()` returns,
  /// and `LocalSessionStrategy.end` is an empty body that ignores the cause. What
  /// it buys is that the one exit here a person actually asked for now says so, so
  /// if this ever does become reachable from a Remote surface it releases the
  /// Guardian session instead of leaving it open — which is the asymmetry
  /// `EndSessionAction` documents having had to route around this method to avoid.
  void exitToLogout() {
    _probeTimer?.cancel();
    _probeTimer = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _recoveryContext = null;
    _recoveryPlan = null;
    _consecutiveFailures = 0;
    _lastProbeResult = null;
    // Before the state assignment, not after. Riverpod notifies listeners
    // synchronously from `state =`, so the consumer runs inside that line and has
    // to find the cause already there — the same ordering the two probe exits
    // below rely on.
    _pendingSessionExit = EndCause.userRequested;
    state = AppConnectionState.loggedOut;
    logger.i('[Connection] Manual exit to loggedOut (userRequested)');
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
          logger.i('[Connection] Recovered (factoryReset) — session is over');
          // [EndCause.sessionLost], which is what the bare `logout()` here
          // defaulted to, and it is the right reading rather than the
          // conservative one: a router that came back factory-reset has already
          // discarded whatever authorised this session, so asking Guardian to
          // close it politely would be a call against a device that no longer
          // recognises the token.
          _pendingSessionExit = EndCause.sessionLost;
          state = AppConnectionState.loggedOut;
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
        logger.w('[Connection] Serial mismatch — session is over');
        // Same cause and the same reason as the factory-reset arm above: the
        // device that answered is not the one this session was opened against.
        _pendingSessionExit = EndCause.sessionLost;
        state = AppConnectionState.loggedOut;
        break;
    }
  }
}
