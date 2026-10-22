import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/dhcp/services/usp_dhcp_service.dart';

import '../../../mocks/test_data/local_network_test_data.dart';
import '../../../util/usp_param_templates.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspDhcpService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspDhcpService(mockUsp);
    // An add first reads the pool table to find the LAN pool it adds under.
    // Tests that read reservations stub their own table.
    when(() => mockUsp.get(any()))
        .thenAnswer((_) async => LocalNetworkTestData.poolRows());
  });

  // ---------------------------------------------------------------------------
  // fetchReservations
  // ---------------------------------------------------------------------------

  group('UspDhcpService — fetchReservations', () {
    test('returns empty list when no reservations', () async {
      when(() => mockUsp.get(any())).thenAnswer(
          (_) async => LocalNetworkTestData.reservationsResponse([]));

      final result = await service.fetchReservations();

      expect(result, isEmpty);
    });

    test('maps chaddr→mac and yiaddr→ip correctly', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          LocalNetworkTestData.reservationsResponse(
              [('AA:BB:CC:DD:EE:FF', '192.168.1.100', true)]));

      final result = await service.fetchReservations();

      expect(result, hasLength(1));
      expect(result[0].mac, 'AA:BB:CC:DD:EE:FF');
      expect(result[0].ip, '192.168.1.100');
      expect(result[0].enable, isTrue);
      expect(
        result[0].instancePath,
        '${LocalNetworkTestData.lanPool}StaticAddress.5.',
      );
    });

    test('maps multiple reservations in order', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => LocalNetworkTestData.reservationsResponse([
                ('AA:BB:CC:DD:EE:01', '192.168.1.101', true),
                ('AA:BB:CC:DD:EE:02', '192.168.1.102', false),
              ]));

      final result = await service.fetchReservations();

      expect(result, hasLength(2));
      expect(result[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(result[1].mac, 'AA:BB:CC:DD:EE:02');
      expect(result[1].enable, isFalse);
    });

    test('a reservation row with every value blank is not listed', () async {
      // usp-codegen 0.18 returns such a row where 0.17 dropped it (#1654).
      const lan = LocalNetworkTestData.lanPool;
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            ...LocalNetworkTestData.reservationsResponse(
                [('AA:BB:CC:DD:EE:01', '192.168.1.101', true)]),
            '${lan}StaticAddress.9.Enable': false,
            '${lan}StaticAddress.9.Chaddr': '',
            '${lan}StaticAddress.9.Yiaddr': '',
          });

      final result = await service.fetchReservations();

      expect(result.map((r) => r.mac), ['AA:BB:CC:DD:EE:01']);
    });

    test('a router without the LAN pool lists no reservations', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            '${LocalNetworkTestData.guestPool}Alias': 'cpe-2',
            '${LocalNetworkTestData.guestPool}Interface':
                'Device.IP.Interface.6',
          });

      expect(await service.fetchReservations(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // saveBatch
  // ---------------------------------------------------------------------------

  group('UspDhcpService — saveBatch', () {
    test('no-op when original and current are identical', () async {
      final original = [
        DhcpReservationUIModel(
          instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
          mac: 'AA:BB:CC:DD:EE:FF',
          ip: '192.168.1.100',
          enable: true,
        ),
      ];

      final result = await service.saveBatch(
        original: original,
        current: List.of(original),
      );

      expect(result.added, 0);
      expect(result.updated, 0);
      expect(result.deleted, 0);
      verifyNever(() => mockUsp.delete(any()));
      verifyNever(() => mockUsp.add(any()));
      verifyNever(() => mockUsp.set(any()));
    });

    test('delete removes items missing from current', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      final original = [
        DhcpReservationUIModel(
          instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
          mac: 'AA:BB:CC:DD:EE:FF',
          ip: '192.168.1.100',
          enable: true,
        ),
      ];

      final result = await service.saveBatch(
        original: original,
        current: [],
      );

      expect(result.deleted, 1);
      verify(() => mockUsp.delete(
            ['Device.DHCPv4.Server.Pool.1.StaticAddress.1.'],
          )).called(1);
    });

    test('multiple deletes use reverse-order sequential calls', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      final original = [
        DhcpReservationUIModel(
          instancePath: 'path.1.',
          mac: 'AA:AA:AA:AA:AA:01',
          ip: '192.168.1.1',
          enable: true,
        ),
        DhcpReservationUIModel(
          instancePath: 'path.2.',
          mac: 'AA:AA:AA:AA:AA:02',
          ip: '192.168.1.2',
          enable: true,
        ),
      ];

      final result = await service.saveBatch(
        original: original,
        current: [],
      );

      expect(result.deleted, 2);
      verify(() => mockUsp.delete(any())).called(2);
    });

    test('add creates items with null instancePath', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'affectedCount': 1,
                'instances': ['Device.DHCPv4.Server.Pool.1.StaticAddress.1.']
              }
            },
          });

      final current = [
        DhcpReservationUIModel(
          mac: '11:22:33:44:55:66',
          ip: '192.168.1.200',
          enable: true,
        ),
      ];

      final result = await service.saveBatch(
        original: [],
        current: current,
      );

      expect(result.added, 1);
      final captured = verify(() => mockUsp.add(captureAny())).captured;
      final items = captured[0] as List<Map<String, dynamic>>;
      expect(items, hasLength(1));
      final params = items[0]['params'] as Map<String, dynamic>;
      expect(params['Chaddr'], '11:22:33:44:55:66');
      expect(params['Yiaddr'], '192.168.1.200');
    });

    test('update detects changed content on same path', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      final original = [
        DhcpReservationUIModel(
          instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
          mac: 'AA:BB:CC:DD:EE:FF',
          ip: '192.168.1.100',
          enable: true,
        ),
      ];
      final current = [
        DhcpReservationUIModel(
          instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
          mac: 'AA:BB:CC:DD:EE:FF',
          ip: '192.168.1.200', // changed IP
          enable: true,
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
                'instances': ['Device.DHCPv4.Server.Pool.1.StaticAddress.3.']
              }
            },
          });
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      final original = [
        DhcpReservationUIModel(
          instancePath: 'path.1.',
          mac: 'AA:AA:AA:AA:AA:01',
          ip: '192.168.1.1',
          enable: true,
        ),
        DhcpReservationUIModel(
          instancePath: 'path.2.',
          mac: 'AA:AA:AA:AA:AA:02',
          ip: '192.168.1.2',
          enable: true,
        ),
      ];
      final current = [
        // path.1. removed (delete)
        DhcpReservationUIModel(
          instancePath: 'path.2.',
          mac: 'AA:AA:AA:AA:AA:02',
          ip: '192.168.1.20', // changed (update)
          enable: true,
        ),
        DhcpReservationUIModel(
          // new entry (add)
          mac: 'BB:BB:BB:BB:BB:03',
          ip: '192.168.1.3',
          enable: true,
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

    test('multiple adds send single batch call', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'affectedCount': 2,
                'instances': [
                  'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
                  'Device.DHCPv4.Server.Pool.1.StaticAddress.2.',
                ]
              }
            },
          });

      final current = [
        DhcpReservationUIModel(
            mac: '11:11:11:11:11:01', ip: '10.0.0.1', enable: true),
        DhcpReservationUIModel(
            mac: '11:11:11:11:11:02', ip: '10.0.0.2', enable: true),
      ];

      final result = await service.saveBatch(original: [], current: current);

      expect(result.added, 2);
      verify(() => mockUsp.add(any())).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // What a save writes
  // ---------------------------------------------------------------------------
  // Paths the service builds are compared as templates (instance numbers as
  // `{i}`); paths that come from the page's own rows are compared as given.

  group('UspDhcpService — what is written', () {
    const okSet = {
      'success': true,
      'result': {'data': <String, dynamic>{}},
    };
    Map<String, dynamic> okAdd(int n) => {
          'success': true,
          'result': {
            'data': {
              'affectedCount': n,
              'instances': [
                for (var i = 0; i < n; i++)
                  'Device.DHCPv4.Server.Pool.4.StaticAddress.${i + 30}.'
              ],
            }
          },
        };

    DhcpReservationUIModel row(String? path, String mac, String ip,
            {bool enable = true}) =>
        DhcpReservationUIModel(
            instancePath: path, mac: mac, ip: ip, enable: enable);

    test('deletes go out one per row, highest row first', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => okSet);
      const p5 = 'Device.DHCPv4.Server.Pool.4.StaticAddress.5.';
      const p9 = 'Device.DHCPv4.Server.Pool.4.StaticAddress.9.';
      const p12 = 'Device.DHCPv4.Server.Pool.4.StaticAddress.12.';

      await service.saveBatch(
        original: [
          row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5'),
          row(p9, 'AA:AA:AA:AA:AA:09', '192.168.1.9'),
          row(p12, 'AA:AA:AA:AA:AA:12', '192.168.1.12'),
        ],
        current: [row(p9, 'AA:AA:AA:AA:AA:09', '192.168.1.9')],
      );

      final calls = verify(() => mockUsp.delete(captureAny())).captured;
      expect(calls, [
        [p12],
        [p5],
      ]);
    });

    test('adds go out in one Add on the LAN pool StaticAddress table',
        () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => LocalNetworkTestData.poolRows());
      when(() => mockUsp.add(any())).thenAnswer((_) async => okAdd(2));

      await service.saveBatch(original: [], current: [
        row(null, '11:11:11:11:11:01', '192.168.1.201'),
        row(null, '11:11:11:11:11:02', '192.168.1.202', enable: false),
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
            'path': 'Device.DHCPv4.Server.Pool.{i}.StaticAddress.',
            'params': {
              'Enable': true,
              'Chaddr': '11:11:11:11:11:01',
              'Yiaddr': '192.168.1.201',
            },
          },
          {
            'path': 'Device.DHCPv4.Server.Pool.{i}.StaticAddress.',
            'params': {
              'Enable': false,
              'Chaddr': '11:11:11:11:11:02',
              'Yiaddr': '192.168.1.202',
            },
          },
        ],
      );
    });

    test('updates go out in one SET on each changed row', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => okSet);
      const p5 = 'Device.DHCPv4.Server.Pool.4.StaticAddress.5.';
      const p9 = 'Device.DHCPv4.Server.Pool.4.StaticAddress.9.';
      const p12 = 'Device.DHCPv4.Server.Pool.4.StaticAddress.12.';

      await service.saveBatch(
        original: [
          row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5'),
          row(p9, 'AA:AA:AA:AA:AA:09', '192.168.1.9'),
          row(p12, 'AA:AA:AA:AA:AA:12', '192.168.1.12'),
        ],
        current: [
          row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.55'),
          row(p9, 'AA:AA:AA:AA:AA:09', '192.168.1.9'),
          row(p12, 'AA:AA:AA:AA:AA:12', '192.168.1.12', enable: false),
        ],
      );

      final params = verify(() => mockUsp.set(captureAny())).captured.single;
      expect(params, {
        '${p5}Enable': true,
        '${p5}Chaddr': 'AA:AA:AA:AA:AA:05',
        '${p5}Yiaddr': '192.168.1.55',
        '${p12}Enable': false,
        '${p12}Chaddr': 'AA:AA:AA:AA:AA:12',
        '${p12}Yiaddr': '192.168.1.12',
      });
    });

    test('immediateToggle writes only Enable on the given row', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => okSet);
      const p9 = 'Device.DHCPv4.Server.Pool.4.StaticAddress.9.';

      await service.immediateToggle(p9, false);

      expect(verify(() => mockUsp.set(captureAny())).captured.single,
          {'${p9}Enable': false});
    });

    test('immediateAdd adds one row on the LAN pool StaticAddress table',
        () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => LocalNetworkTestData.poolRows());
      when(() => mockUsp.add(any())).thenAnswer((_) async => okAdd(1));

      await service.immediateAdd(mac: 'AA:BB:CC:DD:EE:FF', ip: '192.168.1.77');

      final items = verify(() => mockUsp.add(captureAny())).captured.single
          as List<Map<String, dynamic>>;
      expect(items, hasLength(1));
      expect(pathTemplate(items.single['path'] as String),
          'Device.DHCPv4.Server.Pool.{i}.StaticAddress.');
      expect(items.single['params'], {
        'Enable': true,
        'Chaddr': 'AA:BB:CC:DD:EE:FF',
        'Yiaddr': '192.168.1.77',
      });
    });

    test('an add on a router without the LAN pool adds nothing and says so',
        () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            '${LocalNetworkTestData.guestPool}Alias': 'cpe-2',
            '${LocalNetworkTestData.guestPool}Interface':
                'Device.IP.Interface.6',
          });

      await expectLater(
        service.immediateAdd(mac: 'AA:BB:CC:DD:EE:FF', ip: '192.168.1.77'),
        throwsA(isA<ResourceNotFoundError>()),
      );
      verifyNever(() => mockUsp.add(any()));
    });

    test('immediateDelete deletes exactly the given row', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => okSet);
      const p9 = 'Device.DHCPv4.Server.Pool.4.StaticAddress.9.';

      await service.immediateDelete(p9);

      expect(verify(() => mockUsp.delete(captureAny())).captured.single, [p9]);
    });
  });

  // ---------------------------------------------------------------------------
  // Immediate mutations
  // ---------------------------------------------------------------------------

  group('UspDhcpService — immediate mutations', () {
    test('immediateToggle succeeds on firmware success', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.immediateToggle('path.1.', false);

      verify(() => mockUsp.set(any())).called(1);
    });

    test('immediateToggle throws on firmware failure', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                'path.1.Enable': {
                  'errorCode': 7004,
                  'errorMessage': 'Parameter not writable'
                }
              }
            },
          });

      expect(
        () => service.immediateToggle('path.1.', false),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('immediateAdd succeeds on firmware success', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'affectedCount': 1,
                'instances': ['path.1.']
              }
            },
          });

      await service.immediateAdd(mac: 'AA:BB:CC:DD:EE:FF', ip: '192.168.1.100');

      verify(() => mockUsp.add(any())).called(1);
    });

    test('immediateAdd throws on firmware failure', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                'Device.DHCPv4.Server.Pool.1.StaticAddress.': {
                  'errorCode': 7001,
                  'errorMessage': 'Duplicate MAC address'
                }
              }
            },
          });

      expect(
        () =>
            service.immediateAdd(mac: 'AA:BB:CC:DD:EE:FF', ip: '192.168.1.100'),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('immediateDelete succeeds on firmware success', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.immediateDelete('path.1.');

      verify(() => mockUsp.delete(any())).called(1);
    });

    test('immediateDelete throws on firmware failure', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                'path.1.': {
                  'errorCode': 7003,
                  'errorMessage': 'Object not found'
                }
              }
            },
          });

      expect(
        () => service.immediateDelete('path.1.'),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  group('UspDhcpService — error handling', () {
    test('fetchReservations maps USP error to ServiceError', () async {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: HTTP error: HTTP 504');

      expect(
        () => service.fetchReservations(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('saveBatch maps USP error to ServiceError', () async {
      when(() => mockUsp.delete(any())).thenThrow(
          'Delete failed: Protocol error: invalid path (code: 7004)');

      final original = [
        DhcpReservationUIModel(
          instancePath: 'path.1.',
          mac: 'AA:BB:CC:DD:EE:FF',
          ip: '192.168.1.100',
          enable: true,
        ),
      ];

      expect(
        () => service.saveBatch(original: original, current: []),
        throwsA(isA<ServiceError>()),
      );
    });

    test('saveBatch throws on complete failure', () async {
      when(() => mockUsp.delete(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                'path.1.': {
                  'errorCode': 7003,
                  'errorMessage': 'Object not found'
                }
              }
            },
          });

      final original = [
        DhcpReservationUIModel(
          instancePath: 'path.1.',
          mac: 'AA:BB:CC:DD:EE:FF',
          ip: '192.168.1.100',
          enable: true,
        ),
      ];

      expect(
        () => service.saveBatch(original: original, current: []),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });

    test('saveBatch partial success logs warning but continues', () async {
      // Partial success: one succeeds, one fails
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'affectedCount': 1,
                'instances': ['path.1.']
              },
              'error': {
                'path.2.': {'errorCode': 7001, 'errorMessage': 'Duplicate'}
              }
            },
          });

      final current = [
        DhcpReservationUIModel(
            mac: 'AA:AA:AA:AA:AA:01', ip: '192.168.1.1', enable: true),
        DhcpReservationUIModel(
            mac: 'AA:AA:AA:AA:AA:02', ip: '192.168.1.2', enable: true),
      ];

      // Should NOT throw — lenient mode accepts partial success
      final result = await service.saveBatch(original: [], current: current);

      expect(result.added, 2);
    });
  });
}
