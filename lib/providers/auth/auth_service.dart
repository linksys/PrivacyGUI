import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_result.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';
import 'package:privacy_gui/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Return value for login operations containing authentication details.
class LoginInfo {
  final LoginType loginType;
  final SessionToken? sessionToken;
  final String? username;
  final String? password;
  final String? localPassword;

  const LoginInfo({
    required this.loginType,
    this.sessionToken,
    this.username,
    this.password,
    this.localPassword,
  });
}

/// Return value for credential retrieval containing all stored authentication data.
class StoredCredentials {
  final SessionToken? sessionToken;
  final String? sessionTokenTs;
  final String? localPassword;
  final String? username;
  final String? password;
  final String? currentSN;
  final String? selectedNetworkId;
  final bool raMode;

  const StoredCredentials({
    this.sessionToken,
    this.sessionTokenTs,
    this.localPassword,
    this.username,
    this.password,
    this.currentSN,
    this.selectedNetworkId,
    required this.raMode,
  });
}

/// Provider for AuthService singleton instance.
///
/// The service is instantiated once and reused throughout the app lifecycle.
/// Dependencies are provided via Riverpod providers.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(routerRepositoryProvider),
    ref.watch(cloudRepositoryProvider),
    const FlutterSecureStorage(),
  );
});

/// Stateless service encapsulating all authentication business logic.
///
/// This service handles:
/// - Session token validation, expiration checking, and automatic refresh
/// - Authentication flows (cloud login, local login, RA login)
/// - Credential persistence using FlutterSecureStorage and SharedPreferences
/// - Logout operations that clear all authentication data
///
/// The service is stateless and accepts all dependencies via constructor injection.
/// All methods return [AuthResult] types for functional error handling.
///
/// Example:
/// ```dart
/// final authService = ref.read(authServiceProvider);
/// final result = await authService.validateSessionToken();
/// result.when(
///   success: (token) => // Handle valid token,
///   failure: (error) => // Handle error,
/// );
/// ```
class AuthService {
  final RouterRepository _routerRepository;
  final LinksysCloudRepository _cloudRepository;
  final FlutterSecureStorage _secureStorage;

  /// Creates an AuthService with required dependencies.
  ///
  /// All dependencies must be provided via constructor injection
  /// to enable testability and follow Article VI of the constitution.
  AuthService(
    this._routerRepository,
    this._cloudRepository,
    this._secureStorage,
  );

  /// Internal helper to get SharedPreferences instance.
  ///
  /// SharedPreferences requires async initialization via getInstance(),
  /// so it cannot be injected through constructor. This helper provides
  /// consistent access across all methods that need preferences.
  Future<SharedPreferences> _getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  // ============================================================================
  // Phase 3 (US1): Session Token Management
  // ============================================================================

  /// Validates the stored session token and handles automatic refresh if needed.
  ///
  /// This method checks if a session token exists in secure storage, validates
  /// its expiration status, and automatically refreshes it if expired (when a
  /// refresh token is available).
  ///
  /// Returns:
  /// - [AuthSuccess] with [SessionToken] if token is valid or successfully refreshed
  /// - [AuthSuccess] with null if no token exists or refresh failed
  /// - [AuthFailure] with appropriate error if validation or refresh failed
  ///
  /// Handles corrupted data by clearing it and returning null (clean slate recovery).
  Future<AuthResult<SessionToken?>> validateSessionToken() async {
    try {
      // Read token and timestamp from secure storage
      final ts = await _secureStorage.read(key: pSessionTokenTs);
      final json = await _secureStorage.read(key: pSessionToken);

      // No token found - return null (not an error)
      if (ts == null || json == null) {
        logger.d('[AuthService]: No session token found in storage');
        return const AuthSuccess(null);
      }

      // Parse token JSON with corruption handling
      final SessionToken session;
      try {
        session = SessionToken.fromJson(jsonDecode(json));
      } on FormatException catch (e) {
        // Corrupted JSON - clear and return null (clean slate recovery)
        logger.w('[AuthService]: Corrupted session token data, clearing: $e');
        await _secureStorage.delete(key: pSessionToken);
        await _secureStorage.delete(key: pSessionTokenTs);
        return const AuthSuccess(null);
      } catch (e) {
        // Other parsing errors - treat as corrupted data
        logger.w('[AuthService]: Failed to parse session token, clearing: $e');
        await _secureStorage.delete(key: pSessionToken);
        await _secureStorage.delete(key: pSessionTokenTs);
        return const AuthSuccess(null);
      }

      // Check token expiration
      final expireTs = int.parse(ts) + session.expiresIn * 1000;
      final isExpired = expireTs - DateTime.now().millisecondsSinceEpoch < 0;

      logger.d(
          '[AuthService]: Token session Ts: $ts, expire Ts: $expireTs. Expired: $isExpired');

      if (!isExpired) {
        // Token is still valid
        return AuthSuccess(session);
      }

      // Token is expired - attempt automatic refresh if refresh token available
      final refreshToken = session.refreshToken;
      if (refreshToken == null) {
        // No refresh token - clear expired token and return null
        logger
            .d('[AuthService]: Token expired with no refresh token, clearing');
        await _secureStorage.delete(key: pSessionToken);
        await _secureStorage.delete(key: pSessionTokenTs);
        return const AuthSuccess(null);
      }

      // Attempt automatic token refresh
      logger.d('[AuthService]: Token expired, attempting automatic refresh');
      return await refreshSessionToken(refreshToken);
    } on StorageError catch (e) {
      return AuthFailure(e);
    } catch (e) {
      // Unexpected errors wrap in StorageError
      logger.e('[AuthService]: Unexpected error validating token: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }

  /// Refreshes the session token using the provided refresh token.
  ///
  /// This method calls the cloud repository to exchange the refresh token
  /// for a new access token. If successful, the new token is stored.
  ///
  /// Returns:
  /// - [AuthSuccess] with new [SessionToken] if refresh succeeded
  /// - [AuthFailure] with appropriate error if refresh failed
  Future<AuthResult<SessionToken?>> refreshSessionToken(
      String refreshToken) async {
    try {
      // Call cloud repository to refresh token
      final newToken = await _cloudRepository.refreshToken(refreshToken);

      logger.d('[AuthService]: Session token refreshed successfully');

      // Store the new token
      await _secureStorage.write(
        key: pSessionToken,
        value: jsonEncode(newToken.toJson()),
      );
      await _secureStorage.write(
        key: pSessionTokenTs,
        value: '${DateTime.now().millisecondsSinceEpoch}',
      );

      return AuthSuccess(newToken);
    } catch (e) {
      logger.e('[AuthService]: Token refresh failed: $e');
      // Return null on failure (caller can handle as needed)
      return AuthFailure(TokenRefreshError(cause: e));
    }
  }

  // ============================================================================
  // Phase 4 (US2): Authentication Flows
  // ============================================================================

  /// Authenticates with cloud credentials and stores the session token.
  ///
  /// This method logs in to the Linksys cloud service using the provided
  /// username and password. On success, it stores the session token, username,
  /// and password in secure storage for future use.
  ///
  /// Parameters:
  /// - [username]: Cloud account email/username
  /// - [password]: Cloud account password
  /// - [sessionToken]: Optional pre-existing token (for token reuse scenarios)
  ///
  /// Returns:
  /// - [AuthSuccess] with [LoginInfo] if login succeeded and credentials stored
  /// - [AuthFailure] with appropriate error if login or storage failed
  Future<AuthResult<LoginInfo>> cloudLogin({
    required String username,
    required String password,
    SessionToken? sessionToken,
  }) async {
    try {
      // Use provided token or obtain new one via cloud login
      final newToken = sessionToken ??
          await _cloudRepository.login(username: username, password: password);

      // Store cloud credentials
      await _secureStorage.write(
        key: pSessionToken,
        value: jsonEncode(newToken.toJson()),
      );
      await _secureStorage.write(
        key: pSessionTokenTs,
        value: '${DateTime.now().millisecondsSinceEpoch}',
      );
      await _secureStorage.write(
        key: pUsername,
        value: username,
      );
      await _secureStorage.write(
        key: pUserPassword,
        value: password,
      );

      logger.d('[AuthService]: Cloud login successful');

      return AuthSuccess(LoginInfo(
        loginType: LoginType.remote,
        sessionToken: newToken,
        username: username,
        password: password,
      ));
    } on ErrorResponse catch (e) {
      logger.e('[AuthService]: Cloud login failed with ErrorResponse: $e');
      return AuthFailure(UnexpectedError(originalError: e, message: e.code));
    } catch (e) {
      logger.e('[AuthService]: Cloud login failed: $e');
      return AuthFailure(NetworkError(message: e.toString()));
    }
  }

  /// Authenticates with local admin password via JNAP.
  ///
  /// This method validates the admin password by calling the router's JNAP
  /// API. On success, it stores the password in secure storage.
  ///
  /// Parameters:
  /// - [password]: Router admin password
  /// - [pnp]: If true, uses PnP-specific JNAP action (default: false)
  ///
  /// Returns:
  /// - [AuthSuccess] with [LoginInfo] if password is valid and stored
  /// - [AuthFailure] with appropriate error if validation or storage failed
  Future<AuthResult<LoginInfo>> localLogin(
    String password, {
    bool pnp = false,
  }) async {
    try {
      final response = await _routerRepository.send(
        pnp ? JNAPAction.pnpCheckAdminPassword : JNAPAction.checkAdminPassword,
        extraHeaders: {
          kJNAPAuthorization:
              'Basic ${Utils.stringBase64Encode('admin:$password')}'
        },
        data: {
          'adminPassword': password,
        },
        cacheLevel: CacheLevel.noCache,
      );

      // Check JNAP result
      if (response.result != jnapResultOk) {
        logger.w(
            '[AuthService]: Local login failed with JNAP error: ${response.result}');
        return AuthFailure(
            UnexpectedError(originalError: response, message: response.result));
      }

      // Store local password
      await _secureStorage.write(key: pLocalPassword, value: password);

      logger.d('[AuthService]: Local login successful');

      return AuthSuccess(LoginInfo(
        loginType: LoginType.local,
        localPassword: password,
      ));
    } on JNAPError catch (e) {
      // Rethrow JNAPError to preserve error data (e.g., attemptsRemaining, delayTimeRemaining)
      // This is needed for the View layer to display countdown and attempts correctly
      logger.e('[AuthService]: Local login failed: $e');
      rethrow;
    } catch (e) {
      logger.e('[AuthService]: Local login failed: $e');
      return AuthFailure(NetworkError(message: e.toString()));
    }
  }

  /// Authenticates with Remote Assistance (RA) session credentials.
  ///
  /// This method sets up authentication for Remote Assistance mode by storing
  /// the RA session token and network identifiers.
  ///
  /// Parameters:
  /// - [sessionToken]: RA session access token
  /// - [networkId]: Network identifier for the RA session
  /// - [serialNumber]: Device serial number
  ///
  /// Returns:
  /// - [AuthSuccess] with [LoginInfo] if RA credentials stored successfully
  /// - [AuthFailure] with [StorageError] if storage operations failed
  Future<AuthResult<LoginInfo>> raLogin(
    String sessionToken,
    String networkId,
    String serialNumber,
  ) async {
    try {
      // Store network information in SharedPreferences
      final prefs = await _getSharedPreferences();
      await prefs.setString(pCurrentSN, serialNumber);
      await prefs.setString(pSelectedNetworkId, networkId);
      await prefs.setBool(pRAMode, true);

      // Create SessionToken object for RA session
      final token = SessionToken(
        accessToken: sessionToken,
        tokenType: 'Bearer',
        expiresIn: DateTime.now().millisecondsSinceEpoch,
      );

      // Store RA session token
      await _secureStorage.write(
        key: pSessionToken,
        value: jsonEncode(token.toJson()),
      );
      await _secureStorage.write(
        key: pSessionTokenTs,
        value: '${DateTime.now().millisecondsSinceEpoch}',
      );

      logger.d('[AuthService]: RA login successful');

      return AuthSuccess(LoginInfo(
        loginType: LoginType.remote,
        sessionToken: token,
      ));
    } catch (e) {
      logger.e('[AuthService]: RA login failed: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }

  /// Retrieves the admin password hint from the router.
  ///
  /// This method calls the router's JNAP API to fetch the password hint
  /// that was configured by the user for the admin account.
  ///
  /// Returns:
  /// - [AuthSuccess] with password hint string if retrieval succeeded
  /// - [AuthFailure] with appropriate error if retrieval failed
  Future<AuthResult<String>> getPasswordHint() async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getAdminPasswordHint,
      );

      final hint = result.output['passwordHint'] as String? ?? '';
      logger.d('[AuthService]: Password hint retrieved: $hint');

      return AuthSuccess(hint);
    } catch (e) {
      logger.e('[AuthService]: Failed to get password hint: $e');
      return AuthFailure(
          UnexpectedError(originalError: e, message: 'GetPasswordHintFailed'));
    }
  }

  /// Retrieves the admin password authentication status from the router.
  ///
  /// This method retrieves the current authentication status for password
  /// lockout tracking (delay time, remaining attempts).
  ///
  /// Returns:
  /// - [AuthSuccess] with status map if retrieval succeeded
  /// - [AuthFailure] with appropriate error if retrieval failed
  Future<AuthResult<Map<String, dynamic>?>> getAdminPasswordAuthStatus() async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getAdminPasswordAuthStatus,
      );

      logger.d('[AuthService]: Admin password auth status retrieved');
      return AuthSuccess(result.output);
    } catch (e) {
      logger.e('[AuthService]: Failed to get admin password auth status: $e');
      return AuthFailure(
          UnexpectedError(originalError: e, message: 'GetAuthStatusFailed'));
    }
  }

  // ============================================================================
  // Phase 5 (US3): Credential Persistence
  // ============================================================================

  /// Updates cloud credentials in secure storage.
  ///
  /// This method stores cloud authentication credentials (session token,
  /// username, password) in FlutterSecureStorage for persistence across
  /// app sessions.
  ///
  /// Parameters:
  /// - [sessionToken]: Optional session token to store
  /// - [username]: Optional username to store
  /// - [password]: Optional password to store
  ///
  /// Returns:
  /// - [AuthSuccess] with void if credentials stored successfully
  /// - [AuthFailure] with [StorageError] if storage operations failed
  Future<AuthResult<void>> updateCloudCredentials({
    SessionToken? sessionToken,
    String? username,
    String? password,
  }) async {
    try {
      logger.d(
          '[AuthService]: Updating cloud credentials: token=${sessionToken != null}, username=${username != null}, password=${password != null}');

      // Store session token
      if (sessionToken != null) {
        await _secureStorage.write(
          key: pSessionToken,
          value: jsonEncode(sessionToken.toJson()),
        );
        await _secureStorage.write(
          key: pSessionTokenTs,
          value: '${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Store username
      if (username != null) {
        await _secureStorage.write(
          key: pUsername,
          value: username,
        );
      }

      // Store password
      if (password != null) {
        await _secureStorage.write(
          key: pUserPassword,
          value: password,
        );
      }

      logger.d('[AuthService]: Cloud credentials updated successfully');
      return const AuthSuccess(null);
    } catch (e) {
      logger.e('[AuthService]: Failed to update cloud credentials: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }

  /// Retrieves all stored credentials from secure storage.
  ///
  /// This method reads all authentication credentials from both
  /// FlutterSecureStorage and SharedPreferences, returning them in
  /// a structured [StoredCredentials] object.
  ///
  /// Returns:
  /// - [AuthSuccess] with [StoredCredentials] containing all stored credentials
  /// - [AuthFailure] with [StorageError] if retrieval failed
  Future<AuthResult<StoredCredentials>> getStoredCredentials() async {
    try {
      // Read from secure storage
      final sessionTokenJson = await _secureStorage.read(key: pSessionToken);
      final sessionTokenTs = await _secureStorage.read(key: pSessionTokenTs);
      final localPassword = await _secureStorage.read(key: pLocalPassword);
      final username = await _secureStorage.read(key: pUsername);
      final password = await _secureStorage.read(key: pUserPassword);

      // Parse session token if available
      SessionToken? sessionToken;
      if (sessionTokenJson != null && sessionTokenTs != null) {
        try {
          sessionToken = SessionToken.fromJson(jsonDecode(sessionTokenJson));
        } catch (e) {
          logger.w('[AuthService]: Failed to parse stored session token: $e');
          // Continue without session token - don't fail the entire operation
        }
      }

      // Read from SharedPreferences
      final prefs = await _getSharedPreferences();
      final currentSN = prefs.getString(pCurrentSN);
      final selectedNetworkId = prefs.getString(pSelectedNetworkId);
      final raMode = prefs.getBool(pRAMode) ?? false;

      logger.d('[AuthService]: Retrieved credentials from storage');

      return AuthSuccess(StoredCredentials(
        sessionToken: sessionToken,
        sessionTokenTs: sessionTokenTs,
        localPassword: localPassword,
        username: username,
        password: password,
        currentSN: currentSN,
        selectedNetworkId: selectedNetworkId,
        raMode: raMode,
      ));
    } catch (e) {
      logger.e('[AuthService]: Failed to retrieve credentials: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }

  /// Clears all authentication credentials from storage.
  ///
  /// This method removes all stored credentials from both FlutterSecureStorage
  /// and SharedPreferences. This is typically called during logout operations.
  ///
  /// Note: This method only handles credential cleanup. Provider state resets
  /// and RA session cleanup remain the responsibility of the caller.
  ///
  /// Returns:
  /// - [AuthSuccess] with void if all credentials cleared successfully
  /// - [AuthFailure] with [StorageError] if clearing failed
  Future<AuthResult<void>> clearAllCredentials() async {
    try {
      logger.d('[AuthService]: Clearing all credentials');

      // Clear from SharedPreferences
      final prefs = await _getSharedPreferences();
      await prefs.remove(pSelectedNetworkId);
      await prefs.remove(pCurrentSN);
      await prefs.remove(pDeviceToken);
      await prefs.remove(pGRASessionId);
      await prefs.remove(pRAMode);

      // Clear from FlutterSecureStorage
      await _secureStorage.delete(key: pSessionToken);
      await _secureStorage.delete(key: pSessionTokenTs);
      await _secureStorage.delete(key: pLocalPassword);
      await _secureStorage.delete(key: pUsername);
      await _secureStorage.delete(key: pUserPassword);
      await _secureStorage.delete(key: pLinksysToken);
      await _secureStorage.delete(key: pLinksysTokenTs);

      logger.d('[AuthService]: All credentials cleared successfully');
      return const AuthSuccess(null);
    } catch (e) {
      logger.e('[AuthService]: Failed to clear credentials: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }

  /// Helper method to determine login type from stored credentials.
  ///
  /// This method checks which credentials are available in storage and
  /// returns the corresponding login type.
  ///
  /// Returns:
  /// - [AuthSuccess] with [LoginType.remote] if session token exists
  /// - [AuthSuccess] with [LoginType.local] if local password exists
  /// - [AuthSuccess] with [LoginType.none] if no credentials exist
  /// - [AuthFailure] with [StorageError] if retrieval failed
  Future<AuthResult<LoginType>> getStoredLoginType() async {
    try {
      final sessionTokenJson = await _secureStorage.read(key: pSessionToken);
      final localPassword = await _secureStorage.read(key: pLocalPassword);

      LoginType loginType;
      if (sessionTokenJson != null) {
        loginType = LoginType.remote;
      } else if (localPassword != null) {
        loginType = LoginType.local;
      } else {
        loginType = LoginType.none;
      }

      logger.d('[AuthService]: Stored login type: $loginType');
      return AuthSuccess(loginType);
    } catch (e) {
      logger.e('[AuthService]: Failed to get stored login type: $e');
      return AuthFailure(StorageError(originalError: e));
    }
  }
}
