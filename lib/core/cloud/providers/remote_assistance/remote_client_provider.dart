import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';

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
/// 2. If no session, poll until CA creates one
/// 3. Create PIN when session is in INITIATE/PENDING state
/// 4. Poll session status until ACTIVE or expired
/// 5. Handle session termination
///
/// Note: Device credentials (serialNumber, macAddress, deviceUUID) must be
/// provided externally as they are not available in the current session model.
class RemoteClientNotifier extends Notifier<RemoteClientState> {
  StreamSubscription<GRASessionInfo?>? _sessionPollSub;
  Timer? _sessionCreationPollTimer;
  Timer? _expiredCountdownTimer;
  DeviceCredentials? _credentials;

  @override
  RemoteClientState build() {
    ref.onDispose(() {
      _sessionPollSub?.cancel();
      _sessionCreationPollTimer?.cancel();
      _expiredCountdownTimer?.cancel();
    });
    return const RemoteClientState();
  }

  RemoteAssistanceService get _svc => ref.read(remoteAssistanceServiceProvider);

  DeviceCredentials? get _credsOrNull => _credentials;

  /// Set device credentials for API calls.
  ///
  /// Must be called before [initiateRemoteAssistance].
  void setCredentials(DeviceCredentials credentials) {
    _credentials = credentials;
  }

  /// Initialize Remote Assistance flow.
  ///
  /// Flow:
  /// 1. No session → show "contact support" + start polling for CA to create session
  /// 2. Session exists (INITIATE) → call createPin → show PIN (PENDING)
  /// 3. Session PENDING → show PIN + polling for CA to verify
  /// 4. Session ACTIVE → show "remote in progress" + End Session button
  ///
  /// Requires [setCredentials] to be called first.
  Future<void> initiateRemoteAssistance() async {
    final creds = _credsOrNull;
    if (creds == null) {
      logger.w('[RemoteAssistance]: Credentials not set');
      return;
    }

    logger.i('[RemoteAssistance]: initiateRemoteAssistance');

    final sessions = await _svc.fetchSessions(
      serialNumber: creds.serialNumber,
      macAddress: creds.macAddress,
      deviceUUID: creds.deviceUUID,
    );

    if (sessions.isEmpty) {
      // No session - CA hasn't created one yet
      // Show "contact support" and start polling
      logger.i('[RemoteAssistance]: No session - waiting for CA to create one');
      state = state.copyWith(
        sessionInfo: () => GRASessionInfo(
          id: '',
          serialNumber: creds.serialNumber,
          modelNumber: '',
          status: GRASessionStatus.initiate,
          expiredIn: 0,
          createdAt: 0,
          statusChangedAt: 0,
          currentTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );
      _startSessionCreationPoll();
      return;
    }

    // Session exists - fetch full info
    state = state.copyWith(sessions: () => sessions);
    logger.i('[RemoteAssistance]: Found session: ${sessions.first.id}');

    final sessionInfo = await _svc.fetchSessionInfo(
      sessionId: sessions.first.id,
      serialNumber: creds.serialNumber,
      macAddress: creds.macAddress,
      deviceUUID: creds.deviceUUID,
    );

    state = state.copyWith(sessionInfo: () => sessionInfo);

    // If session is INITIATE, create PIN to transition to PENDING
    if (sessionInfo.status == GRASessionStatus.initiate) {
      logger.i('[RemoteAssistance]: Session INITIATE - creating PIN');
      await _createPin();
    } else if (sessionInfo.status == GRASessionStatus.pending) {
      // Already PENDING - PIN should exist, try to get it
      // If PIN not in session info, try createPin (may return existing)
      if (state.pin == null) {
        await _createPin();
      }
    }

    _startExpiredCountdownTimer(sessionInfo);

    // Start polling for status updates (PENDING → ACTIVE)
    _startSessionPoll(sessionInfo.id);
  }

  /// Create PIN via API.
  Future<void> _createPin() async {
    final creds = _credsOrNull;
    if (creds == null) {
      logger.w('[RemoteAssistance]: Cannot create PIN - credentials not set');
      return;
    }
    try {
      final result = await _svc.createPin(
        serialNumber: creds.serialNumber,
        macAddress: creds.macAddress,
        deviceUUID: creds.deviceUUID,
      );
      state = state.copyWith(pin: () => result.pin);
      logger.i('[RemoteAssistance]: PIN created successfully');
    } on ServiceError catch (e) {
      logger.e('[RemoteAssistance]: Failed to create PIN', error: e);
      rethrow;
    }
  }

  /// Poll for session creation by CA.
  ///
  /// When no session exists, periodically check if CA has created one.
  /// Once a session is found, create PIN and switch to pending state.
  void _startSessionCreationPoll({int intervalSeconds = 5}) {
    _sessionCreationPollTimer?.cancel();
    _sessionCreationPollTimer =
        Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
      final creds = _credsOrNull;
      if (creds == null) {
        logger.w('[RemoteAssistance]: Credentials not set, canceling poll');
        _sessionCreationPollTimer?.cancel();
        _sessionCreationPollTimer = null;
        return;
      }

      try {
        final sessions = await _svc.fetchSessions(
          serialNumber: creds.serialNumber,
          macAddress: creds.macAddress,
          deviceUUID: creds.deviceUUID,
        );

        if (sessions.isNotEmpty) {
          logger.i(
              '[RemoteAssistance]: Session created by CA: ${sessions.first.id}');
          _sessionCreationPollTimer?.cancel();
          _sessionCreationPollTimer = null;

          state = state.copyWith(sessions: () => sessions);

          final sessionInfo = await _svc.fetchSessionInfo(
            sessionId: sessions.first.id,
            serialNumber: creds.serialNumber,
            macAddress: creds.macAddress,
            deviceUUID: creds.deviceUUID,
          );

          state = state.copyWith(sessionInfo: () => sessionInfo);

          // Create PIN to authorize CA
          logger.i('[RemoteAssistance]: Creating PIN for session');
          await _createPin();

          _startExpiredCountdownTimer(sessionInfo);

          // Start polling for status updates (PENDING → ACTIVE)
          _startSessionPoll(sessionInfo.id);
        }
      } on ServiceError catch (e) {
        logger.w('[RemoteAssistance]: Session creation poll failed', error: e);
      }
    });
  }

  /// Check for existing RA session and restore state.
  ///
  /// Called after page refresh when dashboard is ready.
  /// Returns true if a session was found and restored.
  Future<bool> checkAndRestoreSession() async {
    if (_credentials == null) {
      logger.d('[RemoteAssistance]: No credentials - cannot restore');
      return false;
    }

    // Skip if already has active session
    if (state.sessionInfo != null &&
        state.sessionInfo!.status != GRASessionStatus.invalid) {
      logger.d('[RemoteAssistance]: Already has active session');
      return true;
    }

    final creds = _credsOrNull;
    if (creds == null) {
      logger.d('[RemoteAssistance]: Credentials not set - cannot restore');
      return false;
    }
    try {
      final sessions = await _svc.fetchSessions(
        serialNumber: creds.serialNumber,
        macAddress: creds.macAddress,
        deviceUUID: creds.deviceUUID,
      );

      if (sessions.isEmpty) {
        logger.d('[RemoteAssistance]: No session to restore');
        return false;
      }

      final sessionInfo = await _svc.fetchSessionInfo(
        sessionId: sessions.first.id,
        serialNumber: creds.serialNumber,
        macAddress: creds.macAddress,
        deviceUUID: creds.deviceUUID,
      );

      // Ignore invalid/expired sessions
      if (sessionInfo.status == GRASessionStatus.invalid) {
        logger.d('[RemoteAssistance]: Session invalid - not restoring');
        return false;
      }

      logger.i('[RemoteAssistance]: Restoring session: ${sessionInfo.id}, '
          'status: ${sessionInfo.status}');

      state = state.copyWith(
        sessions: () => sessions,
        sessionInfo: () => sessionInfo,
      );

      // For PENDING status, try to get/create PIN
      if (sessionInfo.status == GRASessionStatus.pending ||
          sessionInfo.status == GRASessionStatus.initiate) {
        await _createPin();
      }

      _startExpiredCountdownTimer(sessionInfo);
      _startSessionPoll(sessionInfo.id);

      return true;
    } on ServiceError catch (e) {
      logger.w('[RemoteAssistance]: Failed to restore session', error: e);
      return false;
    }
  }

  /// End the current Remote Assistance session.
  Future<void> endRemoteAssistance() async {
    _sessionPollSub?.cancel();
    _sessionPollSub = null;
    _sessionCreationPollTimer?.cancel();
    _sessionCreationPollTimer = null;
    _expiredCountdownTimer?.cancel();
    _expiredCountdownTimer = null;

    final sessionId = state.sessionInfo?.id;
    final status = state.sessionInfo?.status;
    if (sessionId == null || sessionId.isEmpty) {
      state = const RemoteClientState();
      return;
    }

    // Delete session if PENDING or ACTIVE (PIN exists server-side)
    if (status == GRASessionStatus.pending ||
        status == GRASessionStatus.active) {
      final creds = _credsOrNull;
      if (creds == null) {
        logger
            .w('[RemoteAssistance]: Cannot end session - credentials not set');
        state = const RemoteClientState();
        return;
      }
      try {
        await _svc.endSession(
          sessionId: sessionId,
          serialNumber: creds.serialNumber,
          macAddress: creds.macAddress,
          deviceUUID: creds.deviceUUID,
        );
        logger.i('[RemoteAssistance]: Session ended (was $status)');
      } on ServiceError catch (e) {
        // Log but don't block UI flow if server-side deletion fails
        logger.w('[RemoteAssistance]: Failed to end session on server',
            error: e);
      }
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
          // Only start countdown timer if not already running
          if (_expiredCountdownTimer == null) {
            _startExpiredCountdownTimer(sessionInfo);
          }
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
    final creds = _credsOrNull;
    if (creds == null) {
      logger.w('[RemoteAssistance]: Cannot poll - credentials not set');
      return;
    }

    // Poll while session is valid (not INVALID) and not expired (expiredIn > 0 means time remaining)
    while (state.sessionInfo != null &&
        state.sessionInfo!.status != GRASessionStatus.invalid &&
        state.sessionInfo!.expiredIn > 0) {
      try {
        final sessionInfo = await _svc.fetchSessionInfo(
          sessionId: sessionId,
          serialNumber: creds.serialNumber,
          macAddress: creds.macAddress,
          deviceUUID: creds.deviceUUID,
        );
        yield sessionInfo;
      } on ServiceError catch (e) {
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
        countdown ??= sessionInfo.expiredIn.abs();
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
