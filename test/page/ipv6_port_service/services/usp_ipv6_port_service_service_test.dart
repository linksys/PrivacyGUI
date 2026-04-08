import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/generated/ipv6port_service.g.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';

class MockUspService extends Mock implements UspService {}

Ipv6PortServiceRule _rule({
  String instancePath = 'Device.Firewall.Chain.1.Rule.26.',
  bool enable = true,
  String description = 'WebServer',
  int ipVersion = 6,
  String destIp = '2001:db8::1',
  int destPort = 80,
  int destPortRangeMax = 80,
  int protocol = 6,
  String target = 'Accept',
  String creationDate = '2026-01-15T12:00:00Z',
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
      creationDate: creationDate,
    );

void main() {
  late MockUspService mockUsp;
  late UspIpv6PortServiceService service;

  setUp(() {
    mockUsp = MockUspService();
    service = UspIpv6PortServiceService(mockUsp);
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
      final data = Ipv6PortService(items: [
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
          creationDate: '0001-01-01T00:00:00Z',
        ), // filtered: system rule
      ]);

      final result = service.buildRuleUIModels(data);

      expect(result, hasLength(1));
    });

    test('maps all fields correctly', () {
      final data = Ipv6PortService(items: [
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
      final data = Ipv6PortService(items: [
        _rule(protocol: 17),
      ]);

      final result = service.buildRuleUIModels(data);

      expect(result[0].protocol, 'UDP');
    });

    test('empty items returns empty list', () {
      final result = service.buildRuleUIModels(Ipv6PortService(items: []));
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // validateRule
  // ---------------------------------------------------------------------------

  group('UspIpv6PortServiceService — validateRule', () {
    test('valid rule returns empty errors', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: 'WebServer',
        ipv6Address: '2001:db8::1',
        startPort: '80',
        endPort: '443',
      );
      expect(errors, isEmpty);
    });

    test('empty description returns error', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: '',
        ipv6Address: '2001:db8::1',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['description'], 'Name is required');
    });

    test('description with leading space returns error', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: ' WebServer',
        ipv6Address: '2001:db8::1',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['description'],
          'Name must not have leading or trailing spaces');
    });

    test('description over 32 chars returns error', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: 'A' * 33,
        ipv6Address: '2001:db8::1',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['description'], 'Name must be 32 characters or less');
    });

    test('empty IPv6 address returns error', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: 'Rule1',
        ipv6Address: '',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['ipv6Address'], 'IPv6 address is required');
    });

    test('invalid IPv6 format returns error', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: 'Rule1',
        ipv6Address: 'not-an-ipv6',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['ipv6Address'], 'Invalid IPv6 address format');
    });

    test('empty start port returns error', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: 'Rule1',
        ipv6Address: '2001:db8::1',
        startPort: '',
        endPort: '80',
      );
      expect(errors['startPort'], 'Start port is required');
    });

    test('port out of range returns error', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: 'Rule1',
        ipv6Address: '2001:db8::1',
        startPort: '0',
        endPort: '65536',
      );
      expect(errors['startPort'], 'Port must be 1-65535');
      expect(errors['endPort'], 'Port must be 1-65535');
    });

    test('end port less than start port returns error', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: 'Rule1',
        ipv6Address: '2001:db8::1',
        startPort: '443',
        endPort: '80',
      );
      expect(errors['endPort'], 'End port must be >= start port');
    });

    test('multiple errors returned simultaneously', () {
      final errors = UspIpv6PortServiceService.validateRule(
        description: '',
        ipv6Address: '',
        startPort: '',
        endPort: '',
      );
      expect(errors.length, greaterThanOrEqualTo(4));
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
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});

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
      verify(() => mockUsp.delete('path.1.')).called(1);
    });

    test('add creates items with null instancePath', () async {
      when(() => mockUsp.add(any(), any())).thenAnswer((_) async => '');

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
      final captured =
          verify(() => mockUsp.add(captureAny(), captureAny())).captured;
      final params = captured[1] as Map<String, dynamic>;
      expect(params['DestIP'], '2001:db8::2');
      expect(params['Protocol'], 6); // TCP → IANA 6
      expect(params['IPVersion'], 6);
      expect(params['Target'], 'Accept');
    });

    test('update detects changed content', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {});

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
      when(() => mockUsp.delete(any())).thenAnswer((_) async {});
      when(() => mockUsp.add(any(), any())).thenAnswer((_) async => '');
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {});

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
