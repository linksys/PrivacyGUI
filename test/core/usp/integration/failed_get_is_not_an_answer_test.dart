// A failed read is not an answer, all the way up to the service (#1212).
//
// Each case drives the real [UspClient] and the real generated model through a
// transport that RESOLVES with the WASM client's envelope, so what is pinned is
// the whole read path, not the decoder alone. The two shapes a failed read used
// to take are the two below: a table that reads as zero rows (DMZ, bench
// 2026-10-07: the page showed DMZ off after a save while the router held it
// on), and a model of optional leaves that reads as "the feature is not on this
// router" (DataElements' ControllerID, read from code).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';
import 'package:privacy_gui/generated/data_elements_network_info.g.dart';
import 'package:privacy_gui/page/dmz/services/usp_dmz_service.dart';

class _MockTransport extends Mock implements UspTransport {}

Map<String, dynamic> _lostConnection(List<String> paths) => {
      'success': false,
      'result': {
        'data': <String, dynamic>{},
        'error': {
          for (final p in paths)
            p: {
              'errorCode': 9999,
              'errorMessage':
                  'Transport error: Transport error: HTTP error: HTTP 503',
            },
        },
      },
    };

Map<String, dynamic> _answered(Map<String, String> data) => {
      'success': true,
      'result': {'data': data},
    };

void main() {
  late _MockTransport transport;
  late UspClient client;

  setUp(() {
    transport = _MockTransport();
    client = UspClient.withTransport(transport);
  });

  group('DMZ — a table derived from the response keys', () {
    test('a lost read is a NetworkError, not "no DMZ entry"', () async {
      when(() => transport.get(any())).thenAnswer(
          (inv) async => _lostConnection(inv.positionalArguments.first));

      await expectLater(
          UspDmzService(client).fetch(), throwsA(isA<NetworkError>()));
    });

    test('an answered read with no rows is still DMZ off', () async {
      when(() => transport.get(any())).thenAnswer((_) async => _answered({}));

      final (settings, _) = await UspDmzService(client).fetch();

      expect(settings.model.isEnabled, isFalse);
      expect(settings.instancePath, isNull);
    });
  });

  group('DataElementsNetworkInfo — every leaf optional', () {
    test('a lost read throws, so the "ControllerID unavailable" catch runs',
        () async {
      when(() => transport.get(any())).thenAnswer(
          (inv) async => _lostConnection(inv.positionalArguments.first));

      await expectLater(
          DataElementsNetworkInfo.fetch(client), throwsA(anything));
    });

    test('a router without DataElements still reads controllerId: null',
        () async {
      const path = 'Device.WiFi.DataElements.Network.ControllerID';
      when(() => transport.get(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {
                path: {
                  'errorCode': 7026,
                  'errorMessage': 'CheckPathProperties: Path ($path) does not '
                      'exist in the schema',
                },
              },
            },
          });

      final info = await DataElementsNetworkInfo.fetch(client);

      expect(info.controllerId, isNull);
    });
  });
}
