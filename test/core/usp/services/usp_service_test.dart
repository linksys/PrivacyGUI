import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

/// Tests for USP structured response core functionality
/// Focus on result parsing logic, sealed class conversion, and error handling
///
/// These tests use WASM v0.11.0 format: {success, result: {data, error?}}
void main() {
  group('USP Structured Response Parsing Tests', () {
    group('UspResultParser parsing logic', () {
      test('parseSetResult() should create UspSuccess for complete success',
          () {
        // WASM v0.11.0 format: success=true, no error field
        final mockResponse = {
          'success': true,
          'result': {
            'data': {
              'Device.WiFi.SSID.1.SSID': 'NewNetwork',
            },
          },
        };

        final result = UspResultParser.parseSetResult(mockResponse);

        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
        expect(success.details[0].requestedPath, 'bulk_operation');
        expect(success.details[0].retrievedParams?['Device.WiFi.SSID.1.SSID'],
            'NewNetwork');

        expect(success.isSuccessfulInContext(), true);
        expect(success.isSuccessfulInContext(allowPartial: false), true);
        expect(success.isSuccessfulInContext(allowPartial: true), true);
      });

      test('parseSetResult() should create UspPartialSuccess for mixed results',
          () {
        // WASM v0.11.0 format: success=true, but has error field
        final mockResponse = {
          'success': true,
          'result': {
            'data': {
              'Device.WiFi.SSID.1.SSID': 'NewNetwork',
            },
            'error': {
              'Device.WiFi.SSID.1.InvalidParam': {
                'errorCode': 7004,
                'errorMessage': 'Parameter not writable',
              },
            },
          },
        };

        final result = UspResultParser.parseSetResult(mockResponse);

        expect(result, isA<UspPartialSuccess>());
        final partial = result as UspPartialSuccess;

        expect(partial.successes, hasLength(1));
        expect(partial.failures, hasLength(1));
        expect(partial.successes[0].requestedPath, 'bulk_operation');
        expect(partial.failures[0].requestedPath,
            'Device.WiFi.SSID.1.InvalidParam');
        expect(partial.failures[0].errorCode, 7004);
        expect(partial.failures[0].isParameterNotWritable, true);

        expect(partial.errorSummary, contains('Parameter not writable'));

        expect(partial.isSuccessfulInContext(allowPartial: true), true);
        expect(partial.isSuccessfulInContext(allowPartial: false), false);
      });

      test('parseSetResult() should create UspFailure for complete failure',
          () {
        // WASM v0.11.0 format: success=false
        final mockResponse = {
          'success': false,
          'result': {
            'data': <String, dynamic>{},
            'error': {
              'Device.Invalid.Path': {
                'errorCode': 7026,
                'errorMessage': 'Parameter not found',
              },
              'Device.Another.Invalid.Path': {
                'errorCode': 7005,
                'errorMessage': 'Invalid parameter name',
              },
            },
          },
        };

        final result = UspResultParser.parseSetResult(mockResponse);

        expect(result, isA<UspFailure>());
        final failure = result as UspFailure;

        expect(failure.errors, hasLength(2));
        expect(failure.errorSummary, contains('Parameter not found'));
        expect(failure.errorSummary, contains('Invalid parameter name'));

        final error7026s = failure.getErrorsByCode(7026);
        expect(error7026s, hasLength(1));
        expect(error7026s[0].requestedPath, 'Device.Invalid.Path');

        expect(failure.isSuccessfulInContext(), false);
        expect(failure.isSuccessfulInContext(allowPartial: true), false);
      });

      test('parseAddResult() should handle created instances correctly', () {
        // WASM v0.11.0 format for ADD success
        final mockResponse = {
          'success': true,
          'result': {
            'data': {
              'createdPath': 'Device.NAT.PortMapping.3.',
            },
          },
        };

        final result = UspResultParser.parseAddResult(mockResponse);

        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
        expect(success.details[0].retrievedParams?['createdPath'],
            'Device.NAT.PortMapping.3.');
      });

      test('parseDeleteResult() should handle deleted instances correctly', () {
        // WASM v0.11.0 format for DELETE success
        final mockResponse = {
          'success': true,
          'result': {
            'data': {
              'deletedPath': 'Device.NAT.PortMapping.3.',
            },
          },
        };

        final result = UspResultParser.parseDeleteResult(mockResponse);

        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
      });

      test('createEmptySuccess() should return empty success result', () {
        final result = UspResultParser.createEmptySuccess<void>();

        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, isEmpty);
        expect(success.hasAnySuccess, false);
        expect(success.isCompleteSuccess, true);
        expect(success.hasErrors, false);
      });

      test(
          'createFailureFromException() should convert exceptions to UspFailure',
          () {
        final exception = Exception('Network connection timeout');
        const requestedPath = 'Device.WiFi.SSID.1.SSID';

        final result = UspResultParser.createFailureFromException<void>(
          exception,
          requestedPath,
        );

        expect(result, isA<UspFailure>());
        final failure = result as UspFailure;

        expect(failure.errors, hasLength(1));
        expect(failure.errors[0].requestedPath, requestedPath);
        expect(failure.errors[0].errorCode, -1);
        expect(failure.errors[0].errorMessage,
            contains('Network connection timeout'));
      });
    });

    group('Sealed Class Pattern Matching Tests', () {
      test('pattern matching should work with all result types', () {
        const successDetails = [
          UspSuccessDetail(requestedPath: 'test.success')
        ];
        const errorDetails = [
          UspErrorDetail(
              requestedPath: 'test.error',
              errorCode: 7004,
              errorMessage: 'error')
        ];

        final results = <UspOperationResult<void>>[
          UspSuccess(successDetails),
          UspPartialSuccess(successDetails, errorDetails),
          UspFailure(errorDetails),
        ];

        for (final result in results) {
          final type = switch (result) {
            UspSuccess() => 'success',
            UspPartialSuccess() => 'partial',
            UspFailure() => 'failure',
          };

          if (result is UspSuccess) {
            expect(type, 'success');
            expect(result.hasAnySuccess, true);
            expect(result.isCompleteSuccess, true);
            expect(result.hasErrors, false);
          } else if (result is UspPartialSuccess) {
            expect(type, 'partial');
            expect(result.hasAnySuccess, true);
            expect(result.isCompleteSuccess, false);
            expect(result.hasErrors, true);
          } else if (result is UspFailure) {
            expect(type, 'failure');
            expect(result.hasAnySuccess, false);
            expect(result.isCompleteSuccess, false);
            expect(result.hasErrors, true);
          }
        }
      });

      test('pattern matching should extract data correctly', () {
        const successDetails = [
          UspSuccessDetail(requestedPath: 'success-path')
        ];
        const errorDetails = [
          UspErrorDetail(
              requestedPath: 'error-path',
              errorCode: 7004,
              errorMessage: 'error')
        ];

        final results = <UspOperationResult<void>>[
          UspSuccess(successDetails),
          UspPartialSuccess(successDetails, errorDetails),
          UspFailure(errorDetails),
        ];

        for (final result in results) {
          final (successCount, errorCount) = switch (result) {
            UspSuccess(details: final details) => (details.length, 0),
            UspPartialSuccess(successes: final s, failures: final f) => (
                s.length,
                f.length
              ),
            UspFailure(errors: final errors) => (0, errors.length),
          };

          if (result is UspSuccess) {
            expect(successCount, 1);
            expect(errorCount, 0);
          } else if (result is UspPartialSuccess) {
            expect(successCount, 1);
            expect(errorCount, 1);
          } else if (result is UspFailure) {
            expect(successCount, 0);
            expect(errorCount, 1);
          }
        }
      });
    });

    group('UspErrorDetail Special Methods Tests', () {
      test('should identify USP error codes correctly', () {
        final testCases = [
          (7004, true, false, false, false, false),
          (7005, false, true, false, false, false),
          (7006, false, false, true, false, false),
          (7026, false, false, false, true, false),
          (7027, false, false, false, false, true),
          (9999, false, false, false, false, false),
        ];

        for (final (
              code,
              isNotWritable,
              isInvalidName,
              isInvalidValue,
              isParamNotFound,
              isObjNotFound
            ) in testCases) {
          final error = UspErrorDetail(
            requestedPath: 'test',
            errorCode: code,
            errorMessage: 'Test error $code',
          );

          expect(error.isParameterNotWritable, isNotWritable,
              reason: 'Error $code isParameterNotWritable');
          expect(error.isInvalidParameterName, isInvalidName,
              reason: 'Error $code isInvalidParameterName');
          expect(error.isInvalidParameterValue, isInvalidValue,
              reason: 'Error $code isInvalidParameterValue');
          expect(error.isParameterNotFound, isParamNotFound,
              reason: 'Error $code isParameterNotFound');
          expect(error.isObjectNotFound, isObjNotFound,
              reason: 'Error $code isObjectNotFound');
        }
      });

      test('should determine retryability correctly', () {
        final retryableErrors = [7001, 7002, 7003, 9999];
        final nonRetryableErrors = [7004, 7005, 7006, 7026, 7027];

        for (final code in retryableErrors) {
          final error = UspErrorDetail(
            requestedPath: 'test',
            errorCode: code,
            errorMessage: 'Retryable error',
          );
          expect(error.isRetryable, true,
              reason: 'Error $code should be retryable');
        }

        for (final code in nonRetryableErrors) {
          final error = UspErrorDetail(
            requestedPath: 'test',
            errorCode: code,
            errorMessage: 'Non-retryable error',
          );
          expect(error.isRetryable, false,
              reason: 'Error $code should not be retryable');
        }
      });
    });

    group('toString() Method Coverage Tests', () {
      test('UspSuccess toString should include details count', () {
        const details = [UspSuccessDetail(requestedPath: 'test.path')];
        const result = UspSuccess<void>(details);

        expect(result.toString(), contains('UspSuccess'));
        expect(result.toString(), contains('1 details'));
      });

      test('UspPartialSuccess toString should include counts', () {
        const successes = [UspSuccessDetail(requestedPath: 'success.path')];
        const failures = [
          UspErrorDetail(
              requestedPath: 'error.path',
              errorCode: 7004,
              errorMessage: 'error')
        ];
        const result = UspPartialSuccess<void>(successes, failures);

        expect(result.toString(), contains('UspPartialSuccess'));
        expect(result.toString(), contains('1 successes'));
        expect(result.toString(), contains('1 failures'));
      });

      test('UspFailure toString should include error count', () {
        const errors = [
          UspErrorDetail(
              requestedPath: 'error.path',
              errorCode: 7004,
              errorMessage: 'error')
        ];
        const result = UspFailure<void>(errors);

        expect(result.toString(), contains('UspFailure'));
        expect(result.toString(), contains('1 errors'));
      });
    });

    group('Helper Classes Coverage Tests', () {
      test('UspSuccessDetail toString should show requested path', () {
        const detail = UspSuccessDetail(requestedPath: 'Device.Test.Path');
        expect(detail.toString(), contains('UspSuccessDetail'));
        expect(detail.toString(), contains('Device.Test.Path'));
      });

      test('UspErrorDetail toString should show error info', () {
        const error = UspErrorDetail(
          requestedPath: 'Device.Test.Path',
          errorCode: 7004,
          errorMessage: 'Parameter not writable',
        );
        expect(error.toString(), contains('UspErrorDetail'));
        expect(error.toString(), contains('Device.Test.Path'));
        expect(error.toString(), contains('7004'));
        expect(error.toString(), contains('Parameter not writable'));

        expect(error.isErrorCode(7004), true);
        expect(error.isErrorCode(7005), false);
      });

      test(
          'UspUpdatedInstance toString should show affected path and param count',
          () {
        const instance = UspUpdatedInstance(
          affectedPath: 'Device.WiFi.SSID.1.',
          updatedParams: {'SSID': 'TestNetwork', 'Enable': 'true'},
        );
        expect(instance.toString(), contains('UspUpdatedInstance'));
        expect(instance.toString(), contains('Device.WiFi.SSID.1.'));
        expect(instance.toString(), contains('2 params'));
      });

      test(
          'UspCreatedInstance toString should show affected path and param count',
          () {
        const instance = UspCreatedInstance(
          affectedPath: 'Device.NAT.PortMapping.3.',
          initialParams: {'Protocol': 'TCP', 'ExternalPort': '80'},
        );
        expect(instance.toString(), contains('UspCreatedInstance'));
        expect(instance.toString(), contains('Device.NAT.PortMapping.3.'));
        expect(instance.toString(), contains('2 params'));
      });

      test('UspDeletedInstance toString should show affected path', () {
        const instance =
            UspDeletedInstance(affectedPath: 'Device.NAT.PortMapping.3.');
        expect(instance.toString(), contains('UspDeletedInstance'));
        expect(instance.toString(), contains('Device.NAT.PortMapping.3.'));
      });

      test('UspResultParser parseGetResult should handle GET operation', () {
        // WASM v0.11.0 format for GET
        final mockResponse = {
          'success': true,
          'result': {
            'data': {
              'Device.WiFi.SSID.1.SSID': 'TestNetwork',
            },
          },
        };

        final result = UspResultParser.parseGetResult(mockResponse);

        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
        expect(success.details[0].requestedPath, 'bulk_operation');
      });

      test('UspResultParser parseOperateResult should handle OPERATE operation',
          () {
        // WASM v0.11.0 format for OPERATE
        final mockResponse = {
          'success': true,
          'result': {
            'data': {
              'Status': 'Success',
              'PacketsReceived': '4',
            },
          },
        };

        final result = UspResultParser.parseOperateResult(mockResponse);

        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
        expect(success.details[0].requestedPath, 'bulk_operation');
      });
    });

    group('Edge Cases and Error Handling Tests', () {
      test('should handle empty results array', () {
        // WASM v0.11.0 format: success with empty data
        final mockResponse = {
          'success': true,
          'result': {
            'data': <String, dynamic>{},
          },
        };

        final result = UspResultParser.parseSetResult(mockResponse);

        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
        expect(success.details[0].retrievedParams, isEmpty);
      });

      test('should handle missing optional fields in response', () {
        // WASM v0.11.0 format: minimal success response
        final mockResponse = {
          'success': true,
          'result': {
            'data': {
              'Device.Test.Path': 'value',
            },
          },
        };

        final result = UspResultParser.parseSetResult(mockResponse);

        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
      });

      test('should handle malformed error result', () {
        // WASM v0.11.0 format: failure without specific error info
        final mockResponse = {
          'success': false,
          'result': <String, dynamic>{},
        };

        final result = UspResultParser.parseSetResult(mockResponse);

        expect(result, isA<UspFailure>());
        final failure = result as UspFailure;
        expect(failure.errors, hasLength(1));
        expect(failure.errors[0].errorCode, -1);
        expect(failure.errors[0].errorMessage, 'Operation failed');
      });
    });
  });
}
