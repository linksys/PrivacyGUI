import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/data/services/session_service.dart';

import '../../../mocks/test_data/dashboard_manager_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late SessionService service;
  late MockRouterRepository mockRouterRepository;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getDeviceInfo);
  });

  setUp(() {
    mockRouterRepository = MockRouterRepository();
    service = SessionService(mockRouterRepository);
  });

  group('SessionService - checkRouterIsBack', () {
    // T034: checkRouterIsBack returns NodeDeviceInfo when SN matches
    test('returns NodeDeviceInfo when serial number matches', () async {
      // Arrange
      const expectedSN = 'TEST123456';
      final deviceInfoOutput =
          SessionTestData.createDeviceInfoSuccess(serialNumber: expectedSN)
              .output;

      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
                retries: 0,
              ))
          .thenAnswer(
              (_) async => JNAPSuccess(result: 'OK', output: deviceInfoOutput));

      // Act
      final result = await service.checkRouterIsBack(expectedSN);

      // Assert
      expect(result, isA<NodeDeviceInfo>());
      expect(result.serialNumber, equals(expectedSN));
    });

    // T035: checkRouterIsBack throws SerialNumberMismatchError when SN doesn't match
    test('throws SerialNumberMismatchError when serial number does not match',
        () async {
      // Arrange
      const expectedSN = 'EXPECTED_SN';
      const actualSN = 'ACTUAL_SN';
      final deviceInfoOutput =
          SessionTestData.createDeviceInfoSuccess(serialNumber: actualSN)
              .output;

      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
                retries: 0,
              ))
          .thenAnswer(
              (_) async => JNAPSuccess(result: 'OK', output: deviceInfoOutput));

      // Act & Assert
      expect(
        () => service.checkRouterIsBack(expectedSN),
        throwsA(isA<SerialNumberMismatchError>()),
      );
    });

    // T036: checkRouterIsBack throws ConnectivityError when router unreachable
    test('throws ConnectivityError when router is unreachable', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getDeviceInfo,
            fetchRemote: true,
            retries: 0,
          )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => service.checkRouterIsBack('TEST123456'),
        throwsA(isA<ConnectivityError>()),
      );
    });

    // T037: checkRouterIsBack maps JNAPError to ServiceError correctly
    test('maps JNAPError to ServiceError correctly', () async {
      // Arrange
      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
                retries: 0,
              ))
          .thenThrow(const JNAPError(
              result: '_ErrorUnauthorized', error: 'Unauthorized'));

      // Act & Assert
      expect(
        () => service.checkRouterIsBack('TEST123456'),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('returns NodeDeviceInfo when expected serial number is empty',
        () async {
      // Arrange - empty SN should skip validation
      final deviceInfoOutput =
          SessionTestData.createDeviceInfoSuccess(serialNumber: 'ANY_SN')
              .output;

      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
                retries: 0,
              ))
          .thenAnswer(
              (_) async => JNAPSuccess(result: 'OK', output: deviceInfoOutput));

      // Act
      final result = await service.checkRouterIsBack('');

      // Assert
      expect(result, isA<NodeDeviceInfo>());
      expect(result.serialNumber, equals('ANY_SN'));
    });
  });

  group('SessionService - checkDeviceInfo', () {
    // T044: checkDeviceInfo returns cached value immediately when available
    test('returns cached value immediately when available', () async {
      // Arrange
      final cachedDeviceInfo = NodeDeviceInfo.fromJson(
        SessionTestData.createDeviceInfoSuccess(serialNumber: 'CACHED_SN')
            .output,
      );

      // Act
      final result = await service.checkDeviceInfo(cachedDeviceInfo);

      // Assert
      expect(result, equals(cachedDeviceInfo));
      expect(result.serialNumber, equals('CACHED_SN'));
      // No API call should be made when cached value exists
      verifyZeroInteractions(mockRouterRepository);
    });

    // T045: checkDeviceInfo makes API call when cached value is null
    test('makes API call when cached value is null', () async {
      // Arrange
      final deviceInfoOutput =
          SessionTestData.createDeviceInfoSuccess(serialNumber: 'FRESH_SN')
              .output;

      when(() => mockRouterRepository.send(
                any(),
                retries: any(named: 'retries'),
                timeoutMs: any(named: 'timeoutMs'),
              ))
          .thenAnswer(
              (_) async => JNAPSuccess(result: 'OK', output: deviceInfoOutput));

      // Act
      final result = await service.checkDeviceInfo(null);

      // Assert
      expect(result, isA<NodeDeviceInfo>());
      expect(result.serialNumber, equals('FRESH_SN'));
      verify(() => mockRouterRepository.send(
            JNAPAction.getDeviceInfo,
            retries: 0,
            timeoutMs: 3000,
          )).called(1);
    });

    // T046: checkDeviceInfo throws ServiceError on API failure
    test('throws ServiceError on API failure', () async {
      // Arrange
      when(() => mockRouterRepository.send(
                any(),
                retries: any(named: 'retries'),
                timeoutMs: any(named: 'timeoutMs'),
              ))
          .thenThrow(const JNAPError(
              result: 'ErrorDeviceNotFound', error: 'Device not found'));

      // Act & Assert
      expect(
        () => service.checkDeviceInfo(null),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });
  });

  group('SessionService - forceFetchDeviceInfo', () {
    // T047: forceFetchDeviceInfo always makes API call
    test('always makes API call to fetch fresh device info', () async {
      // Arrange
      final deviceInfoOutput =
          SessionTestData.createDeviceInfoSuccess(serialNumber: 'FRESH_SN')
              .output;

      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
              ))
          .thenAnswer(
              (_) async => JNAPSuccess(result: 'OK', output: deviceInfoOutput));

      // Act
      final result = await service.forceFetchDeviceInfo();

      // Assert
      expect(result, isA<NodeDeviceInfo>());
      expect(result.serialNumber, equals('FRESH_SN'));
      verify(() => mockRouterRepository.send(
            JNAPAction.getDeviceInfo,
            fetchRemote: true,
          )).called(1);
    });

    // T048: forceFetchDeviceInfo throws UnauthorizedError on unauthorized
    test('throws UnauthorizedError on _ErrorUnauthorized', () async {
      // Arrange
      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
              ))
          .thenThrow(const JNAPError(
              result: '_ErrorUnauthorized', error: 'Unauthorized'));

      // Act & Assert
      expect(
        () => service.forceFetchDeviceInfo(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    // T049: forceFetchDeviceInfo throws ResourceNotFoundError
    test('throws ResourceNotFoundError on ErrorDeviceNotFound', () async {
      // Arrange
      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
              ))
          .thenThrow(const JNAPError(
              result: 'ErrorDeviceNotFound', error: 'Device not found'));

      // Act & Assert
      expect(
        () => service.forceFetchDeviceInfo(),
        throwsA(isA<ResourceNotFoundError>()),
      );
    });

    // T050: forceFetchDeviceInfo throws UnexpectedError on unknown error
    test('throws UnexpectedError on unknown JNAP error', () async {
      // Arrange
      when(() => mockRouterRepository.send(
                JNAPAction.getDeviceInfo,
                fetchRemote: true,
              ))
          .thenThrow(const JNAPError(
              result: 'UnknownError', error: 'Something went wrong'));

      // Act & Assert
      expect(
        () => service.forceFetchDeviceInfo(),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
