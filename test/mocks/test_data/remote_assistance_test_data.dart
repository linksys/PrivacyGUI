import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';

/// Test data builder for Remote Assistance service and provider tests.
///
/// Provides factory methods to create test instances with sensible defaults.
/// This centralizes test data and makes tests more readable.
class RemoteAssistanceTestData {
  // ==========================================================================
  // Constants
  // ==========================================================================

  static const testSerialNumber = '65G10M27E03053';
  static const testMacAddress = 'AA:BB:CC:DD:EE:FF';
  static const testDeviceUUID = 'device-uuid-12345';
  static const testDeviceToken = 'device-token-abc123';
  static const testSessionToken = 'session-token-xyz789';
  static const testSessionId = '3683AC72-A4F9-40DC-9CA5-CD5D53F815A9';
  static const testPin = '123456';
  static const testModelNumber = 'LN16-EU';

  // ==========================================================================
  // Factory Methods
  // ==========================================================================

  /// Returns the expected result from createPin API.
  static ({String sessionId, String pin}) createPinResult() =>
      (sessionId: testSessionId, pin: testPin);

  /// Creates a DeviceCredentials instance.
  static DeviceCredentials credentials({
    String serialNumber = testSerialNumber,
    String macAddress = testMacAddress,
    String deviceUUID = testDeviceUUID,
  }) =>
      DeviceCredentials(
        serialNumber: serialNumber,
        macAddress: macAddress,
        deviceUUID: deviceUUID,
      );

  /// Creates a GRASessionInfo with default or custom values.
  static GRASessionInfo sessionInfo({
    String id = testSessionId,
    String serialNumber = testSerialNumber,
    String modelNumber = testModelNumber,
    GRASessionStatus status = GRASessionStatus.active,
    int expiredIn = 600, // 10 minutes remaining (positive = time left)
    int createdAt = 1748315872000,
    int statusChangedAt = 1748315989000,
    int currentTime = 1748316924838,
  }) =>
      GRASessionInfo(
        id: id,
        serialNumber: serialNumber,
        modelNumber: modelNumber,
        status: status,
        expiredIn: expiredIn,
        createdAt: createdAt,
        statusChangedAt: statusChangedAt,
        currentTime: currentTime,
      );

  /// Creates a session with the given status.
  static GRASessionInfo sessionWithStatus(
    GRASessionStatus status, {
    String id = testSessionId,
    int expiredIn = 600,
  }) =>
      sessionInfo(id: id, status: status, expiredIn: expiredIn);

  /// Creates an INITIATE status session.
  static GRASessionInfo initiateSession() =>
      sessionWithStatus(GRASessionStatus.initiate);

  /// Creates a PENDING status session.
  static GRASessionInfo pendingSession() =>
      sessionWithStatus(GRASessionStatus.pending);

  /// Creates an ACTIVE status session.
  static GRASessionInfo activeSession() =>
      sessionWithStatus(GRASessionStatus.active);

  /// Creates an INVALID status session.
  static GRASessionInfo invalidSession() =>
      sessionWithStatus(GRASessionStatus.invalid);

  /// Creates an expired session (expiredIn <= 0).
  static GRASessionInfo expiredSession() =>
      sessionWithStatus(GRASessionStatus.pending, expiredIn: 0);

  /// Creates a list of sessions with different statuses.
  static List<GRASessionInfo> sessionList({int count = 2}) => [
        sessionInfo(id: 'session-1', status: GRASessionStatus.active),
        if (count > 1)
          sessionInfo(id: 'session-2', status: GRASessionStatus.pending),
        if (count > 2)
          sessionInfo(id: 'session-3', status: GRASessionStatus.invalid),
      ];

  /// Creates an ErrorResponse for testing error mapping.
  static ErrorResponse errorResponse({
    required String code,
    String? errorMessage,
    int status = 400,
  }) =>
      ErrorResponse(code: code, errorMessage: errorMessage, status: status);
}
