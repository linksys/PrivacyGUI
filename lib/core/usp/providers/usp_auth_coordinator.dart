import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

/// Coordinates USP authentication alongside JNAP authentication.
///
/// USP auth is an **additional local auth channel** — it never replaces JNAP auth.
/// This coordinator syncs login/logout between the two protocols and handles
/// session restoration on page reload (Web) where WASM state is lost.
///
/// Key behaviors:
/// - [syncAfterLocalLogin]: Auto-login USP after successful JNAP local login
/// - [syncAfterLogout]: Logout USP when JNAP logs out
/// - [restoreSession]: Re-authenticate USP using stored password on page reload
/// - [ensureAuth]: Proactive token refresh triggered by SSE heartbeat
///
/// USP login failure never blocks JNAP operations — [ProtocolResolver] falls
/// back to JNAP when `isAuthenticated` is false.
class UspAuthCoordinator {
  final UspClient? _usp;
  final FlutterSecureStorage _storage;

  DateTime? _lastTokenRefresh;
  Completer<void>? _refreshInProgress;

  /// Called when proactive refresh gets 401 — session externally terminated.
  VoidCallback? onForceLogout;

  /// Proactive refresh threshold. Must be less than JWT TTL (15 min).
  /// At 12 min, the worst-case margin is ~2:30 (heartbeat at 12:29 + refresh).
  static const Duration _refreshThreshold = Duration(minutes: 12);

  // Matches WASM error format "Transport error: HTTP error: HTTP 401"
  // and simplified format "HTTP 401 Unauthorized". Avoids false positives
  // on non-401 status codes (e.g., "HTTP 500").
  static final _authErrorPattern = RegExp(r'HTTP (?:error: HTTP )?401');
  static bool _isAuthError(Object error) {
    return _authErrorPattern.hasMatch(error.toString());
  }

  UspAuthCoordinator(this._usp, this._storage) {
    _usp?.onReauthRequired = () => _forceRestoreSession();
    _usp?.onRefreshTokenSuccess = () {
      _lastTokenRefresh = DateTime.now();
    };
  }

  /// Called after JNAP localLogin succeeds — auto-sync USP authentication.
  Future<void> syncAfterLocalLogin(String password) async {
    if (_usp == null) return;
    try {
      await _usp.login(password);
      _lastTokenRefresh = DateTime.now();
      logger.d('[USP][Auth]USP login synced successfully');
    } catch (e) {
      // USP login failure does not affect JNAP — ProtocolResolver
      // will fall back to JNAP when isAuthenticated=false
      logger.w('[USP][Auth]USP login failed after JNAP login: $e');
    }
  }

  /// Called during JNAP logout — sync logout USP.
  Future<void> syncAfterLogout() async {
    _lastTokenRefresh = null;
    if (_usp == null || !_usp.isAuthenticated) return;
    try {
      await _usp.logout();
      logger.d('[USP][Auth]USP logout synced successfully');
    } catch (e) {
      logger.w('[USP][Auth]USP logout failed: $e');
    }
  }

  /// Called on page reload / app restart — restore USP session from stored password.
  ///
  /// On Web, WASM state is lost on reload. This method reads the locally
  /// stored password from FlutterSecureStorage and re-authenticates USP.
  Future<void> restoreSession() async {
    if (_usp == null) {
      logger.w('[USP][Auth]restoreSession skipped: UspClient is null');
      return;
    }
    if (_usp.isAuthenticated) {
      logger.d('[USP][Auth]restoreSession skipped: already authenticated');
      return;
    }
    await _loginWithStoredPassword();
  }

  /// Force restore session — bypasses [isAuthenticated] guard.
  ///
  /// Used as [UspClient.onReauthRequired] callback. After a 401, the WASM
  /// client may still report isAuthenticated=true (token exists in memory
  /// but is expired/revoked). This method skips the guard and attempts
  /// re-login unconditionally.
  Future<void> _forceRestoreSession() async {
    if (_usp == null) {
      logger.w('[USP][Auth]forceRestoreSession skipped: UspClient is null');
      return;
    }
    await _loginWithStoredPassword();
  }

  /// Shared login logic — reads stored password and calls [UspClient.login].
  /// Returns true if login succeeded, false otherwise. Never throws.
  Future<bool> _loginWithStoredPassword() async {
    final password = await _storage.read(key: pLocalPassword);
    if (password == null || password.isEmpty) {
      logger.w('[USP][Auth]restoreSession skipped: no stored password');
      return false;
    }
    try {
      await _usp!.login(password);
      _lastTokenRefresh = DateTime.now();
      logger.d(
          '[USP][Auth]restoreSession login done, isAuthenticated=${_usp.isAuthenticated}');
      return true;
    } catch (e) {
      logger.w('[USP][Auth]restoreSession login failed: $e');
      return false;
    }
  }

  /// Attempts USP login independently (not as sync after JNAP).
  ///
  /// Used as fallback when JNAP is unavailable (e.g., firmware disabled JNAP).
  /// Returns true if USP login succeeds and is authenticated.
  Future<bool> tryUspLogin(String password) async {
    if (_usp == null) {
      logger.w('[USP][Auth]tryUspLogin skipped: UspClient is null');
      return false;
    }
    try {
      await _usp.login(password);
      final authenticated = _usp.isAuthenticated;
      if (authenticated) {
        _lastTokenRefresh = DateTime.now();
        logger.d('[USP][Auth]USP standalone login succeeded');
      }
      return authenticated;
    } catch (e) {
      logger.w('[USP][Auth]USP standalone login failed: $e');
      return false;
    }
  }

  /// Proactive token refresh — called on every SSE heartbeat (~30s).
  ///
  /// Strategy: Only refreshes when elapsed time ≥ [_refreshThreshold] (12 min)
  /// to avoid unnecessary network calls. On 401, triggers force logout instead
  /// of attempting [restoreSession], because:
  /// - SSE heartbeat arriving means the connection is live
  /// - A 401 on proactive refresh means the session was externally terminated
  ///   (e.g., SSH killed the session on the router)
  /// - Force logout is cleaner than silent re-login in this scenario
  ///
  /// Network errors are silently skipped — the next heartbeat will retry.
  Future<void> ensureAuth() async {
    if (_usp == null || !_usp.isAuthenticated) return;
    if (_usp.isReauthInProgress) return;
    if (_refreshInProgress != null) return;

    final last = _lastTokenRefresh;
    if (last != null && DateTime.now().difference(last) < _refreshThreshold) {
      return;
    }

    _refreshInProgress = Completer<void>();
    try {
      await _usp.refreshToken();
      _lastTokenRefresh = DateTime.now();
      logger.d('[USP][Auth]Proactive token refresh succeeded');
    } catch (e) {
      if (_isAuthError(e)) {
        _lastTokenRefresh = null; // Allow immediate retry if logout is delayed
        logger.w('[USP][Auth]Proactive refresh got 401 — forcing logout: $e');
        onForceLogout?.call();
      } else {
        logger.w('[USP][Auth]Proactive refresh failed (non-auth, will retry): $e');
      }
    } finally {
      _refreshInProgress = null;
    }
  }
}

final uspAuthCoordinatorProvider = Provider<UspAuthCoordinator>((ref) {
  return UspAuthCoordinator(
    ref.watch(uspClientProvider),
    const FlutterSecureStorage(),
  );
});
