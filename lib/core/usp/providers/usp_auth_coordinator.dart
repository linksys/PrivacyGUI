import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
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

  // Matches invalid credentials errors:
  // - WASM: "Transport error: HTTP error: HTTP 401"
  // - WASM: "HTTP 401 Unauthorized"
  // - WASM/Rust: "Login failed: Authentication error: Invalid credentials"
  // - Bridge CGI: "Invalid username or password", "Invalid password"
  static final _invalidCredentialsPattern = RegExp(
    r'HTTP (?:error: HTTP )?401|Invalid (username or password|password|credentials)',
    caseSensitive: false,
  );

  // Matches account locked errors:
  // - Bridge CGI: "Account locked", "Account is locked"
  static final _accountLockedPattern = RegExp(
    r'Account.*(locked|lock)',
    caseSensitive: false,
  );

  static bool _isAuthError(Object error) {
    return _invalidCredentialsPattern.hasMatch(error.toString());
  }

  static bool _isAccountLockedError(Object error) {
    return _accountLockedPattern.hasMatch(error.toString());
  }

  UspAuthCoordinator(this._usp, this._storage) {
    _usp?.onReauthRequired = restoreSession;
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
      logger.d('[USP][Auth]: USP login synced successfully');
    } catch (e) {
      // USP login failure does not affect JNAP — ProtocolResolver
      // will fall back to JNAP when isAuthenticated=false
      logger.w('[USP][Auth]: USP login failed after JNAP login: $e');
    }
  }

  /// Called during JNAP logout — sync logout USP.
  Future<void> syncAfterLogout() async {
    _lastTokenRefresh = null;
    if (_usp == null || !_usp.isAuthenticated) return;
    try {
      await _usp.logout();
      logger.d('[USP][Auth]: USP logout synced successfully');
    } catch (e) {
      logger.w('[USP][Auth]: USP logout failed: $e');
    }
  }

  /// Re-authenticates USP using the stored local password.
  ///
  /// Used in three scenarios:
  /// - **Page reload (Web)**: WASM in-memory state is lost, `isAuthenticated`
  ///   reads false, login restores the session.
  /// - **401 reauth Stage 2** (`UspClient.onReauthRequired`): the WASM client
  ///   still reports `isAuthenticated=true` because the token exists in
  ///   memory, but it has been revoked server-side.
  /// - **Recovery probe after router reboot/firmware flash**: the WASM client
  ///   reports `isAuthenticated=true` carrying a token that the rebooted
  ///   router signed with a previous key, so it now 401s.
  ///
  /// `login()` is idempotent — calling it on a still-valid session simply
  /// mints a new token, so we do not gate on `isAuthenticated`. Gating here
  /// previously caused recovery probes after firmware reboot to repeatedly
  /// 401 because the stale-but-`true` flag short-circuited the re-login.
  Future<void> restoreSession() async {
    if (_usp == null) {
      logger.w('[USP][Auth]: restoreSession skipped: UspClient is null');
      return;
    }
    await _loginWithStoredPassword();
  }

  /// Shared login logic — reads stored password and calls [UspClient.login].
  /// Returns true if login succeeded, false otherwise. Never throws.
  Future<bool> _loginWithStoredPassword() async {
    final password = await _storage.read(key: pLocalPassword);
    if (password == null || password.isEmpty) {
      logger.w('[USP][Auth]: restoreSession skipped: no stored password');
      return false;
    }
    try {
      await _usp!.login(password);
      _lastTokenRefresh = DateTime.now();
      logger.d(
          '[USP][Auth]: restoreSession login done, isAuthenticated=${_usp.isAuthenticated}');
      return true;
    } catch (e) {
      logger.w('[USP][Auth]: restoreSession login failed: $e');
      return false;
    }
  }

  /// Attempts USP login independently (not as sync after JNAP).
  ///
  /// Used as fallback when JNAP is unavailable (e.g., firmware disabled JNAP).
  /// Throws [ServiceError] on failure to preserve error details for UI display.
  Future<void> tryUspLogin(String password) async {
    if (_usp == null) {
      logger.w('[USP][Auth]: tryUspLogin skipped: UspClient is null');
      throw const ServiceNotInitializedError(
          detail: 'USP client not available');
    }
    try {
      await _usp.login(password);
      if (!_usp.isAuthenticated) {
        throw const InvalidCredentialsError();
      }
      _lastTokenRefresh = DateTime.now();
      logger.d('[USP][Auth]: USP standalone login succeeded');
    } catch (e) {
      logger.w('[USP][Auth]: USP standalone login failed: $e');
      if (e is ServiceError) rethrow;
      // Map WASM errors to ServiceError
      final errorStr = e.toString();
      if (_isAccountLockedError(e)) {
        // Carry the error-code identifier (not a free-form string) so the login
        // view's errorCodeHelper resolves it to the "too many attempts /
        // account locked" message. See _mapToViewError passthrough.
        throw UnexpectedError(originalError: e, detail: errorAdminAccountLocked);
      } else if (_isAuthError(e)) {
        throw const InvalidCredentialsError();
      } else if (errorStr.contains('HTTP 5') ||
          errorStr.contains('network') ||
          errorStr.contains('fetch')) {
        throw NetworkError(detail: errorStr);
      }
      throw UnexpectedError(originalError: e, detail: errorStr);
    }
  }

  /// Reads the router serial number via USP after authentication.
  ///
  /// Used by recovery probe to verify router identity after re-login.
  Future<String> getSerialNumber() async {
    if (_usp == null) {
      throw StateError('UspClient is null');
    }
    final result = await _usp.get(['Device.DeviceInfo.SerialNumber']);
    final serial = result['Device.DeviceInfo.SerialNumber'] as String?;
    if (serial == null || serial.isEmpty) {
      throw StateError('Serial number not available');
    }
    return serial;
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
      logger.d('[USP][Auth]: Proactive token refresh succeeded');
    } catch (e) {
      if (_isAuthError(e)) {
        _lastTokenRefresh = null; // Allow immediate retry if logout is delayed
        logger.w('[USP][Auth]: Proactive refresh got 401 — forcing logout: $e');
        onForceLogout?.call();
      } else {
        logger.w(
            '[USP][Auth]: Proactive refresh failed (non-auth, will retry): $e');
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
