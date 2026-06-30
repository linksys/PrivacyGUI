import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Provider for AuthService singleton instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Stateless service encapsulating local authentication business logic.
///
/// Note: Password is no longer stored — only session tokens are persisted
/// via [UspTokenStorage] in sessionStorage for page reload recovery.
class AuthService {
  AuthService();

  // ============================================================================
  // Logout
  // ============================================================================

  /// Clears all authentication-related data.
  ///
  /// Note: Token storage is cleared by [UspAuthCoordinator.syncAfterLogout].
  Future<void> clearAllCredentials() async {
    logger.d('[AuthService]: clearAllCredentials called (no-op, '
        'token storage cleared by UspAuthCoordinator)');
  }
}
