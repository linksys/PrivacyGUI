import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:usp_ui_flutter/core/utils/logger.dart';

/// Result of an authentication operation
class AuthResult {
  final bool success;
  final String? token;
  final DateTime? expiry;
  final String? errorMessage;

  const AuthResult({
    required this.success,
    this.token,
    this.expiry,
    this.errorMessage,
  });

  @override
  String toString() =>
      'AuthResult(success: $success, token: ${token != null ? '[REDACTED]' : null}, expiry: $expiry, error: $errorMessage)';
}

/// JWT authentication manager for USP
///
/// Handles authentication with the router's auth endpoint,
/// token storage, refresh, and logout.
class UspAuth {
  final String _authEndpoint;
  final FlutterSecureStorage _storage;
  final http.Client _httpClient;

  String? _token;
  DateTime? _expiry;

  static const _tokenKey = 'usp_auth_token';
  static const _expiryKey = 'usp_auth_expiry';

  UspAuth({
    required String authEndpoint,
    required FlutterSecureStorage storage,
    http.Client? httpClient,
  })  : _authEndpoint = authEndpoint,
        _storage = storage,
        _httpClient = httpClient ?? http.Client();

  /// Initialize from stored credentials
  Future<void> initialize() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      final expiryStr = await _storage.read(key: _expiryKey);
      if (expiryStr != null) {
        _expiry = DateTime.parse(expiryStr);
      }
      logger.d(
          '[UspAuth]: Initialized - token exists: ${_token != null}, expiry: $_expiry');
    } catch (e, stackTrace) {
      logger.e('[UspAuth]: Failed to initialize from storage', error: e, stackTrace: stackTrace);
      _token = null;
      _expiry = null;
    }
  }

  /// Login with password
  Future<AuthResult> login(String password) async {
    try {
      logger.d('[UspAuth]: Attempting login to $_authEndpoint');

      final response = await _httpClient.post(
        Uri.parse(_authEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );

      logger.d('[UspAuth]: Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Check for success field in response (USP auth API format)
        final success = data['success'] as bool? ?? false;
        if (!success) {
          logger.w('[UspAuth]: Authentication failed - success=false');
          return const AuthResult(
            success: false,
            errorMessage: 'Invalid password',
          );
        }

        _token = data['token'] as String?;

        if (_token == null) {
          logger.e('[UspAuth]: Invalid response format: missing token');
          return const AuthResult(
            success: false,
            errorMessage: 'Invalid response format from server',
          );
        }

        // Extract expiry from JWT token or use default (15 minutes)
        _expiry = _extractExpiryFromJwt(_token!) ??
            DateTime.now().add(const Duration(minutes: 15));

        await _storage.write(key: _tokenKey, value: _token);
        await _storage.write(key: _expiryKey, value: _expiry!.toIso8601String());

        logger.d('[UspAuth]: Login successful, token expires at $_expiry');

        return AuthResult(
          success: true,
          token: _token,
          expiry: _expiry,
        );
      } else if (response.statusCode == 401) {
        logger.w('[UspAuth]: Authentication failed - invalid password');
        return const AuthResult(
          success: false,
          errorMessage: 'Invalid password',
        );
      } else {
        logger.e('[UspAuth]: Authentication failed with status ${response.statusCode}');
        return AuthResult(
          success: false,
          errorMessage: 'Authentication failed: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      logger.e('[UspAuth]: Login error', error: e, stackTrace: stackTrace);
      return AuthResult(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Extract expiry from JWT token's exp claim
  DateTime? _extractExpiryFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode payload (base64url)
      String payload = parts[1];
      // Add padding if needed
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      logger.w('[UspAuth]: Failed to extract expiry from JWT: $e');
    }
    return null;
  }

  /// Get valid token, refreshing if needed
  Future<String?> getValidToken() async {
    if (_token == null) {
      logger.d('[UspAuth]: No token available');
      return null;
    }

    // Refresh if expiring within 5 minutes
    if (_expiry != null &&
        _expiry!.difference(DateTime.now()).inMinutes < 5) {
      logger.d('[UspAuth]: Token expiring soon, attempting refresh');
      final result = await refresh();
      if (!result.success) {
        logger.w('[UspAuth]: Token refresh failed: ${result.errorMessage}');
        return null;
      }
    }

    return _token;
  }

  /// Refresh token
  Future<AuthResult> refresh() async {
    if (_token == null) {
      logger.w('[UspAuth]: Cannot refresh - no token available');
      return const AuthResult(
        success: false,
        errorMessage: 'No token to refresh',
      );
    }

    try {
      logger.d('[UspAuth]: Attempting token refresh');

      final response = await _httpClient.post(
        Uri.parse('$_authEndpoint/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      logger.d('[UspAuth]: Refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _token = data['token'] as String?;
        final expiresIn = data['expires_in'] as int?;

        if (_token == null || expiresIn == null) {
          logger.e('[UspAuth]: Invalid refresh response format');
          return const AuthResult(
            success: false,
            errorMessage: 'Invalid response format from server',
          );
        }

        _expiry = DateTime.now().add(Duration(seconds: expiresIn));

        await _storage.write(key: _tokenKey, value: _token);
        await _storage.write(key: _expiryKey, value: _expiry!.toIso8601String());

        logger.d('[UspAuth]: Token refreshed successfully, expires at $_expiry');

        return AuthResult(
          success: true,
          token: _token,
          expiry: _expiry,
        );
      } else if (response.statusCode == 401) {
        logger.w('[UspAuth]: Refresh failed - token invalid');
        // Clear invalid token
        await logout();
        return const AuthResult(
          success: false,
          errorMessage: 'Token invalid or expired',
        );
      } else {
        logger.e('[UspAuth]: Refresh failed with status ${response.statusCode}');
        return AuthResult(
          success: false,
          errorMessage: 'Refresh failed: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      logger.e('[UspAuth]: Refresh error', error: e, stackTrace: stackTrace);
      return AuthResult(
        success: false,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    logger.d('[UspAuth]: Logging out');
    _token = null;
    _expiry = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiryKey);
  }

  bool get isAuthenticated => _token != null && !isExpired;
  bool get isExpired => _expiry?.isBefore(DateTime.now()) ?? true;
  String? get token => _token;
  DateTime? get expiry => _expiry;
}
