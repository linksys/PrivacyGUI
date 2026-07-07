import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/guardian_api_client.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

final remoteAssistanceServiceProvider =
    Provider<RemoteAssistanceService>((ref) {
  return RemoteAssistanceService(ref.watch(guardianApiClientProvider));
});

/// Service layer for Remote Assistance operations.
///
/// Encapsulates Guardian API calls and error mapping per Article VI.
class RemoteAssistanceService {
  final GuardianApiClient _api;

  RemoteAssistanceService(this._api);

  /// Fetch all Remote Assistance sessions for a device.
  Future<List<GRASessionInfo>> fetchSessions({
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) async {
    try {
      final token = await _api.fetchDeviceToken(
        serialNumber: serialNumber,
        macAddress: macAddress,
        deviceUUID: deviceUUID,
      );
      return await _api.getSessions(
        linksysToken: token,
        serialNumber: serialNumber,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Fetch info for a specific session.
  Future<GRASessionInfo> fetchSessionInfo({
    required String sessionId,
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) async {
    try {
      final token = await _api.fetchDeviceToken(
        serialNumber: serialNumber,
        macAddress: macAddress,
        deviceUUID: deviceUUID,
      );
      return await _api.getSessionInfo(
        linksysToken: token,
        sessionId: sessionId,
        serialNumber: serialNumber,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Create a PIN for Remote Assistance.
  ///
  /// Requires session to exist (CA must create it first).
  /// Returns session ID and PIN code.
  Future<({String sessionId, String pin})> createPin({
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) async {
    try {
      final token = await _api.fetchDeviceToken(
        serialNumber: serialNumber,
        macAddress: macAddress,
        deviceUUID: deviceUUID,
      );
      final result = await _api.createPin(
        linksysToken: token,
        serialNumber: serialNumber,
      );
      return (sessionId: result.sessionId, pin: result.pin);
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// End/delete a Remote Assistance session.
  Future<void> endSession({
    required String sessionId,
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) async {
    try {
      final token = await _api.fetchDeviceToken(
        serialNumber: serialNumber,
        macAddress: macAddress,
        deviceUUID: deviceUUID,
      );
      await _api.deleteSession(
        linksysToken: token,
        sessionId: sessionId,
        serialNumber: serialNumber,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  // =========================================================================
  // CA (Support Agent) Side
  // =========================================================================

  /// Fetch session info for CA side using session token.
  ///
  /// CA uses the temporary session token (from URL param) for authentication,
  /// not device credentials like the client side.
  Future<GRASessionInfo> fetchSessionInfoForCA({
    required String sessionToken,
    required String sessionId,
  }) async {
    try {
      return await _api.getSessionInfoForCA(
        sessionToken: sessionToken,
        sessionId: sessionId,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// End/delete session for CA side.
  Future<void> endSessionForCA({
    required String sessionToken,
    required String sessionId,
  }) async {
    try {
      await _api.deleteSessionForCA(
        sessionToken: sessionToken,
        sessionId: sessionId,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Map Cloud API errors to ServiceError (Article XIII).
  ServiceError _mapError(Object error) {
    if (error is ErrorResponse) {
      // Check HTTP status first — 401 always means unauthorized
      if (error.status == 401) {
        return const UnauthorizedError();
      }
      return switch (error.code) {
        'INVALID_SESSION' ||
        'SESSION_EXPIRED' ||
        'BAD_AUTHENTICATION' =>
          const SessionTokenExpiredError(),
        'UNAUTHORIZED' => const UnauthorizedError(),
        'NOT_FOUND' => const ResourceNotFoundError(),
        'INVALID_INPUT' => InvalidInputError(detail: error.errorMessage),
        'REQUEST_TIMEOUT' => NetworkError(detail: error.errorMessage),
        _ => UnexpectedError(originalError: error, detail: error.errorMessage),
      };
    }
    return UnexpectedError(originalError: error, detail: error.toString());
  }
}
