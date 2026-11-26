import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart'
    show sessionAuthGateProvider;
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/session_auth_gate.dart';
import 'package:privacy_gui/core/usp/services/session_restore_outcome.dart';
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

  /// Where a refused credential is reported (#1666). Null only in tests that
  /// do not need one.
  final SessionAuthGate? _gate;

  DateTime? _lastTokenRefresh;
  Completer<void>? _refreshInProgress;
  Completer<SessionRestoreOutcome>? _restoreInProgress;
  DateTime? _lastRestoreAttempt;
  bool? _lastRestoreResult;

  /// Cooldown period after a failed restore attempt to prevent rapid retries.
  /// Short (1s) since refreshToken doesn't risk account lockout like login does.
  static const Duration _restoreCooldown = Duration(seconds: 1);

  /// Proactive refresh threshold. Must be less than JWT TTL (15 min).
  /// At 12 min, the worst-case margin is ~2:30 (heartbeat at 12:29 + refresh).
  static const Duration _refreshThreshold = Duration(minutes: 12);

  // Matches invalid credentials errors:
  // - WASM: "Transport error: HTTP error: HTTP 401"
  // - WASM: "HTTP 401 Unauthorized"
  // - WASM/Rust: "Login failed: Authentication error: Invalid credentials"
  // - Bridge CGI: "Invalid username or password", "Invalid password"
  // - WASM/Rust, from `refreshToken`: "Token refresh failed: Authentication
  //   error: Authentication token has expired (code: 2)" — the router will
  //   not refresh this session (#1666 AC4). Measured 2026-11-26 (M60, FW
  //   2.0.4.26112201, usp-client 0.16.0) for a token that genuinely expired
  //   312 s and more before, and word for word the same for a never-issued or
  //   tampered one; 94 s after expiry a refresh still succeeded. It carries no
  //   `HTTP 401`, so before this a heartbeat that could never refresh again
  //   read it as a network error and retried on every beat.
  static final _invalidCredentialsPattern = RegExp(
    r'HTTP (?:error: HTTP )?401|Invalid (username or password|password|credentials)'
    r'|Authentication token has expired',
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

  UspAuthCoordinator(this._usp, this._tokenStorage, {SessionAuthGate? gate})
      : _gate = gate {
    // Here, beside the other two, because this is the first place in Riverpod
    // that holds the façade: `UspClient` is built in `di.dart` and by Remote
    // Assistance's `activate()`, and the boot restore reads this provider
    // before anything else needs the gate.
    if (gate != null) _usp?.attachAuthGate(gate);
    _usp?.onReauthRequired = restoreSession;
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
  /// 3. Otherwise → [SessionRestoreOutcome.rejected] when the router refused
  ///    the token or there was none, [SessionRestoreOutcome.unreachable] when
  ///    it could not be asked
  ///
  /// Password is never stored — this is intentional for security.
  /// If the token expires, the user must enter their password again.
  ///
  /// **Reports nothing (#1666).** Whoever asked decides what the outcome
  /// means: `UspClient.reauth` ends the session on a rejection; a recovery
  /// after an outage, which expects failures, ignores it. Before, this method
  /// forced the logout itself unless told it was "recovering", and a caller that
  /// joined an in-flight restore inherited whichever flag the first one passed.
  ///
  /// Never throws. Multiple concurrent calls are coalesced — only the first
  /// triggers an actual restore; the others get its outcome.
  Future<SessionRestoreOutcome> restoreSession() async {
    if (_usp == null) {
      logger.w('[USP][Auth]: restoreSession skipped: UspClient is null');
      return SessionRestoreOutcome.unreachable;
    }

    // Coalesce concurrent calls — return in-flight result if one exists
    final inFlight = _restoreInProgress;
    if (inFlight != null) {
      logger.d('[USP][Auth]: restoreSession already in progress, awaiting...');
      return inFlight.future;
    }

    final restore = Completer<SessionRestoreOutcome>();
    _restoreInProgress = restore;
    SessionRestoreOutcome outcome;
    try {
      outcome = await _restoreSessionImpl();
    } catch (e) {
      logger.w('[USP][Auth]: restoreSession failed unexpectedly: $e');
      outcome = SessionRestoreOutcome.unreachable;
    }
    if (identical(_restoreInProgress, restore)) _restoreInProgress = null;
    restore.complete(outcome);
    return outcome;
  }

  /// Forget everything this object knows about the *current* session, keeping
  /// the object itself.
  ///
  /// Acceptance 9 of #1323. All five fields below are per-session bookkeeping,
  /// and this coordinator outlives a session: it is a non-autoDispose singleton
  /// whose only `ref.watch` is on `uspClientProvider`, and #1322 made that
  /// provider's value stable across a re-`activate()` (the façade is re-pointed,
  /// not replaced), so nothing rebuilds it. A second Remote Assistance session
  /// therefore started with the first one's history:
  ///
  ///  * `_lastRestoreResult == false` plus `_lastRestoreAttempt` inside the
  ///    1-second cooldown makes the next `restoreSession()` return the *previous*
  ///    session's failure without trying.
  ///  * `_lastTokenRefresh` from the old token defers the first proactive refresh
  ///    by up to 12 minutes on a token that is not the same token.
  ///  * a non-null `_restoreInProgress` or `_refreshInProgress` left by a call
  ///    that was cut off mid-flight coalesces every future caller onto a
  ///    `Completer` that will never complete.
  ///
  /// **Who calls this is the mode's decision, not this class's.** See
  /// `CredentialStrategy.onCredentialRebound`: locally a re-login is the same
  /// authority as before and clearing the timestamps would discard a valid
  /// refresh window, so only `RemoteCredentialStrategy` reaches this.
  void resetSessionState() {
    logger.d('[USP][Auth]: resetSessionState — dropping per-session state');
    _lastTokenRefresh = null;
    _refreshInProgress = null;
    _restoreInProgress = null;
    _lastRestoreAttempt = null;
    _lastRestoreResult = null;
  }

  /// Implementation of session restore with token-only strategy.
  Future<SessionRestoreOutcome> _restoreSessionImpl() async {
    // Step 1: If WASM client already has a token, try refreshing it
    if (_usp!.isAuthenticated) {
      try {
        await _usp.refreshToken();
        _lastTokenRefresh = DateTime.now();
        _persistToken();
        logger.d('[USP][Auth]: restoreSession via in-memory token succeeded');
        return SessionRestoreOutcome.restored;
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
      logger.d('[USP][Auth]: restoreSession: no stored token');
      return SessionRestoreOutcome.rejected;
    }

    // Check cooldown to prevent rapid retries
    final lastAttempt = _lastRestoreAttempt;
    if (lastAttempt != null &&
        _lastRestoreResult == false &&
        DateTime.now().difference(lastAttempt) < _restoreCooldown) {
      logger.d('[USP][Auth]: restoreSession skipped: cooldown after failure');
      return SessionRestoreOutcome.unreachable;
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
      return SessionRestoreOutcome.restored;
    } catch (e) {
      _lastRestoreResult = false;
      if (_isAuthError(e)) {
        logger.d('[USP][Auth]: stored token expired/invalid, clearing');
        _clearStoredTokenIf(storedToken);
        return SessionRestoreOutcome.rejected;
      }
      logger.w('[USP][Auth]: stored token refresh failed: $e');
      // Network error — says nothing about the token
      return SessionRestoreOutcome.unreachable;
    }
  }

  /// Clears the stored token only if it is still [tried] (#1666).
  ///
  /// A refresh can be slow, and a login can land while it runs: the token in
  /// storage is then the new session's, and the old attempt's failure must not
  /// take it with it.
  void _clearStoredTokenIf(String? tried) {
    if (tried == null || _tokenStorage.load() != tried) return;
    _tokenStorage.clear();
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
  /// to avoid unnecessary network calls. When the router will not refresh the
  /// session — a 401, or `refreshToken`'s "Authentication token has expired",
  /// which is what a tab that slept past the token's lifetime wakes to (#1666)
  /// — ends the session through the gate instead of attempting
  /// [restoreSession], with the ticket taken when this refresh started, because:
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

    final ticket = _gate?.ticket;
    final tried = _usp.sessionToken;
    _refreshInProgress = Completer<void>();
    try {
      await _usp.refreshToken();
      _lastTokenRefresh = DateTime.now();
      _persistToken();
      logger.d('[USP][Auth]: Proactive token refresh succeeded');
    } catch (e) {
      if (_isAuthError(e)) {
        _lastTokenRefresh = null;
        _clearStoredTokenIf(tried);
        logger.w('[USP][Auth]: Proactive refresh refused — ending the '
            'session: $e');
        if (ticket != null) _gate?.end(ticket);
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
    gate: ref.read(sessionAuthGateProvider),
  );
});
