import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_service.dart';

class MockUspClient extends Mock implements UspClient {}

// ---------------------------------------------------------------------------
// WASM v0.11.0 response helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> uspSuccess({Map<String, dynamic> data = const {}}) => {
      'success': true,
      'result': {'data': data},
    };

Map<String, dynamic> uspAddSuccess(List<String> instances) => {
      'success': true,
      'result': {
        'data': {
          'affectedCount': instances.length,
          'instances': instances,
        },
      },
    };

Map<String, dynamic> uspFailure(
        {String path = 'bulk_operation',
        int errorCode = 7004,
        String errorMessage = 'Operation failed'}) =>
    {
      'success': false,
      'result': {
        'data': <String, dynamic>{},
        'error': {
          path: {
            'errorCode': errorCode,
            'errorMessage': errorMessage,
          }
        },
      },
    };

void main() {
  late MockUspClient mockUsp;
  late UspPortForwardingService service;

  setUpAll(() {
    registerFallbackValue(const PortForwarding(items: []));
    registerFallbackValue(const PortTriggering(items: []));
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    mockUsp = MockUspClient();
    service = UspPortForwardingService(mockUsp);
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

      final result = await service.fetchForwardingRules();

      expect(result, hasLength(1));
      expect(result[0].description, 'HTTP');
      expect(result[0].externalPort, 80);
      expect(result[0].protocol, 'TCP');
    });
  });

  group('UspPortForwardingService — fetchTriggeringRules', () {
    test('fetches and transforms triggering rules', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => <String, dynamic>{
            'Device.NAT.PortTrigger.1.Enable': true,
            'Device.NAT.PortTrigger.1.Description': 'FTP',
            'Device.NAT.PortTrigger.1.Port': 21,
            'Device.NAT.PortTrigger.1.PortEndRange': 21,
            'Device.NAT.PortTrigger.1.Protocol': 'TCP',
          });

      final result = await service.fetchTriggeringRules();

      expect(result, hasLength(1));
      expect(result[0].description, 'FTP');
      expect(result[0].triggerPort, 21);
    });
  });

  // ---------------------------------------------------------------------------
  // immediateToggleForwarding
  // ---------------------------------------------------------------------------

  group('UspPortForwardingService — immediateToggleForwarding', () {
    test('succeeds on UspSuccess', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

      await service.immediateToggleForwarding('path.1.', false);

      verify(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .called(1);
    });

    test('throws on UspFailure', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspFailure());

      expect(
        () => service.immediateToggleForwarding('path.1.', false),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // immediateAddForwarding
  // ---------------------------------------------------------------------------

  group('UspPortForwardingService — immediateAddForwarding', () {
    test('succeeds on UspSuccess', () async {
      when(() => mockUsp.add(any())).thenAnswer(
          (_) async => uspAddSuccess(['Device.NAT.PortMapping.1.']));

      await service.immediateAddForwarding(
        externalPort: 80,
        internalPort: 80,
        internalClient: '192.168.1.100',
        protocol: 'TCP',
      );

      verify(() => mockUsp.add(any())).called(1);
    });

    test('throws on UspFailure', () async {
      when(() => mockUsp.add(any()))
          .thenAnswer((_) async => uspFailure(errorMessage: 'Add rejected'));

      expect(
        () => service.immediateAddForwarding(
          externalPort: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
        ),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // immediateToggleTriggering
  // ---------------------------------------------------------------------------

  group('UspPortForwardingService — immediateToggleTriggering', () {
    test('succeeds on UspSuccess', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

      await service.immediateToggleTriggering('path.1.', true);

      verify(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .called(1);
    });

    test('throws on UspFailure', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspFailure());

      expect(
        () => service.immediateToggleTriggering('path.1.', true),
        throwsA(isA<UspCompleteFailureError>()),
      );
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
      when(() => mockUsp.delete(any())).thenAnswer((_) async => uspSuccess());

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
      verify(() => mockUsp.delete(any())).called(1);
    });

    test('add creates items with null instancePath', () async {
      when(() => mockUsp.add(any())).thenAnswer(
          (_) async => uspAddSuccess(['Device.NAT.PortMapping.1.']));

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
      final captured = verify(() => mockUsp.add(captureAny())).captured;
      final items = captured[0] as List<Map<String, dynamic>>;
      final params = items[0]['params'] as Map<String, dynamic>;
      expect(params['ExternalPort'], 22);
      expect(params['InternalClient'], '192.168.1.50');
      expect(params['Protocol'], 'Both');
    });

    test('update detects changed content', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

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
      when(() => mockUsp.delete(any())).thenAnswer((_) async => uspSuccess());
      when(() => mockUsp.add(any())).thenAnswer(
          (_) async => uspAddSuccess(['Device.NAT.PortMapping.2.']));
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

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

    test('multi-item delete uses reverse-order sequential calls', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => uspSuccess());

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

    test('multi-item add sends single batch call', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => uspAddSuccess(
          ['Device.NAT.PortMapping.1.', 'Device.NAT.PortMapping.2.']));

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
      verify(() => mockUsp.add(any())).called(1);
    });

    test('throws when all batch operations fail', () async {
      when(() => mockUsp.delete(any()))
          .thenAnswer((_) async => uspFailure(errorMessage: 'Delete rejected'));

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
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('does not throw when some operations succeed', () async {
      // delete fails, add succeeds
      when(() => mockUsp.delete(any()))
          .thenAnswer((_) async => uspFailure(errorMessage: 'Delete rejected'));
      when(() => mockUsp.add(any())).thenAnswer(
          (_) async => uspAddSuccess(['Device.NAT.PortMapping.2.']));

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
      ];
      final current = [
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

      // Completes without throwing
      expect(result.deleted, 1);
      expect(result.added, 1);
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
      when(() => mockUsp.delete(any())).thenAnswer((_) async => uspSuccess());

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
      verify(() => mockUsp.delete(any())).called(1);
    });

    test('add creates parent + forward rules', () async {
      when(() => mockUsp.add(any())).thenAnswer(
          (_) async => uspAddSuccess(['Device.NAT.PortTrigger.5.']));

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
      verify(() => mockUsp.add(any())).called(3);
    });

    test('add with no forward rules creates parent only', () async {
      when(() => mockUsp.add(any())).thenAnswer(
          (_) async => uspAddSuccess(['Device.NAT.PortTrigger.5.']));

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
      verify(() => mockUsp.add(any())).called(1);
    });

    test('add skips forward rules when parent ADD fails', () async {
      when(() => mockUsp.add(any()))
          .thenAnswer((_) async => uspFailure(errorMessage: 'Add rejected'));

      final current = [
        PortTriggeringRuleUIModel(
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
          forwardRules: [
            PortTriggerForwardRuleUIModel(
              forwardPort: 1024,
              forwardProtocol: 'TCP',
            ),
          ],
        ),
      ];

      // All ops failed → throws
      expect(
        () => service.saveTriggeringBatch(original: [], current: current),
        throwsA(isA<UspCompleteFailureError>()),
      );

      // Only parent add called, forward rule add NOT called
      verify(() => mockUsp.add(any())).called(1);
    });

    test('update detects changed parent fields', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

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

    // -------------------------------------------------------------------------
    // #1061 regression: editing the forwarded-port of an EXISTING trigger must
    // persist. Before the fix, saveTriggeringBatch only patched parent-level
    // fields and never touched the nested Rule.* sub-table, so the edit was
    // silently dropped.
    // -------------------------------------------------------------------------

    test('#1061: editing forwarded-port of existing rule issues Set on Rule.*',
        () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

      final original = [
        PortTriggeringRuleUIModel(
          instancePath: 'Device.NAT.PortTrigger.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
          forwardRules: const [
            PortTriggerForwardRuleUIModel(
              instancePath: 'Device.NAT.PortTrigger.1.Rule.1.',
              forwardPort: 1024,
              forwardPortEndRange: 1030,
              forwardProtocol: 'TCP',
            ),
          ],
        ),
      ];
      final current = [
        PortTriggeringRuleUIModel(
          instancePath: 'Device.NAT.PortTrigger.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
          forwardRules: const [
            PortTriggerForwardRuleUIModel(
              instancePath: 'Device.NAT.PortTrigger.1.Rule.1.',
              forwardPort: 2048, // changed
              forwardPortEndRange: 2050, // changed
              forwardProtocol: 'UDP', // changed
            ),
          ],
        ),
      ];

      await service.saveTriggeringBatch(original: original, current: current);

      // The forward-rule edit is reconciled via an in-place Set carrying the
      // Rule.{j} param paths with the NEW values.
      final captured = verify(() => mockUsp.set(captureAny())).captured;
      expect(captured, hasLength(1));
      final params = captured.first as Map<String, dynamic>;
      expect(params['Device.NAT.PortTrigger.1.Rule.1.Port'], 2048);
      expect(params['Device.NAT.PortTrigger.1.Rule.1.PortEndRange'], 2050);
      expect(params['Device.NAT.PortTrigger.1.Rule.1.Protocol'], 'UDP');
    });

    test('#1061: adding a forward rule to existing trigger calls add on Rule.',
        () async {
      when(() => mockUsp.add(any())).thenAnswer(
          (_) async => uspAddSuccess(['Device.NAT.PortTrigger.1.Rule.2.']));

      final original = [
        PortTriggeringRuleUIModel(
          instancePath: 'Device.NAT.PortTrigger.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
          forwardRules: const [
            PortTriggerForwardRuleUIModel(
              instancePath: 'Device.NAT.PortTrigger.1.Rule.1.',
              forwardPort: 1024,
              forwardProtocol: 'TCP',
            ),
          ],
        ),
      ];
      final current = [
        PortTriggeringRuleUIModel(
          instancePath: 'Device.NAT.PortTrigger.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
          forwardRules: const [
            PortTriggerForwardRuleUIModel(
              instancePath: 'Device.NAT.PortTrigger.1.Rule.1.',
              forwardPort: 1024,
              forwardProtocol: 'TCP',
            ),
            PortTriggerForwardRuleUIModel(
              // new local rule, no instancePath yet
              forwardPort: 3000,
              forwardProtocol: 'UDP',
            ),
          ],
        ),
      ];

      await service.saveTriggeringBatch(original: original, current: current);

      final captured = verify(() => mockUsp.add(captureAny())).captured;
      expect(captured, hasLength(1));
      final items = captured.first as List;
      expect(items.first['path'], 'Device.NAT.PortTrigger.1.Rule.');
      expect(items.first['params']['Port'], 3000);
      expect(items.first['params']['Protocol'], 'UDP');
    });

    test('#1061: removing a forward rule from existing trigger calls delete',
        () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => uspSuccess());

      final original = [
        PortTriggeringRuleUIModel(
          instancePath: 'Device.NAT.PortTrigger.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
          forwardRules: const [
            PortTriggerForwardRuleUIModel(
              instancePath: 'Device.NAT.PortTrigger.1.Rule.1.',
              forwardPort: 1024,
              forwardProtocol: 'TCP',
            ),
            PortTriggerForwardRuleUIModel(
              instancePath: 'Device.NAT.PortTrigger.1.Rule.2.',
              forwardPort: 3000,
              forwardProtocol: 'UDP',
            ),
          ],
        ),
      ];
      final current = [
        PortTriggeringRuleUIModel(
          instancePath: 'Device.NAT.PortTrigger.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerProtocol: 'TCP',
          forwardRules: const [
            PortTriggerForwardRuleUIModel(
              instancePath: 'Device.NAT.PortTrigger.1.Rule.1.',
              forwardPort: 1024,
              forwardProtocol: 'TCP',
            ),
          ],
        ),
      ];

      await service.saveTriggeringBatch(original: original, current: current);

      final captured = verify(() => mockUsp.delete(captureAny())).captured;
      expect(captured, hasLength(1));
      expect(captured.first, ['Device.NAT.PortTrigger.1.Rule.2.']);
    });

    test('#1061: unchanged forward rules issue no Rule.* operations', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

      final rule = PortTriggeringRuleUIModel(
        instancePath: 'Device.NAT.PortTrigger.1.',
        enabled: true,
        description: 'FTP',
        triggerPort: 21,
        triggerProtocol: 'TCP',
        forwardRules: const [
          PortTriggerForwardRuleUIModel(
            instancePath: 'Device.NAT.PortTrigger.1.Rule.1.',
            forwardPort: 1024,
            forwardProtocol: 'TCP',
          ),
        ],
      );
      // Only the parent-level field (enabled) changes; forward rules identical.
      final current = [rule.copyWith(enabled: false)];

      await service.saveTriggeringBatch(original: [rule], current: current);

      // Parent Set fires once (Enable). No forward Set/add/delete.
      verifyNever(() => mockUsp.add(any()));
      verifyNever(() => mockUsp.delete(any()));
    });

    test('mixed batch: delete + add + update', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => uspSuccess());
      when(() => mockUsp.add(any())).thenAnswer(
          (_) async => uspAddSuccess(['Device.NAT.PortTrigger.9.']));
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => uspSuccess());

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

    test('multi-item delete uses reverse-order sequential calls', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => uspSuccess());

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

    test('throws when all batch operations fail', () async {
      when(() => mockUsp.delete(any()))
          .thenAnswer((_) async => uspFailure(errorMessage: 'Delete rejected'));

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
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling — transport layer exceptions
  // ---------------------------------------------------------------------------

  group('UspPortForwardingService — transport error handling', () {
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

    test('saveForwardingBatch maps transport error to ServiceError', () async {
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

    test('saveTriggeringBatch maps transport error to ServiceError', () async {
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

    test('immediateToggleForwarding maps transport error', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: HTTP error: HTTP 504');

      expect(
        () => service.immediateToggleForwarding('path.1.', false),
        throwsA(isA<NetworkError>()),
      );
    });

    test('immediateAddForwarding maps transport error', () async {
      when(() => mockUsp.add(any()))
          .thenThrow('Add failed: Transport error: HTTP error: HTTP 504');

      expect(
        () => service.immediateAddForwarding(
          externalPort: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
        ),
        throwsA(isA<NetworkError>()),
      );
    });
  });
}
