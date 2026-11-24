import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/errors/usp_refusal_reason.dart';
import 'package:privacy_gui/core/usp/models/usp_operation_result.dart';

import '../../../mocks/test_data/usp_add_refusal_test_data.dart';
import '../../../mocks/test_data/usp_envelope_test_data.dart';

void main() {
  group('UspOperationResult sealed class', () {
    test('UspSuccess should indicate complete success', () {
      // Test with actual successful operations
      const successDetails = [
        UspSuccessDetail(requestedPath: 'Device.Test.Path'),
      ];
      const result = UspSuccess<void>(successDetails);

      expect(result.hasAnySuccess, true);
      expect(result.isCompleteSuccess, true);
      expect(result.hasErrors, false);
      expect(result.isSuccessfulInContext(), true);
      expect(result.isSuccessfulInContext(allowPartial: true), true);

      // Test empty success case separately
      const emptyResult = UspSuccess<void>([]);
      expect(emptyResult.hasAnySuccess, false); // No actual operations
      expect(emptyResult.isCompleteSuccess,
          true); // But still complete success (no errors)
      expect(emptyResult.hasErrors, false);
    });

    test('UspPartialSuccess should indicate partial success', () {
      const successes = [
        UspSuccessDetail(requestedPath: 'Device.WiFi.SSID.1.SSID'),
      ];
      const failures = [
        UspErrorDetail(
          requestedPath: 'Device.WiFi.SSID.1.Enable',
          errorCode: 7004,
          errorMessage: 'Parameter not writable',
        ),
      ];
      const result = UspPartialSuccess<void>(successes, failures);

      expect(result.hasAnySuccess, true);
      expect(result.isCompleteSuccess, false);
      expect(result.hasErrors, true);
      expect(result.isSuccessfulInContext(), false);
      expect(result.isSuccessfulInContext(allowPartial: true), true);

      expect(result.errorSummary,
          'Device.WiFi.SSID.1.Enable: Parameter not writable');
      expect(result.successSummary, 'Device.WiFi.SSID.1.SSID');
    });

    test('UspFailure should indicate complete failure', () {
      const errors = [
        UspErrorDetail(
          requestedPath: 'Device.WiFi.SSID.1.SSID',
          errorCode: 7005,
          errorMessage: 'Invalid parameter name',
        ),
        UspErrorDetail(
          requestedPath: 'Device.WiFi.SSID.1.Enable',
          errorCode: 7004,
          errorMessage: 'Parameter not writable',
        ),
      ];
      const result = UspFailure<void>(errors);

      expect(result.hasAnySuccess, false);
      expect(result.isCompleteSuccess, false);
      expect(result.hasErrors, true);
      expect(result.isSuccessfulInContext(), false);
      expect(result.isSuccessfulInContext(allowPartial: true), false);

      expect(result.errorSummary, contains('Invalid parameter name'));
      expect(result.errorSummary, contains('Parameter not writable'));

      final writableErrors = result.getErrorsByCode(7004);
      expect(writableErrors, hasLength(1));
      expect(writableErrors.first.requestedPath, 'Device.WiFi.SSID.1.Enable');
    });
  });

  group('Pattern matching with switch expressions', () {
    test('should handle all cases correctly', () {
      // Helper function to test pattern matching with dynamic dispatch
      String getResultType(UspOperationResult result) {
        return switch (result) {
          UspSuccess() => 'success',
          UspPartialSuccess() => 'partial',
          UspFailure() => 'failure',
        };
      }

      // Test complete success
      const success = UspSuccess<void>([]);
      expect(getResultType(success), 'success');

      // Test partial success
      const partial = UspPartialSuccess<void>([], []);
      expect(getResultType(partial), 'partial');

      // Test failure
      const failure = UspFailure<void>([]);
      expect(getResultType(failure), 'failure');
    });

    test('should extract data from pattern matching', () {
      // Helper function to extract counts from any result type
      (int, int) getCounts(UspOperationResult result) {
        return switch (result) {
          UspSuccess(details: final details) => (details.length, 0),
          UspPartialSuccess(successes: final s, failures: final f) => (
              s.length,
              f.length
            ),
          UspFailure(errors: final errors) => (0, errors.length),
        };
      }

      const successes = [
        UspSuccessDetail(requestedPath: 'path1'),
        UspSuccessDetail(requestedPath: 'path2'),
      ];
      const failures = [
        UspErrorDetail(
            requestedPath: 'path3', errorCode: 7004, errorMessage: 'error'),
      ];
      const result = UspPartialSuccess<void>(successes, failures);

      final (successCount, errorCount) = getCounts(result);

      expect(successCount, 2);
      expect(errorCount, 1);
    });
  });

  group('UspErrorDetail', () {
    test('should correctly identify USP error codes', () {
      const error1 = UspErrorDetail(
        requestedPath: 'test',
        errorCode: 7004,
        errorMessage: 'Parameter not writable',
      );

      expect(error1.isParameterNotWritable, true);
      expect(error1.isInvalidParameterName, false);
      expect(error1.isRetryable, false);

      const error2 = UspErrorDetail(
        requestedPath: 'test',
        errorCode: 7001,
        errorMessage: 'Network error',
      );

      expect(error2.isRetryable, true);
    });
  });

  group('UspResultParser', () {
    // Tests use the unified format: {success, result: {data, errors?}}

    test('should parse complete success result', () {
      // success=true, no errors
      final rawResult = {
        'success': true,
        'result': {
          'data': {
            'Device.WiFi.SSID.1.SSID': 'NewNetwork',
          },
        },
      };

      final result = UspResultParser.parseSetResult(rawResult);

      expect(result, isA<UspSuccess>());
      final success = result as UspSuccess;
      expect(success.details, hasLength(1));
      expect(success.details.first.requestedPath, 'bulk_operation');
      expect(success.details.first.retrievedParams?['Device.WiFi.SSID.1.SSID'],
          'NewNetwork');
    });

    test('should parse partial success result', () {
      // success=true, but errors has an entry for the refused parameter
      final rawResult = UspEnvelopeTestData.parameterErrors(
        {
          'Device.WiFi.SSID.1.Enable': (
            code: 7004,
            message: 'Parameter not writable',
          ),
        },
        success: true,
        data: {'Device.WiFi.SSID.1.SSID': 'NewNetwork'},
      );

      final result = UspResultParser.parseSetResult(rawResult);

      expect(result, isA<UspPartialSuccess>());
      final partial = result as UspPartialSuccess;
      expect(partial.successes, hasLength(1));
      expect(partial.failures, hasLength(1));
      expect(partial.failures.first.errorCode, 7004);
      expect(partial.failures.first.requestedPath, 'Device.WiFi.SSID.1.Enable');
      expect(partial.failures.first.kind, UspErrorKind.parameter);
    });

    test('should parse complete failure result', () {
      // success=false
      final rawResult = UspEnvelopeTestData.pathErrors(
        {'Device.Invalid.Path': (code: 7026, message: 'Parameter not found')},
        success: false,
      );

      final result = UspResultParser.parseSetResult(rawResult);

      expect(result, isA<UspFailure>());
      final failure = result as UspFailure;
      expect(failure.errors, hasLength(1));
      expect(failure.errors.first.errorCode, 7026);
      expect(failure.errors.first.isParameterNotFound, true);
      expect(failure.errors.first.kind, UspErrorKind.path);
    });

    test('should create empty success result', () {
      final result = UspResultParser.createEmptySuccess<void>();

      expect(result, isA<UspSuccess>());
      final success = result as UspSuccess;
      expect(success.details, isEmpty);
    });

    test('should create failure from exception', () {
      final exception = Exception('Network timeout');
      final result = UspResultParser.createFailureFromException<void>(
        exception,
        'Device.WiFi.SSID.1.SSID',
      );

      expect(result, isA<UspFailure>());
      final failure = result as UspFailure;
      expect(failure.errors, hasLength(1));
      expect(failure.errors.first.requestedPath, 'Device.WiFi.SSID.1.SSID');
      expect(failure.errors.first.errorCode, -1);
      expect(failure.errors.first.errorMessage, contains('Network timeout'));
    });
  });

  // linksys/FWDEV#204: the firmware names why it refused at the start of the
  // refused leaf's message; `UspRefusalReason.fromErrorMessage` (its own test
  // file) reads it, and the parser stamps it on each entry. Envelope verbatim
  // from the bench
  // (FLWRT 2.0.3.26100921, 2026-10-12, Device.NAT.PortMapping, the app's WASM
  // client, allowPartial:false).
  group('UspResultParser — the reason a refused write names', () {
    const p = 'Device.NAT.PortMapping.2.';
    const groupFailed = "SetParameterGroup: group set failed at "
        "'Device.NAT.PortMapping.2.ExternalPortEndRange' (Invalid value)";

    test(
        'a refused Set: the refused leaf carries the reason, wherever it is '
        'listed; the leaves that only failed with it carry none', () {
      final result = UspResultParser.parseSetResult(
        UspEnvelopeTestData.parameterErrors(
          {
            '${p}ExternalPort': (code: 7012, message: groupFailed),
            '${p}ExternalPortEndRange': (
              code: 7012,
              message: 'ErrorRulesOverlap: external ports 18070-18090 are '
                  'already forwarded.',
            ),
            '${p}InternalPort': (code: 7012, message: groupFailed),
            '${p}Description': (code: 7012, message: groupFailed),
          },
          success: false,
        ),
      );

      final errors = (result as UspFailure).errors;
      final byPath = {for (final e in errors) e.requestedPath: e.refusalReason};
      expect(byPath, {
        '${p}ExternalPort': UspRefusalReason.unknown,
        '${p}ExternalPortEndRange': UspRefusalReason.rulesOverlap,
        '${p}InternalPort': UspRefusalReason.unknown,
        '${p}Description': UspRefusalReason.unknown,
      });
    });
  });

  // usp-client 0.14.0 (linksys/usp_framework#114). The envelope is what 0.14.0
  // returns for the bench's captured AddResp (FW 2.0.4.26103108, 2026-11-09,
  // a 26th port trigger), decoded from those bytes; 0.13.0 returned the same
  // `data` with no `error`, which read as a clean success.
  group('UspResultParser — a refused Add (usp-client 0.14.0)', () {
    const row = 'Device.NAT.PortTrigger.26.';
    test('reads as a partial success: the row, and every refused parameter',
        () {
      final result =
          UspResultParser.parseAddResult(UspAddRefusalTestData.refusedAdd(
        instances: [row],
        refusedRow: row,
        otherParams: ['Enable', 'Description', 'PortEndRange', 'Protocol'],
      ));

      expect(result, isA<UspPartialSuccess<List<String>>>());
      final partial = result as UspPartialSuccess<List<String>>;
      expect(
          partial.successes.single.createdInstances!.single.affectedPath, row);
      expect(partial.failures, hasLength(5));
      expect(
          partial.failures
              .singleWhere((f) => f.requestedPath == '${row}Port')
              .errorMessage,
          'ErrorTooManyRules: at most 25 port triggering rules.');
      // The one FWDEV#204 reason no refused Set can produce: only an Add
      // reaches the limit, so it needed 0.14.0 to arrive at all.
      expect(
          partial.failures
              .singleWhere((f) => f.requestedPath == '${row}Port')
              .refusalReason,
          UspRefusalReason.tooManyRules);
    });
  });

  // usp-client 0.16.0 returns every error twice: the `errors` list and the
  // deprecated `error` map, which the next minor release drops. A write's
  // failures are read from the list only, so dropping the map changes nothing.
  group('UspResultParser — reads the errors list (usp-client 0.16.0)', () {
    test('a failure comes from errors, never from the deprecated error map',
        () {
      final raw = UspEnvelopeTestData.parameterErrors(
        {'Device.WiFi.SSID.1.Enable': (code: 7004, message: 'Not writable')},
        success: true,
        data: {'Device.WiFi.SSID.1.SSID': 'NewNetwork'},
      );
      (raw['result'] as Map<String, dynamic>)['error'] = {
        'Device.Some.Other.Path': {'errorCode': 7012, 'errorMessage': 'Stale'},
      };

      final failures =
          (UspResultParser.parseSetResult(raw) as UspPartialSuccess).failures;

      expect(
          failures.map((f) => f.requestedPath), ['Device.WiFi.SSID.1.Enable']);
    });

    test('a write that succeeded with only an error map reads as a success',
        () {
      final result = UspResultParser.parseSetResult({
        'success': true,
        'result': {
          'data': <String, dynamic>{},
          'error': {
            'Device.WiFi.SSID.1.Enable': {
              'errorCode': 7004,
              'errorMessage': 'Not writable',
            },
          },
        },
      });

      expect(result, isA<UspSuccess>());
    });

    test(
        'two errors under one path are both kept, where the map would keep '
        'only the last', () {
      // Two port mappings added to the same table, both refused: one
      // `kind: path` entry each, both keyed by the table path that was
      // requested.
      final result = UspResultParser.parseAddResult(
        UspEnvelopeTestData.envelope(
          success: false,
          data: const {'affectedCount': 0, 'instances': <String>[]},
          errors: [
            (
              kind: 'path',
              path: 'Device.NAT.PortMapping.',
              errorCode: 7005,
              errorMessage: 'ErrorTooManyRules: at most 25 rules.',
            ),
            (
              kind: 'path',
              path: 'Device.NAT.PortMapping.',
              errorCode: 7012,
              errorMessage: 'ErrorRulesOverlap: external ports overlap.',
            ),
          ],
        ),
      );

      final errors = (result as UspFailure).errors;
      expect(errors.map((e) => e.errorCode), [7005, 7012]);
      expect(errors.map((e) => e.refusalReason), [
        UspRefusalReason.tooManyRules,
        UspRefusalReason.rulesOverlap,
      ]);
    });

    test('an entry that names no path is keyed by the empty path', () {
      // The client's 9997 for input it could not read names no path.
      final result = UspResultParser.parseSetResult(
        UspEnvelopeTestData.failedAsAWhole(
          const [],
          errorCode: 9997,
          errorMessage: 'Validation error: parameters must be an object',
        ),
      );

      final error = (result as UspFailure).errors.single;
      expect(error.requestedPath, '');
      expect(error.errorCode, 9997);
      expect(error.kind, UspErrorKind.request);
    });

    test('a failure of the whole call is kind request, one per path', () {
      final result = UspResultParser.parseDeleteResult(
        UspEnvelopeTestData.failedAsAWhole(
          const ['Device.NAT.PortMapping.3.', 'Device.NAT.PortMapping.4.'],
          errorCode: 9999,
          errorMessage: 'Transport error: Failed to fetch',
        ),
      );

      final errors = (result as UspFailure).errors;
      expect(errors.map((e) => e.requestedPath),
          ['Device.NAT.PortMapping.3.', 'Device.NAT.PortMapping.4.']);
      expect(errors.map((e) => e.kind), everyElement(UspErrorKind.request));
    });

    test('a kind the client does not name reads as unknown', () {
      final result = UspResultParser.parseSetResult(
        UspEnvelopeTestData.envelope(
          success: false,
          errors: [
            (
              kind: 'something-new',
              path: 'Device.WiFi.SSID.1.SSID',
              errorCode: 7002,
              errorMessage: 'Internal error',
            ),
          ],
        ),
      );

      expect((result as UspFailure).errors.single.kind, UspErrorKind.unknown);
    });

    test('a failure with no errors at all still fails, with no detail', () {
      final result = UspResultParser.parseAddResult({
        'success': false,
        'result': {'data': <String, dynamic>{}},
      });

      final error = (result as UspFailure).errors.single;
      expect(error.errorCode, -1);
      expect(error.kind, UspErrorKind.unknown);
    });
  });

  group('Instance data classes', () {
    test('UspUpdatedInstance should parse correctly', () {
      final map = {
        'affectedPath': 'Device.WiFi.SSID.1.',
        'updatedParams': {'SSID': 'NewNetwork', 'Enable': 'true'}
      };

      final instance = UspUpdatedInstance.fromMap(map);

      expect(instance.affectedPath, 'Device.WiFi.SSID.1.');
      expect(instance.updatedParams['SSID'], 'NewNetwork');
      expect(instance.updatedParams['Enable'], 'true');
    });

    test('UspCreatedInstance should parse correctly', () {
      final map = {
        'affectedPath': 'Device.NAT.PortMapping.3.',
        'initialParams': {'Protocol': 'TCP', 'ExternalPort': '80'}
      };

      final instance = UspCreatedInstance.fromMap(map);

      expect(instance.affectedPath, 'Device.NAT.PortMapping.3.');
      expect(instance.initialParams['Protocol'], 'TCP');
      expect(instance.initialParams['ExternalPort'], '80');
    });

    test('UspDeletedInstance should parse correctly', () {
      final map = {
        'affectedPath': 'Device.NAT.PortMapping.3.',
      };

      final instance = UspDeletedInstance.fromMap(map);

      expect(instance.affectedPath, 'Device.NAT.PortMapping.3.');
    });
  });
}
