import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/ipv6port_service.g.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';

class MockUspClient extends Mock implements UspClient {}

Map<String, dynamic> _ok() => {
      'success': true,
      'result': {'data': <String, dynamic>{}},
    };

Map<String, dynamic> _added(String instance) => {
      'success': true,
      'result': {
        'data': {
          'affectedCount': 1,
          'instances': [instance],
        },
      },
    };

/// A refusal as the WASM client resolves it: it never throws on one.
Map<String, dynamic> _refused(String errorMessage,
        {String path = 'Device.Firewall.Chain.3.Rule.'}) =>
    {
      'success': false,
      'result': {
        'data': <String, dynamic>{},
        'error': {
          path: {'errorCode': 9007, 'errorMessage': errorMessage},
        },
      },
    };

/// A Set the router applied in part: some paths written, one refused.
Map<String, dynamic> _partlyRefused(String path, String errorMessage) => {
      'success': true,
      'result': {
        'data': {'Device.Firewall.Chain.3.Rule.26.Enable': 'true'},
        'error': {
          path: {'errorCode': 9007, 'errorMessage': errorMessage},
        },
      },
    };

Ipv6PortServiceRuleUIModel _ui({
  String? instancePath = 'Device.Firewall.Chain.3.Rule.26.',
  bool enabled = true,
  String description = 'Game',
  String ipv6Address = '2001:db8::1',
  String protocol = 'TCP',
  int startPort = 3074,
  int endPort = 3075,
}) =>
    Ipv6PortServiceRuleUIModel(
      instancePath: instancePath,
      enabled: enabled,
      description: description,
      ipv6Address: ipv6Address,
      protocol: protocol,
      startPort: startPort,
      endPort: endPort,
    );

Ipv6PortServiceRule _rule({
  String instancePath = 'Device.Firewall.Chain.3.Rule.26.',
  bool enable = true,
  String description = 'WebServer',
  int ipVersion = 6,
  String destIp = '2001:db8::1',
  int destPort = 80,
  int destPortRangeMax = 80,
  int protocol = 6,
  String target = 'Accept',
  DateTime? creationDate,
}) =>
    Ipv6PortServiceRule(
      instancePath: instancePath,
      enable: enable,
      description: description,
      ipVersion: ipVersion,
      destIp: destIp,
      destPort: destPort,
      destPortRangeMax: destPortRangeMax,
      protocol: protocol,
      target: target,
      creationDate: creationDate ?? DateTime.parse('2026-01-15T12:00:00Z'),
    );

/// The firewall chain table as the router lists it: the UPnP chain on
/// Chain.2 with a listed-looking rule of its own, then [rules] on the
/// `Defaults Configuration` chain on Chain.3.
Ipv6PortService _chains(List<Ipv6PortServiceRule> rules) =>
    Ipv6PortService(items: [
      Ipv6PortServiceChain(
        instancePath: 'Device.Firewall.Chain.2.',
        name: 'UPnP Port Mapping (dynamic rules)',
        rules: [
          _rule(
              instancePath: 'Device.Firewall.Chain.2.Rule.4.',
              description: 'upnp-mapping'),
        ],
      ),
      Ipv6PortServiceChain(
        instancePath: 'Device.Firewall.Chain.3.',
        name: 'Defaults Configuration',
        rules: rules,
      ),
    ]);

void main() {
  late MockUspClient mockUsp;
  late UspIpv6PortServiceService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspIpv6PortServiceService(mockUsp);
    // An add first reads the chain table to find the chain it adds under.
    // Tests that read rules stub their own table.
    when(() => mockUsp.get(any())).thenAnswer((_) async => {
          'Device.Firewall.Chain.2.Name': 'UPnP Port Mapping (dynamic rules)',
          'Device.Firewall.Chain.3.Name': 'Defaults Configuration',
        });
  });

  // ---------------------------------------------------------------------------
  // Protocol mapping
  // ---------------------------------------------------------------------------

  group('UspIpv6PortServiceService — protocol mapping', () {
    test('mapIanaToDisplay maps known protocols', () {
      expect(service.mapIanaToDisplay(6), 'TCP');
      expect(service.mapIanaToDisplay(17), 'UDP');
      expect(service.mapIanaToDisplay(255), 'Both');
    });

    test('mapIanaToDisplay defaults unknown to Both', () {
      expect(service.mapIanaToDisplay(99), 'Both');
    });

    test('mapDisplayToIana maps known names', () {
      expect(service.mapDisplayToIana('TCP'), 6);
      expect(service.mapDisplayToIana('UDP'), 17);
      expect(service.mapDisplayToIana('Both'), 255);
    });

    test('mapDisplayToIana defaults unknown to 255', () {
      expect(service.mapDisplayToIana('SCTP'), 255);
    });
  });

  // ---------------------------------------------------------------------------
  // buildRuleUIModels
  // ---------------------------------------------------------------------------

  group('UspIpv6PortServiceService — buildRuleUIModels', () {
    test('filters to IPv6 Accept user rules only', () {
      final data = _chains([
        _rule(ipVersion: 6, target: 'Accept'),
        _rule(
          instancePath: 'p.27.',
          ipVersion: 4,
          target: 'Accept',
        ), // filtered: not IPv6
        _rule(
          instancePath: 'p.28.',
          ipVersion: 6,
          target: 'Drop',
        ), // filtered: not Accept
        _rule(
          instancePath: 'p.29.',
          ipVersion: 6,
          target: 'Accept',
          creationDate: DateTime.parse('0001-01-01T00:00:00Z'),
        ), // filtered: system rule
      ]);

      final result = service.buildRuleUIModels(data);

      expect(result, hasLength(1));
    });

    test('maps all fields correctly', () {
      final data = _chains([
        _rule(
          instancePath: 'path.26.',
          enable: true,
          description: 'SSH',
          destIp: '2001:db8::1',
          destPort: 22,
          destPortRangeMax: 22,
          protocol: 6,
        ),
      ]);

      final result = service.buildRuleUIModels(data);

      expect(result[0].instancePath, 'path.26.');
      expect(result[0].enabled, isTrue);
      expect(result[0].description, 'SSH');
      expect(result[0].ipv6Address, '2001:db8::1');
      expect(result[0].startPort, 22);
      expect(result[0].endPort, 22);
      expect(result[0].protocol, 'TCP');
    });

    test('maps protocol 17 to UDP display', () {
      final data = _chains([
        _rule(protocol: 17),
      ]);

      final result = service.buildRuleUIModels(data);

      expect(result[0].protocol, 'UDP');
    });

    test('empty items returns empty list', () {
      final result = service.buildRuleUIModels(_chains([]));
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchPage — the rules the page lists, and the descriptions it hides
  // ---------------------------------------------------------------------------

  group('UspIpv6PortServiceService — fetchPage', () {
    /// A GET answer for [rules], keyed the way the router reports them.
    Map<String, dynamic> getAnswer(List<Ipv6PortServiceRule> rules) => {
          for (final chain in _chains(rules).items)
            '${chain.instancePath}Name': chain.name,
          for (final r in _chains(rules).items.expand((c) => c.rules)) ...{
            '${r.instancePath}Enable': r.enable,
            '${r.instancePath}Description': r.description,
            '${r.instancePath}IPVersion': r.ipVersion,
            '${r.instancePath}DestIP': r.destIp,
            '${r.instancePath}DestPort': r.destPort,
            '${r.instancePath}DestPortRangeMax': r.destPortRangeMax,
            '${r.instancePath}Protocol': r.protocol,
            '${r.instancePath}Target': r.target,
            '${r.instancePath}CreationDate':
                r.creationDate.toUtc().toIso8601String(),
          },
        };

    // FW refuses a description any firewall rule already has
    // (ErrorDescriptionInUse), so the dialog needs the ones the page hides.
    test('returns the listed rules and the descriptions of the hidden ones',
        () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => getAnswer([
            _rule(
                instancePath: 'Device.Firewall.Chain.3.Rule.1.',
                description: 'RULE_IDENT',
                ipVersion: 4,
                target: 'Drop'),
            _rule(
                instancePath: 'Device.Firewall.Chain.3.Rule.2.',
                description: 'Allow-DHCPv6',
                creationDate: DateTime.parse('0001-01-01T00:00:00Z')),
            _rule(
                instancePath: 'Device.Firewall.Chain.3.Rule.26.',
                description: 'Game'),
          ]));

      final page = await service.fetchPage();

      expect(page.rules.map((r) => r.description), ['Game']);
      expect(page.hiddenRuleDescriptions, {'RULE_IDENT', 'Allow-DHCPv6'});
    });

    test('a hidden rule with no description adds none', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => getAnswer([
            _rule(
                instancePath: 'Device.Firewall.Chain.3.Rule.1.',
                description: '',
                ipVersion: 4),
          ]));

      final page = await service.fetchPage();

      expect(page.hiddenRuleDescriptions, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // saveBatch
  // ---------------------------------------------------------------------------

  group('UspIpv6PortServiceService — saveBatch', () {
    test('no-op when lists identical', () async {
      final rules = [
        Ipv6PortServiceRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'SSH',
          ipv6Address: '2001:db8::1',
          protocol: 'TCP',
          startPort: 22,
          endPort: 22,
        ),
      ];

      final result = await service.saveBatch(
        original: rules,
        current: List.of(rules),
      );

      expect(result.added, 0);
      expect(result.updated, 0);
      expect(result.deleted, 0);
    });

    test('delete removes missing items', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      final original = [
        Ipv6PortServiceRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'SSH',
          ipv6Address: '2001:db8::1',
          protocol: 'TCP',
          startPort: 22,
          endPort: 22,
        ),
      ];

      final result = await service.saveBatch(
        original: original,
        current: [],
      );

      expect(result.deleted, 1);
      verify(() => mockUsp.delete(any())).called(1);
    });

    test('add creates items with null instancePath', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'affectedCount': 1,
                'instances': ['Device.Firewall.Chain.3.Rule.26.']
              }
            },
          });

      final current = [
        Ipv6PortServiceRuleUIModel(
          enabled: true,
          description: 'Web',
          ipv6Address: '2001:db8::2',
          protocol: 'TCP',
          startPort: 80,
          endPort: 443,
        ),
      ];

      final result = await service.saveBatch(
        original: [],
        current: current,
      );

      expect(result.added, 1);
      final captured = verify(() => mockUsp.add(captureAny())).captured;
      final items = captured[0] as List<Map<String, dynamic>>;
      final params = items[0]['params'] as Map<String, dynamic>;
      expect(params['DestIP'], '2001:db8::2');
      expect(params['Protocol'], 6); // TCP → IANA 6
      expect(params['IPVersion'], 6);
      expect(params['Target'], 'Accept');
      // Added under the Defaults Configuration chain, never the UPnP chain in
      // front of it.
      expect(items[0]['path'], 'Device.Firewall.Chain.3.Rule.');
    });

    test('an add on a router without the default chain adds nothing', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.Firewall.Chain.2.Name': 'UPnP Port Mapping (dynamic rules)',
          });

      await expectLater(
        service.saveBatch(original: [], current: [_ui(instancePath: null)]),
        throwsA(isA<ResourceNotFoundError>()),
      );
      verifyNever(() => mockUsp.add(any()));
    });

    test('update detects changed content', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      final original = [
        Ipv6PortServiceRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'SSH',
          ipv6Address: '2001:db8::1',
          protocol: 'TCP',
          startPort: 22,
          endPort: 22,
        ),
      ];
      final current = [
        Ipv6PortServiceRuleUIModel(
          instancePath: 'path.1.',
          enabled: false, // changed
          description: 'SSH',
          ipv6Address: '2001:db8::1',
          protocol: 'TCP',
          startPort: 22,
          endPort: 22,
        ),
      ];

      final result = await service.saveBatch(
        original: original,
        current: current,
      );

      expect(result.updated, 1);
    });

    test('mixed batch: delete + add + update', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'affectedCount': 1,
                'instances': ['Device.Firewall.Chain.3.Rule.27.']
              }
            },
          });
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      final original = [
        Ipv6PortServiceRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'ToDelete',
          ipv6Address: '::1',
          protocol: 'TCP',
          startPort: 80,
          endPort: 80,
        ),
        Ipv6PortServiceRuleUIModel(
          instancePath: 'path.2.',
          enabled: true,
          description: 'ToUpdate',
          ipv6Address: '2001:db8::2',
          protocol: 'UDP',
          startPort: 53,
          endPort: 53,
        ),
      ];
      final current = [
        Ipv6PortServiceRuleUIModel(
          instancePath: 'path.2.',
          enabled: false, // changed
          description: 'ToUpdate',
          ipv6Address: '2001:db8::2',
          protocol: 'UDP',
          startPort: 53,
          endPort: 53,
        ),
        Ipv6PortServiceRuleUIModel(
          description: 'NewRule',
          enabled: true,
          ipv6Address: '2001:db8::3',
          protocol: 'Both',
          startPort: 1000,
          endPort: 2000,
        ),
      ];

      final result = await service.saveBatch(
        original: original,
        current: current,
      );

      expect(result.deleted, 1);
      expect(result.added, 1);
      expect(result.updated, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // saveBatch — a refused step fails the save (FWDEV#204, feed_usp#50)
  // ---------------------------------------------------------------------------

  group('UspIpv6PortServiceService — saveBatch refusals', () {
    setUp(() {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => _ok());
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _ok());
      when(() => mockUsp.add(any()))
          .thenAnswer((_) async => _added('Device.Firewall.Chain.3.Rule.30.'));
    });

    test('a refused Add fails the save with the router\'s message', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async =>
          _refused('ErrorTooManyRules: at most 15 IPv6 port service rules.'));

      await expectLater(
        service.saveBatch(original: [], current: [_ui(instancePath: null)]),
        throwsA(isA<UspCompleteFailureError>().having(
          (e) => e.failures.single.errorMessage,
          'the router\'s reason',
          'ErrorTooManyRules: at most 15 IPv6 port service rules.',
        )),
      );
    });

    // Until feed_usp#50 FW refused nothing, so a partial result was only
    // logged and the save reported "saved".
    test('a partly refused Set fails the save', () async {
      when(() => mockUsp.set(any(),
          allowPartial: any(
              named: 'allowPartial'))).thenAnswer((_) async => _partlyRefused(
          'Device.Firewall.Chain.3.Rule.26.Target',
          'ErrorRulesOverlap: ports 3074-3075 already open to 2001:db8::1.'));

      await expectLater(
        service.saveBatch(
          original: [_ui()],
          current: [_ui(enabled: false)],
        ),
        throwsA(isA<UspPartialFailureError>().having(
          (e) => e.failures.single.errorMessage,
          'the router\'s reason',
          startsWith('ErrorRulesOverlap'),
        )),
      );
    });

    test('a refused Add after a written Delete is a partial failure', () async {
      when(() => mockUsp.add(any())).thenAnswer(
          (_) async => _refused('ErrorDescriptionInUse: another rule.'));

      await expectLater(
        service.saveBatch(
          original: [_ui(instancePath: 'Device.Firewall.Chain.3.Rule.27.')],
          current: [_ui(instancePath: null, description: 'New')],
        ),
        throwsA(isA<UspPartialFailureError>()),
      );
      verify(() => mockUsp.delete(['Device.Firewall.Chain.3.Rule.27.']))
          .called(1);
    });

    test('a refused Delete does not keep the other steps from being sent',
        () async {
      when(() => mockUsp.delete(any())).thenAnswer(
          (_) async => _refused('Object does not exist', path: 'p.27.'));

      await expectLater(
        service.saveBatch(
          original: [
            _ui(instancePath: 'p.27.', description: 'Gone'),
            _ui(),
          ],
          current: [
            _ui(enabled: false),
            _ui(instancePath: null, description: 'New', startPort: 9000),
          ],
        ),
        throwsA(isA<UspPartialFailureError>()),
      );
      verify(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .called(1);
      verify(() => mockUsp.add(any())).called(1);
    });

    // A rule renamed or moved off a port in the same save frees its name or
    // port for a rule added in that save; FW checks the Add against the
    // rules as they are when it arrives.
    test('steps are sent as Delete, then Set, then Add', () async {
      await service.saveBatch(
        original: [
          _ui(instancePath: 'p.27.', description: 'Gone'),
          _ui(description: 'Game'),
        ],
        current: [
          _ui(description: 'Game (old)'),
          _ui(instancePath: null, description: 'Game'),
        ],
      );

      verifyInOrder([
        () => mockUsp.delete(['p.27.']),
        () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')),
        () => mockUsp.add(any()),
      ]);
    });

    // FW runs its checks when Target is written, so the other parameters
    // must be in the rule by then.
    test('Target is the last parameter of an Add and of a Set', () async {
      await service.saveBatch(
        original: [_ui()],
        current: [
          _ui(enabled: false),
          _ui(instancePath: null, description: 'New', startPort: 9000),
        ],
      );

      final setParams = verify(() => mockUsp.set(captureAny(),
              allowPartial: any(named: 'allowPartial'))).captured.single
          as Map<String, dynamic>;
      expect(setParams.keys.last, 'Device.Firewall.Chain.3.Rule.26.Target');

      final addItems =
          verify(() => mockUsp.add(captureAny())).captured.single as List;
      final addParams = addItems.single['params'] as Map<String, dynamic>;
      expect(addParams.keys.last, 'Target');
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  group('UspIpv6PortServiceService — error handling', () {
    test('fetch maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: HTTP error: HTTP 504');

      expect(
        () => service.fetch(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('saveBatch maps USP error to ServiceError', () async {
      when(() => mockUsp.delete(any())).thenThrow(
          'Delete failed: Protocol error: invalid path (code: 7004)');

      final original = [
        Ipv6PortServiceRuleUIModel(
          instancePath: 'path.1.',
          enabled: true,
          description: 'SSH',
          ipv6Address: '2001:db8::1',
          protocol: 'TCP',
          startPort: 22,
          endPort: 22,
        ),
      ];

      expect(
        () => service.saveBatch(original: original, current: []),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}
