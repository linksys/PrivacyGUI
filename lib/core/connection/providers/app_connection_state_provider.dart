import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

final recoveryProbeServiceProvider = Provider<RecoveryProbeService>((ref) {
  final bridge = ref.watch(uspBridgeClientProvider);
  final auth = ref.watch(uspAuthCoordinatorProvider);
  final fingerprint = ref.watch(routerFingerprintServiceProvider);
  return RecoveryProbeService(
    bridge: bridge!,
    authCoordinator: auth,
    fingerprintService: fingerprint,
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
      final loginType = next.value?.loginType;
      if (loginType == null || loginType == LoginType.none) {
        _probeTimer?.cancel();
        _probeTimer = null;
        _cooldownTimer?.cancel();
        _cooldownTimer = null;
        state = AppConnectionState.loggedOut;
      }
    });

    ref.onDispose(() {
      _probeTimer?.cancel();
      _cooldownTimer?.cancel();
      sseManager?.onReconnectFailed = null;
    });

    return AppConnectionState.authenticated;
  }

  void enterWaiting({required RecoveryContext context}) {
    if (state == AppConnectionState.waitingForRecovery) return;

    logger.i('[Connection] Entering waitingForRecovery '
        '(trigger: ${context.trigger}, cooldown: ${context.cooldown}, '
        'healthOnly: ${context.healthOnly})');

    _recoveryContext = context;
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
    _probeTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _runProbe());
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
        _probeTimer?.cancel();
        _probeTimer = null;
        state = AppConnectionState.loggedOut;
        logger.w('[Connection] Serial mismatch — force logout');
        ref.read(authProvider.notifier).logout();
        break;
    }
  }
}
