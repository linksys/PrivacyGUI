import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart'
    show sessionAuthGateProvider;
import 'package:privacy_gui/core/usp/services/session_auth_gate.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_state.dart';
// ignore: avoid_web_libraries_in_flutter, sessionStorage for web persistence
import 'dart:html'
    if (dart.library.io) 'package:privacy_gui/providers/remote_access/stub_html.dart'
    as html;

const _kSessionKey = 'ra_session';
const _kPollInterval = Duration(seconds: 30);
const _kMaxPollFailures = 3;
const _kStorageSaveInterval = 10;

/// Provider that manages remote assistance session state.
///
/// Persists session info to sessionStorage (Web) for refresh survival.
/// Note: Remote mode determination is handled by [GlobalConfig.remote].
final remoteAccessProvider =
    NotifierProvider<RemoteAccessNotifier, RemoteAccessState>(
  RemoteAccessNotifier.new,
);

class RemoteAccessNotifier extends Notifier<RemoteAccessState> {
  Timer? _countdownTimer;
  Timer? _pollTimer;
  int _pollFailureCount = 0;

  @override
  RemoteAccessState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
      _pollTimer?.cancel();
    });

    // Try to restore from sessionStorage on init
    final restored = _restoreFromStorage();
    if (restored != null) {
      _startCountdown();
      _startPolling();
      return restored;
    }

    return const RemoteAccessState();
  }

  /// Update session info and start countdown timer.
  void updateSessionInfo(
    GRASessionInfo? info,
    int? remainingSeconds, {
    String? sessionToken,
  }) {
    _countdownTimer?.cancel();

    if (info == null || remainingSeconds == null) {
      state = state.copyWith(clearSessionInfo: true);
      _clearStorage();
      return;
    }

    // Calculate expiry time from remaining seconds
    final expiryTime = DateTime.now().add(Duration(seconds: remainingSeconds));

    state = state.copyWith(
      sessionInfo: info,
      sessionToken: sessionToken,
      remainingSeconds: remainingSeconds,
      expiryTime: expiryTime,
    );

    _saveToStorage();
    _startCountdown();
    _startPolling();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.remainingSeconds;
      if (remaining == null || remaining <= 0) {
        timer.cancel();
        state = state.copyWith(remainingSeconds: 0);
        return;
      }
      state = state.copyWith(remainingSeconds: remaining - 1);
      // Update storage with new remaining time periodically
      if (remaining % _kStorageSaveInterval == 0) {
        _saveToStorage();
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _pollSessionInfo());
  }

  Future<void> _pollSessionInfo() async {
    final sessionId = state.sessionInfo?.id;
    final sessionToken = state.sessionToken;
    if (sessionId == null || sessionToken == null) return;
    // The session this poll speaks for, taken with its id and token (#1666): a
    // poll still in flight when a new session is activated answers for the old
    // one.
    final ticket = ref.read(sessionAuthGateProvider).ticket;

    try {
      final service = ref.read(remoteAssistanceServiceProvider);
      final info = await service.fetchSessionInfoForCA(
        sessionToken: sessionToken,
        sessionId: sessionId,
      );

      // Calculate remaining seconds from API response
      // Use abs() to handle both negative (current) and positive (future) expiredIn values
      final remainingSeconds = info.expiredIn.abs();
      final expiryTime =
          DateTime.now().add(Duration(seconds: remainingSeconds));

      logger.d(
          '[RA] Poll: remaining=${remainingSeconds}s, status=${info.status}');

      _pollFailureCount = 0;
      state = state.copyWith(
        sessionInfo: info,
        remainingSeconds: remainingSeconds,
        expiryTime: expiryTime,
        hasPollError: false,
      );
      _saveToStorage();

      // If session is no longer active, stop polling
      if (info.status == GRASessionStatus.invalid) {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
      }
    } on UnauthorizedError {
      // A 401: whether it means this session is over is the gate's (#1666).
      // The end itself is the chip's: it navigates to `?expired=true` and then
      // logs out, an order the route redirect would break if this logged out
      // first.
      switch (ref.read(sessionAuthGateProvider).decideOn401(ticket)) {
        case AuthDecision.end:
          logger.w('[RA] Poll unauthorized (401) — forcing session end');
          _forceSessionEnd(sessionId);
        case AuthDecision.retry || AuthDecision.ignore:
          logger.d('[RA] Poll unauthorized (401) for a session that is over '
              'or not this one — ignored');
      }
    } catch (e) {
      _pollFailureCount++;
      logger.w('[RA] Poll failed (attempt $_pollFailureCount): $e');

      if (_pollFailureCount >= _kMaxPollFailures) {
        state = state.copyWith(hasPollError: true);
      }
    }
  }

  /// Force session end due to auth failure (401), for the session that was
  /// polled.
  ///
  /// Creates a new session info with INVALID status and stops all timers.
  /// The UI will detect this state change and navigate away appropriately.
  ///
  /// Only if [polledSessionId] is still the current session (#1666): before,
  /// this invalidated whatever session was current when the answer arrived, so
  /// a poll still in flight across a re-activation ended the new session.
  void _forceSessionEnd(String polledSessionId) {
    final currentInfo = state.sessionInfo;
    if (currentInfo == null || currentInfo.id != polledSessionId) {
      logger.d('[RA] The polled session is no longer current — not ending it');
      return;
    }
    _pollTimer?.cancel();
    _countdownTimer?.cancel();

    // Create invalid session info to trigger UI end flow
    final invalidInfo = GRASessionInfo(
      id: currentInfo.id,
      serialNumber: currentInfo.serialNumber,
      modelNumber: currentInfo.modelNumber,
      status: GRASessionStatus.invalid,
      expiredIn: 0,
      createdAt: currentInfo.createdAt,
      statusChangedAt: DateTime.now().millisecondsSinceEpoch,
      currentTime: DateTime.now().millisecondsSinceEpoch,
    );
    state = state.copyWith(sessionInfo: invalidInfo, remainingSeconds: 0);
    _clearStorage();
  }

  /// Clear session state (when disconnecting).
  void clearSession() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    state = state.copyWith(clearSessionInfo: true);
    _clearStorage();
  }

  // === Storage (Web sessionStorage) ===

  void _saveToStorage() {
    if (!kIsWeb) return;
    try {
      final data = {
        'sessionInfo': state.sessionInfo?.toMap(),
        'sessionToken': state.sessionToken,
        'remainingSeconds': state.remainingSeconds,
        'expiryTime': state.expiryTime?.millisecondsSinceEpoch,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      html.window.sessionStorage[_kSessionKey] = jsonEncode(data);
    } catch (e) {
      // Ignore storage errors
    }
  }

  RemoteAccessState? _restoreFromStorage() {
    if (!kIsWeb) return null;
    try {
      final stored = html.window.sessionStorage[_kSessionKey];
      if (stored == null) return null;

      final data = jsonDecode(stored) as Map<String, dynamic>;
      final sessionInfoMap = data['sessionInfo'] as Map<String, dynamic>?;
      if (sessionInfoMap == null) return null;

      final savedAt = data['savedAt'] as int?;
      final savedRemaining = data['remainingSeconds'] as int?;
      final expiryTimeMs = data['expiryTime'] as int?;

      // Calculate actual remaining time (adjust for time passed since save)
      int? remainingSeconds;
      if (savedAt != null && savedRemaining != null) {
        final elapsed =
            (DateTime.now().millisecondsSinceEpoch - savedAt) ~/ 1000;
        remainingSeconds = (savedRemaining - elapsed).clamp(0, savedRemaining);
      }

      // Restore expiry time
      DateTime? expiryTime;
      if (expiryTimeMs != null) {
        expiryTime = DateTime.fromMillisecondsSinceEpoch(expiryTimeMs);
      }

      return RemoteAccessState(
        sessionInfo: GRASessionInfo.fromMap(sessionInfoMap),
        sessionToken: data['sessionToken'] as String?,
        remainingSeconds: remainingSeconds,
        expiryTime: expiryTime,
      );
    } catch (e) {
      _clearStorage();
      return null;
    }
  }

  void _clearStorage() {
    if (!kIsWeb) return;
    try {
      html.window.sessionStorage.remove(_kSessionKey);
    } catch (e) {
      // Ignore
    }
  }
}
