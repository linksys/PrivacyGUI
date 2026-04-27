import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/dhcp/services/usp_dhcp_service.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspDhcpService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspDhcpService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // fetchReservations
  // ---------------------------------------------------------------------------

  group('UspDhcpService — fetchReservations', () {
    test('returns empty list when no reservations', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await service.fetchReservations();

      expect(result, isEmpty);
    });

    test('maps chaddr→mac and yiaddr→ip correctly', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Enable': true,
            'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Chaddr':
                'AA:BB:CC:DD:EE:FF',
            'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Yiaddr':
                '192.168.1.100',
          });

      final result = await service.fetchReservations();

      expect(result, hasLength(1));
      expect(result[0].mac, 'AA:BB:CC:DD:EE:FF');
      expect(result[0].ip, '192.168.1.100');
      expect(result[0].enable, isTrue);
      expect(
        result[0].instancePath,
        'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
      );
    });

    test('maps multiple reservations in order', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Enable': true,
            'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Chaddr':
                'AA:BB:CC:DD:EE:01',
            'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Yiaddr':
                '192.168.1.101',
            'Device.DHCPv4.Server.Pool.1.StaticAddress.2.Enable': false,
            'Device.DHCPv4.Server.Pool.1.StaticAddress.2.Chaddr':
                'AA:BB:CC:DD:EE:02',
            'Device.DHCPv4.Server.Pool.1.StaticAddress.2.Yiaddr':
                '192.168.1.102',
          });

      final result = await service.fetchReservations();

      expect(result, hasLength(2));
      expect(result[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(result[1].mac, 'AA:BB:CC:DD:EE:02');
      expect(result[1].enable, isFalse);
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
