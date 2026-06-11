import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_state.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html'
    if (dart.library.io) 'package:privacy_gui/providers/remote_access/stub_html.dart'
    as html;

const _kSessionKey = 'ra_session';

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

  @override
  RemoteAccessState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });

    // Try to restore from sessionStorage on init
    final restored = _restoreFromStorage();
    if (restored != null) {
      _startCountdown();
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

    state = state.copyWith(
      sessionInfo: info,
      sessionToken: sessionToken,
      remainingSeconds: remainingSeconds,
    );

    _saveToStorage();
    _startCountdown();
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
      // Update storage with new remaining time periodically (every 10s)
      if (remaining % 10 == 0) {
        _saveToStorage();
      }
    });
  }

  /// Clear session state (when disconnecting).
  void clearSession() {
    _countdownTimer?.cancel();
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

      // Calculate actual remaining time (adjust for time passed since save)
      int? remainingSeconds;
      if (savedAt != null && savedRemaining != null) {
        final elapsed =
            (DateTime.now().millisecondsSinceEpoch - savedAt) ~/ 1000;
        remainingSeconds = (savedRemaining - elapsed).clamp(0, savedRemaining);
      }

      return RemoteAccessState(
        sessionInfo: GRASessionInfo.fromMap(sessionInfoMap),
        sessionToken: data['sessionToken'] as String?,
        remainingSeconds: remainingSeconds,
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
