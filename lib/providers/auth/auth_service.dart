import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_result.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

/// Provider for AuthService singleton instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(const FlutterSecureStorage());
});

/// Stateless service encapsulating local authentication business logic.
///
/// This service handles:
/// - Credential persistence using FlutterSecureStorage
/// - Logout operations that clear all authentication data
class AuthService {
  final FlutterSecureStorage _secureStorage;

  AuthService(this._secureStorage);

  // ============================================================================
  // Credential Persistence
  // ============================================================================

  Future<AuthResult<String?>> getStoredLocalPassword() async {
    try {
      final localPassword = await _secureStorage.read(key: pLocalPassword);
      logger.d(
          '[AuthService]: Stored local password exists: ${localPassword != null}');
      return AuthSuccess(localPassword);
    } catch (e) {
      logger.e('[AuthService]: Failed to retrieve local password: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }

  Future<AuthResult<LoginType>> getStoredLoginType() async {
    try {
      final localPassword = await _secureStorage.read(key: pLocalPassword);

      final loginType =
          localPassword != null ? LoginType.local : LoginType.none;

      logger.d('[AuthService]: Stored login type: $loginType');
      return AuthSuccess(loginType);
    } catch (e) {
      logger.e('[AuthService]: Failed to get stored login type: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }

  Future<AuthResult<void>> saveLocalPassword(String password) async {
    try {
      await _secureStorage.write(key: pLocalPassword, value: password);
      logger.d('[AuthService]: Local password saved');
      return const AuthSuccess(null);
    } catch (e) {
      logger.e('[AuthService]: Failed to save local password: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }

  Future<AuthResult<void>> clearAllCredentials() async {
    try {
      logger.d('[AuthService]: Clearing all credentials');

      await _secureStorage.delete(key: pLocalPassword);

      logger.d('[AuthService]: All credentials cleared successfully');
      return const AuthSuccess(null);
    } catch (e) {
      logger.e('[AuthService]: Failed to clear credentials: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }
}
