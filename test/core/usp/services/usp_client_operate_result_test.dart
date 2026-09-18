import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';

class _MockTransport extends Mock implements UspTransport {}

// =============================================================================
// `operate()`'s reading of the unified response (#1533).
//
// usp-client 0.13.0 (usp_framework#59) fixed the schema defect that swallowed
// synchronous Operate failures: a command the agent refuses now arrives as
// `success: false` with the agent's code in band, and the JS Promise **fulfils**
// — the reject path would replace the agent's code with a 9999 transport
// sentinel, so the failure is only observable by reading the returned value.
//
// This extraction used to read `data` and nothing else, so a refused command
// returned `{}` and every caller reported success. A router-refused firmware
// chunk completed normally in the UI with no error anywhere.
//
// Two properties this file holds:
//
//  * **A refusal throws, and it throws in the USP layer's own shape** —
//    `Operate failed: Operation error: … (code: N)` — so `parseUspError` reads it
//    as an *operation* failure carrying the agent's code, and every existing
//    `catch (e) => mapUspErrorToServiceError(e)` classifies it correctly. The
//    transport layer does not throw `ServiceError` itself: that is the service
//    layer's currency (constitution Article XIII).
//  * **Success is unchanged, plus `requestPath`** — 0.13.0 adds it for an
//    accepted asynchronous command, and it is the only server-assigned handle
//    for that outcome when not subscribed to Notify.
// =============================================================================

void main() {
  Map<String, dynamic> refused({
    String path = 'Device.LocalAgent.X_LINKSYS_Download()',
    int code = 7022,
    String message = 'Command Failure',
  }) =>
      {
        'success': false,
        'result': {
          'data': <String, dynamic>{},
          'error': {
            path: {'errorCode': code, 'errorMessage': message},
          },
        },
      };

  group('UspClient.extractOperateResult — a refused command', () {
    test('throws, rather than returning an empty map', () {
      expect(
        () => UspClient.extractOperateResult(refused()),
        throwsA(anything),
        reason: 'the defect was that this returned {} and read as success',
      );
    });

    test('throws in a shape parseUspError reads as an operation failure', () {
      Object? thrown;
      try {
        UspClient.extractOperateResult(refused());
      } catch (e) {
        thrown = e;
      }

      final parsed = parseUspError(thrown!);
      expect(parsed, isNotNull,
          reason: 'an unparseable throw would map to UnexpectedError');
      expect(parsed!.operation, 'Operate');
      expect(parsed.category, UspErrorCategory.operation,
          reason: 'a refusal is not a transport problem');
      expect(parsed.faultCode, 7022,
          reason: "the agent's code must survive to the mapper");
    });

    test('names the command and the agent message', () {
      Object? thrown;
      try {
        UspClient.extractOperateResult(
          refused(path: 'Device.Reboot()', message: 'Command Failure'),
        );
      } catch (e) {
        thrown = e;
      }

      expect(thrown.toString(), contains('Device.Reboot()'));
      expect(thrown.toString(), contains('Command Failure'));
    });

    test('still throws when the error detail is missing entirely', () {
      // Fail closed: `success: false` is the fact that matters, and a caller
      // that receives {} cannot tell it from a success.
      final bare = {
        'success': false,
        'result': {'data': <String, dynamic>{}}
      };

      Object? thrown;
      try {
        UspClient.extractOperateResult(bare);
      } catch (e) {
        thrown = e;
      }

      expect(thrown, isNotNull);
      expect(parseUspError(thrown!)?.category, UspErrorCategory.operation);
    });
  });

  group('UspClient.extractOperateResult — success', () {
    test('flattens commandKey and outputArgs as before', () {
      final out = UspClient.extractOperateResult({
        'success': true,
        'result': {
          'data': {
            'commandKey': 'a1b2c3d4-0000-0000-0000-000000000000',
            'outputArgs': {'Status': 'Success', 'AverageResponseTime': 12},
          },
        },
      });

      expect(out['commandKey'], 'a1b2c3d4-0000-0000-0000-000000000000');
      expect(out['Status'], 'Success');
      expect(out['AverageResponseTime'], '12',
          reason: 'output args are stringified, as before');
    });

    test('carries requestPath, which 0.13.0 adds for an accepted async command',
        () {
      final out = UspClient.extractOperateResult({
        'success': true,
        'result': {
          'data': {
            'commandKey': 'k',
            'requestPath': 'Device.IP.Diagnostics.IPPing()',
          },
        },
      });

      expect(out['requestPath'], 'Device.IP.Diagnostics.IPPing()');
    });

    test('returns the raw map when it is not the unified shape', () {
      final raw = {'commandKey': 'legacy'};
      expect(UspClient.extractOperateResult(raw), same(raw));
    });

    test('returns empty when a successful response carries no data', () {
      final out = UspClient.extractOperateResult({
        'success': true,
        'result': {'data': null},
      });
      expect(out, isEmpty);
    });
  });

  // The two groups above test the extraction in isolation. This one runs the real
  // `operate()` over a faked transport, so the path a caller actually takes —
  // transport answers `success: false` → `operate` throws → a service maps it — is
  // covered end to end. Worth having because `UspClient` is mocked wholesale in the
  // firmware tests, which means nothing there ever executes this extraction: a
  // refusal is injected as a pre-formatted throw, and the two halves are only
  // joined by the mock.
  group('operate() over a faked transport', () {
    setUpAll(() => registerFallbackValue(<String, String>{}));

    test(
        'a transport that answers success:false makes operate() throw a mappable refusal',
        () async {
      final transport = _MockTransport();
      when(() => transport.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => {
                'success': false,
                'result': {
                  'data': <String, dynamic>{},
                  'error': {
                    'Device.LocalAgent.X_LINKSYS_Download()': {
                      'errorCode': 7022,
                      'errorMessage': 'Command Failure',
                    },
                  },
                },
              });
      final client = UspClient.withTransport(transport);

      Object? thrown;
      try {
        await client.operate('Device.LocalAgent.X_LINKSYS_Download()');
      } catch (e) {
        thrown = e;
      }

      expect(thrown, isNotNull, reason: 'the refusal must not read as success');

      final mapped = mapUspErrorToServiceError(thrown!);
      expect(mapped, isA<UspCompleteFailureError>());
      expect(mapped.code, 7022);
      expect(mapped, isNot(isA<NetworkError>()));
      // Non-empty, because an empty list localizes as the generic
      // "something went wrong" — see service_error_localizations_test.dart.
      expect((mapped as UspCompleteFailureError).failures, isNotEmpty);
    });

    test('a transport that answers success:true returns the flattened output',
        () async {
      final transport = _MockTransport();
      when(() => transport.operate(any(), args: any(named: 'args')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {
                  'data': {
                    'commandKey': 'k-1',
                    'outputArgs': {'Status': 'Complete'}
                  },
                },
              });
      final client = UspClient.withTransport(transport);

      final out = await client.operate('Device.Reboot()');

      expect(out['commandKey'], 'k-1');
      expect(out['Status'], 'Complete');
    });
  });
}
