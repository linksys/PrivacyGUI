import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

final remoteAssistanceServiceProvider =
    Provider<RemoteAssistanceService>((ref) {
  // Use cloud-only repository to ensure API calls go to cloud, not local router
  return RemoteAssistanceService(ref.watch(cloudOnlyRepositoryProvider));
});

/// Service layer for Remote Assistance operations.
///
/// Encapsulates Cloud API calls and error mapping per Article VI.
class RemoteAssistanceService {
  final LinksysCloudRepository _repo;

  RemoteAssistanceService(this._repo);

  /// Fetch all Remote Assistance sessions for a device.
  Future<List<GRASessionInfo>> fetchSessions({
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) async {
    try {
      final token = await _repo.fetchDeviceToken(
        serialNumber: serialNumber,
        macAddress: macAddress,
        deviceUUID: deviceUUID,
      );
      return await _repo.getRemoteAssistanceSessions(
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
      final token = await _repo.fetchDeviceToken(
        serialNumber: serialNumber,
        macAddress: macAddress,
        deviceUUID: deviceUUID,
      );
      return await _repo.getRemoteAssistanceSessionInfo(
        linksysToken: token,
        sessionId: sessionId,
        serialNumber: serialNumber,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  /// Create a PIN for Remote Assistance.
  Future<String> createPin({
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) async {
    try {
      final token = await _repo.fetchDeviceToken(
        serialNumber: serialNumber,
        macAddress: macAddress,
        deviceUUID: deviceUUID,
      );
      return await _repo.createRemoteAssistancePin(
        linksysToken: token,
        serialNumber: serialNumber,
      );
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
      final token = await _repo.fetchDeviceToken(
        serialNumber: serialNumber,
        macAddress: macAddress,
        deviceUUID: deviceUUID,
      );
      await _repo.deleteRemoteAssistanceSession(
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
      return await _repo.getRemoteAssistanceSessionInfoForCA(
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
      await _repo.deleteRemoteAssistanceSessionForCA(
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
      return switch (error.code) {
        'INVALID_SESSION' ||
        'SESSION_EXPIRED' ||
        'BAD_AUTHENTICATION' =>
          const SessionTokenExpiredError(),
        'UNAUTHORIZED' => const UnauthorizedError(),
        'NOT_FOUND' => const ResourceNotFoundError(),
        'INVALID_INPUT' => InvalidInputError(message: error.errorMessage),
        'REQUEST_TIMEOUT' => NetworkError(message: error.errorMessage),
        _ => UnexpectedError(originalError: error, message: error.errorMessage),
      };
    }
    return UnexpectedError(originalError: error, message: error.toString());
  }
}
