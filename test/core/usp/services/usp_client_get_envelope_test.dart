// A GET reports its failure in the envelope it resolves with, and UspClient
// reads it there (#1212).
//
// THE DEFECT. The WASM client never rejects a GET on a transport failure: it
// resolves with `{success: false, result: {data: {}, error: {<path>: {errorCode:
// 9999, …}}}}` (measured from Node against the vendored client, 2026-10-07).
// The old `UspClientWeb.get` kept `result.data` and dropped the rest, so a lost
// connection reached every model as an empty map — a required-leaf model threw
// 9998 and the user read "the value entered is not valid"; a table read as "no
// rows" (DMZ showed off after a save, with no error, while the router held it
// on).
//
// Every transport here RESOLVES with the envelope, as the real client does. A
// fake that throws exercises a path production never takes.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';

class _MockTransport extends Mock implements UspTransport {}

const _path = 'Device.Firewall.DMZ.';

Map<String, dynamic> _transportFailure(String message) => {
      'success': false,
      'result': {
        'data': <String, dynamic>{},
        'error': {
          _path: {'errorCode': 9999, 'errorMessage': message},
        },
      },
    };

void main() {
  late _MockTransport transport;
  late UspClient client;

  setUp(() {
    transport = _MockTransport();
    client = UspClient.withTransport(transport);
  });

  group('UspClient.get — a failure in the envelope', () {
    test('a 9999 transport failure throws, and maps to NetworkError', () async {
      when(() => transport.get(any())).thenAnswer((_) async =>
          _transportFailure(
              'Transport error: Transport error: HTTP error: HTTP 503'));

      Object? thrown;
      try {
        await client.get([_path]);
      } catch (e) {
        thrown = e;
      }

      expect(thrown, isNotNull, reason: 'a lost read must not read as empty');
      expect(mapUspErrorToServiceError(thrown!), isA<NetworkError>());
    });
  });

  group('UspClient.get — the throttler does not keep a failed read', () {
    test('the next read inside the cache window reaches the router', () async {
      client.throttler = BridgeRequestThrottler();
      var failing = true;
      when(() => transport.get(any())).thenAnswer((_) async => failing
          ? _transportFailure(
              'Transport error: Transport error: Failed to fetch')
          : {
              'success': true,
              'result': {
                'data': {'${_path}1.Enable': '1'},
              },
            });

      await expectLater(client.get([_path]), throwsA(anything));
      failing = false;
      final second = await client.get([_path]);

      expect(second, {'${_path}1.Enable': true});
      verify(() => transport.get(any())).called(2);
    });
  });

  group('UspClient.get — a 401 in the envelope', () {
    const unauthorized =
        'Transport error: Transport error: HTTP error: HTTP 401';

    test('local: refreshes the token and reads again', () async {
      var expired = true;
      when(() => transport.refreshToken(token: any(named: 'token')))
          .thenAnswer((_) async => expired = false);
      when(() => transport.get(any())).thenAnswer((_) async => expired
          ? _transportFailure(unauthorized)
          : {
              'success': true,
              'result': {
                'data': {'${_path}1.Enable': '1'},
              },
            });

      final result = await client.get([_path]);

      expect(result, {'${_path}1.Enable': true});
      verify(() => transport.refreshToken(token: any(named: 'token')))
          .called(1);
      verify(() => transport.get(any())).called(2);
    });

    test('remote: ends the session, and the read fails', () async {
      client.authBehavior = AuthBehavior.remote;
      var forcedLogouts = 0;
      client.onForceLogout = () => forcedLogouts++;
      when(() => transport.get(any()))
          .thenAnswer((_) async => _transportFailure(unauthorized));

      Object? thrown;
      try {
        await client.get([_path]);
      } catch (e) {
        thrown = e;
      }

      expect(mapUspErrorToServiceError(thrown!), isA<NotAuthenticatedError>());
      expect(forcedLogouts, 1);
    });
  });

  // Both shapes measured on the bench M60, FW 2.0.3.26100833, 2026-10-13: a
  // path the firmware does not have answers 7026 for that path alone.
  group('UspClient.get — a path the router does not have', () {
    const missing = 'Device.X_LINKSYS_AutoIPoE.APIVersion';
    const present = 'Device.Firewall.MACFilterMode';
    const notInSchema = {
      'errorCode': 7026,
      'errorMessage': 'CheckPathProperties: Path (Device.X_LINKSYS_AutoIPoE.'
          'APIVersion) does not exist in the schema',
    };

    test('read with others: the others come back, the missing one is absent',
        () async {
      when(() => transport.get(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {present: 'Disabled'},
              'error': {missing: notInSchema},
            },
          });

      final result = await client.get([missing, present]);

      expect(result, {present: 'Disabled'});
    });

    test('read alone: success is false, and it still reads as absent',
        () async {
      when(() => transport.get(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'data': <String, dynamic>{},
              'error': {missing: notInSchema},
            },
          });

      final result = await client.get([missing]);

      expect(result.containsKey(missing), isFalse);
    });

    test('a lone 7026 whose envelope omits `data` still reads as absent',
        () async {
      when(() => transport.get(any())).thenAnswer((_) async => {
            'success': false,
            'result': {
              'error': {missing: notInSchema},
            },
          });

      expect(await client.get([missing]), isEmpty);
    });

    test('a genuinely empty table is still an empty answer', () async {
      when(() => transport.get(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      expect(await client.get([_path]), isEmpty);
    });
  });
}
