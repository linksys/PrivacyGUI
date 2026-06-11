import 'package:http/http.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/http/linksys_http_client.dart';

/// Guardian Remote Assistance API service extension.
///
/// Provides HTTP methods for managing Remote Assistance sessions.
///
/// Two authentication modes:
/// 1. **Client (device owner)**: X-Linksys-Token + X-Linksys-SN
/// 2. **CA (support agent)**: Authorization header with session token
extension GuardiansRemoteAssistanceService on LinksysHttpClient {
  /// Get all Remote Assistance sessions for a device.
  ///
  /// Requires device token and serial number for authentication.
  Future<Response> getSessions({
    required String linksysToken,
    required String serialNumber,
  }) {
    final endpoint = combineUrl(kSessions);
    final header = Map<String, String>.from(defaultHeader)
      ..[kHeaderLinksysToken] = linksysToken
      ..[kHeaderSerialNumber] = serialNumber;
    return get(Uri.parse(endpoint), headers: header);
  }

  /// Get information for a specific Remote Assistance session.
  Future<Response> getSessionInfo({
    required String linksysToken,
    required String sessionId,
    required String serialNumber,
  }) {
    final endpoint =
        combineUrl(kSessionInfo, args: {kVarRASessionId: sessionId});
    final header = Map<String, String>.from(defaultHeader)
      ..[kHeaderLinksysToken] = linksysToken
      ..[kHeaderSerialNumber] = serialNumber;
    return get(Uri.parse(endpoint), headers: header);
  }

  /// Create a PIN code for Remote Assistance.
  ///
  /// The PIN is shown to the user so they can share it with support.
  /// Once verified by support, the session becomes ACTIVE.
  Future<Response> createPin({
    required String linksysToken,
    required String serialNumber,
  }) {
    final endpoint = combineUrl(kCreatePin);
    final header = Map<String, String>.from(defaultHeader)
      ..[kHeaderLinksysToken] = linksysToken
      ..[kHeaderSerialNumber] = serialNumber;
    return post(Uri.parse(endpoint), headers: header);
  }

  /// Delete/terminate a Remote Assistance session.
  Future<Response> deleteSession({
    required String linksysToken,
    required String sessionId,
    required String serialNumber,
  }) {
    final endpoint =
        combineUrl(kSessionInfo, args: {kVarRASessionId: sessionId});
    final header = Map<String, String>.from(defaultHeader)
      ..[kHeaderLinksysToken] = linksysToken
      ..[kHeaderSerialNumber] = serialNumber;
    return delete(Uri.parse(endpoint), headers: header);
  }

  // =========================================================================
  // CA (Support Agent) Side - uses Authorization header
  // =========================================================================

  /// Get session info for CA side.
  ///
  /// Uses Authorization header with CA's session token instead of device token.
  Future<Response> getSessionInfoForCA({
    required String sessionToken,
    required String sessionId,
  }) {
    final endpoint =
        combineUrl(kSessionInfo, args: {kVarRASessionId: sessionId});
    final header = Map<String, String>.from(defaultHeader)
      ..['Authorization'] = wrapSessionToken(sessionToken);
    return get(Uri.parse(endpoint), headers: header);
  }

  /// Delete/terminate session for CA side.
  ///
  /// Uses Authorization header with CA's session token instead of device token.
  Future<Response> deleteSessionForCA({
    required String sessionToken,
    required String sessionId,
  }) {
    final endpoint =
        combineUrl(kSessionInfo, args: {kVarRASessionId: sessionId});
    final header = Map<String, String>.from(defaultHeader)
      ..['Authorization'] = wrapSessionToken(sessionToken);
    return delete(Uri.parse(endpoint), headers: header);
  }
}
