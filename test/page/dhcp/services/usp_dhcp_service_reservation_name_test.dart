import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/dhcp/services/usp_dhcp_service.dart';

import '../../../mocks/test_data/local_network_test_data.dart';
import '../../../mocks/test_data/usp_envelope_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

/// The reservation name and FW's refusals (linksys/PrivacyGUI#1698,
/// linksys/FWDEV#211, feed_usp#54).
void main() {
  late MockUspClient mockUsp;
  late UspDhcpService service;

  const lan = LocalNetworkTestData.lanPool;
  const p5 = '${lan}StaticAddress.5.';
  const p6 = '${lan}StaticAddress.6.';

  const okSet = {
    'success': true,
    'result': {'data': <String, dynamic>{}},
  };
  const okAdd = {
    'success': true,
    'result': {
      'data': {
        'affectedCount': 1,
        'instances': ['${lan}StaticAddress.7.'],
      }
    },
  };

  setUp(() {
    mockUsp = MockUspClient();
    service = UspDhcpService(mockUsp);
    when(() => mockUsp.get(any()))
        .thenAnswer((_) async => LocalNetworkTestData.poolRows());
  });

  DhcpReservationUIModel row(String? path, String mac, String ip,
          {String name = ''}) =>
      DhcpReservationUIModel(
          instancePath: path, mac: mac, ip: ip, enable: true, name: name);

  Map<String, dynamic> addedParams() =>
      ((verify(() => mockUsp.add(captureAny())).captured.single
              as List<Map<String, dynamic>>)
          .single['params'] as Map<String, dynamic>);

  group('read', () {
    test('a reservation with a name reads it', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            ...LocalNetworkTestData.reservationsResponse([
              ('AA:BB:CC:DD:EE:01', '192.168.1.101', true),
              ('AA:BB:CC:DD:EE:02', '192.168.1.102', true),
            ]),
            '${p5}X_LINKSYS_Name': 'living-room-tv',
          });

      final result = await service.fetchReservations();

      expect(result.map((r) => r.name), ['living-room-tv', '']);
    });

    test('a router that does not report the name reads every one as unnamed',
        () async {
      // Existing reservations, from a router without X_LINKSYS_Name.
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          LocalNetworkTestData.reservationsResponse(
              [('AA:BB:CC:DD:EE:01', '192.168.1.101', true)]));

      final result = await service.fetchReservations();

      expect(result.single.name, '');
      expect(result.single.mac, 'AA:BB:CC:DD:EE:01');
    });
  });

  group('Add', () {
    test('immediateAdd sends the name', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => okAdd);

      await service.immediateAdd(
          mac: 'AA:BB:CC:DD:EE:FF', ip: '192.168.1.77', name: 'printer');

      expect(addedParams(), {
        'Enable': true,
        'Chaddr': 'AA:BB:CC:DD:EE:FF',
        'Yiaddr': '192.168.1.77',
        'X_LINKSYS_Name': 'printer',
      });
    });

    test('immediateAdd sends no name when it is empty', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => okAdd);

      await service.immediateAdd(mac: 'AA:BB:CC:DD:EE:FF', ip: '192.168.1.77');

      expect(addedParams().containsKey('X_LINKSYS_Name'), isFalse);
    });

    test('a batch Add sends the name, and no name for an unnamed row',
        () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => okAdd);

      await service.saveBatch(original: [], current: [
        row(null, '11:11:11:11:11:01', '192.168.1.201', name: 'nas'),
        row(null, '11:11:11:11:11:02', '192.168.1.202'),
      ]);

      final items = verify(() => mockUsp.add(captureAny())).captured.single
          as List<Map<String, dynamic>>;
      expect(items.map((i) => (i['params'] as Map)['X_LINKSYS_Name']),
          ['nas', null]);
      expect(
          (items[1]['params'] as Map).containsKey('X_LINKSYS_Name'), isFalse);
    });
  });

  group('Set', () {
    test('a changed name is sent on its row', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => okSet);

      await service.saveBatch(
        original: [row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5')],
        current: [row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5', name: 'tv')],
      );

      final params = verify(() => mockUsp.set(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(params['${p5}X_LINKSYS_Name'], 'tv');
    });

    test('an unchanged name is not sent, and an unnamed row sends no name',
        () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => okSet);

      await service.saveBatch(
        original: [
          row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5', name: 'tv'),
          row(p6, 'AA:AA:AA:AA:AA:06', '192.168.1.6'),
        ],
        current: [
          row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.55', name: 'tv'),
          row(p6, 'AA:AA:AA:AA:AA:06', '192.168.1.66'),
        ],
      );

      final params = verify(() => mockUsp.set(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(params.keys.where((k) => k.endsWith('X_LINKSYS_Name')), isEmpty);
      expect(params['${p5}Yiaddr'], '192.168.1.55');
      expect(params['${p6}Yiaddr'], '192.168.1.66');
    });

    test('a name cleared to empty is not sent as ""', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => okSet);

      await service.saveBatch(
        original: [row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5', name: 'tv')],
        current: [row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5')],
      );

      final params = verify(() => mockUsp.set(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(params.containsKey('${p5}X_LINKSYS_Name'), isFalse);
    });
  });

  group('FW refusals', () {
    /// A refused Set as obuspa answers it: 7012 on every leaf of the row, the
    /// message only on the leaf dhcpmngr refused, the rest "group set failed".
    Map<String, dynamic> refusedSet(String leaf, String message) =>
        UspEnvelopeTestData.parameterErrors(
          {
            for (final l in ['Enable', 'Chaddr', 'Yiaddr'])
              '$p5$l': (
                code: 7012,
                message: l == leaf
                    ? message
                    : "SetParameterGroup: group set failed at '$p5$leaf' "
                        '(Invalid value)',
              ),
          },
          success: false,
        );

    test('a refused Set carries FW\'s message', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async =>
          refusedSet('Yiaddr', DhcpReservationRefusalNames.invalidIp));

      await expectLater(
        service.saveBatch(
          original: [row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5')],
          current: [row(p5, 'AA:AA:AA:AA:AA:05', '10.0.0.5')],
        ),
        throwsA(isA<InvalidInputError>()
            .having(
                (e) => e.field, 'field', DhcpReservationRefusalNames.invalidIp)
            .having((e) => e.code, 'code', 7012)),
      );
    });

    test('a Set partly refused still fails with FW\'s message', () async {
      // obuspa commits the other values; the refusal must still reach the page.
      when(() => mockUsp.set(any()))
          .thenAnswer((_) async => UspEnvelopeTestData.parameterErrors(
                {
                  '${p5}X_LINKSYS_Name': (
                    code: 7012,
                    message: DhcpReservationRefusalNames.invalidName,
                  ),
                },
                success: true,
                data: {'${p5}Enable': true},
              ));

      await expectLater(
        service.saveBatch(
          original: [row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5')],
          current: [
            row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5', name: 'bad-name')
          ],
        ),
        throwsA(isA<InvalidInputError>().having(
            (e) => e.field, 'field', DhcpReservationRefusalNames.invalidName)),
      );
    });

    test('a refused Add carries FW\'s message', () async {
      when(() => mockUsp.add(any()))
          .thenAnswer((_) async => UspEnvelopeTestData.pathErrors(
                {
                  '${lan}StaticAddress.': (
                    code: 7004,
                    message: DhcpReservationRefusalNames.invalidIp,
                  ),
                },
                success: false,
              ));

      await expectLater(
        service.immediateAdd(mac: 'AA:BB:CC:DD:EE:FF', ip: '10.0.0.5'),
        throwsA(isA<InvalidInputError>()
            .having(
                (e) => e.field, 'field', DhcpReservationRefusalNames.invalidIp)
            .having((e) => e.code, 'code', 7004)),
      );
    });

    test('a refusal without one of FW\'s messages keeps its batch type',
        () async {
      when(() => mockUsp.set(any())).thenAnswer(
          (_) async => refusedSet('Yiaddr', 'Something else went wrong'));

      await expectLater(
        service.saveBatch(
          original: [row(p5, 'AA:AA:AA:AA:AA:05', '192.168.1.5')],
          current: [row(p5, 'AA:AA:AA:AA:AA:05', '10.0.0.5')],
        ),
        throwsA(isA<UspCompleteFailureError>()),
      );
    });
  });
}
