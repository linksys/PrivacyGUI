import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';
import 'package:privacy_gui/page/nodes/services/add_wired_nodes_service.dart';

import '../../../mocks/test_data/add_wired_nodes_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late AddWiredNodesService service;
  late MockRouterRepository mockRouterRepository;

  setUp(() {
    mockRouterRepository = MockRouterRepository();
    service = AddWiredNodesService(mockRouterRepository);
  });

  group('AddWiredNodesService', () {
    group('setAutoOnboardingEnabled', () {
      test('sends JNAP action with enabled=true', () async {
        when(() => mockRouterRepository.send(
                  JNAPAction.setWiredAutoOnboardingSettings,
                  data: {'isAutoOnboardingEnabled': true},
                  auth: true,
                ))
            .thenAnswer((_) async =>
                AddWiredNodesTestData.createWiredAutoOnboardingSettingsSuccess(
                    isEnabled: true));

        await service.setAutoOnboardingEnabled(true);

        verify(() => mockRouterRepository.send(
              JNAPAction.setWiredAutoOnboardingSettings,
              data: {'isAutoOnboardingEnabled': true},
              auth: true,
            )).called(1);
      });

      test('sends JNAP action with enabled=false', () async {
        when(() => mockRouterRepository.send(
                  JNAPAction.setWiredAutoOnboardingSettings,
                  data: {'isAutoOnboardingEnabled': false},
                  auth: true,
                ))
            .thenAnswer((_) async =>
                AddWiredNodesTestData.createWiredAutoOnboardingSettingsSuccess(
                    isEnabled: false));

        await service.setAutoOnboardingEnabled(false);

        verify(() => mockRouterRepository.send(
              JNAPAction.setWiredAutoOnboardingSettings,
              data: {'isAutoOnboardingEnabled': false},
              auth: true,
            )).called(1);
      });

      test('throws ServiceError on JNAP error', () async {
        when(() => mockRouterRepository.send(
              JNAPAction.setWiredAutoOnboardingSettings,
              data: any(named: 'data'),
              auth: true,
            )).thenThrow(AddWiredNodesTestData.createJNAPError());

        expect(
          () => service.setAutoOnboardingEnabled(true),
          throwsA(isA<ServiceError>()),
        );
      });
    });

    group('getAutoOnboardingEnabled', () {
      test('returns true when enabled', () async {
        when(() => mockRouterRepository.send(
                  JNAPAction.getWiredAutoOnboardingSettings,
                  auth: true,
                ))
            .thenAnswer((_) async =>
                AddWiredNodesTestData.createWiredAutoOnboardingSettingsSuccess(
                    isEnabled: true));

        final result = await service.getAutoOnboardingEnabled();

        expect(result, isTrue);
      });

      test('returns false when disabled', () async {
        when(() => mockRouterRepository.send(
                  JNAPAction.getWiredAutoOnboardingSettings,
                  auth: true,
                ))
            .thenAnswer((_) async =>
                AddWiredNodesTestData.createWiredAutoOnboardingSettingsSuccess(
                    isEnabled: false));

        final result = await service.getAutoOnboardingEnabled();

        expect(result, isFalse);
      });

      test('returns false when field is missing', () async {
        when(() => mockRouterRepository.send(
              JNAPAction.getWiredAutoOnboardingSettings,
              auth: true,
            )).thenAnswer((_) async => JNAPSuccess(result: 'ok', output: {}));

        final result = await service.getAutoOnboardingEnabled();

        expect(result, isFalse);
      });

      test('throws ServiceError on JNAP error', () async {
        when(() => mockRouterRepository.send(
              JNAPAction.getWiredAutoOnboardingSettings,
              auth: true,
            )).thenThrow(AddWiredNodesTestData.createJNAPError());

        expect(
          () => service.getAutoOnboardingEnabled(),
          throwsA(isA<ServiceError>()),
        );
      });
    });

    group('pollBackhaulChanges', () {
      test('returns stream of BackhaulPollResult', () async {
        final backhaulDevice = AddWiredNodesTestData.createBackhaulDevice(
          deviceUUID: 'new-uuid',
          connectionType: 'Wired',
          timestamp:
              DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        );

        when(() => mockRouterRepository.scheduledCommand(
                  action: JNAPAction.getBackhaulInfo,
                  auth: true,
                  firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
                  retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
                  maxRetry: any(named: 'maxRetry'),
                  condition: any(named: 'condition'),
                  onCompleted: any(named: 'onCompleted'),
                ))
            .thenAnswer((_) =>
                Stream.value(AddWiredNodesTestData.createBackhaulInfoSuccess(
                  devices: [backhaulDevice],
                )));

        final snapshot = <BackhaulInfoUIModel>[];
        final stream = service.pollBackhaulChanges(snapshot);
        final results = await stream.toList();

        expect(results, hasLength(1));
        expect(results.first, isA<BackhaulPollResult>());
        expect(results.first.backhaulList, hasLength(1));
        expect(results.first.backhaulList.first.deviceUUID, 'new-uuid');
      });

      test('calculates foundCounting for new nodes', () async {
        final newDevice = AddWiredNodesTestData.createBackhaulDevice(
          deviceUUID: 'new-uuid',
          connectionType: 'Wired',
          timestamp:
              DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        );

        when(() => mockRouterRepository.scheduledCommand(
                  action: JNAPAction.getBackhaulInfo,
                  auth: true,
                  firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
                  retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
                  maxRetry: any(named: 'maxRetry'),
                  condition: any(named: 'condition'),
                  onCompleted: any(named: 'onCompleted'),
                ))
            .thenAnswer((_) =>
                Stream.value(AddWiredNodesTestData.createBackhaulInfoSuccess(
                  devices: [newDevice],
                )));

        final snapshot = <BackhaulInfoUIModel>[];
        final stream = service.pollBackhaulChanges(snapshot);
        final results = await stream.toList();

        expect(results.first.foundCounting, greaterThan(0));
        expect(results.first.anyOnboarded, isTrue);
      });

      test('uses shorter retries when refreshing', () async {
        when(() => mockRouterRepository.scheduledCommand(
                  action: JNAPAction.getBackhaulInfo,
                  auth: true,
                  firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
                  retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
                  maxRetry: 6, // refreshing uses 6 retries
                  condition: any(named: 'condition'),
                  onCompleted: any(named: 'onCompleted'),
                ))
            .thenAnswer((_) => Stream.value(
                AddWiredNodesTestData.createBackhaulInfoSuccess()));

        final stream = service.pollBackhaulChanges([], refreshing: true);
        await stream.toList();

        verify(() => mockRouterRepository.scheduledCommand(
              action: JNAPAction.getBackhaulInfo,
              auth: true,
              firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
              retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
              maxRetry: 6,
              condition: any(named: 'condition'),
              onCompleted: any(named: 'onCompleted'),
            )).called(1);
      });

      test('uses longer retries when not refreshing', () async {
        when(() => mockRouterRepository.scheduledCommand(
                  action: JNAPAction.getBackhaulInfo,
                  auth: true,
                  firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
                  retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
                  maxRetry: 60, // normal uses 60 retries
                  condition: any(named: 'condition'),
                  onCompleted: any(named: 'onCompleted'),
                ))
            .thenAnswer((_) => Stream.value(
                AddWiredNodesTestData.createBackhaulInfoSuccess()));

        final stream = service.pollBackhaulChanges([], refreshing: false);
        await stream.toList();

        verify(() => mockRouterRepository.scheduledCommand(
              action: JNAPAction.getBackhaulInfo,
              auth: true,
              firstDelayInMilliSec: any(named: 'firstDelayInMilliSec'),
              retryDelayInMilliSec: any(named: 'retryDelayInMilliSec'),
              maxRetry: 60,
              condition: any(named: 'condition'),
              onCompleted: any(named: 'onCompleted'),
            )).called(1);
      });
    });

    group('fetchNodes', () {
      test('returns list of LinksysDevice filtered by nodeType', () async {
        final nodeDevice = AddWiredNodesTestData.createDevice(
          deviceID: 'node-123',
          nodeType: 'Slave',
        );
        final nonNodeDevice = AddWiredNodesTestData.createDevice(
          deviceID: 'device-456',
          nodeType: null,
        );

        when(() => mockRouterRepository.send(
                  JNAPAction.getDevices,
                  fetchRemote: true,
                  auth: true,
                ))
            .thenAnswer((_) async => AddWiredNodesTestData.createDevicesSuccess(
                  devices: [nodeDevice, nonNodeDevice],
                ));

        final result = await service.fetchNodes();

        expect(result, hasLength(1));
        expect(result.first.deviceID, 'node-123');
      });

      test('returns empty list on error', () async {
        when(() => mockRouterRepository.send(
              JNAPAction.getDevices,
              fetchRemote: true,
              auth: true,
            )).thenThrow(AddWiredNodesTestData.createJNAPError());

        final result = await service.fetchNodes();

        expect(result, isEmpty);
      });

      test('returns empty list when devices field is empty', () async {
        when(() => mockRouterRepository.send(
                  JNAPAction.getDevices,
                  fetchRemote: true,
                  auth: true,
                ))
            .thenAnswer((_) async =>
                AddWiredNodesTestData.createDevicesSuccess(devices: []));

        final result = await service.fetchNodes();

        expect(result, isEmpty);
      });
    });
  });
}
