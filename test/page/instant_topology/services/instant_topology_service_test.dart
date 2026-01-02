import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_topology/services/instant_topology_service.dart';

import '../../../mocks/test_data/instant_topology_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late InstantTopologyService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    // Register fallback values for Mocktail
    registerFallbackValue(JNAPAction.reboot);
    registerFallbackValue(JNAPAction.getDevices);
    registerFallbackValue(CommandType.local);
    registerFallbackValue(CacheLevel.noCache);
    registerFallbackValue(
        JNAPTransactionBuilder(commands: const [], auth: false));
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = InstantTopologyService(mockRepository);
  });

  // ===========================================================================
  // User Story 1 - Reboot Tests (T009-T013)
  // ===========================================================================

  group('InstantTopologyService - rebootNodes', () {
    test('sends reboot action for master node when list is empty', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => InstantTopologyTestData.createRebootSuccess());

      // Act
      await service.rebootNodes([]);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.reboot,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            auth: true,
          )).called(1);
    });

    test('sends reboot2 transaction for multiple child nodes in reverse order',
        () async {
      // Arrange
      final deviceUUIDs = ['uuid-1', 'uuid-2', 'uuid-3'];

      when(() => mockRepository.transaction(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async =>
              InstantTopologyTestData.createMultiNodeRebootSuccess(
                  deviceUUIDs));

      // Mock scheduledCommand to return stream that completes with all offline
      when(() => mockRepository.scheduledCommand(
            action: any(named: 'action'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            maxRetry: any(named: 'maxRetry'),
            condition: any(named: 'condition'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => Stream.fromIterable([
            InstantTopologyTestData.createAllNodesOfflineResponse(deviceUUIDs),
          ]));

      // Act
      await service.rebootNodes(deviceUUIDs);

      // Assert
      final captured = verify(() => mockRepository.transaction(
            captureAny(),
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).captured;

      final builder = captured.first as JNAPTransactionBuilder;
      expect(builder.commands.length, 3);
      // Verify reverse order
      expect(builder.commands[0].key, JNAPAction.reboot2);
      expect(builder.commands[0].value['deviceUUID'], 'uuid-3');
      expect(builder.commands[1].value['deviceUUID'], 'uuid-2');
      expect(builder.commands[2].value['deviceUUID'], 'uuid-1');
    });

    test('throws NodeOperationFailedError when reboot fails', () async {
      // Arrange
      final jnapError = InstantTopologyTestData.createRebootError();
      when(() => mockRepository.send(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            auth: any(named: 'auth'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.rebootNodes([]),
        throwsA(isA<NodeOperationFailedError>()),
      );
    });

    test('throws UnauthorizedError when authentication fails', () async {
      // Arrange
      final jnapError = JNAPError(result: '_ErrorUnauthorized');
      when(() => mockRepository.send(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            auth: any(named: 'auth'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.rebootNodes([]),
        throwsA(isA<UnauthorizedError>()),
      );
    });
  });

  group('InstantTopologyService - waitForNodesOffline', () {
    test('completes successfully when all nodes go offline', () async {
      // Arrange
      final deviceUUIDs = ['uuid-1', 'uuid-2'];

      when(() => mockRepository.scheduledCommand(
            action: any(named: 'action'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            maxRetry: any(named: 'maxRetry'),
            condition: any(named: 'condition'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => Stream.fromIterable([
            InstantTopologyTestData.createAllNodesOfflineResponse(deviceUUIDs),
          ]));

      // Act & Assert - should complete without throwing
      await expectLater(
        service.waitForNodesOffline(deviceUUIDs, maxRetry: 1, retryDelayMs: 10),
        completes,
      );
    });

    test(
        'throws TopologyTimeoutError when nodes remain online after max retries',
        () async {
      // Arrange
      final deviceUUIDs = ['uuid-1', 'uuid-2'];

      // Return online response - the stream will complete after maxRetry attempts
      when(() => mockRepository.scheduledCommand(
            action: any(named: 'action'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            maxRetry: any(named: 'maxRetry'),
            condition: any(named: 'condition'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => Stream.fromIterable([
            // Always return online - stream ends after items exhausted
            InstantTopologyTestData.createAllNodesOnlineResponse(deviceUUIDs),
          ]));

      // Act & Assert
      expect(
        () => service.waitForNodesOffline(
          deviceUUIDs,
          maxRetry: 1,
          retryDelayMs: 10,
        ),
        throwsA(isA<TopologyTimeoutError>()),
      );
    });

    test('TopologyTimeoutError contains timeout duration and device IDs',
        () async {
      // Arrange
      final deviceUUIDs = ['uuid-1', 'uuid-2'];

      when(() => mockRepository.scheduledCommand(
            action: any(named: 'action'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            maxRetry: any(named: 'maxRetry'),
            condition: any(named: 'condition'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => Stream.fromIterable([
            InstantTopologyTestData.createAllNodesOnlineResponse(deviceUUIDs),
          ]));

      // Act & Assert
      try {
        await service.waitForNodesOffline(
          deviceUUIDs,
          maxRetry: 5,
          retryDelayMs: 100,
        );
        fail('Expected TopologyTimeoutError');
      } on TopologyTimeoutError catch (e) {
        expect(e.deviceIds, deviceUUIDs);
        expect(e.timeout, const Duration(milliseconds: 500)); // 5 * 100ms
      }
    });
  });

  // ===========================================================================
  // User Story 2 - Factory Reset Tests (T019-T021)
  // ===========================================================================

  group('InstantTopologyService - factoryResetNodes', () {
    test('sends factoryReset action for master node when list is empty',
        () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => InstantTopologyTestData.createFactoryResetSuccess());

      // Act
      await service.factoryResetNodes([]);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.factoryReset,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            auth: true,
          )).called(1);
    });

    test('sends factoryReset2 transaction for multiple nodes in reverse order',
        () async {
      // Arrange
      final deviceUUIDs = ['uuid-1', 'uuid-2'];

      when(() => mockRepository.transaction(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async =>
              InstantTopologyTestData.createMultiNodeFactoryResetSuccess(
                  deviceUUIDs));

      when(() => mockRepository.scheduledCommand(
            action: any(named: 'action'),
            retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
            maxRetry: any(named: 'maxRetry'),
            condition: any(named: 'condition'),
            auth: any(named: 'auth'),
          )).thenAnswer((_) => Stream.fromIterable([
            InstantTopologyTestData.createAllNodesOfflineResponse(deviceUUIDs),
          ]));

      // Act
      await service.factoryResetNodes(deviceUUIDs);

      // Assert
      final captured = verify(() => mockRepository.transaction(
            captureAny(),
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).captured;

      final builder = captured.first as JNAPTransactionBuilder;
      expect(builder.commands.length, 2);
      expect(builder.commands[0].key, JNAPAction.factoryReset2);
      expect(builder.commands[0].value['deviceUUID'], 'uuid-2'); // Reversed
      expect(builder.commands[1].value['deviceUUID'], 'uuid-1');
    });

    test('throws NodeOperationFailedError when factory reset fails', () async {
      // Arrange
      final jnapError = InstantTopologyTestData.createGenericError(
        errorCode: 'ErrorFactoryResetFailed',
      );
      when(() => mockRepository.send(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            auth: any(named: 'auth'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.factoryResetNodes([]),
        throwsA(isA<NodeOperationFailedError>()),
      );
    });
  });

  // ===========================================================================
  // User Story 3 - LED Blink Tests (T026-T028)
  // ===========================================================================

  group('InstantTopologyService - startBlinkNodeLED', () {
    test('sends startBlinkNodeLed action with device ID', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => InstantTopologyTestData.createStartBlinkSuccess());

      // Act
      await service.startBlinkNodeLED('device-123');

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.startBlinkNodeLed,
            data: {'deviceID': 'device-123'},
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            auth: true,
          )).called(1);
    });

    test('throws NodeOperationFailedError when blink start fails', () async {
      // Arrange
      final jnapError = InstantTopologyTestData.createBlinkError(
        deviceId: 'device-123',
      );
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            auth: any(named: 'auth'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.startBlinkNodeLED('device-123'),
        throwsA(isA<NodeOperationFailedError>()),
      );
    });

    test('NodeOperationFailedError contains correct device ID and operation',
        () async {
      // Arrange
      final jnapError = InstantTopologyTestData.createBlinkError();
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            auth: any(named: 'auth'),
          )).thenThrow(jnapError);

      // Act & Assert
      try {
        await service.startBlinkNodeLED('device-456');
        fail('Expected NodeOperationFailedError');
      } on NodeOperationFailedError catch (e) {
        expect(e.deviceId, 'device-456');
        expect(e.operation, 'blinkStart');
      }
    });
  });

  group('InstantTopologyService - stopBlinkNodeLED', () {
    test('sends stopBlinkNodeLed action', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer(
              (_) async => InstantTopologyTestData.createStopBlinkSuccess());

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

    test('throws NodeOperationFailedError when blink stop fails', () async {
      // Arrange
      final jnapError = InstantTopologyTestData.createBlinkError();
      when(() => mockRepository.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.stopBlinkNodeLED(),
        throwsA(isA<NodeOperationFailedError>()),
      );
    });

    test('NodeOperationFailedError has empty deviceId for stopBlinkNodeLED',
        () async {
      // Arrange
      final jnapError = InstantTopologyTestData.createBlinkError();
      when(() => mockRepository.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(jnapError);

      // Act & Assert
      try {
        await service.stopBlinkNodeLED();
        fail('Expected NodeOperationFailedError');
      } on NodeOperationFailedError catch (e) {
        expect(e.deviceId, '');
        expect(e.operation, 'blinkStop');
      }
    });
  });
}
