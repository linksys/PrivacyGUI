import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';

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
///
/// USP login failure never blocks JNAP operations — [ProtocolResolver] falls
/// back to JNAP when `isAuthenticated` is false.
class UspAuthCoordinator {
  final UspService? _usp;
  final FlutterSecureStorage _storage;

  UspAuthCoordinator(this._usp, this._storage) {
    _usp?.onReauthRequired = () => restoreSession();
  }

  /// Called after JNAP localLogin succeeds — auto-sync USP authentication.
  Future<void> syncAfterLocalLogin(String password) async {
    if (_usp == null) return;
    try {
      await _usp.login(password);
      logger.d('[USP][Auth]USP login synced successfully');
    } catch (e) {
      // USP login failure does not affect JNAP — ProtocolResolver
      // will fall back to JNAP when isAuthenticated=false
      logger.w('[USP][Auth]USP login failed after JNAP login: $e');
    }
  }

  /// Called during JNAP logout — sync logout USP.
  Future<void> syncAfterLogout() async {
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
      logger.w('[USP][Auth]restoreSession skipped: UspService is null');
      return;
    }
    if (_usp.isAuthenticated) {
      logger.d('[USP][Auth]restoreSession skipped: already authenticated');
      return;
    }
    final password = await _storage.read(key: pLocalPassword);
    if (password == null || password.isEmpty) {
      logger.w('[USP][Auth]restoreSession skipped: no stored password');
      return;
    }
    try {
      await _usp.login(password);
      logger.d(
          '[USP][Auth]restoreSession login done, isAuthenticated=${_usp.isAuthenticated}');
    } catch (e) {
      logger.w('[USP][Auth]restoreSession login failed: $e');
    }
  }

  /// Attempts USP login independently (not as sync after JNAP).
  ///
  /// Used as fallback when JNAP is unavailable (e.g., firmware disabled JNAP).
  /// Returns true if USP login succeeds and is authenticated.
  Future<bool> tryUspLogin(String password) async {
    if (_usp == null) {
      logger.w('[USP][Auth]tryUspLogin skipped: UspService is null');
      return false;
    }
    try {
      await _usp.login(password);
      final authenticated = _usp.isAuthenticated;
      if (authenticated) {
        logger.d('[USP][Auth]USP standalone login succeeded');
      }
      return authenticated;
    } catch (e) {
      logger.w('[USP][Auth]USP standalone login failed: $e');
      return false;
    }
  }

  /// Called periodically (e.g., every polling cycle) to keep USP token alive.
  Future<void> ensureAuth() async {
    if (_usp == null || !_usp.isAuthenticated) return;
    try {
      await _usp.refreshToken();
    } catch (e) {
      logger.w('[USP][Auth]USP token refresh failed, attempting restore: $e');
      await restoreSession();
    }
  }
}

final uspAuthCoordinatorProvider = Provider<UspAuthCoordinator>((ref) {
  return UspAuthCoordinator(
    ref.watch(uspServiceProvider),
    const FlutterSecureStorage(),
  );
});
