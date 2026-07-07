import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

import 'usp_token_storage.dart';

/// Coordinates USP authentication alongside JNAP authentication.
///
/// USP auth is an **additional local auth channel** — it never replaces JNAP auth.
/// This coordinator syncs login/logout between the two protocols and handles
/// session restoration on page reload (Web) where WASM state is lost.
///
/// Key behaviors:
/// - [syncAfterLocalLogin]: Auto-login USP after successful JNAP local login
/// - [syncAfterLogout]: Logout USP when JNAP logs out
/// - [restoreSession]: Re-authenticate USP using stored token on page reload
/// - [ensureAuth]: Proactive token refresh triggered by SSE heartbeat
///
/// Token persistence uses sessionStorage (cleared on browser close) for security.
/// Password is never stored — only used for initial login.
///
/// USP login failure never blocks JNAP operations — [ProtocolResolver] falls
/// back to JNAP when `isAuthenticated` is false.
class UspAuthCoordinator {
  final UspClient? _usp;
  final UspTokenStorage _tokenStorage;

  DateTime? _lastTokenRefresh;
  Completer<void>? _refreshInProgress;
  Completer<bool>? _restoreInProgress;
  DateTime? _lastRestoreAttempt;
  bool? _lastRestoreResult;

  /// Cooldown period after a failed restore attempt to prevent rapid retries.
  /// Short (1s) since refreshToken doesn't risk account lockout like login does.
  static const Duration _restoreCooldown = Duration(seconds: 1);

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

  UspAuthCoordinator(this._usp, this._tokenStorage) {
    // 401 retry is not recovery — force logout on failure
    _usp?.onReauthRequired = () => restoreSession(isRecovering: false);
    _usp?.onRefreshTokenSuccess = () {
      _lastTokenRefresh = DateTime.now();
      _persistToken();
    };
  }

  /// Persists the current session token to storage for page reload recovery.
  void _persistToken() {
    final token = _usp?.sessionToken;
    if (token != null && token.isNotEmpty) {
      _tokenStorage.save(token);
    }
  }

  /// Called after JNAP localLogin succeeds — auto-sync USP authentication.
  Future<void> syncAfterLocalLogin(String password) async {
    if (_usp == null) return;
    try {
      await _usp.login(password);
      _lastTokenRefresh = DateTime.now();
      _persistToken();
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
    _tokenStorage.clear();
    if (_usp == null || !_usp.isAuthenticated) return;
    try {
      await _usp.logout();
      logger.d('[USP][Auth]: USP logout synced successfully');
    } catch (e) {
      logger.w('[USP][Auth]: USP logout failed: $e');
    }
  }

  /// Re-authenticates USP using stored token from sessionStorage.
  ///
  /// Strategy (token-only):
  /// 1. If WASM client has a token in memory → try `refreshToken()` first
  /// 2. If no in-memory token → try restoring from sessionStorage via
  ///    `refreshToken(storedToken)` which validates and restores the session
  /// 3. If no stored token or refresh failed → trigger force logout
  ///
  /// Password is never stored — this is intentional for security.
  /// If the token expires, the user must enter their password again.
  ///
  /// Set [isRecovering] to true when the app is waiting for the router to
  /// recover (e.g., after reboot). In this case, failure is expected and
  /// force logout is suppressed — the recovery probe will retry later.
  ///
  /// Multiple concurrent calls are coalesced — only the first triggers an
  /// actual restore; subsequent callers await the same result.
  Future<void> restoreSession({bool isRecovering = false}) async {
    if (_usp == null) {
      logger.w('[USP][Auth]: restoreSession skipped: UspClient is null');
      return;
    }

    // Coalesce concurrent calls — return in-flight result if one exists
    if (_restoreInProgress != null) {
      logger.d('[USP][Auth]: restoreSession already in progress, awaiting...');
      await _restoreInProgress!.future;
      return;
    }

    _restoreInProgress = Completer<bool>();
    try {
      final result = await _restoreSessionImpl(isRecovering: isRecovering);
      _restoreInProgress!.complete(result);
    } catch (e) {
      _restoreInProgress!.completeError(e);
    } finally {
      _restoreInProgress = null;
    }
  }

  /// Implementation of session restore with token-only strategy.
  Future<bool> _restoreSessionImpl({required bool isRecovering}) async {
    // Step 1: If WASM client already has a token, try refreshing it
    if (_usp!.isAuthenticated) {
      try {
        await _usp.refreshToken();
        _lastTokenRefresh = DateTime.now();
        _persistToken();
        logger.d('[USP][Auth]: restoreSession via in-memory token succeeded');
        return true;
      } catch (e) {
        if (_isAuthError(e)) {
          logger.d('[USP][Auth]: in-memory token refresh got 401, '
              'trying stored token');
        } else {
          logger.w('[USP][Auth]: in-memory token refresh failed: $e');
        }
        // Fall through to try stored token
      }
    }

    // Step 2: Try restoring from sessionStorage
    final storedToken = _tokenStorage.load();
    if (storedToken == null || storedToken.isEmpty) {
      logger.d('[USP][Auth]: restoreSession skipped: no stored token');
      _triggerForceLogoutIfNotRecovering(isRecovering);
      return false;
    }

    // Check cooldown to prevent rapid retries
    final lastAttempt = _lastRestoreAttempt;
    if (lastAttempt != null &&
        _lastRestoreResult == false &&
        DateTime.now().difference(lastAttempt) < _restoreCooldown) {
      logger.d('[USP][Auth]: restoreSession skipped: cooldown after failure');
      return false;
    }

    _lastRestoreAttempt = DateTime.now();

    try {
      // refreshToken(token) validates the external token with the server
      // and restores the session if valid
      await _usp.refreshToken(token: storedToken);
      _lastTokenRefresh = DateTime.now();
      _persistToken();
      _lastRestoreResult = true;
      logger.d('[USP][Auth]: restoreSession via stored token succeeded');
      return true;
    } catch (e) {
      _lastRestoreResult = false;
      if (_isAuthError(e)) {
        logger.d('[USP][Auth]: stored token expired/invalid, clearing');
        _tokenStorage.clear();
        _triggerForceLogoutIfNotRecovering(isRecovering);
      } else {
        logger.w('[USP][Auth]: stored token refresh failed: $e');
        // Network error — don't force logout, might recover
      }
      return false;
    }
  }

  /// Triggers force logout unless in recovery mode.
  void _triggerForceLogoutIfNotRecovering(bool isRecovering) {
    if (isRecovering) {
      logger.d('[USP][Auth]: Suppressing force logout — in recovery mode');
      return;
    }
    logger.w('[USP][Auth]: Triggering force logout');
    onForceLogout?.call();
  }

  /// Re-authenticates with a new password after password change.
  ///
  /// Call this after successfully changing the admin password to:
  /// 1. Logout the old session (old token becomes invalid)
  /// 2. Login with the new password
  /// 3. Persist the new token
  ///
  /// Throws [ServiceError] on failure — caller should handle gracefully
  /// (e.g., redirect to login page).
  Future<void> reloginWithNewPassword(String newPassword) async {
    if (_usp == null) {
      logger
          .w('[USP][Auth]: reloginWithNewPassword skipped: UspClient is null');
      throw const ServiceNotInitializedError(
          detail: 'USP client not available');
    }

    logger.d('[USP][Auth]: Re-authenticating with new password');

    // Clear old token first
    _tokenStorage.clear();
    _lastTokenRefresh = null;

    try {
      // Logout old session (best-effort, ignore errors)
      try {
        await _usp.logout();
      } catch (e) {
        logger.d('[USP][Auth]: Old session logout failed (expected): $e');
      }

      // Login with new password
      await _usp.login(newPassword);
      if (!_usp.isAuthenticated) {
        throw const InvalidCredentialsError();
      }

      _lastTokenRefresh = DateTime.now();
      _persistToken();
      logger.d('[USP][Auth]: Re-authentication with new password succeeded');
    } catch (e) {
      logger.w('[USP][Auth]: Re-authentication failed: $e');
      if (e is ServiceError) rethrow;
      throw UnexpectedError(originalError: e, detail: e.toString());
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
      _persistToken();
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
        throw UnexpectedError(
            originalError: e, detail: errorAdminAccountLocked);
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
      _persistToken();
      logger.d('[USP][Auth]: Proactive token refresh succeeded');
    } catch (e) {
      if (_isAuthError(e)) {
        _lastTokenRefresh = null;
        _tokenStorage.clear();
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
    UspTokenStorage(),
  );
});
