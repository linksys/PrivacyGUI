import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

/// Riverpod provider for RouterPasswordService
final routerPasswordServiceProvider = Provider<RouterPasswordService>((ref) {
  return RouterPasswordService(
    ref.watch(routerRepositoryProvider),
    const FlutterSecureStorage(),
  );
});

/// Stateless service for router password operations
///
/// Encapsulates JNAP communication and password persistence logic,
/// separating business logic from state management (RouterPasswordNotifier).
class RouterPasswordService {
  /// Constructor injection of dependencies
  RouterPasswordService(
    this._routerRepository,
    this._secureStorage,
  );

  final RouterRepository _routerRepository;
  final FlutterSecureStorage _secureStorage;

  /// Fetches router password configuration from JNAP and secure storage
  ///
  /// Returns: Map with keys 'isDefault', 'isSetByUser', 'hint', 'storedPassword'
  /// Throws: [ServiceError] on failure (NetworkError, StorageError, UnexpectedError)
  Future<Map<String, dynamic>> fetchPasswordConfiguration() async {
    try {
      // Fetch password configuration from JNAP
      final results = await _routerRepository.fetchIsConfigured();

      // Extract isAdminPasswordDefault
      final bool isAdminDefault = JNAPTransactionSuccessWrap.getResult(
                  JNAPAction.isAdminPasswordDefault, Map.fromEntries(results))
              ?.output['isAdminPasswordDefault'] ??
          false;

      // Extract isAdminPasswordSetByUser
      final bool isSetByUser = JNAPTransactionSuccessWrap.getResult(
                  JNAPAction.isAdminPasswordSetByUser, Map.fromEntries(results))
              ?.output['isAdminPasswordSetByUser'] ??
          true;

      // Conditionally fetch password hint if set by user
      String passwordHint = '';
      if (isSetByUser) {
        passwordHint = await _routerRepository
            .send(JNAPAction.getAdminPasswordHint)
            .then((result) => result.output['passwordHint'] ?? '')
            .onError((error, stackTrace) => '');
      }

      // Read stored password from secure storage
      final password = await _secureStorage.read(key: pLocalPassword);

      return {
        'isDefault': isAdminDefault,
        'isSetByUser': isSetByUser,
        'hint': passwordHint,
        'storedPassword': password ?? '',
      };
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    } catch (e) {
      throw StorageError(originalError: e);
    }
  }

  /// Sets admin password using setup reset code
  ///
  /// Parameters:
  ///   - password: New admin password
  ///   - hint: Password hint
  ///   - code: Setup reset code
  ///
  /// Throws: [ServiceError] on failure (InvalidResetCodeError, NetworkError, etc.)
  Future<void> setPasswordWithResetCode(
    String password,
    String hint,
    String code,
  ) async {
    try {
      await _routerRepository.send(
        JNAPAction.setupSetAdminPassword,
        data: {
          'adminPassword': password,
          'passwordHint': hint,
          'resetCode': code,
        },
        type: CommandType.local,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Sets admin password with current credentials
  ///
  /// Parameters:
  ///   - password: New admin password
  ///   - hint: Password hint (optional)
  ///
  /// Throws: [ServiceError] on failure (InvalidAdminPasswordError, NetworkError, etc.)
  Future<void> setPasswordWithCredentials(
    String password, [
    String? hint,
  ]) async {
    try {
      await _routerRepository.send(
        JNAPAction.coreSetAdminPassword,
        data: {
          'adminPassword': password,
          'passwordHint': hint ?? '',
        },
        type: CommandType.local,
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Verifies router recovery code
  ///
  /// Parameters:
  ///   - code: Recovery code to verify
  ///
  /// Returns: Map with keys 'isValid', 'attemptsRemaining'
  /// Throws: [ServiceError] on failure (UnexpectedError for non-recoverable errors)
  Future<Map<String, dynamic>> verifyRecoveryCode(String code) async {
    try {
      await _routerRepository.send(
        JNAPAction.verifyRouterResetCode,
        data: {
          'resetCode': code,
        },
      );
      return {
        'isValid': true,
        'attemptsRemaining': null,
      };
    } on JNAPError catch (error) {
      if (error.result == 'ErrorInvalidResetCode') {
        final errorOutput = jsonDecode(error.error!) as Map<String, dynamic>;
        final remaining = errorOutput['attemptsRemaining'] as int;
        return {
          'isValid': false,
          'attemptsRemaining': remaining,
        };
      } else if (error.result == 'ErrorConsecutiveInvalidResetCodeEntered') {
        return {
          'isValid': false,
          'attemptsRemaining': 0,
        };
      }
      throw mapJnapErrorToServiceError(error);
    }
  }

  /// Persists password to secure storage
  ///
  /// Parameters:
  ///   - password: Password to store
  ///
  /// Throws: [StorageError] on FlutterSecureStorage write failure
  Future<void> persistPassword(String password) async {
    try {
      await _secureStorage.write(key: pLocalPassword, value: password);
    } catch (e) {
      throw StorageError(originalError: e);
    }
  }

}
