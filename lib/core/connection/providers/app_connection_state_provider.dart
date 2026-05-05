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
  Timer? _probeTimer;
  Timer? _cooldownTimer;
  bool _sseSuspended = false;
  RecoveryContext? _recoveryContext;

  @override
  AppConnectionState build() {
    ref.listen(sseConnectionStateProvider, (_, next) {
      final sseState = next.valueOrNull;
      _sseSuspended = sseState == SseConnectionState.suspended;
    });

    ref.onDispose(() {
      _probeTimer?.cancel();
      _cooldownTimer?.cancel();
    });

    return AppConnectionState.authenticated;
  }

  void enterWaiting({required RecoveryContext context}) {
    if (state == AppConnectionState.waitingForRecovery) return;

    logger.i('[Connection] Entering waitingForRecovery '
        '(trigger: ${context.trigger}, cooldown: ${context.cooldown}, '
        'healthOnly: ${context.healthOnly})');

    _recoveryContext = context;
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
    state = AppConnectionState.loggedOut;
    logger.i('[Connection] Manual exit to loggedOut');
    ref.read(authProvider.notifier).logout();
  }

  void _startProbeLoop() {
    _probeTimer?.cancel();
    _runProbe();
    _probeTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _runProbe());
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

    switch (result) {
      case ProbeResult.unreachable:
        break;
      case ProbeResult.recovered:
        _probeTimer?.cancel();
        _probeTimer = null;
        state = AppConnectionState.authenticated;
        logger.i('[Connection] Recovered — reconnecting SSE');
        ref.read(sseManagerProvider)?.connect();
        break;
      case ProbeResult.serialMismatch:
        _probeTimer?.cancel();
        _probeTimer = null;
        state = AppConnectionState.loggedOut;
        logger.w('[Connection] Serial mismatch — force logout');
        ref.read(authProvider.notifier).logout();
        break;
    }
  }
}
