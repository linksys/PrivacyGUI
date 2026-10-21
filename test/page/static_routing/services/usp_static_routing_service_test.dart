import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/page/static_routing/services/usp_static_routing_service.dart';

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
  // Refusals (FWDEV#213)
  // ---------------------------------------------------------------------------

  group('UspStaticRoutingService — refused saves', () {
    final saved = StaticRouteUIModel(
      instancePath: 'Device.Routing.Router.1.IPv4Forwarding.30.',
      enabled: true,
      name: 'bench1021-dup',
      destIpAddress: '10.20.0.0',
      destSubnetMask: '255.255.0.0',
      gatewayIpAddress: '192.168.1.50',
      interfaceName: 'LAN',
      interfacePath: 'Device.IP.Interface.1',
    );

    // A refused Edit as the router answers it (FW 2.0.3.26101641, bench
    // 2026-10-21): 7012 on every leaf of the Set, the error name only on the
    // leaf FW refused, and the others pointing at it.
    Map<String, dynamic> refusedEdit(String leaf, String message) {
      const p = 'Device.Routing.Router.1.IPv4Forwarding.30.';
      return {
        'success': false,
        'result': {
          'data': <String, dynamic>{},
          'error': {
            for (final l in [
              'Enable',
              'DestIPAddress',
              'DestSubnetMask',
              'GatewayIPAddress',
              'Interface',
              'Alias',
            ])
              '$p$l': {
                'errorCode': 7012,
                'errorMessage': l == leaf
                    ? message
                    : "SetParameterGroup: group set failed at '$p$leaf' "
                        '(Invalid value)',
              },
          },
        },
      };
    }

    void answerSet(Map<String, dynamic> envelope) {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => envelope);
    }

    for (final (leaf, message, name) in [
      (
        'DestIPAddress',
        'ErrorInvalidIPAddress: 127.20.0.0 is a reserved address.',
        StaticRouteRefusalNames.invalidIpAddress,
      ),
      (
        'DestSubnetMask',
        'ErrorInvalidNetworkPrefixLength: the mask must be /8 to /31.',
        StaticRouteRefusalNames.invalidNetworkPrefixLength,
      ),
      (
        'Interface',
        'ErrorInvalidGateway: a LAN route gateway must be a host of the LAN '
            'subnet.',
        StaticRouteRefusalNames.invalidGateway,
      ),
      (
        'Alias',
        'ErrorDuplicateEntryName: a route is already named r1.',
        StaticRouteRefusalNames.duplicateEntryName,
      ),
      (
        'DestIPAddress',
        'ErrorTooManyEntries: at most 20 static routes.',
        StaticRouteRefusalNames.tooManyEntries,
      ),
    ]) {
      test('a refused Edit carries $name', () async {
        answerSet(refusedEdit(leaf, message));

        await expectLater(
          service.saveBatch(
            original: [saved],
            current: [saved.copyWith(destIpAddress: '127.20.0.0')],
          ),
          throwsA(isA<InvalidInputError>()
              .having((e) => e.field, 'field', name)
              .having((e) => e.code, 'code', 7012)),
        );
      });
    }

    test('a refused Edit without an error name stays the batch error',
        () async {
      answerSet({
        'success': false,
        'result': {
          'data': <String, dynamic>{},
          'error': {
            'Device.Routing.Router.1.IPv4Forwarding.30.Enable': {
              'errorCode': 9999,
              'errorMessage': 'Transport error: HTTP error: HTTP 503',
            },
          },
        },
      });

      await expectLater(
        service.saveBatch(
          original: [saved],
          current: [saved.copyWith(enabled: false)],
        ),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    // FWDEV#213: Set before Add, so a name a rename frees is free when the
    // Add lands; Delete first, so a deleted route frees its slot and its name.
    test('sends Delete, then Set, then Add', () async {
      final calls = <String>[];
      when(() => mockUsp.delete(any())).thenAnswer((_) async {
        calls.add('delete');
        return {
          'success': true,
          'result': {'data': <String, dynamic>{}},
        };
      });
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async {
        calls.add('set');
        return {
          'success': true,
          'result': {'data': <String, dynamic>{}},
        };
      });
      when(() => mockUsp.add(any())).thenAnswer((_) async {
        calls.add('add');
        return {
          'success': true,
          'result': {
            'data': {
              'instances': ['Device.Routing.Router.1.IPv4Forwarding.33.']
            }
          },
        };
      });
      final other = saved.copyWith(
          instancePath: 'Device.Routing.Router.1.IPv4Forwarding.31.',
          name: 'other');

      await service.saveBatch(
        original: [saved, other],
        current: [
          saved.copyWith(name: 'renamed'),
          StaticRouteUIModel(
            enabled: true,
            name: 'bench1021-dup',
            destIpAddress: '10.40.0.0',
            destSubnetMask: '255.255.0.0',
            gatewayIpAddress: '192.168.1.50',
            interfaceName: 'LAN',
          ),
        ],
      );

      expect(calls, ['delete', 'set', 'add']);
    });

    // A step that failed leaves the router in a state the next step was not
    // checked against: at 20 routes, an Add after a failed Delete is a 21st.
    test('a failed Delete stops the save before Set and Add', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                'Device.Routing.Router.1.IPv4Forwarding.31.': {
                  'errorCode': 9999,
                  'errorMessage': 'Transport error: HTTP error: HTTP 503',
                },
              },
            },
          });
      final other = saved.copyWith(
          instancePath: 'Device.Routing.Router.1.IPv4Forwarding.31.',
          name: 'other');

      await expectLater(
        service.saveBatch(
          original: [saved, other],
          current: [
            saved.copyWith(enabled: false),
            StaticRouteUIModel(
              enabled: true,
              name: 'new',
              destIpAddress: '10.40.0.0',
              destSubnetMask: '255.255.0.0',
              gatewayIpAddress: '192.168.1.50',
              interfaceName: 'LAN',
            ),
          ],
        ),
        throwsA(isA<UspCompleteFailureError>()),
      );
      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
      verifyNever(() => mockUsp.add(any()));
    });

    test('a refused Set stops the save before Add, with its error name',
        () async {
      answerSet(refusedEdit(
          'DestIPAddress', 'ErrorInvalidIPAddress: 0.1.0.0 is reserved.'));

      await expectLater(
        service.saveBatch(
          original: [saved],
          current: [
            saved.copyWith(destIpAddress: '0.1.0.0'),
            StaticRouteUIModel(
              enabled: true,
              name: 'new',
              destIpAddress: '10.40.0.0',
              destSubnetMask: '255.255.0.0',
              gatewayIpAddress: '192.168.1.50',
              interfaceName: 'LAN',
            ),
          ],
        ),
        throwsA(isA<InvalidInputError>().having(
            (e) => e.field, 'field', StaticRouteRefusalNames.invalidIpAddress)),
      );
      verifyNever(() => mockUsp.add(any()));
    });

    test('a partly refused Add fails the save', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'instances': ['Device.Routing.Router.1.IPv4Forwarding.32.']
              },
              'error': {
                'Device.Routing.Router.1.IPv4Forwarding.': {
                  'errorCode': 7004,
                  'errorMessage': 'Add failed',
                },
              },
            },
          });

      await expectLater(
        service.saveBatch(
          original: [],
          current: [
            StaticRouteUIModel(
              enabled: true,
              name: 'new',
              destIpAddress: '10.30.0.0',
              destSubnetMask: '255.255.0.0',
              gatewayIpAddress: '192.168.1.50',
              interfaceName: 'LAN',
            ),
          ],
        ),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // NAT / Dynamic routing (RIP)
  // ---------------------------------------------------------------------------

  // Read only where DeviceCapability.dynamicRouting says the router has the
  // leaf, so a value that does not come back is a failed read, not a missing
  // feature.
  group('UspStaticRoutingService — RIP switch', () {
    const ripPath = 'Device.Routing.RIP.Enable';

    test('fetchRipEnabled reads true and false', () async {
      when(() => mockUsp.get([ripPath]))
          .thenAnswer((_) async => {ripPath: true});
      expect(await service.fetchRipEnabled(), isTrue);

      when(() => mockUsp.get([ripPath]))
          .thenAnswer((_) async => {ripPath: false});
      expect(await service.fetchRipEnabled(), isFalse);
    });

    test('fetchRipEnabled throws when the value does not come back', () async {
      // The WASM client resolves a failed Get with empty data, which the
      // optional codegen field reads as null.
      when(() => mockUsp.get([ripPath]))
          .thenAnswer((_) async => <String, dynamic>{});
      expect(() => service.fetchRipEnabled(), throwsA(isA<ServiceError>()));
    });

    test('fetchRipEnabled maps a thrown USP error to ServiceError', () async {
      when(() => mockUsp.get([ripPath]))
          .thenThrow('Get failed: Transport error: HTTP error: HTTP 504');
      expect(() => service.fetchRipEnabled(), throwsA(isA<ServiceError>()));
    });

    test('saveRipEnabled sends the one leaf in one Set', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      await service.saveRipEnabled(true);

      final captured = verify(() => mockUsp.set(captureAny(),
          allowPartial: any(named: 'allowPartial'))).captured;
      expect(captured, [
        {ripPath: true}
      ]);
    });

    test('saveRipEnabled throws when the router refuses it', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': false,
                'result': {
                  'data': <String, dynamic>{},
                  'error': {
                    ripPath: {'errorCode': 7026, 'errorMessage': 'Invalid path'}
                  },
                },
              });

      expect(() => service.saveRipEnabled(true),
          throwsA(isA<UspCompleteFailureError>()));
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

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
