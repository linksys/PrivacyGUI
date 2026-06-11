import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/cloud/guardian_api_client.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/remote_assistance/services/remote_assistance_service.dart';

class MockGuardianApiClient extends Mock implements GuardianApiClient {}

/// Test data builder for Remote Assistance service tests.
class RemoteAssistanceTestData {
  static const testSerialNumber = '65G10M27E03053';
  static const testMacAddress = '11:22:33:44:55:66';
  static const testDeviceUUID = 'device-uuid-1234';
  static const testDeviceToken = 'device-token-abc123';
  static const testSessionToken = 'session-token-xyz789';
  static const testSessionId = '3683AC72-A4F9-40DC-9CA5-CD5D53F815A9';
  static const testPin = '123456';
  static const testModelNumber = 'LN16-EU';

  /// Creates a GRASessionInfo with default or custom values.
  static GRASessionInfo sessionInfo({
    String id = testSessionId,
    String serialNumber = testSerialNumber,
    String modelNumber = testModelNumber,
    GRASessionStatus status = GRASessionStatus.active,
    int expiredIn = -748,
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

  /// Creates a list of sessions with different statuses.
  static List<GRASessionInfo> sessionList({int count = 2}) => [
        sessionInfo(
          id: 'session-1',
          status: GRASessionStatus.active,
        ),
        if (count > 1)
          sessionInfo(
            id: 'session-2',
            status: GRASessionStatus.pending,
          ),
        if (count > 2)
          sessionInfo(
            id: 'session-3',
            status: GRASessionStatus.invalid,
          ),
      ];

  /// Creates an ErrorResponse for testing error mapping.
  static ErrorResponse errorResponse({
    required String code,
    String? message,
    int status = 400,
  }) =>
      ErrorResponse(
        status: status,
        code: code,
        errorMessage: message,
      );
}

void main() {
  late MockGuardianApiClient mockApi;
  late RemoteAssistanceService service;

  setUp(() {
    mockApi = MockGuardianApiClient();
    service = RemoteAssistanceService(mockApi);
  });

  group('RemoteAssistanceService.fetchSessions', () {
    test('returns list of sessions on success', () async {
      final expectedSessions = RemoteAssistanceTestData.sessionList();

      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenAnswer((_) async => RemoteAssistanceTestData.testDeviceToken);

      when(() => mockApi.getSessions(
            linksysToken: any(named: 'linksysToken'),
            serialNumber: any(named: 'serialNumber'),
          )).thenAnswer((_) async => expectedSessions);

      final result = await service.fetchSessions(
        serialNumber: RemoteAssistanceTestData.testSerialNumber,
        macAddress: RemoteAssistanceTestData.testMacAddress,
        deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
      );

      expect(result, equals(expectedSessions));
      expect(result.length, equals(2));
      expect(result[0].status, equals(GRASessionStatus.active));

      verify(() => mockApi.fetchDeviceToken(
            serialNumber: RemoteAssistanceTestData.testSerialNumber,
            macAddress: RemoteAssistanceTestData.testMacAddress,
            deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
          )).called(1);

      verify(() => mockApi.getSessions(
            linksysToken: RemoteAssistanceTestData.testDeviceToken,
            serialNumber: RemoteAssistanceTestData.testSerialNumber,
          )).called(1);
    });

    test('returns empty list when no sessions exist', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenAnswer((_) async => RemoteAssistanceTestData.testDeviceToken);

      when(() => mockApi.getSessions(
            linksysToken: any(named: 'linksysToken'),
            serialNumber: any(named: 'serialNumber'),
          )).thenAnswer((_) async => []);

      final result = await service.fetchSessions(
        serialNumber: RemoteAssistanceTestData.testSerialNumber,
        macAddress: RemoteAssistanceTestData.testMacAddress,
        deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
      );

      expect(result, isEmpty);
    });

    test('throws SessionTokenExpiredError on INVALID_SESSION', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'INVALID_SESSION',
        message: 'Session is invalid',
      ));

      expect(
        () => service.fetchSessions(
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        throwsA(isA<SessionTokenExpiredError>()),
      );
    });

    test('throws UnauthorizedError on UNAUTHORIZED', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'UNAUTHORIZED',
        message: 'Not authorized',
      ));

      expect(
        () => service.fetchSessions(
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        throwsA(isA<UnauthorizedError>()),
      );
    });
  });

  group('RemoteAssistanceService.fetchSessionInfo', () {
    test('returns session info on success', () async {
      final expectedSession = RemoteAssistanceTestData.sessionInfo();

      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenAnswer((_) async => RemoteAssistanceTestData.testDeviceToken);

      when(() => mockApi.getSessionInfo(
            linksysToken: any(named: 'linksysToken'),
            sessionId: any(named: 'sessionId'),
            serialNumber: any(named: 'serialNumber'),
          )).thenAnswer((_) async => expectedSession);

      final result = await service.fetchSessionInfo(
        sessionId: RemoteAssistanceTestData.testSessionId,
        serialNumber: RemoteAssistanceTestData.testSerialNumber,
        macAddress: RemoteAssistanceTestData.testMacAddress,
        deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
      );

      expect(result, equals(expectedSession));
      expect(result.id, equals(RemoteAssistanceTestData.testSessionId));
      expect(result.status, equals(GRASessionStatus.active));

      verify(() => mockApi.getSessionInfo(
            linksysToken: RemoteAssistanceTestData.testDeviceToken,
            sessionId: RemoteAssistanceTestData.testSessionId,
            serialNumber: RemoteAssistanceTestData.testSerialNumber,
          )).called(1);
    });

    test('throws ResourceNotFoundError on NOT_FOUND', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenAnswer((_) async => RemoteAssistanceTestData.testDeviceToken);

      when(() => mockApi.getSessionInfo(
            linksysToken: any(named: 'linksysToken'),
            sessionId: any(named: 'sessionId'),
            serialNumber: any(named: 'serialNumber'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'NOT_FOUND',
        message: 'Session not found',
      ));

      expect(
        () => service.fetchSessionInfo(
          sessionId: RemoteAssistanceTestData.testSessionId,
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });
  });

  group('RemoteAssistanceService.createPin', () {
    test('returns PIN on success', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenAnswer((_) async => RemoteAssistanceTestData.testDeviceToken);

      when(() => mockApi.createPin(
            linksysToken: any(named: 'linksysToken'),
            serialNumber: any(named: 'serialNumber'),
          )).thenAnswer((_) async => RemoteAssistanceTestData.testPin);

      final result = await service.createPin(
        serialNumber: RemoteAssistanceTestData.testSerialNumber,
        macAddress: RemoteAssistanceTestData.testMacAddress,
        deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
      );

      expect(result, equals(RemoteAssistanceTestData.testPin));

      verify(() => mockApi.createPin(
            linksysToken: RemoteAssistanceTestData.testDeviceToken,
            serialNumber: RemoteAssistanceTestData.testSerialNumber,
          )).called(1);
    });

    test('throws InvalidInputError on INVALID_INPUT', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenAnswer((_) async => RemoteAssistanceTestData.testDeviceToken);

      when(() => mockApi.createPin(
            linksysToken: any(named: 'linksysToken'),
            serialNumber: any(named: 'serialNumber'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'INVALID_INPUT',
        message: 'Invalid serial number format',
      ));

      expect(
        () => service.createPin(
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        throwsA(isA<InvalidInputError>()),
      );
    });
  });

  group('RemoteAssistanceService.endSession', () {
    test('completes successfully on success', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenAnswer((_) async => RemoteAssistanceTestData.testDeviceToken);

      when(() => mockApi.deleteSession(
            linksysToken: any(named: 'linksysToken'),
            sessionId: any(named: 'sessionId'),
            serialNumber: any(named: 'serialNumber'),
          )).thenAnswer((_) async {});

      await expectLater(
        service.endSession(
          sessionId: RemoteAssistanceTestData.testSessionId,
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        completes,
      );

      verify(() => mockApi.deleteSession(
            linksysToken: RemoteAssistanceTestData.testDeviceToken,
            sessionId: RemoteAssistanceTestData.testSessionId,
            serialNumber: RemoteAssistanceTestData.testSerialNumber,
          )).called(1);
    });

    test('throws SessionTokenExpiredError on SESSION_EXPIRED', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'SESSION_EXPIRED',
        message: 'Session has expired',
      ));

      expect(
        () => service.endSession(
          sessionId: RemoteAssistanceTestData.testSessionId,
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        throwsA(isA<SessionTokenExpiredError>()),
      );
    });

    test('throws SessionTokenExpiredError on BAD_AUTHENTICATION', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'BAD_AUTHENTICATION',
        message: 'Authentication failed',
      ));

      expect(
        () => service.endSession(
          sessionId: RemoteAssistanceTestData.testSessionId,
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        throwsA(isA<SessionTokenExpiredError>()),
      );
    });
  });

  group('RemoteAssistanceService.fetchSessionInfoForCA', () {
    test('returns session info on success (CA side)', () async {
      final expectedSession = RemoteAssistanceTestData.sessionInfo();

      when(() => mockApi.getSessionInfoForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          )).thenAnswer((_) async => expectedSession);

      final result = await service.fetchSessionInfoForCA(
        sessionToken: RemoteAssistanceTestData.testSessionToken,
        sessionId: RemoteAssistanceTestData.testSessionId,
      );

      expect(result, equals(expectedSession));

      verify(() => mockApi.getSessionInfoForCA(
            sessionToken: RemoteAssistanceTestData.testSessionToken,
            sessionId: RemoteAssistanceTestData.testSessionId,
          )).called(1);

      // Verify fetchDeviceToken is NOT called for CA side
      verifyNever(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          ));
    });

    test('throws ResourceNotFoundError on NOT_FOUND', () async {
      when(() => mockApi.getSessionInfoForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'NOT_FOUND',
        message: 'Session not found',
      ));

      expect(
        () => service.fetchSessionInfoForCA(
          sessionToken: RemoteAssistanceTestData.testSessionToken,
          sessionId: RemoteAssistanceTestData.testSessionId,
        ),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });

    test('throws SessionTokenExpiredError on INVALID_SESSION', () async {
      when(() => mockApi.getSessionInfoForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'INVALID_SESSION',
        message: 'Invalid session token',
      ));

      expect(
        () => service.fetchSessionInfoForCA(
          sessionToken: RemoteAssistanceTestData.testSessionToken,
          sessionId: RemoteAssistanceTestData.testSessionId,
        ),
        throwsA(isA<SessionTokenExpiredError>()),
      );
    });
  });

  group('RemoteAssistanceService.endSessionForCA', () {
    test('completes successfully on success (CA side)', () async {
      when(() => mockApi.deleteSessionForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          )).thenAnswer((_) async {});

      await expectLater(
        service.endSessionForCA(
          sessionToken: RemoteAssistanceTestData.testSessionToken,
          sessionId: RemoteAssistanceTestData.testSessionId,
        ),
        completes,
      );

      verify(() => mockApi.deleteSessionForCA(
            sessionToken: RemoteAssistanceTestData.testSessionToken,
            sessionId: RemoteAssistanceTestData.testSessionId,
          )).called(1);

      // Verify fetchDeviceToken is NOT called for CA side
      verifyNever(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          ));
    });

    test('throws UnauthorizedError on UNAUTHORIZED', () async {
      when(() => mockApi.deleteSessionForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'UNAUTHORIZED',
        message: 'Not authorized to end session',
      ));

      expect(
        () => service.endSessionForCA(
          sessionToken: RemoteAssistanceTestData.testSessionToken,
          sessionId: RemoteAssistanceTestData.testSessionId,
        ),
        throwsA(isA<UnauthorizedError>()),
      );
    });
  });

  group('RemoteAssistanceService._mapError', () {
    // Test error mapping through public methods that call _mapError

    test('maps REQUEST_TIMEOUT to NetworkError', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'REQUEST_TIMEOUT',
        message: 'Request timed out',
      ));

      expect(
        () => service.fetchSessions(
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        throwsA(isA<NetworkError>()),
      );
    });

    test('maps unknown ErrorResponse code to UnexpectedError', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenThrow(RemoteAssistanceTestData.errorResponse(
        code: 'UNKNOWN_ERROR_CODE',
        message: 'Something unexpected happened',
      ));

      expect(
        () => service.fetchSessions(
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('maps non-ErrorResponse exception to UnexpectedError', () async {
      when(() => mockApi.fetchDeviceToken(
            serialNumber: any(named: 'serialNumber'),
            macAddress: any(named: 'macAddress'),
            deviceUUID: any(named: 'deviceUUID'),
          )).thenThrow(Exception('Generic exception'));

      expect(
        () => service.fetchSessions(
          serialNumber: RemoteAssistanceTestData.testSerialNumber,
          macAddress: RemoteAssistanceTestData.testMacAddress,
          deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
        ),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
