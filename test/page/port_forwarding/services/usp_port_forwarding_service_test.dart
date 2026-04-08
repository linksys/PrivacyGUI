import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_service.dart';

class MockUspService extends Mock implements UspService {}

class MockUspDeviceService extends Mock implements UspDeviceService {}

void main() {
  late MockUspService mockUsp;
  late MockUspDeviceService mockDeviceSvc;
  late UspPortForwardingService service;

  setUpAll(() {
    registerFallbackValue(const PortForwarding(items: []));
    registerFallbackValue(const PortTriggering(items: []));
  });

  setUp(() {
    mockUsp = MockUspService();
    mockDeviceSvc = MockUspDeviceService();
    service = UspPortForwardingService(mockUsp, mockDeviceSvc);
  });

  // ---------------------------------------------------------------------------
  // fetch
  // ---------------------------------------------------------------------------

  group('UspPortForwardingService — fetchForwardingRules', () {
    test('fetches and transforms forwarding rules', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => <String, dynamic>{
            'Device.NAT.PortMapping.1.Enable': true,
            'Device.NAT.PortMapping.1.ExternalPort': 80,
            'Device.NAT.PortMapping.1.ExternalPortEndRange': 80,
            'Device.NAT.PortMapping.1.InternalPort': 8080,
            'Device.NAT.PortMapping.1.InternalClient': '192.168.1.100',
            'Device.NAT.PortMapping.1.Protocol': 'TCP',
            'Device.NAT.PortMapping.1.Description': 'HTTP',
          });
      when(() => mockDeviceSvc.buildPortForwardingRuleUIModels(
            any(),
          )).thenReturn([
        PortForwardingRuleUIModel(
          instancePath: 'Device.NAT.PortMapping.1.',
          description: 'HTTP',
          externalPort: 80,
          internalPort: 8080,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ]);

      final result = await service.fetchForwardingRules();

      expect(result, hasLength(1));
      expect(result[0].description, 'HTTP');
      verify(() => mockDeviceSvc.buildPortForwardingRuleUIModels(any()))
          .called(1);
    });
  });

  group('UspPortForwardingService — fetchTriggeringRules', () {
    test('fetches and transforms triggering rules', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => <String, dynamic>{
            'Device.NAT.PortTrigger.1.Enable': true,
            'Device.NAT.PortTrigger.1.Description': 'FTP',
            'Device.NAT.PortTrigger.1.TriggerPort': 21,
            'Device.NAT.PortTrigger.1.TriggerProtocol': 'TCP',
          });
      when(() => mockDeviceSvc.buildPortTriggeringRuleUIModels(
            any(),
          )).thenReturn([
        PortTriggeringRuleUIModel(
          instancePath: 'Device.NAT.PortTrigger.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
        ),
      ]);

      final result = await service.fetchTriggeringRules();

      expect(result, hasLength(1));
      expect(result[0].description, 'FTP');
      verify(() => mockDeviceSvc.buildPortTriggeringRuleUIModels(any()))
          .called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // saveForwardingBatch
  // ---------------------------------------------------------------------------

  group('UspPortForwardingService — saveForwardingBatch', () {
    test('no-op when lists identical', () async {
      final rules = [
        PortForwardingRuleUIModel(
          instancePath: 'path.1.',
          description: 'HTTP',
          externalPort: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ];

      final result = await service.saveForwardingBatch(
        original: rules,
        current: List.of(rules),
      );

      expect(result.added, 0);
      expect(result.updated, 0);
      expect(result.deleted, 0);
    });

    test('delete removes items missing from current', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});

      final original = [
        PortForwardingRuleUIModel(
          instancePath: 'path.1.',
          description: 'HTTP',
          externalPort: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ];

      final result = await service.saveForwardingBatch(
        original: original,
        current: [],
      );

      expect(result.deleted, 1);
      verify(() => mockUsp.delete('path.1.')).called(1);
    });

    test('add creates items with null instancePath', () async {
      when(() => mockUsp.add(any(), any())).thenAnswer((_) async => '');

      final current = [
        PortForwardingRuleUIModel(
          description: 'SSH',
          externalPort: 22,
          internalPort: 22,
          internalClient: '192.168.1.50',
          protocol: 'Both',
          enabled: true,
        ),
      ];

      final result = await service.saveForwardingBatch(
        original: [],
        current: current,
      );

      expect(result.added, 1);
      final captured =
          verify(() => mockUsp.add(captureAny(), captureAny())).captured;
      final params = captured[1] as Map<String, dynamic>;
      expect(params['ExternalPort'], 22);
      expect(params['InternalClient'], '192.168.1.50');
      expect(params['Protocol'], 'Both');
    });

    test('update detects changed content', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {});

      final original = [
        PortForwardingRuleUIModel(
          instancePath: 'path.1.',
          description: 'HTTP',
          externalPort: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ];
      final current = [
        PortForwardingRuleUIModel(
          instancePath: 'path.1.',
          description: 'HTTP',
          externalPort: 8080, // changed
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ];

      final result = await service.saveForwardingBatch(
        original: original,
        current: current,
      );

      expect(result.updated, 1);
    });

    test('mixed batch: delete + add + update', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});
      when(() => mockUsp.add(any(), any())).thenAnswer((_) async => '');
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {});

      final original = [
        PortForwardingRuleUIModel(
          instancePath: 'path.1.',
          description: 'ToDelete',
          externalPort: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
        PortForwardingRuleUIModel(
          instancePath: 'path.2.',
          description: 'ToUpdate',
          externalPort: 443,
          internalPort: 443,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ];
      final current = [
        PortForwardingRuleUIModel(
          instancePath: 'path.2.',
          description: 'ToUpdate',
          externalPort: 443,
          internalPort: 443,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: false, // changed
        ),
        PortForwardingRuleUIModel(
          description: 'NewRule',
          externalPort: 22,
          internalPort: 22,
          internalClient: '192.168.1.50',
          protocol: 'Both',
          enabled: true,
        ),
      ];

      final result = await service.saveForwardingBatch(
        original: original,
        current: current,
      );

      expect(result.deleted, 1);
      expect(result.added, 1);
      expect(result.updated, 1);
    });

    test('multi-item delete uses sequential delay', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});

      final original = [
        PortForwardingRuleUIModel(
          instancePath: 'path.1.',
          description: 'Rule1',
          externalPort: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
        PortForwardingRuleUIModel(
          instancePath: 'path.2.',
          description: 'Rule2',
          externalPort: 443,
          internalPort: 443,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ];

      final result = await service.saveForwardingBatch(
        original: original,
        current: [],
      );

      expect(result.deleted, 2);
      verify(() => mockUsp.delete(any())).called(2);
    });

    test('multi-item add uses sequential delay', () async {
      when(() => mockUsp.add(any(), any())).thenAnswer((_) async => '');

      final current = [
        PortForwardingRuleUIModel(
          description: 'Rule1',
          externalPort: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
        PortForwardingRuleUIModel(
          description: 'Rule2',
          externalPort: 443,
          internalPort: 443,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ];

      final result = await service.saveForwardingBatch(
        original: [],
        current: current,
      );

      expect(result.added, 2);
      verify(() => mockUsp.add(any(), any())).called(2);
    });
  });

  // ---------------------------------------------------------------------------
  // saveTriggeringBatch
  // ---------------------------------------------------------------------------

  group('UspPortForwardingService — saveTriggeringBatch', () {
    test('no-op when lists identical', () async {
      final rules = [
        PortTriggeringRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
          forwardRules: [
            PortTriggerForwardRuleUIModel(
              forwardPort: 1024,
              forwardPortEndRange: 1030,
              forwardProtocol: 'TCP',
            ),
          ],
        ),
      ];

      final result = await service.saveTriggeringBatch(
        original: rules,
        current: List.of(rules),
      );

      expect(result.added, 0);
      expect(result.updated, 0);
      expect(result.deleted, 0);
    });

    test('delete removes items missing from current', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});

      final original = [
        PortTriggeringRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
        ),
      ];

      final result = await service.saveTriggeringBatch(
        original: original,
        current: [],
      );

      expect(result.deleted, 1);
      verify(() => mockUsp.delete('path.1.')).called(1);
    });

    test('add creates parent + forward rules', () async {
      when(() => mockUsp.add(any(), any()))
          .thenAnswer((_) async => 'Device.NAT.PortTrigger.5.');

      final current = [
        PortTriggeringRuleUIModel(
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
          forwardRules: [
            PortTriggerForwardRuleUIModel(
              forwardPort: 1024,
              forwardPortEndRange: 1030,
              forwardProtocol: 'TCP',
            ),
            PortTriggerForwardRuleUIModel(
              forwardPort: 2048,
              forwardProtocol: 'UDP',
            ),
          ],
        ),
      ];

      final result = await service.saveTriggeringBatch(
        original: [],
        current: current,
      );

      expect(result.added, 1);
      // 1 parent add + 2 forward rule adds = 3 total add calls
      verify(() => mockUsp.add(any(), any())).called(3);
    });

    test('add with no forward rules creates parent only', () async {
      when(() => mockUsp.add(any(), any()))
          .thenAnswer((_) async => 'Device.NAT.PortTrigger.5.');

      final current = [
        PortTriggeringRuleUIModel(
          enabled: true,
          description: 'Simple',
          triggerPort: 5060,
          triggerProtocol: 'UDP',
        ),
      ];

      final result = await service.saveTriggeringBatch(
        original: [],
        current: current,
      );

      expect(result.added, 1);
      verify(() => mockUsp.add(any(), any())).called(1);
    });

    test('update detects changed parent fields', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {});

      final original = [
        PortTriggeringRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
        ),
      ];
      final current = [
        PortTriggeringRuleUIModel(
          instancePath: 'path.1.',
          enabled: false, // changed
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
        ),
      ];

      final result = await service.saveTriggeringBatch(
        original: original,
        current: current,
      );

      expect(result.updated, 1);
    });

    test('mixed batch: delete + add + update', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});
      when(() => mockUsp.add(any(), any()))
          .thenAnswer((_) async => 'Device.NAT.PortTrigger.9.');
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {});

      final original = [
        PortTriggeringRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'ToDelete',
          triggerPort: 21,
          triggerProtocol: 'TCP',
        ),
        PortTriggeringRuleUIModel(
          instancePath: 'path.2.',
          enabled: true,
          description: 'ToUpdate',
          triggerPort: 5060,
          triggerProtocol: 'UDP',
        ),
      ];
      final current = [
        PortTriggeringRuleUIModel(
          instancePath: 'path.2.',
          enabled: false, // changed
          description: 'ToUpdate',
          triggerPort: 5060,
          triggerProtocol: 'UDP',
        ),
        PortTriggeringRuleUIModel(
          enabled: true,
          description: 'NewTrigger',
          triggerPort: 80,
          triggerProtocol: 'TCP',
        ),
      ];

      final result = await service.saveTriggeringBatch(
        original: original,
        current: current,
      );

      expect(result.deleted, 1);
      expect(result.added, 1);
      expect(result.updated, 1);
    });

    test('multi-item delete uses sequential delay', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});

      final original = [
        PortTriggeringRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'Trigger1',
          triggerPort: 21,
          triggerProtocol: 'TCP',
        ),
        PortTriggeringRuleUIModel(
          instancePath: 'path.2.',
          enabled: true,
          description: 'Trigger2',
          triggerPort: 5060,
          triggerProtocol: 'UDP',
        ),
      ];

      final result = await service.saveTriggeringBatch(
        original: original,
        current: [],
      );

      expect(result.deleted, 2);
      verify(() => mockUsp.delete(any())).called(2);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  group('UspPortForwardingService — error handling', () {
    test('fetchForwardingRules maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: HTTP error: HTTP 504');

      expect(
        () => service.fetchForwardingRules(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('fetchTriggeringRules maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: HTTP error: HTTP 504');

      expect(
        () => service.fetchTriggeringRules(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('saveForwardingBatch maps USP error to ServiceError', () async {
      when(() => mockUsp.delete(any())).thenThrow(
          'Delete failed: Protocol error: invalid path (code: 7004)');

      final original = [
        PortForwardingRuleUIModel(
          instancePath: 'path.1.',
          description: 'HTTP',
          externalPort: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ];

      expect(
        () => service.saveForwardingBatch(original: original, current: []),
        throwsA(isA<ServiceError>()),
      );
    });

    test('saveTriggeringBatch maps USP error to ServiceError', () async {
      when(() => mockUsp.delete(any())).thenThrow(
          'Delete failed: Protocol error: invalid path (code: 7004)');

      final original = [
        PortTriggeringRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
        ),
      ];

      expect(
        () => service.saveTriggeringBatch(original: original, current: []),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}
