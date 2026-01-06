import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/data/services/firmware_update_service.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_ui_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/_index.dart';
import '../../../test_data/device_manager_test_state.dart';

void main() {
  group('FirmwareUpdateService', () {
    late MockRouterRepository mockRouterRepository;
    late MockDeviceManagerNotifier mockDeviceManagerNotifier;
    late ServiceHelper mockServiceHelper;
    late ProviderContainer container;

    setUp(() {
      // getIt.reset(); // Reset GetIt before each test
      getIt.allowReassignment = true; // Allow reassigning singletons

      // Re-register MockServiceHelper with GetIt after reset for each test
      getIt.registerSingleton<ServiceHelper>(MockServiceHelper());
      mockServiceHelper = getIt.get<ServiceHelper>();

      mockRouterRepository = MockRouterRepository();
      mockDeviceManagerNotifier = MockDeviceManagerNotifier();

      SharedPreferences.setMockInitialValues(
          {}); // Initialize SharedPreferences for testing

      // Stub isSupportNodeFirmwareUpdate
      when(mockServiceHelper.isSupportNodeFirmwareUpdate(any))
          .thenReturn(false);

      // mock device manager build
      when(mockDeviceManagerNotifier.build()).thenReturn(
          DeviceManagerState.fromMap(deviceManagerCherry7TestState));

      container = ProviderContainer(
        overrides: [
          routerRepositoryProvider.overrideWithValue(mockRouterRepository),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        ],
      );
    });

    test('setFirmwareUpdatePolicy calls routerRepo and returns new settings',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);
      final currentSettings = FirmwareUpdateSettings(
        updatePolicy: 'auto',
        autoUpdateWindow: FirmwareAutoUpdateWindow.simple(),
      );
      const newPolicy = 'manual';

      when(mockRouterRepository.send(any,
              auth: anyNamed('auth'),
              cacheLevel: anyNamed('cacheLevel'),
              data: anyNamed('data')))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      final result =
          await service.setFirmwareUpdatePolicy(newPolicy, currentSettings);

      expect(result.updatePolicy, newPolicy);
      verify(mockRouterRepository.send(
        any,
        auth: true,
        cacheLevel: CacheLevel.noCache,
        data: anyNamed('data'),
      )).called(1);
    });

    test('setFirmwareUpdatePolicy throws error when routerRepo.send fails',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);
      final currentSettings = FirmwareUpdateSettings(
        updatePolicy: 'auto',
        autoUpdateWindow: FirmwareAutoUpdateWindow.simple(),
      );
      const newPolicy = 'manual';

      when(mockRouterRepository.send(any,
              auth: anyNamed('auth'),
              cacheLevel: anyNamed('cacheLevel'),
              data: anyNamed('data')))
          .thenThrow(JNAPError(result: '500', error: 'Error'));

      expect(() => service.setFirmwareUpdatePolicy(newPolicy, currentSettings),
          throwsA(isA<JNAPError>()));
    });

    test('fetchAvailableFirmwareUpdates returns correct data on success',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);
      // nodesStatus should the same as deviceManagerState.deviceList
      final master = container.read(deviceManagerProvider).masterDevice;
      final nodesStatus = [
        FirmwareUpdateUIModel(
            deviceId: master.deviceID,
            deviceName: master.getDeviceLocation(),
            isMaster: true,
            lastSuccessfulCheckTime: '',
            availableUpdate: AvailableUpdateUIModel(
                version: '1', date: 'd', description: 'desc'))
      ];

      when(mockRouterRepository.send(any,
              auth: anyNamed('auth'),
              cacheLevel: anyNamed('cacheLevel'),
              fetchRemote: anyNamed('fetchRemote'),
              data: anyNamed('data'),
              retries: anyNamed('retries')))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      when(mockRouterRepository.scheduledCommand(
              action: anyNamed('action'),
              maxRetry: anyNamed('maxRetry'),
              retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
              condition: anyNamed('condition'),
              onCompleted: anyNamed('onCompleted'),
              requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
              auth: anyNamed('auth')))
          .thenAnswer((_) => Stream.value(JNAPSuccess(result: 'OK', output: {
                'lastSuccessfulCheckTime': DateTime.now()
                    .toIso8601String(), // Provide a valid time string
                'availableUpdate': const {
                  'firmwareVersion': '1.0.0',
                  'firmwareDate': '2025-01-01',
                },
              })));
      final (uiModels, isWaitingChildrenAfterUpdating) =
          await service.fetchAvailableFirmwareUpdates(nodesStatus, null);

      expect(uiModels.length, 1);
      expect(uiModels.first.deviceId, master.deviceID);
      expect(isWaitingChildrenAfterUpdating, isFalse);
    });

    test('_isNeedDoFetch returns true when lastCheckTime is old', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final oldCheckTime = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
      final result = service.isNeedDoFetch(lastCheckTime: oldCheckTime);
      expect(result, isTrue);
    });

    test('_isNeedDoFetch returns false when lastCheckTime is recent', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final recentCheckTime = DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch;
      final result = service.isNeedDoFetch(lastCheckTime: recentCheckTime);
      expect(result, isFalse);
    });

    test('_startCheckFirmwareUpdateStatus returns correct data on success',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);

      when(mockRouterRepository.scheduledCommand(
              action: anyNamed('action'),
              maxRetry: anyNamed('maxRetry'),
              retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
              condition: anyNamed('condition'),
              onCompleted: anyNamed('onCompleted'),
              requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
              auth: anyNamed('auth')))
          .thenAnswer((_) => Stream.value(JNAPSuccess(result: 'OK', output: {
                'lastSuccessfulCheckTime': DateTime.now()
                    .toIso8601String(), // Provide a valid time string
                'availableUpdate': const {
                  'firmwareVersion': '1.0.0',
                  'firmwareDate': '2025-01-01',
                },
              })));

      final resultStream = service.startCheckFirmwareUpdateStatus();
      final resultList = await resultStream.toList();

      expect(resultList.length, 1);
      expect(resultList.first.length, 1);
    });

    test('isRecordConsistent returns true when records are consistent', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final list = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];
      final records = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.isRecordConsistent(list, records);

      expect(result, isTrue);
    });

    test('isRecordConsistent returns false when records are inconsistent', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final list = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
      ];
      final records = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.isRecordConsistent(list, records);

      expect(result, isFalse);
    });

    test(
        '_checkFirmwareUpdateComplete returns true when firmware update is complete',
        () {
      final service = container.read(firmwareUpdateServiceProvider);
      final result = JNAPSuccess(result: 'OK', output: const {});

      final records = <FirmwareUpdateUIModel>[];

      final isComplete = service.checkFirmwareUpdateComplete(result, records);

      expect(isComplete, isTrue);
    });

    test(
        '_checkFirmwareUpdateComplete returns false when firmware update is not complete',
        () {
      final service = container.read(firmwareUpdateServiceProvider);
      final result = JNAPSuccess(
          result: 'OK',
          output: FirmwareUpdateStatus(
            lastSuccessfulCheckTime: '2024-12-27T03:49:53Z',
            availableUpdate: FirmwareUpdateData(
                firmwareVersion: '1.0.3.216308',
                firmwareDate: '2024-11-25T06:10:04Z',
                description: ''),
            pendingOperation: FirmwareUpdateOperationStatus(
                operation: 'updating', progressPercent: 50),
            lastOperationFailure: null,
          ).toMap());

      final records = <FirmwareUpdateUIModel>[];

      final isComplete = service.checkFirmwareUpdateComplete(result, records);

      expect(isComplete, isFalse);
    });

    test('updateFirmware returns correct data on success', () async {
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
      ];

      when(mockRouterRepository.send(any,
              auth: anyNamed('auth'),
              cacheLevel: anyNamed('cacheLevel'),
              fetchRemote: anyNamed('fetchRemote'),
              data: anyNamed('data')))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      when(mockRouterRepository.scheduledCommand(
              action: anyNamed('action'),
              maxRetry: anyNamed('maxRetry'),
              retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
              condition: anyNamed('condition'),
              onCompleted: anyNamed('onCompleted'),
              requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
              auth: anyNamed('auth')))
          .thenAnswer(
              (_) => Stream.value(JNAPSuccess(result: 'OK', output: const {})));

      final resultStream =
          service.updateFirmware(nodesStatus, (exceedMaxRetry) {});
      final resultList = await resultStream.toList();

      expect(resultList.length, 1);
      expect(resultList.first.length, 1);
    });

    test('finishFirmwareUpdate sets pFWUpdated to true in SharedPreferences',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);
      await service.finishFirmwareUpdate();
      final sharedPreferences = await SharedPreferences.getInstance();
      expect(sharedPreferences.getBool(pFWUpdated), isTrue);
    });

    test('fetchFirmwareUpdateStream returns correct data on success', () async {
      final service = container.read(firmwareUpdateServiceProvider);

      final nodesStatus = [
        FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: '',
            availableUpdate: AvailableUpdateUIModel(
                version: '1', date: 'd', description: 'desc'))
      ];

      when(mockRouterRepository.send(any,
              auth: anyNamed('auth'),
              cacheLevel: anyNamed('cacheLevel'),
              fetchRemote: anyNamed('fetchRemote'),
              data: anyNamed('data'),
              retries: anyNamed('retries')))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      when(mockRouterRepository.scheduledCommand(
              action: anyNamed('action'),
              maxRetry: anyNamed('maxRetry'),
              retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
              condition: anyNamed('condition'),
              onCompleted: anyNamed('onCompleted'),
              requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
              auth: anyNamed('auth')))
          .thenAnswer(
              (_) => Stream.value(JNAPSuccess(result: 'OK', output: const {})));

      final resultStream = service.fetchFirmwareUpdateStream(
          force: true, retry: 2, currentNodesStatus: nodesStatus);
      final resultList = await resultStream.toList();

      expect(resultList.length, 1);
      expect(resultList.first.length, 1);
    });

    test('getAvailableUpdateNumber returns correct count', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = [
        FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: '',
            availableUpdate: AvailableUpdateUIModel(
                version: '1', date: 'd', description: 'desc')),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.getAvailableUpdateNumber(nodesStatus);

      expect(result, 1);
    });

    test('isFailedCheckFirmwareUpdate returns true if any node has failed', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: '',
            lastOperationFailure: 'error'),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.isFailedCheckFirmwareUpdate(nodesStatus);

      expect(result, isTrue);
    });

    test('isFailedCheckFirmwareUpdate returns false if no node has failed', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.isFailedCheckFirmwareUpdate(nodesStatus);

      expect(result, isFalse);
    });
  });

  group('FirmwareUpdateService with node support', () {
    late MockRouterRepository mockRouterRepository;
    late MockDeviceManagerNotifier mockDeviceManagerNotifier;
    late ServiceHelper mockServiceHelper;
    late ProviderContainer container;

    setUp(() {
      getIt.allowReassignment = true;
      getIt.registerSingleton<ServiceHelper>(MockServiceHelper());
      mockServiceHelper = getIt.get<ServiceHelper>();

      mockRouterRepository = MockRouterRepository();
      mockDeviceManagerNotifier = MockDeviceManagerNotifier();

      SharedPreferences.setMockInitialValues({});

      // Stub isSupportNodeFirmwareUpdate to TRUE
      when(mockServiceHelper.isSupportNodeFirmwareUpdate(any)).thenReturn(true);

      when(mockDeviceManagerNotifier.build()).thenReturn(
          DeviceManagerState.fromMap(deviceManagerCherry7TestState));

      container = ProviderContainer(
        overrides: [
          routerRepositoryProvider.overrideWithValue(mockRouterRepository),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        ],
      );
    });

    test('setFirmwareUpdatePolicy calls routerRepo and returns new settings',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);
      final currentSettings = FirmwareUpdateSettings(
        updatePolicy: 'auto',
        autoUpdateWindow: FirmwareAutoUpdateWindow.simple(),
      );
      const newPolicy = 'manual';

      when(mockRouterRepository.send(any,
              auth: anyNamed('auth'),
              cacheLevel: anyNamed('cacheLevel'),
              data: anyNamed('data')))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      final result =
          await service.setFirmwareUpdatePolicy(newPolicy, currentSettings);

      expect(result.updatePolicy, newPolicy);
      verify(mockRouterRepository.send(
        any,
        auth: true,
        cacheLevel: CacheLevel.noCache,
        data: anyNamed('data'),
      )).called(1);
    });

    test('setFirmwareUpdatePolicy throws error when routerRepo.send fails',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);
      final currentSettings = FirmwareUpdateSettings(
        updatePolicy: 'auto',
        autoUpdateWindow: FirmwareAutoUpdateWindow.simple(),
      );
      const newPolicy = 'manual';

      when(mockRouterRepository.send(any,
              auth: anyNamed('auth'),
              cacheLevel: anyNamed('cacheLevel'),
              data: anyNamed('data')))
          .thenThrow(JNAPError(result: '500', error: 'Error'));

      expect(() => service.setFirmwareUpdatePolicy(newPolicy, currentSettings),
          throwsA(isA<JNAPError>()));
    });

    test('fetchAvailableFirmwareUpdates returns correct data on success',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);
      // nodesStatus should the same as deviceManagerState.deviceList
      final master = container.read(deviceManagerProvider).masterDevice;
      final nodesStatus = [
        FirmwareUpdateUIModel(
            deviceId: master.deviceID,
            deviceName: master.getDeviceLocation(),
            isMaster: true,
            lastSuccessfulCheckTime: '',
            availableUpdate: AvailableUpdateUIModel(
                version: '1', date: 'd', description: 'desc'))
      ];

      when(mockRouterRepository.send(any,
              auth: anyNamed('auth'),
              cacheLevel: anyNamed('cacheLevel'),
              fetchRemote: anyNamed('fetchRemote'),
              data: anyNamed('data'),
              retries: anyNamed('retries')))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      when(mockRouterRepository.scheduledCommand(
              action: anyNamed('action'),
              maxRetry: anyNamed('maxRetry'),
              retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
              condition: anyNamed('condition'),
              onCompleted: anyNamed('onCompleted'),
              requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
              auth: anyNamed('auth')))
          .thenAnswer((_) => Stream.value(JNAPSuccess(result: 'OK', output: {
                'firmwareUpdateStatus': [
                  {
                    'deviceUUID': master.deviceID,
                    'lastSuccessfulCheckTime': DateTime.now().toIso8601String(),
                    'availableUpdate': const {
                      'firmwareVersion': '1.0.0',
                      'firmwareDate': '2025-01-01',
                    },
                  }
                ]
              })));
      final (uiModels, isWaitingChildrenAfterUpdating) =
          await service.fetchAvailableFirmwareUpdates(nodesStatus, null);

      expect(uiModels.length, 1);
      expect(uiModels.first.deviceId, master.deviceID);
      expect(isWaitingChildrenAfterUpdating, isFalse);
    });

    test('_isNeedDoFetch returns true when lastCheckTime is old', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final oldCheckTime = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
      final result = service.isNeedDoFetch(lastCheckTime: oldCheckTime);
      expect(result, isTrue);
    });

    test('_isNeedDoFetch returns false when lastCheckTime is recent', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final recentCheckTime = DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch;
      final result = service.isNeedDoFetch(lastCheckTime: recentCheckTime);
      expect(result, isFalse);
    });

    test('isRecordConsistent returns true when records are consistent', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final list = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];
      final records = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.isRecordConsistent(list, records);

      expect(result, isTrue);
    });

    test('isRecordConsistent returns false when records are inconsistent', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final list = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
      ];
      final records = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.isRecordConsistent(list, records);

      expect(result, isFalse);
    });

    test('updateFirmware returns correct data on success', () async {
      const data = {
        "firmwareUpdateStatus": [
          {
            "deviceUUID": "57be989c-ba16-4caf-ae81-741213214844",
            "lastSuccessfulCheckTime": "2025-11-17T06:38:43Z",
            "availableUpdate": {
              "firmwareVersion": "1-0-6-25111211",
              "firmwareDate": "2025-11-13T01:39:47Z",
              "description": ""
            }
          },
          {
            "deviceUUID": "97095913-0394-433c-b18a-74121321488c",
            "lastSuccessfulCheckTime": "2025-11-17T06:38:43Z",
            "availableUpdate": {
              "firmwareVersion": "1-0-6-25111211",
              "firmwareDate": "2025-11-13T01:39:47Z",
              "description": ""
            }
          },
          {
            "deviceUUID": "c9eba5c1-cc07-4825-aa7a-74121321475c",
            "lastSuccessfulCheckTime": "2025-11-17T06:38:43Z",
            "availableUpdate": {
              "firmwareVersion": "1-0-6-25111211",
              "firmwareDate": "2025-11-13T01:39:47Z",
              "description": ""
            }
          }
        ]
      };
      final firmwareUpdateStatusList = data['firmwareUpdateStatus']!
          .map<NodesFirmwareUpdateStatus>(
              (e) => NodesFirmwareUpdateStatus.fromMap(e))
          .toList();
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = firmwareUpdateStatusList
          .mapIndexed((index, e) => FirmwareUpdateUIModel(
                deviceId: e.deviceUUID,
                deviceName: 'device $index',
                isMaster: index == 0,
                lastSuccessfulCheckTime: e.lastSuccessfulCheckTime,
              ))
          .toList();

      when(mockRouterRepository.send(any,
              auth: anyNamed('auth'),
              cacheLevel: anyNamed('cacheLevel'),
              fetchRemote: anyNamed('fetchRemote'),
              data: anyNamed('data')))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      when(mockRouterRepository.scheduledCommand(
              action: anyNamed('action'),
              maxRetry: anyNamed('maxRetry'),
              retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
              condition: anyNamed('condition'),
              onCompleted: anyNamed('onCompleted'),
              requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
              auth: anyNamed('auth')))
          .thenAnswer(
              (_) => Stream.value(JNAPSuccess(result: 'OK', output: data)));

      final resultStream =
          service.updateFirmware(nodesStatus, (exceedMaxRetry) {});
      final resultList = await resultStream.toList();

      expect(resultList.length, 1);
      expect(resultList.first.length, 3);
    });

    test('finishFirmwareUpdate sets pFWUpdated to true in SharedPreferences',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);
      await service.finishFirmwareUpdate();
      final sharedPreferences = await SharedPreferences.getInstance();
      expect(sharedPreferences.getBool(pFWUpdated), isTrue);
    });

    test('getAvailableUpdateNumber returns correct count', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = [
        FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: '',
            availableUpdate: AvailableUpdateUIModel(
                version: '1', date: 'd', description: 'desc')),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.getAvailableUpdateNumber(nodesStatus);

      expect(result, 1);
    });

    test('isFailedCheckFirmwareUpdate returns true if any node has failed', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: '',
            lastOperationFailure: 'error'),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.isFailedCheckFirmwareUpdate(nodesStatus);

      expect(result, isTrue);
    });

    test('isFailedCheckFirmwareUpdate returns false if no node has failed', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.isFailedCheckFirmwareUpdate(nodesStatus);

      expect(result, isFalse);
    });

    test('isFailedCheckFirmwareUpdate returns false if no node has failed', () {
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = [
        const FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: ''),
        const FirmwareUpdateUIModel(
            deviceId: '2',
            deviceName: 'd2',
            isMaster: false,
            lastSuccessfulCheckTime: ''),
      ];

      final result = service.isFailedCheckFirmwareUpdate(nodesStatus);

      expect(result, isFalse);
    });

    test('fetchFirmwareUpdateStream calls nodesUpdateFirmwareNow', () async {
      final service = container.read(firmwareUpdateServiceProvider);
      final nodesStatus = [
        FirmwareUpdateUIModel(
            deviceId: '1',
            deviceName: 'd1',
            isMaster: true,
            lastSuccessfulCheckTime: '',
            availableUpdate: AvailableUpdateUIModel(
                version: '1', date: 'd', description: 'desc'))
      ];

      when(mockRouterRepository.send(
        any,
        data: anyNamed('data'),
        cacheLevel: anyNamed('cacheLevel'),
        fetchRemote: anyNamed('fetchRemote'),
        auth: anyNamed('auth'),
        retries: anyNamed('retries'),
      )).thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      when(mockRouterRepository.scheduledCommand(
              action: anyNamed('action'),
              maxRetry: anyNamed('maxRetry'),
              retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
              condition: anyNamed('condition'),
              onCompleted: anyNamed('onCompleted'),
              requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
              auth: anyNamed('auth')))
          .thenAnswer((_) => Stream.value(JNAPSuccess(
              result: 'OK', output: const {'firmwareUpdateStatus': []})));

      final resultStream = service.fetchFirmwareUpdateStream(
          force: true, retry: 2, currentNodesStatus: nodesStatus);
      await resultStream.toList();

      verify(mockRouterRepository.send(
        JNAPAction.nodesUpdateFirmwareNow,
        data: {'onlyCheck': true},
        cacheLevel: CacheLevel.noCache,
        fetchRemote: true,
        auth: true,
        retries: 0,
      )).called(1);
    });

    test('_startCheckFirmwareUpdateStatus returns correct data on success',
        () async {
      final service = container.read(firmwareUpdateServiceProvider);

      when(mockRouterRepository.scheduledCommand(
              action: anyNamed('action'),
              maxRetry: anyNamed('maxRetry'),
              retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
              condition: anyNamed('condition'),
              onCompleted: anyNamed('onCompleted'),
              requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
              auth: anyNamed('auth')))
          .thenAnswer((invocation) {
        expect(invocation.namedArguments[#action],
            JNAPAction.getNodesFirmwareUpdateStatus);
        return Stream.value(JNAPSuccess(result: 'OK', output: {
          'firmwareUpdateStatus': [
            {
              'deviceUUID': 'uuid1',
              'lastSuccessfulCheckTime': DateTime.now().toIso8601String(),
              'availableUpdate': const {
                'firmwareVersion': '1.0.0',
                'firmwareDate': '2025-01-01',
              },
            }
          ]
        }));
      });

      final resultStream = service.startCheckFirmwareUpdateStatus();
      final resultList = await resultStream.toList();

      expect(resultList.length, 1);
      expect(resultList.first.length, 1);
      expect(resultList.first.first.deviceId, 'uuid1');
    });

    test(
        '_checkFirmwareUpdateComplete returns false when firmware update is not complete for nodes',
        () {
      final service = container.read(firmwareUpdateServiceProvider);
      final result = JNAPSuccess(result: 'OK', output: const {
        'firmwareUpdateStatus': [
          {
            'deviceUUID': 'uuid1',
            'lastSuccessfulCheckTime': '2024-12-27T03:49:53Z',
            'availableUpdate': {
              'firmwareVersion': '1.0.3.216308',
              'firmwareDate': '2024-11-25T06:10:04Z',
              'description': ''
            },
            'pendingOperation': {
              'operation': 'updating',
              'progressPercent': 50
            },
            'lastOperationFailure': null,
          }
        ]
      });

      final records = <FirmwareUpdateUIModel>[];

      final isComplete = service.checkFirmwareUpdateComplete(result, records);

      expect(isComplete, isFalse);
    });

    test(
        '_checkFirmwareUpdateComplete returns true when firmware update is complete for nodes',
        () {
      final service = container.read(firmwareUpdateServiceProvider);
      final result = JNAPSuccess(result: 'OK', output: const {
        'firmwareUpdateStatus': [
          {
            'deviceUUID': 'uuid1',
            'lastSuccessfulCheckTime': '2024-12-27T03:49:53Z',
            'availableUpdate': null,
            'pendingOperation': null,
            'lastOperationFailure': null,
          }
        ]
      });

      final records = <FirmwareUpdateUIModel>[];

      final isComplete = service.checkFirmwareUpdateComplete(result, records);

      expect(isComplete, isTrue);
    });
  });
}
