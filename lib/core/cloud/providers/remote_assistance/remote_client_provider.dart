import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/remote_assistance/services/remote_assistance_service.dart';

final remoteClientProvider =
    NotifierProvider<RemoteClientNotifier, RemoteClientState>(
  RemoteClientNotifier.new,
);

/// Device credentials required for Guardian API calls.
class DeviceCredentials {
  final String serialNumber;
  final String macAddress;
  final String deviceUUID;

  const DeviceCredentials({
    required this.serialNumber,
    required this.macAddress,
    required this.deviceUUID,
  });
}

/// Notifier for Remote Assistance client (device owner side).
///
/// Manages the RA session lifecycle:
/// 1. Fetch existing sessions
/// 2. Create PIN when session is in INITIATE/PENDING state
/// 3. Poll session status until ACTIVE or expired
/// 4. Handle session termination
///
/// Note: Device credentials (serialNumber, macAddress, deviceUUID) must be
/// provided externally as they are not available in the current session model.
class RemoteClientNotifier extends Notifier<RemoteClientState> {
  StreamSubscription<GRASessionInfo?>? _sessionPollSub;
  Timer? _expiredCountdownTimer;
  DeviceCredentials? _credentials;

  @override
  RemoteClientState build() => const RemoteClientState();

  RemoteAssistanceService get _svc => ref.read(remoteAssistanceServiceProvider);

  DeviceCredentials get _creds {
    if (_credentials == null) {
      throw StateError(
          'Device credentials not set. Call setCredentials first.');
    }
    return _credentials!;
  }

  /// Set device credentials for API calls.
  ///
  /// Must be called before [initiateRemoteAssistance].
  void setCredentials(DeviceCredentials credentials) {
    _credentials = credentials;
  }

  /// Initialize Remote Assistance flow.
  ///
  /// Fetches existing sessions, creates PIN if needed, and starts polling.
  /// Requires [setCredentials] to be called first.
  Future<void> initiateRemoteAssistance() async {
    final creds = _creds;

    logger.i('[RemoteAssistance]: initiateRemoteAssistance');

    final sessions = await _svc.fetchSessions(
      serialNumber: creds.serialNumber,
      macAddress: creds.macAddress,
      deviceUUID: creds.deviceUUID,
    );

    if (sessions.isEmpty) {
      logger.i('[RemoteAssistance]: No active sessions');
      state = const RemoteClientState();
      return;
    }

    state = state.copyWith(sessions: () => sessions);
    logger.i('[RemoteAssistance]: Found session: ${sessions.first.id}');

    final sessionInfo = await _svc.fetchSessionInfo(
      sessionId: sessions.first.id,
      serialNumber: creds.serialNumber,
      macAddress: creds.macAddress,
      deviceUUID: creds.deviceUUID,
    );

    state = state.copyWith(sessionInfo: () => sessionInfo);
    _startExpiredCountdownTimer(sessionInfo);

    // Create PIN if session is in INITIATE or PENDING without PIN
    if (sessionInfo.status == GRASessionStatus.initiate ||
        (sessionInfo.status == GRASessionStatus.pending && state.pin == null)) {
      logger
          .i('[RemoteAssistance]: Creating PIN for session ${sessionInfo.id}');
      await createPin();
    }

    // Start polling for status updates
    _startSessionPoll(sessionInfo.id);
  }

  /// Create a PIN for the current session.
  Future<String?> createPin() async {
    final creds = _creds;

    final pin = await _svc.createPin(
      serialNumber: creds.serialNumber,
      macAddress: creds.macAddress,
      deviceUUID: creds.deviceUUID,
    );

    state = state.copyWith(pin: () => pin);
    logger.i('[RemoteAssistance]: PIN created');
    return pin;
  }

  /// End the current Remote Assistance session.
  Future<void> endRemoteAssistance() async {
    _sessionPollSub?.cancel();
    _sessionPollSub = null;
    _expiredCountdownTimer?.cancel();
    _expiredCountdownTimer = null;

    final sessionId = state.sessionInfo?.id;
    if (sessionId == null) {
      state = const RemoteClientState();
      return;
    }

    // Only delete if session is active
    if (state.sessionInfo?.status == GRASessionStatus.active) {
      final creds = _creds;
      await _svc.endSession(
        sessionId: sessionId,
        serialNumber: creds.serialNumber,
        macAddress: creds.macAddress,
        deviceUUID: creds.deviceUUID,
      );
      logger.i('[RemoteAssistance]: Session ended');
    }

    state = const RemoteClientState();
  }

  /// Start polling for session status updates.
  void _startSessionPoll(String sessionId, {int intervalSeconds = 3}) {
    _sessionPollSub?.cancel();
    _sessionPollSub = _pollSessionStatus(sessionId, intervalSeconds).listen(
      (sessionInfo) {
        if (sessionInfo != null) {
          state = state.copyWith(sessionInfo: () => sessionInfo);
          _startExpiredCountdownTimer(sessionInfo);
        }
      },
      onError: (e) {
        logger.e('[RemoteAssistance]: Poll error', error: e);
      },
    );
  }

  /// Stream that polls session status periodically.
  Stream<GRASessionInfo?> _pollSessionStatus(
    String sessionId,
    int intervalSeconds,
  ) async* {
    final creds = _creds;

    while (state.sessionInfo != null && state.sessionInfo!.expiredIn < 0) {
      try {
        final sessionInfo = await _svc.fetchSessionInfo(
          sessionId: sessionId,
          serialNumber: creds.serialNumber,
          macAddress: creds.macAddress,
          deviceUUID: creds.deviceUUID,
        );
        yield sessionInfo;
      } catch (e) {
        logger.w('[RemoteAssistance]: Poll fetch failed', error: e);
        yield null;
      }
      await Future.delayed(Duration(seconds: intervalSeconds));
    }
  }

  /// Start countdown timer for session expiry.
  void _startExpiredCountdownTimer(GRASessionInfo sessionInfo) {
    _expiredCountdownTimer?.cancel();
    _expiredCountdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        var countdown = state.expiredCountdown;
        countdown ??= sessionInfo.expiredIn * -1;
        countdown--;

        state = state.copyWith(expiredCountdown: () => countdown);

        if (countdown < 0) {
          timer.cancel();
          _expiredCountdownTimer = null;
        }
      },
    );
  }
}
