import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/nodes/services/node_detail_service.dart';

import '../../../mocks/test_data/node_detail_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late NodeDetailService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    // Register fallback values for Mocktail
    registerFallbackValue(JNAPAction.startBlinkNodeLed);
    registerFallbackValue(CacheLevel.noCache);
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = NodeDetailService(mockRepository);
  });

  group('NodeDetailService - startBlinkNodeLED', () {
    test('sends correct JNAP action with deviceId', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async => NodeDetailTestData.createBlinkNodeSuccess());

      // Act
      await service.startBlinkNodeLED('test-device-id');

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.startBlinkNodeLed,
            data: {'deviceID': 'test-device-id'},
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            auth: true,
          )).called(1);
    });

    test('succeeds when JNAP call returns success', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async => NodeDetailTestData.createBlinkNodeSuccess());

      // Act & Assert
      await expectLater(
        service.startBlinkNodeLED('device-123'),
        completes,
      );
    });

    test('throws UnauthorizedError when JNAP returns unauthorized error',
        () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            auth: any(named: 'auth'),
          )).thenThrow(NodeDetailTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.startBlinkNodeLED('device-123'),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws UnexpectedError when JNAP returns generic error', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
                auth: any(named: 'auth'),
              ))
          .thenThrow(NodeDetailTestData.createUnexpectedError('ErrorUnknown'));

      // Act & Assert
      expect(
        () => service.startBlinkNodeLED('device-123'),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('throws UnexpectedError when JNAP returns network timeout error',
        () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
                auth: any(named: 'auth'),
              ))
          .thenThrow(
              NodeDetailTestData.createUnexpectedError('ErrorNetworkTimeout'));

      // Act & Assert
      expect(
        () => service.startBlinkNodeLED('device-123'),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('NodeDetailService - stopBlinkNodeLED', () {
    test('sends correct JNAP action without data', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer(
              (_) async => NodeDetailTestData.createStopBlinkNodeSuccess());

      // Act
      await service.stopBlinkNodeLED();

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.stopBlinkNodeLed,
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });

    test('succeeds when JNAP call returns success', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer(
              (_) async => NodeDetailTestData.createStopBlinkNodeSuccess());

      // Act & Assert
      await expectLater(
        service.stopBlinkNodeLED(),
        completes,
      );
    });

    test('throws UnauthorizedError when JNAP returns unauthorized error',
        () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(NodeDetailTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.stopBlinkNodeLED(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws UnexpectedError when JNAP returns generic error', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenThrow(NodeDetailTestData.createUnexpectedError('ErrorUnknown'));

      // Act & Assert
      expect(
        () => service.stopBlinkNodeLED(),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('throws UnexpectedError when JNAP returns network timeout error',
        () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenThrow(
              NodeDetailTestData.createUnexpectedError('ErrorNetworkTimeout'));

      // Act & Assert
      expect(
        () => service.stopBlinkNodeLED(),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}
