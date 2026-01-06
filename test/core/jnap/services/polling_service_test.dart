import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/data/services/polling_service.dart';
import 'package:privacy_gui/di.dart';

import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../mocks/test_data/polling_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late PollingService service;
  late MockRouterRepository mockRouterRepository;

  setUpAll(() {
    // Initialize better actions map for JNAPAction.actionValue to work
    initBetterActions();

    registerFallbackValue(JNAPAction.getDeviceMode);
    registerFallbackValue(
      JNAPTransactionBuilder(commands: const [], auth: true),
    );

    // Register mock ServiceHelper
    if (getIt.isRegistered<ServiceHelper>()) {
      getIt.unregister<ServiceHelper>();
    }
    getIt.registerSingleton<ServiceHelper>(MockServiceHelper());
  });

  setUp(() {
    mockRouterRepository = MockRouterRepository();
    service = PollingService(mockRouterRepository);
  });

  group('PollingService - checkDeviceMode', () {
    test('returns Master mode on success', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getDeviceMode,
            fetchRemote: true,
          )).thenAnswer(
        (_) async => PollingTestData.createDeviceModeSuccess(mode: 'Master'),
      );

      // Act
      final result = await service.checkDeviceMode();

      // Assert
      expect(result, equals('Master'));
      verify(() => mockRouterRepository.send(
            JNAPAction.getDeviceMode,
            fetchRemote: true,
          )).called(1);
    });

    test('returns Slave mode on success', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getDeviceMode,
            fetchRemote: true,
          )).thenAnswer(
        (_) async => PollingTestData.createDeviceModeSuccess(mode: 'Slave'),
      );

      // Act
      final result = await service.checkDeviceMode();

      // Assert
      expect(result, equals('Slave'));
    });

    test('returns Unconfigured when mode is null', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getDeviceMode,
            fetchRemote: true,
          )).thenAnswer(
        (_) async => const JNAPSuccess(result: 'OK', output: {}),
      );

      // Act
      final result = await service.checkDeviceMode();

      // Assert
      expect(result, equals('Unconfigured'));
    });
  });

  group('PollingService - buildCoreTransactions', () {
    test('includes getBackhaulInfo when mode is Master', () {
      // Act
      final commands = service.buildCoreTransactions(mode: 'Master');

      // Assert
      final hasBackhaulInfo = commands.any(
        (entry) => entry.key == JNAPAction.getBackhaulInfo,
      );
      expect(hasBackhaulInfo, isTrue);
    });

    test('excludes getBackhaulInfo when mode is Slave', () {
      // Act
      final commands = service.buildCoreTransactions(mode: 'Slave');

      // Assert
      final hasBackhaulInfo = commands.any(
        (entry) => entry.key == JNAPAction.getBackhaulInfo,
      );
      expect(hasBackhaulInfo, isFalse);
    });

    test('excludes getBackhaulInfo when mode is Unconfigured', () {
      // Act
      final commands = service.buildCoreTransactions(mode: 'Unconfigured');

      // Assert
      final hasBackhaulInfo = commands.any(
        (entry) => entry.key == JNAPAction.getBackhaulInfo,
      );
      expect(hasBackhaulInfo, isFalse);
    });

    test('excludes getBackhaulInfo when mode is null', () {
      // Act
      final commands = service.buildCoreTransactions();

      // Assert
      final hasBackhaulInfo = commands.any(
        (entry) => entry.key == JNAPAction.getBackhaulInfo,
      );
      expect(hasBackhaulInfo, isFalse);
    });

    test('always includes essential JNAP actions', () {
      // Act
      final commands = service.buildCoreTransactions(mode: 'Master');

      // Assert
      final actionKeys = commands.map((e) => e.key).toList();

      // Essential actions that should always be present
      expect(
          actionKeys, contains(JNAPAction.getNodesWirelessNetworkConnections));
      expect(actionKeys, contains(JNAPAction.getNetworkConnections));
      expect(actionKeys, contains(JNAPAction.getRadioInfo));
      expect(actionKeys, contains(JNAPAction.getDevices));
      expect(actionKeys, contains(JNAPAction.getFirmwareUpdateSettings));
      expect(actionKeys, contains(JNAPAction.getWANStatus));
      expect(actionKeys, contains(JNAPAction.getEthernetPortConnections));
      expect(actionKeys, contains(JNAPAction.getSystemStats));
      expect(actionKeys, contains(JNAPAction.getPowerTableSettings));
      expect(actionKeys, contains(JNAPAction.getLocalTime));
      expect(actionKeys, contains(JNAPAction.getDeviceInfo));
      expect(actionKeys, contains(JNAPAction.getMACFilterSettings));
    });

    test('returns non-empty list', () {
      // Act
      final commands = service.buildCoreTransactions();

      // Assert
      expect(commands, isNotEmpty);
      expect(commands.length, greaterThanOrEqualTo(12));
    });
  });

  group('PollingService - executeTransaction', () {
    test('executes transaction successfully', () async {
      // Arrange
      final commands = [
        const MapEntry<JNAPAction, Map<String, dynamic>>(
          JNAPAction.getDeviceInfo,
          {},
        ),
      ];
      final expectedResult = PollingTestData.createSuccessfulCoreTransaction();

      when(() => mockRouterRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => expectedResult);

      // Act
      final result = await service.executeTransaction(commands);

      // Assert
      expect(result, equals(expectedResult));
      verify(() => mockRouterRepository.transaction(
            any(),
            fetchRemote: false,
          )).called(1);
    });

    test('executes transaction with force flag', () async {
      // Arrange
      final commands = [
        const MapEntry<JNAPAction, Map<String, dynamic>>(
          JNAPAction.getDeviceInfo,
          {},
        ),
      ];
      final expectedResult = PollingTestData.createSuccessfulCoreTransaction();

      when(() => mockRouterRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => expectedResult);

      // Act
      final result = await service.executeTransaction(commands, force: true);

      // Assert
      expect(result, equals(expectedResult));
      verify(() => mockRouterRepository.transaction(
            any(),
            fetchRemote: true,
          )).called(1);
    });

    test('throws exception on transaction failure', () async {
      // Arrange
      final commands = [
        const MapEntry<JNAPAction, Map<String, dynamic>>(
          JNAPAction.getDeviceInfo,
          {},
        ),
      ];

      when(() => mockRouterRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenThrow(Exception('Transaction failed'));

      // Act & Assert
      expect(
        () => service.executeTransaction(commands),
        throwsException,
      );
    });
  });

  group('PollingService - parseCacheData', () {
    // Use known action values that exist in _betterActionMap
    const deviceInfoAction = JNAPAction.getDeviceInfo;
    const radioInfoAction = JNAPAction.getRadioInfo;

    test('returns parsed data when all commands have cache', () {
      // Arrange
      final commands = [
        MapEntry<JNAPAction, Map<String, dynamic>>(deviceInfoAction, {}),
        MapEntry<JNAPAction, Map<String, dynamic>>(radioInfoAction, {}),
      ];
      final cache = {
        deviceInfoAction.actionValue: {
          'data': {
            'result': 'OK',
            'output': {'serialNumber': 'TEST123'}
          },
        },
        radioInfoAction.actionValue: {
          'data': {
            'result': 'OK',
            'output': {'radios': []}
          },
        },
      };

      // Act
      final result = service.parseCacheData(cache: cache, commands: commands);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(2));
      expect(result.containsKey(deviceInfoAction), isTrue);
      expect(result.containsKey(radioInfoAction), isTrue);
    });

    test('returns null when cache is incomplete', () {
      // Arrange
      final commands = [
        MapEntry<JNAPAction, Map<String, dynamic>>(deviceInfoAction, {}),
        MapEntry<JNAPAction, Map<String, dynamic>>(radioInfoAction, {}),
      ];
      final cache = {
        deviceInfoAction.actionValue: {
          'data': {
            'result': 'OK',
            'output': {'serialNumber': 'TEST123'}
          },
        },
        // Missing radioInfoAction
      };

      // Act
      final result = service.parseCacheData(cache: cache, commands: commands);

      // Assert
      expect(result, isNull);
    });

    test('returns null when cache is empty', () {
      // Arrange
      final commands = [
        MapEntry<JNAPAction, Map<String, dynamic>>(deviceInfoAction, {}),
      ];
      final cache = <String, dynamic>{};

      // Act
      final result = service.parseCacheData(cache: cache, commands: commands);

      // Assert
      expect(result, isNull);
    });

    test('returns empty map when commands is empty', () {
      // Arrange
      final commands = <MapEntry<JNAPAction, Map<String, dynamic>>>[];
      final cache = {
        deviceInfoAction.actionValue: {
          'data': {
            'result': 'OK',
            'output': {'serialNumber': 'TEST123'}
          },
        },
      };

      // Act
      final result = service.parseCacheData(cache: cache, commands: commands);

      // Assert
      expect(result, isNotNull);
      expect(result!.isEmpty, isTrue);
    });

    test('excludes entries with null data', () {
      // Arrange
      final commands = [
        MapEntry<JNAPAction, Map<String, dynamic>>(deviceInfoAction, {}),
        MapEntry<JNAPAction, Map<String, dynamic>>(radioInfoAction, {}),
      ];
      final cache = {
        deviceInfoAction.actionValue: {
          'data': {
            'result': 'OK',
            'output': {'serialNumber': 'TEST123'}
          },
        },
        radioInfoAction.actionValue: {
          'data': null, // null data
        },
      };

      // Act
      final result = service.parseCacheData(cache: cache, commands: commands);

      // Assert
      expect(result, isNotNull);
      expect(result!.length, equals(1));
      expect(result.containsKey(deviceInfoAction), isTrue);
      expect(result.containsKey(radioInfoAction), isFalse);
    });
  });

  group('PollingService - updateFernetKeyFromResult', () {
    test('does not throw when device info is present with valid serial number',
        () {
      // Arrange
      final data = <JNAPAction, JNAPResult>{
        JNAPAction.getDeviceInfo:
            PollingTestData.createDeviceInfoSuccess(serialNumber: 'TEST123456'),
      };

      // Act & Assert - should not throw
      expect(
        () => service.updateFernetKeyFromResult(data),
        returnsNormally,
      );
    });

    test('handles missing device info gracefully', () {
      // Arrange
      final data = <JNAPAction, JNAPResult>{
        JNAPAction.getRadioInfo: PollingTestData.createRadioInfoSuccess(),
      };

      // Act & Assert - should not throw
      expect(
        () => service.updateFernetKeyFromResult(data),
        returnsNormally,
      );
    });

    test('handles empty data gracefully', () {
      // Arrange
      final data = <JNAPAction, JNAPResult>{};

      // Act & Assert - should not throw
      expect(
        () => service.updateFernetKeyFromResult(data),
        returnsNormally,
      );
    });

    test('handles device info with empty serial number gracefully', () {
      // Arrange
      final data = <JNAPAction, JNAPResult>{
        JNAPAction.getDeviceInfo:
            PollingTestData.createDeviceInfoSuccess(serialNumber: ''),
      };

      // Act & Assert - should not throw
      expect(
        () => service.updateFernetKeyFromResult(data),
        returnsNormally,
      );
    });

    test('handles device info error result gracefully', () {
      // Arrange
      final data = <JNAPAction, JNAPResult>{
        JNAPAction.getDeviceInfo: const JNAPError(
          result: 'ErrorUnknown',
          error: 'Device info unavailable',
        ),
      };

      // Act & Assert - should not throw
      expect(
        () => service.updateFernetKeyFromResult(data),
        returnsNormally,
      );
    });
  });
}
