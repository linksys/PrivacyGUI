import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/page/instant_topology/services/instant_topology_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';

class MockInstantTopologyService extends Mock
    implements InstantTopologyService {}

class MockDeviceManagerNotifier extends Mock implements DeviceManagerNotifier {}

void main() {
  late MockInstantTopologyService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockInstantTopologyService();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        instantTopologyServiceProvider.overrideWithValue(mockService),
        // Override deviceManagerProvider with empty state for simpler tests
        deviceManagerProvider.overrideWith(() {
          final notifier = MockDeviceManagerNotifier();
          return notifier;
        }),
      ],
    );
  }

  // ===========================================================================
  // T035 - Provider reboot() delegation tests
  // ===========================================================================

  group('InstantTopologyNotifier - reboot()', () {
    test('delegates to service.rebootNodes with empty list for master node',
        () async {
      // Arrange
      container = createContainer();
      when(() => mockService.rebootNodes(any())).thenAnswer((_) async {});

      // Act
      await container.read(instantTopologyProvider.notifier).reboot();

      // Assert
      verify(() => mockService.rebootNodes([])).called(1);
    });

    test('delegates to service.rebootNodes with device UUIDs', () async {
      // Arrange
      container = createContainer();
      final deviceUUIDs = ['uuid-1', 'uuid-2'];
      when(() => mockService.rebootNodes(any())).thenAnswer((_) async {});

      // Act
      await container
          .read(instantTopologyProvider.notifier)
          .reboot(deviceUUIDs);

      // Assert
      verify(() => mockService.rebootNodes(deviceUUIDs)).called(1);
    });

    test('rethrows ServiceError from service', () async {
      // Arrange
      container = createContainer();
      const error = NodeOperationFailedError(
        deviceId: 'uuid-1',
        operation: 'reboot',
      );
      when(() => mockService.rebootNodes(any())).thenThrow(error);

      // Act & Assert
      expect(
        () => container.read(instantTopologyProvider.notifier).reboot(),
        throwsA(isA<NodeOperationFailedError>()),
      );
    });

    test('rethrows TopologyTimeoutError from service', () async {
      // Arrange
      container = createContainer();
      const error = TopologyTimeoutError(
        timeout: Duration(seconds: 60),
        deviceIds: ['uuid-1'],
      );
      when(() => mockService.rebootNodes(any())).thenThrow(error);

      // Act & Assert
      expect(
        () =>
            container.read(instantTopologyProvider.notifier).reboot(['uuid-1']),
        throwsA(isA<TopologyTimeoutError>()),
      );
    });
  });

  // ===========================================================================
  // T036 - Provider factoryReset() delegation tests
  // ===========================================================================

  group('InstantTopologyNotifier - factoryReset()', () {
    test(
        'delegates to service.factoryResetNodes with empty list for master node',
        () async {
      // Arrange
      container = createContainer();
      when(() => mockService.factoryResetNodes(any())).thenAnswer((_) async {});

      // Act
      await container.read(instantTopologyProvider.notifier).factoryReset([]);

      // Assert
      verify(() => mockService.factoryResetNodes([])).called(1);
    });

    test('delegates to service.factoryResetNodes with device UUIDs', () async {
      // Arrange
      container = createContainer();
      final deviceUUIDs = ['uuid-1', 'uuid-2'];
      when(() => mockService.factoryResetNodes(any())).thenAnswer((_) async {});

      // Act
      await container
          .read(instantTopologyProvider.notifier)
          .factoryReset(deviceUUIDs);

      // Assert
      verify(() => mockService.factoryResetNodes(deviceUUIDs)).called(1);
    });

    test('rethrows ServiceError from service', () async {
      // Arrange
      container = createContainer();
      const error = NodeOperationFailedError(
        deviceId: 'uuid-1',
        operation: 'factoryReset',
      );
      when(() => mockService.factoryResetNodes(any())).thenThrow(error);

      // Act & Assert
      expect(
        () => container.read(instantTopologyProvider.notifier).factoryReset([]),
        throwsA(isA<NodeOperationFailedError>()),
      );
    });
  });

  // ===========================================================================
  // T037 - Provider toggleBlinkNode() delegation tests
  // ===========================================================================

  group('InstantTopologyNotifier - LED blink methods', () {
    test('startBlinkNodeLED delegates to service', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.startBlinkNodeLED(any())).thenAnswer((_) async {});

      // Act
      await container
          .read(instantTopologyProvider.notifier)
          .startBlinkNodeLED('device-123');

      // Assert
      verify(() => mockService.startBlinkNodeLED('device-123')).called(1);
    });

    test('stopBlinkNodeLED delegates to service', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.stopBlinkNodeLED()).thenAnswer((_) async {});

      // Act
      await container.read(instantTopologyProvider.notifier).stopBlinkNodeLED();

      // Assert
      verify(() => mockService.stopBlinkNodeLED()).called(1);
    });

    test('startBlinkNodeLED rethrows ServiceError', () async {
      // Arrange
      container = createContainer();
      const error = NodeOperationFailedError(
        deviceId: 'device-123',
        operation: 'blinkStart',
      );
      when(() => mockService.startBlinkNodeLED(any())).thenThrow(error);

      // Act & Assert
      expect(
        () => container
            .read(instantTopologyProvider.notifier)
            .startBlinkNodeLED('device-123'),
        throwsA(isA<NodeOperationFailedError>()),
      );
    });

    test('stopBlinkNodeLED rethrows ServiceError', () async {
      // Arrange
      container = createContainer();
      const error = NodeOperationFailedError(
        deviceId: '',
        operation: 'blinkStop',
      );
      when(() => mockService.stopBlinkNodeLED()).thenThrow(error);

      // Act & Assert
      expect(
        () =>
            container.read(instantTopologyProvider.notifier).stopBlinkNodeLED(),
        throwsA(isA<NodeOperationFailedError>()),
      );
    });
  });

  // ===========================================================================
  // T038 - Provider ServiceError handling tests
  // ===========================================================================

  group('InstantTopologyNotifier - ServiceError handling', () {
    test('handles TopologyTimeoutError correctly', () async {
      // Arrange
      container = createContainer();
      const error = TopologyTimeoutError(
        timeout: Duration(seconds: 60),
        deviceIds: ['uuid-1', 'uuid-2'],
      );
      when(() => mockService.rebootNodes(any())).thenThrow(error);

      // Act & Assert
      try {
        await container
            .read(instantTopologyProvider.notifier)
            .reboot(['uuid-1']);
        fail('Expected TopologyTimeoutError');
      } on TopologyTimeoutError catch (e) {
        expect(e.timeout, const Duration(seconds: 60));
        expect(e.deviceIds, ['uuid-1', 'uuid-2']);
      }
    });

    test('handles NodeOperationFailedError correctly', () async {
      // Arrange
      container = createContainer();
      const error = NodeOperationFailedError(
        deviceId: 'device-456',
        operation: 'reboot',
        originalError: 'JNAP error',
      );
      when(() => mockService.rebootNodes(any())).thenThrow(error);

      // Act & Assert
      try {
        await container.read(instantTopologyProvider.notifier).reboot([]);
        fail('Expected NodeOperationFailedError');
      } on NodeOperationFailedError catch (e) {
        expect(e.deviceId, 'device-456');
        expect(e.operation, 'reboot');
        expect(e.originalError, 'JNAP error');
      }
    });

    test('handles UnauthorizedError correctly', () async {
      // Arrange
      container = createContainer();
      const error = UnauthorizedError();
      when(() => mockService.factoryResetNodes(any())).thenThrow(error);

      // Act & Assert
      expect(
        () => container.read(instantTopologyProvider.notifier).factoryReset([]),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('handles UnexpectedError correctly', () async {
      // Arrange
      container = createContainer();
      const error = UnexpectedError(message: 'Something went wrong');
      when(() => mockService.startBlinkNodeLED(any())).thenThrow(error);

      // Act & Assert
      expect(
        () => container
            .read(instantTopologyProvider.notifier)
            .startBlinkNodeLED('device-123'),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
