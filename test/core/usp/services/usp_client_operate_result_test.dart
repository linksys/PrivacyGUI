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

/// The string `extractOperateResult` throws for [raw].
///
/// A helper rather than a `try`/`catch` in each test: the thrown value is a `String`
/// by design (the USP layer's own error currency, so `parseUspError` can read it),
/// and `expect(..., throwsA(...))` cannot hand the value back for inspection.
String _thrownFrom(Map<String, dynamic> raw) {
  try {
    UspClient.extractOperateResult(raw);
  } catch (e) {
    return e as String;
  }
  throw StateError('expected extractOperateResult to throw for $raw');
}

/// The same refusal with its `errorCode` as a `double`, which is how an integral JS
/// number can arrive across the interop boundary.
extension on Map<String, dynamic> {
  Map<String, dynamic> withDoubleCode() {
    final error = (this['result'] as Map)['error'] as Map;
    final entry = error.entries.first;
    final detail = Map<String, dynamic>.from(entry.value as Map);
    detail['errorCode'] = (detail['errorCode'] as int).toDouble();
    return {
      ...this,
      'result': {
        ...(this['result'] as Map),
        'error': {entry.key: detail},
      },
    };
  }
}

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

  // ══════════════════════════════════════════════════════════════════════════
  // Round-1 review remediation — the three defects the reviews found
  // ══════════════════════════════════════════════════════════════════════════
  //
  // All three are the *same* failure mode as the bug this PR was written to fix: a
  // refusal that reaches a user as something other than a refusal. Each was a
  // different way back into it.
  group('UspClient.extractOperateResult — review remediation', () {
    test('a refusal with no `result` key still throws', () {
      // The guard used to sit *after* `if (result == null) return raw`, so this
      // shape returned the raw map and a caller reading it saw a success. Whether
      // the agent can produce it is not knowable from this repo — `success` is
      // assembled inside the wasm and the JS shim holds no `success: false` literal
      // — which is the argument for checking rather than against.
      expect(
        () => UspClient.extractOperateResult({'success': false}),
        throwsA(isA<String>()),
      );
    });

    test('a refusal with a null `result` still throws', () {
      expect(
        () =>
            UspClient.extractOperateResult({'success': false, 'result': null}),
        throwsA(isA<String>()),
      );
    });

    test('a non-unified response is still passed through untouched', () {
      // The fallback the reordering must not have eaten: no `success` key at all,
      // no `result` — a pre-0.13.0 shape, returned as-is.
      final raw = {'commandKey': 'k', 'outputArgs': <String, String>{}};

      expect(UspClient.extractOperateResult(raw), same(raw));
    });

    test('an integral code arriving as a double still reads as a fault code',
        () {
      // JS numbers are doubles, and `errorCode` crosses the interop boundary
      // untyped. Interpolated raw it rendered `(code: 7022.0)`, whose digits the
      // fault-code pattern cannot match through the `.` — so `faultCode` came back
      // null and the user got "Something went wrong" for the one code this change
      // exists to give a message to.
      final thrown = _thrownFrom(refused(code: 7022).withDoubleCode());

      expect(thrown, contains('(code: 7022)'));
      expect(thrown, isNot(contains('7022.0')));
      expect(parseUspError(thrown)?.faultCode, 7022);
    });

    test('a non-integral code is left alone, because it is not a fault code',
        () {
      // Normalising means "render an integer as an integer", not "coerce anything
      // numeric into one". A fractional value is not a USP fault code and must not
      // be promoted into looking like one.
      final thrown = _thrownFrom({
        'success': false,
        'result': {
          'error': {
            'Device.X()': {'errorCode': 70.5, 'errorMessage': 'odd'},
          },
        },
      });

      expect(thrown, contains('70.5'));
      expect(parseUspError(thrown)?.faultCode, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // The refusal reaches the user in their own language, whatever the code
  // ══════════════════════════════════════════════════════════════════════════
  //
  // The review's Critical, and the one finding that was a user-visible regression
  // **this PR introduced**: `_mapOperationError` was dead in the WASM build until
  // refusals started throwing, so its `UnexpectedError` fallthrough could not be
  // reached. Once it could, every code other than 7022 landed on it — and
  // `service_error_localizations.dart` surfaces `UnexpectedError`'s `detail`
  // verbatim, so a log-shaped English string went on screen in all 26 locales.
  group('mapUspErrorToServiceError — a refusal is never raw English', () {
    test('7022 maps to a batch failure carrying its code', () {
      final error = mapUspErrorToServiceError(_thrownFrom(refused(code: 7022)));

      expect(error, isA<UspCompleteFailureError>());
      expect(
          (error as UspCompleteFailureError).failures.single.errorCode, 7022);
    });

    test('a code other than 7022 maps the same way, not to UnexpectedError',
        () {
      // 9005 is the interesting one: `_localizeFaultCode` already knows it as
      // `errorResourceNotFound`, so generalising this arm is not merely "less raw"
      // — it is *more specific* than the 7022-only version could ever be.
      final error = mapUspErrorToServiceError(_thrownFrom(refused(code: 9005)));

      expect(error, isA<UspCompleteFailureError>(),
          reason:
              'UnexpectedError surfaces its detail verbatim, which would put '
              'the log string on screen in every locale');
      expect(
          (error as UspCompleteFailureError).failures.single.errorCode, 9005);
    });

    test('an unknown code still maps to a batch failure', () {
      // `_localizeFaultCode`'s `_` arm is `errorUnexpected` — localized. So even a
      // code nothing recognises reaches the user in their own language, which the
      // raw-detail path did not.
      final error = mapUspErrorToServiceError(_thrownFrom(refused(code: 8123)));

      expect(error, isA<UspCompleteFailureError>());
      expect(
          (error as UspCompleteFailureError).failures.single.errorCode, 8123);
    });

    test('a refusal with NO code is not raw English either', () {
      // Round 2's Critical, and the half the coded arm could not reach. Two reviewers
      // disagreed about whether this path exists; it does — `_operateRefusal` builds
      // exactly this when the agent's error detail is absent, which the
      // "still throws when the error detail is missing entirely" test above
      // establishes independently.
      //
      // Asserted as "the log string is not the user-facing message" rather than as an
      // exact sentence: the point is that `UnexpectedError.detail` is rendered
      // verbatim, so leaving it set is what put English on screen in all 26 locales.
      final thrown = _thrownFrom({
        'success': false,
        'result': {'data': <String, dynamic>{}},
      });
      final error = mapUspErrorToServiceError(thrown);

      expect(error, isA<UnexpectedError>());
      expect((error as UnexpectedError).detail, isNull,
          reason:
              'a set `detail` is surfaced verbatim, and this one is a log line');
      // The raw string is not lost — it stays available for logs and diagnostics.
      expect(error.originalError, thrown);
    });

    test('a native operation error with no code keeps its own mapping', () {
      // The three string arms sit after the generalised one and must stay
      // reachable: they match native `OperationError::*` strings, which carry no
      // `(code: N)` suffix, so `faultCode` is null and the new `if` declines.
      // The `<verb> failed: ` prefix is what `parseUspError` strips before reading
      // the category, so the bare `Operation error: …` a first draft of this test
      // used was never classified as one at all.
      expect(
        mapUspErrorToServiceError(
            'Get failed: Operation error: Path not found: Device.Bogus.Path'),
        isA<ResourceNotFoundError>(),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Round-2 review remediation
  // ══════════════════════════════════════════════════════════════════════════
  group('UspClient.extractOperateResult — round-2 remediation', () {
    test('an infinite code does not crash the refusal', () {
      // My own round-1 fix had this hole, and it is a measured one:
      // `double.infinity.truncateToDouble()` **is** infinity, so the normalisation
      // guard passed for ±Infinity and `toInt()` threw
      // `UnsupportedError: Infinity or NaN toInt` — swapping the refusal string for
      // a crash and losing the code and the router's message with it. NaN was safe
      // only because `NaN != NaN`.
      final thrown = _thrownFrom({
        'success': false,
        'result': {
          'error': {
            'Device.X()': {'errorCode': double.infinity, 'errorMessage': 'odd'},
          },
        },
      });

      expect(thrown, contains('refused'));
      expect(thrown, contains('Infinity'),
          reason: 'not a fault code, so it is rendered rather than normalised');
      expect(parseUspError(thrown)?.faultCode, isNull);
    });

    test('a code in the router message does not steer the category', () {
      // The suffix is appended *after* the router's verbatim message, so a vendor
      // message carrying its own `(code: N)` used to win `firstMatch`. Measured:
      // with 9001 in the message and 7022 in the suffix, the parser returned 9001.
      final thrown = _thrownFrom({
        'success': false,
        'result': {
          'error': {
            'Device.X()': {
              'errorCode': 7022,
              'errorMessage': 'upstream said (code: 9001)',
            },
          },
        },
      });

      expect(parseUspError(thrown)?.faultCode, 7022,
          reason:
              'the suffix is the code; a code-shaped substring of prose is not');
    });

    test('9999 is not treated as a refusal', () {
      // `_localizeFaultCode` maps 9999 to `errorNetwork`, and its own table says
      // 9999 "never reached the router". Routing a *refusal* there would report the
      // router answering as the network failing — the exact confusion #1533 exists
      // to remove. It should never arrive (the code comes from the agent's own
      // error map), which is why this is a guard rather than a branch.
      final error = mapUspErrorToServiceError(_thrownFrom(refused(code: 9999)));

      expect(error, isNot(isA<UspCompleteFailureError>()));
    });

    test('the failure detail carries the router message, not a 7022 label', () {
      // `'Command Failure'` is TR-369's name for 7022 alone. Once the arm covered
      // every code it was being stamped onto 9005 and 7004 refusals too — a wrong
      // label, and a visible one: `usp_test_console_view.dart` renders `failures`.
      final error = mapUspErrorToServiceError(
          _thrownFrom(refused(code: 9005, message: 'no such object')));

      final detail = (error as UspCompleteFailureError).failures.single;
      expect(detail.errorMessage, isNot('Command Failure'));
      expect(detail.errorMessage, contains('no such object'));
    });
  });

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
