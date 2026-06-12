import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/http/linksys_http_client.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/utils/logger.dart';

final guardianApiClientProvider = Provider((ref) => GuardianApiClient());

/// API client for Guardian Remote Assistance services.
///
/// Handles HTTP communication with Guardian API including:
/// - Device token management (with caching)
/// - Remote Assistance session operations
///
/// Two authentication modes:
/// 1. **Client (device owner)**: X-Linksys-Token + X-Linksys-SN headers
/// 2. **CA (support agent)**: Authorization header with session token
class GuardianApiClient {
  final LinksysHttpClient _http;

  GuardianApiClient({LinksysHttpClient? httpClient})
      : _http = httpClient ?? LinksysHttpClient();

  String _buildUrl(String endpoint, {Map<String, String>? args}) {
    String url = 'https://${cloudEnvironmentConfig[kCloudBase]}$endpoint';
    args?.forEach((key, value) => url = url.replaceFirst(key, value));
    return url;
  }

  Map<String, String> get _defaultHeaders => {
        kHeaderClientTypeId: kClientTypeId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ===========================================================================
  // Device Token
  // ===========================================================================

  /// Fetch device token from Guardian API.
  ///
  /// The token is cached in secure storage with a 1-hour TTL.
  Future<String> fetchDeviceToken({
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) async {
    const storage = FlutterSecureStorage();
    final cachedToken = await storage.read(key: pLinksysToken);
    final cachedTs = await storage.read(key: pLinksysTokenTs);

    if (cachedToken != null && cachedTs != null) {
      final ts = int.tryParse(cachedTs) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age < 3600000) {
        logger.d('[Guardian] Using cached device token');
        return cachedToken;
      }
    }

    logger.d('[Guardian] Fetching new device token');
    final url = Uri.parse(_buildUrl(kDeviceToken)).replace(queryParameters: {
      'serialNumber': serialNumber,
      'macAddress': macAddress,
      'uuid': deviceUUID.toUpperCase(),
    });

    final response = await _http.get(url, headers: _defaultHeaders);
    final token = jsonDecode(response.body)['linksysToken'] as String;

    await storage.write(key: pLinksysToken, value: token);
    await storage.write(
      key: pLinksysTokenTs,
      value: '${DateTime.now().millisecondsSinceEpoch}',
    );

    return token;
  }

  // ===========================================================================
  // Remote Assistance - Client (Device Owner) Side
  // ===========================================================================

  /// Get all Remote Assistance sessions for a device.
  Future<List<GRASessionInfo>> getSessions({
    required String linksysToken,
    required String serialNumber,
  }) async {
    final response = await _request(
      method: 'GET',
      endpoint: kSessions,
      linksysToken: linksysToken,
      serialNumber: serialNumber,
    );
    final content = jsonDecode(response.body)['content'] as List? ?? [];
    return content.map((e) => GRASessionInfo.fromMap(e)).toList();
  }

  /// Get information for a specific Remote Assistance session.
  Future<GRASessionInfo> getSessionInfo({
    required String linksysToken,
    required String sessionId,
    required String serialNumber,
  }) async {
    final response = await _request(
      method: 'GET',
      endpoint: kSessionInfo,
      args: {kVarRASessionId: sessionId},
      linksysToken: linksysToken,
      serialNumber: serialNumber,
    );
    return GRASessionInfo.fromMap(jsonDecode(response.body));
  }

  /// Create a PIN code for Remote Assistance (customer UI).
  ///
  /// POST /remote-assistances/sessions/pin
  /// Requires session to exist (CA must create it first).
  /// Returns session id and pin.
  Future<({String sessionId, String pin})> createPin({
    required String linksysToken,
    required String serialNumber,
  }) async {
    final response = await _request(
      method: 'POST',
      endpoint: kCreatePin,
      linksysToken: linksysToken,
      serialNumber: serialNumber,
    );
    final body = jsonDecode(response.body);
    logger.d('[Guardian] createPin response: $body');
    return (
      sessionId: body['id'] as String? ?? '',
      pin: body['pin'] as String? ?? '',
    );
  }

  /// Delete/terminate a Remote Assistance session.
  Future<void> deleteSession({
    required String linksysToken,
    required String sessionId,
    required String serialNumber,
  }) async {
    await _request(
      method: 'DELETE',
      endpoint: kSessionInfo,
      args: {kVarRASessionId: sessionId},
      linksysToken: linksysToken,
      serialNumber: serialNumber,
    );
  }

  // ===========================================================================
  // Remote Assistance - CA (Support Agent) Side
  // ===========================================================================

  /// Get session info for CA side using session token.
  Future<GRASessionInfo> getSessionInfoForCA({
    required String sessionToken,
    required String sessionId,
  }) async {
    final response = await _request(
      method: 'GET',
      endpoint: kSessionInfo,
      args: {kVarRASessionId: sessionId},
      sessionToken: sessionToken,
    );
    return GRASessionInfo.fromMap(jsonDecode(response.body));
  }

  /// Delete/terminate session for CA side.
  Future<void> deleteSessionForCA({
    required String sessionToken,
    required String sessionId,
  }) async {
    await _request(
      method: 'DELETE',
      endpoint: kSessionInfo,
      args: {kVarRASessionId: sessionId},
      sessionToken: sessionToken,
    );
  }

  // ===========================================================================
  // Private Helpers
  // ===========================================================================

  Future<http.Response> _request({
    required String method,
    required String endpoint,
    Map<String, String>? args,
    String? linksysToken,
    String? serialNumber,
    String? sessionToken,
  }) async {
    final url = Uri.parse(_buildUrl(endpoint, args: args));
    final headers = Map<String, String>.from(_defaultHeaders);

    if (sessionToken != null) {
      headers['Authorization'] =
          'LinksysUserAuth session_token="$sessionToken"';
    } else if (linksysToken != null && serialNumber != null) {
      headers[kHeaderLinksysToken] = linksysToken;
      headers[kHeaderSerialNumber] = serialNumber;
    }

    logger.d('[Guardian] $method $url');
    logger.d('[Guardian] Headers: ${headers.keys.toList()}');

    final response = await switch (method) {
      'GET' => _http.get(url, headers: headers),
      'POST' => _http.post(url, headers: headers),
      'DELETE' => _http.delete(url, headers: headers),
      _ => throw ArgumentError('Unsupported HTTP method: $method'),
    };

    logger.d('[Guardian] Response: ${response.statusCode}');
    _validateResponse(response);
    return response;
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode >= 400) {
      logger.w('[Guardian] API error: ${response.statusCode} ${response.body}');
      throw http.ClientException(
        'API error ${response.statusCode}: ${response.reasonPhrase}',
        response.request?.url,
      );
    }
  }
}
