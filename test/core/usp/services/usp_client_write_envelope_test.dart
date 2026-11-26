// A write the router never answered throws from UspClient; a write it answered
// — accepted or refused — comes back as its envelope (#1666).
//
// THE DEFECT. The WASM client never rejects a write on a transport failure:
// Set, setOrdered, Add and Delete each resolve with `success: false` and one
// `kind: request` entry of code 9999 (`Transport error: HTTP error: …`) —
// measured from Node against the vendored usp-client 0.16.0, 2026-11-25, for a
// 401, a 503, a lost connection, a fetch timeout and an unreadable body
// (`test/web/usp_write_test.mjs`). UspClient passed that envelope through, so
// `_withAuthRetry` never saw a write's 401: a Remote Assistance session whose
// token was rejected stayed on screen, and locally nothing re-logged in.
//
// THE LINE. The router refusing the whole request is ALSO `kind: request`, but
// with its own code (7005 for an atomic Set it cannot apply) and its own text.
// That is an answer, and the services read its reason from the envelope; only
// the code tells it from the unanswered request.
//
// Every transport here RESOLVES with the envelope, as the real client does.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';

import '../../../mocks/test_data/usp_envelope_test_data.dart';

class _MockTransport extends Mock implements UspTransport {}

const _path = 'Device.WiFi.SSID.1.SSID';

Map<String, dynamic> _unanswered(String message) =>
    UspEnvelopeTestData.failedAsAWhole([_path],
        errorCode: 9999, errorMessage: message);

Object? _thrownBy(void Function() call) {
  try {
    call();
  } catch (e) {
    return e;
  }
  return null;
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, String>{});
    registerFallbackValue(<List<Map<String, String>>>[]);
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<String>[]);
  });

  group('UspClient.throwIfUnanswered', () {
    for (final (message, mapsTo) in [
      ('Transport error: HTTP error: HTTP 401', isA<NotAuthenticatedError>()),
      ('Transport error: HTTP error: HTTP 503', isA<NetworkError>()),
      (
        'Transport error: HTTP error: error sending request: '
            'JsValue(TypeError: Failed to fetch)',
        isA<NetworkError>()
      ),
    ]) {
      test('a request the router never answered throws: $message', () {
        final thrown = _thrownBy(
            () => UspClient.throwIfUnanswered('Set', _unanswered(message)));

        expect(thrown, isA<String>());
        expect(thrown, startsWith('Set failed: '));
        expect(thrown, contains(message.split('HTTP error: ').last),
            reason: 'the unanswered-write checks and `_isAuthError` read the '
                "client's own text");
        expect(mapUspErrorToServiceError(thrown!), mapsTo);
      });
    }

    test('the router refusing the whole request is an answer, returned as is',
        () {
      final refused = UspEnvelopeTestData.failedAsAWhole([_path],
          errorCode: 7005,
          errorMessage: 'Allow partial=false not supported across more than '
              'one USP Service');

      expect(UspClient.throwIfUnanswered('Set', refused), same(refused));
    });

    test('an object or a parameter the router refused is returned', () {
      final object = UspEnvelopeTestData.pathErrors(
          {'Device.NAT.PortMapping.': (code: 7012, message: 'refused')},
          success: false);
      final parameter = UspEnvelopeTestData.parameterErrors(
          {'Device.WiFi.SSID.1.SSID': (code: 7012, message: 'refused')},
          success: false);

      expect(UspClient.throwIfUnanswered('Add', object), same(object));
      expect(UspClient.throwIfUnanswered('Set', parameter), same(parameter));
    });

    test("the client's decode and validation failures are returned", () {
      for (final code in [9998, 9997]) {
        final failed = UspEnvelopeTestData.failedAsAWhole([_path],
            errorCode: code, errorMessage: 'Protocol error: synthetic');
        expect(UspClient.throwIfUnanswered('Set', failed), same(failed),
            reason: '$code');
      }
    });

    test('a write that succeeded is returned', () {
      final ok = {
        'success': true,
        'result': {'data': <String, dynamic>{}},
      };
      expect(UspClient.throwIfUnanswered('Delete', ok), same(ok));
    });
  });

  group('UspClient write verbs — a request the router never answered', () {
    late _MockTransport transport;
    late UspClient client;
    const lost = 'Transport error: HTTP error: error sending request: '
        'JsValue(TypeError: Failed to fetch)';

    setUp(() {
      transport = _MockTransport();
      client = UspClient.withTransport(transport);
      when(() => transport.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _unanswered(lost));
      when(() => transport.setOrdered(any(),
              allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _unanswered(lost));
      when(() => transport.add(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _unanswered(lost));
      when(() =>
              transport.delete(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _unanswered(lost));
    });

    // One call per public write and per private helper behind it, so a check
    // added to one helper instead of all of them cannot pass.
    final calls = <String, Future<Object?> Function(UspClient)>{
      'set': (c) => c.set({_path: 'NewHome'}),
      'set (batch)': (c) => c.set({_path: 'NewHome', 'Device.X': '1'}),
      'setOrdered': (c) => c.setOrdered([
            [
              {_path: 'NewHome'}
            ]
          ]),
      'add': (c) => c.add([
            {'path': 'Device.NAT.PortMapping.'}
          ]),
      'add (batch)': (c) => c.add([
            {'path': 'Device.NAT.PortMapping.'},
            {'path': 'Device.NAT.PortMapping.'},
          ]),
      'delete': (c) => c.delete(['Device.NAT.PortMapping.1.']),
      'delete (batch)': (c) =>
          c.delete(['Device.NAT.PortMapping.1.', 'Device.NAT.PortMapping.2.']),
    };

    for (final MapEntry(key: name, value: call) in calls.entries) {
      test('$name throws, and maps to NetworkError', () async {
        Object? thrown;
        try {
          await call(client);
        } catch (e) {
          thrown = e;
        }

        expect(thrown, isA<String>(), reason: 'not an envelope to read');
        expect(thrown, contains('Failed to fetch'));
        expect(mapUspErrorToServiceError(thrown!), isA<NetworkError>());
      });
    }
  });
}
