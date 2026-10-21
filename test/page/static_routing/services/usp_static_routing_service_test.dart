import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/page/static_routing/services/usp_static_routing_service.dart';

import '../../../util/usp_param_templates.dart';

class MockUspClient extends Mock implements UspClient {}

StaticRoute _route({
  String instancePath = 'Device.Routing.Router.1.IPv4Forwarding.1.',
  bool enable = true,
  String destIpAddress = '10.0.0.0',
  String destSubnetMask = '255.255.255.0',
  String gatewayIpAddress = '192.168.1.1',
  String interface_ = 'Device.IP.Interface.2',
  String origin = 'Static',
  String alias = 'TestRoute',
}) =>
    StaticRoute(
      instancePath: instancePath,
      enable: enable,
      destIpAddress: destIpAddress,
      destSubnetMask: destSubnetMask,
      gatewayIpAddress: gatewayIpAddress,
      interface_: interface_,
      origin: origin,
      alias: alias,
    );

void main() {
  late MockUspClient mockUsp;
  late UspStaticRoutingService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspStaticRoutingService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // buildRouteUIModels
  // ---------------------------------------------------------------------------

  group('UspStaticRoutingService — buildRouteUIModels', () {
    test('filters to static routes only', () {
      final data = StaticRouting(items: [
        _route(origin: 'Static', alias: 'MyRoute'),
        _route(origin: 'DHCPv4', alias: 'DhcpRoute'),
      ]);

      final result = service.buildRouteUIModels(data);

      expect(result, hasLength(1));
      expect(result[0].name, 'MyRoute');
    });

    test('maps interface path to display name', () {
      final data = StaticRouting(items: [
        _route(interface_: 'Device.IP.Interface.1', origin: 'Static'),
        _route(
          instancePath: 'p.2.',
          interface_: 'Device.IP.Interface.2',
          origin: 'Static',
        ),
      ]);

      final result = service.buildRouteUIModels(data);

      expect(result[0].interfaceName, 'LAN');
      expect(result[1].interfaceName, 'Internet');
    });

    test('unknown interface falls through unchanged', () {
      final data = StaticRouting(items: [
        _route(interface_: 'Device.IP.Interface.99', origin: 'Static'),
      ]);

      final result = service.buildRouteUIModels(data);

      expect(result[0].interfaceName, 'Device.IP.Interface.99');
    });

    test('preserves all fields correctly', () {
      final data = StaticRouting(items: [
        _route(
          instancePath: 'path.1.',
          enable: false,
          destIpAddress: '10.0.0.0',
          destSubnetMask: '255.0.0.0',
          gatewayIpAddress: '192.168.1.254',
          interface_: 'Device.IP.Interface.2',
          origin: 'Static',
          alias: 'VPN',
        ),
      ]);

      final result = service.buildRouteUIModels(data);

      expect(result[0].instancePath, 'path.1.');
      expect(result[0].enabled, isFalse);
      expect(result[0].destIpAddress, '10.0.0.0');
      expect(result[0].destSubnetMask, '255.0.0.0');
      expect(result[0].gatewayIpAddress, '192.168.1.254');
      expect(result[0].interfacePath, 'Device.IP.Interface.2');
    });

    test('empty data returns empty list', () {
      final result = service.buildRouteUIModels(StaticRouting(items: []));
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // mapDisplayToInterface
  // ---------------------------------------------------------------------------

  group('UspStaticRoutingService — mapDisplayToInterface', () {
    test('LAN maps to Device.IP.Interface.1', () {
      expect(service.mapDisplayToInterface('LAN'), 'Device.IP.Interface.1');
    });

    test('Internet maps to Device.IP.Interface.2', () {
      expect(
          service.mapDisplayToInterface('Internet'), 'Device.IP.Interface.2');
    });

    test('unknown name passes through', () {
      expect(service.mapDisplayToInterface('WAN2'), 'WAN2');
    });
  });

  // ---------------------------------------------------------------------------
  // saveBatch
  // ---------------------------------------------------------------------------

  group('UspStaticRoutingService — saveBatch', () {
    test('no-op when lists are identical', () async {
      final routes = [
        StaticRouteUIModel(
          instancePath: 'path.1.',
          enabled: true,
          name: 'Route1',
          destIpAddress: '10.0.0.0',
          destSubnetMask: '255.255.255.0',
          gatewayIpAddress: '192.168.1.1',
          interfaceName: 'Internet',
          interfacePath: 'Device.IP.Interface.2',
        ),
      ];

      final result = await service.saveBatch(
        original: routes,
        current: List.of(routes),
      );

      expect(result.added, 0);
      expect(result.updated, 0);
      expect(result.deleted, 0);
    });

    test('delete removes items missing from current', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      final original = [
        StaticRouteUIModel(
          instancePath: 'path.1.',
          enabled: true,
          name: 'Route1',
          destIpAddress: '10.0.0.0',
          destSubnetMask: '255.255.255.0',
          gatewayIpAddress: '',
          interfaceName: 'Internet',
          interfacePath: 'Device.IP.Interface.2',
        ),
      ];

      final result = await service.saveBatch(
        original: original,
        current: [],
      );

      expect(result.deleted, 1);
      verify(() => mockUsp.delete(['path.1.'])).called(1);
    });

    test('add creates items with null instancePath', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'affectedCount': 1,
                'instances': ['Device.Routing.Router.1.IPv4Forwarding.1.']
              }
            },
          });

      final current = [
        StaticRouteUIModel(
          enabled: true,
          name: 'NewRoute',
          destIpAddress: '172.16.0.0',
          destSubnetMask: '255.255.0.0',
          gatewayIpAddress: '192.168.1.1',
          interfaceName: 'LAN',
          interfacePath: '',
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
      expect(params['DestIPAddress'], '172.16.0.0');
      // LAN should be mapped back to TR-181 path
      expect(params['Interface'], 'Device.IP.Interface.1');
    });

    test('update detects changed content', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      final original = [
        StaticRouteUIModel(
          instancePath: 'path.1.',
          enabled: true,
          name: 'Route1',
          destIpAddress: '10.0.0.0',
          destSubnetMask: '255.255.255.0',
          gatewayIpAddress: '192.168.1.1',
          interfaceName: 'Internet',
          interfacePath: 'Device.IP.Interface.2',
        ),
      ];
      final current = [
        StaticRouteUIModel(
          instancePath: 'path.1.',
          enabled: true,
          name: 'Route1',
          destIpAddress: '10.0.0.0',
          destSubnetMask: '255.255.0.0', // changed
          gatewayIpAddress: '192.168.1.1',
          interfaceName: 'Internet',
          interfacePath: 'Device.IP.Interface.2',
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
                'instances': ['Device.Routing.Router.1.IPv4Forwarding.2.']
              }
            },
          });
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      final original = [
        StaticRouteUIModel(
          instancePath: 'path.1.',
          enabled: true,
          name: 'ToDelete',
          destIpAddress: '10.0.0.0',
          destSubnetMask: '255.255.255.0',
          gatewayIpAddress: '',
          interfaceName: 'Internet',
          interfacePath: 'Device.IP.Interface.2',
        ),
        StaticRouteUIModel(
          instancePath: 'path.2.',
          enabled: true,
          name: 'ToUpdate',
          destIpAddress: '172.16.0.0',
          destSubnetMask: '255.255.0.0',
          gatewayIpAddress: '',
          interfaceName: 'LAN',
          interfacePath: 'Device.IP.Interface.1',
        ),
      ];
      final current = [
        // path.1. removed (delete)
        StaticRouteUIModel(
          instancePath: 'path.2.',
          enabled: false, // changed (update)
          name: 'ToUpdate',
          destIpAddress: '172.16.0.0',
          destSubnetMask: '255.255.0.0',
          gatewayIpAddress: '',
          interfaceName: 'LAN',
          interfacePath: 'Device.IP.Interface.1',
        ),
        StaticRouteUIModel(
          // new entry (add)
          enabled: true,
          name: 'NewRoute',
          destIpAddress: '192.168.2.0',
          destSubnetMask: '255.255.255.0',
          gatewayIpAddress: '',
          interfaceName: 'Internet',
          interfacePath: '',
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

  // ---------------------------------------------------------------------------
  // What a save writes
  // ---------------------------------------------------------------------------
  // Paths the service builds are compared as templates (instance numbers as
  // `{i}`); paths that come from the page's own rows are compared as given.
  // The interfaces are the ones the bench router has today: lan on
  // Interface.1, wan on Interface.2.

  group('UspStaticRoutingService — what is written', () {
    const okSet = {
      'success': true,
      'result': {'data': <String, dynamic>{}},
    };
    const r5 = 'Device.Routing.Router.1.IPv4Forwarding.5.';
    const r9 = 'Device.Routing.Router.1.IPv4Forwarding.9.';
    const r12 = 'Device.Routing.Router.1.IPv4Forwarding.12.';

    StaticRouteUIModel route(String? path, String name,
            {String dest = '10.0.0.0',
            String iface = 'LAN',
            bool enabled = true}) =>
        StaticRouteUIModel(
          instancePath: path,
          enabled: enabled,
          name: name,
          destIpAddress: dest,
          destSubnetMask: '255.255.255.0',
          gatewayIpAddress: '192.168.1.254',
          interfaceName: iface,
        );

    void stubInterfaces() {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.IP.Interface.1.Alias': 'lan',
            'Device.IP.Interface.2.Alias': 'wan',
            'Device.Routing.Router.1.Alias': 'cpe-1',
          });
    }

    test('deletes go out one per row, highest row first', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => okSet);

      await service.saveBatch(
        original: [route(r5, 'a'), route(r9, 'b'), route(r12, 'c')],
        current: [route(r9, 'b')],
      );

      expect(verify(() => mockUsp.delete(captureAny())).captured, [
        [r12],
        [r5],
      ]);
    });

    test('adds go out in one Add on the router forwarding table', () async {
      stubInterfaces();
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'affectedCount': 2,
                'instances': [r9, r12],
              }
            },
          });

      await service.saveBatch(original: [], current: [
        route(null, 'ToLan', dest: '172.16.0.0'),
        route(null, 'ToWan',
            dest: '172.17.0.0', iface: 'Internet', enabled: false),
      ]);

      final items = verify(() => mockUsp.add(captureAny())).captured.single
          as List<Map<String, dynamic>>;
      expect(
        [
          for (final item in items)
            {
              'path': pathTemplate(item['path'] as String),
              'params': item['params'],
            }
        ],
        [
          {
            'path': 'Device.Routing.Router.{i}.IPv4Forwarding.',
            'params': {
              'Enable': true,
              'DestIPAddress': '172.16.0.0',
              'DestSubnetMask': '255.255.255.0',
              'GatewayIPAddress': '192.168.1.254',
              'Interface': 'Device.IP.Interface.1',
              'Alias': 'ToLan',
            },
          },
          {
            'path': 'Device.Routing.Router.{i}.IPv4Forwarding.',
            'params': {
              'Enable': false,
              'DestIPAddress': '172.17.0.0',
              'DestSubnetMask': '255.255.255.0',
              'GatewayIPAddress': '192.168.1.254',
              'Interface': 'Device.IP.Interface.2',
              'Alias': 'ToWan',
            },
          },
        ],
      );
    });

    test('updates go out in one SET on each changed row', () async {
      stubInterfaces();
      when(() => mockUsp.set(any())).thenAnswer((_) async => okSet);

      await service.saveBatch(
        original: [route(r5, 'a'), route(r9, 'b'), route(r12, 'c')],
        current: [
          route(r5, 'a', dest: '10.5.0.0'),
          route(r9, 'b'),
          route(r12, 'c', iface: 'Internet'),
        ],
      );

      expect(verify(() => mockUsp.set(captureAny())).captured.single, {
        '${r5}Enable': true,
        '${r5}DestIPAddress': '10.5.0.0',
        '${r5}DestSubnetMask': '255.255.255.0',
        '${r5}GatewayIPAddress': '192.168.1.254',
        '${r5}Interface': 'Device.IP.Interface.1',
        '${r5}Alias': 'a',
        '${r12}Enable': true,
        '${r12}DestIPAddress': '10.0.0.0',
        '${r12}DestSubnetMask': '255.255.255.0',
        '${r12}GatewayIPAddress': '192.168.1.254',
        '${r12}Interface': 'Device.IP.Interface.2',
        '${r12}Alias': 'c',
      });
    });
  });

  group('UspStaticRoutingService — error handling', () {
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
        StaticRouteUIModel(
          instancePath: 'path.1.',
          enabled: true,
          name: 'Route1',
          destIpAddress: '10.0.0.0',
          destSubnetMask: '255.255.255.0',
          gatewayIpAddress: '192.168.1.1',
          interfaceName: 'Internet',
          interfacePath: 'Device.IP.Interface.2',
        ),
      ];

      expect(
        () => service.saveBatch(original: original, current: []),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}
