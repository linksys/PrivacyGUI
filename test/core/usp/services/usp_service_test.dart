import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

/// Tests for USP structured response core functionality
/// Focus on result parsing logic, sealed class conversion, and error handling
void main() {
  group('USP Structured Response Parsing Tests', () {
    group('UspResultParser parsing logic', () {
      test('parseSetResult() should create UspSuccess for complete success',
          () {
        // Arrange - mock response with all operations successful
        final mockResponse = {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': [
            {
              'requestedPath': 'Device.WiFi.SSID.1.SSID',
              'success': true,
              'updatedInstances': [
                {
                  'affectedPath': 'Device.WiFi.SSID.1.',
                  'updatedParams': {'SSID': 'NewNetwork'}
                }
              ]
            }
          ]
        };

        // Act - parse the response into structured result
        final result = UspResultParser.parseSetResult(mockResponse);

        // Assert - verify UspSuccess with correct data
        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
        expect(success.details[0].requestedPath, 'Device.WiFi.SSID.1.SSID');
        expect(success.allUpdatedInstances, hasLength(1));
        expect(
            success.allUpdatedInstances[0].affectedPath, 'Device.WiFi.SSID.1.');
        expect(
            success.allUpdatedInstances[0].updatedParams['SSID'], 'NewNetwork');

        // Test context-aware success methods
        expect(success.isSuccessfulInContext(), true);
        expect(success.isSuccessfulInContext(allowPartial: false), true);
        expect(success.isSuccessfulInContext(allowPartial: true), true);
      });

      test('parseSetResult() should create UspPartialSuccess for mixed results',
          () {
        // Arrange - mock response with both success and failure operations
        final mockResponse = {
          'overallSuccess': false,
          'hasAnySuccess': true,
          'hasErrors': true,
          'results': [
            {
              'requestedPath': 'Device.WiFi.SSID.1.SSID',
              'success': true,
              'updatedInstances': [
                {
                  'affectedPath': 'Device.WiFi.SSID.1.',
                  'updatedParams': {'SSID': 'NewNetwork'}
                }
              ]
            },
            {
              'requestedPath': 'Device.WiFi.SSID.1.InvalidParam',
              'success': false,
              'errorCode': 7004,
              'errorMessage': 'Parameter not writable'
            }
          ]
        };

        // Act - parse the mixed result response
        final result = UspResultParser.parseSetResult(mockResponse);

        // Assert - verify UspPartialSuccess with both successes and failures
        expect(result, isA<UspPartialSuccess>());
        final partial = result as UspPartialSuccess;

        expect(partial.successes, hasLength(1));
        expect(partial.failures, hasLength(1));
        expect(partial.successes[0].requestedPath, 'Device.WiFi.SSID.1.SSID');
        expect(partial.failures[0].requestedPath,
            'Device.WiFi.SSID.1.InvalidParam');
        expect(partial.failures[0].errorCode, 7004);
        expect(partial.failures[0].isParameterNotWritable, true);

        expect(partial.errorSummary, contains('Parameter not writable'));
        expect(partial.successSummary, contains('Device.WiFi.SSID.1.SSID'));

        // Test context-aware success methods for partial success
        expect(partial.isSuccessfulInContext(allowPartial: true), true);
        expect(partial.isSuccessfulInContext(allowPartial: false), false);
      });

      test('parseSetResult() should create UspFailure for complete failure',
          () {
        // Arrange - mock response with all operations failed
        final mockResponse = {
          'overallSuccess': false,
          'hasAnySuccess': false,
          'hasErrors': true,
          'results': [
            {
              'requestedPath': 'Device.Invalid.Path',
              'success': false,
              'errorCode': 7026,
              'errorMessage': 'Parameter not found'
            },
            {
              'requestedPath': 'Device.Another.Invalid.Path',
              'success': false,
              'errorCode': 7005,
              'errorMessage': 'Invalid parameter name'
            }
          ]
        };

        // Act - parse the complete failure response
        final result = UspResultParser.parseSetResult(mockResponse);

        // Assert - verify UspFailure with all error details
        expect(result, isA<UspFailure>());
        final failure = result as UspFailure;

        expect(failure.errors, hasLength(2));
        expect(failure.errors[0].isParameterNotFound, true);
        expect(failure.errors[1].isInvalidParameterName, true);
        expect(failure.errorSummary, contains('Parameter not found'));
        expect(failure.errorSummary, contains('Invalid parameter name'));

        final error7026s = failure.getErrorsByCode(7026);
        expect(error7026s, hasLength(1));
        expect(error7026s[0].requestedPath, 'Device.Invalid.Path');

        // Test context-aware success methods for failure
        expect(failure.isSuccessfulInContext(), false);
        expect(failure.isSuccessfulInContext(allowPartial: true), false);
      });

      test('parseAddResult() should handle created instances correctly', () {
        // Arrange - mock response for ADD operation with created instance
        final mockResponse = {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': [
            {
              'requestedPath': 'Device.NAT.PortMapping.',
              'success': true,
              'createdInstances': [
                {
                  'affectedPath': 'Device.NAT.PortMapping.3.',
                  'initialParams': {
                    'Protocol': 'TCP',
                    'ExternalPort': '80',
                    'InternalClient': '192.168.1.100'
                  }
                }
              ]
            }
          ]
        };

        // Act - parse ADD result with created instances
        final result = UspResultParser.parseAddResult(mockResponse);

        // Assert - verify created instance data is preserved
        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;

        expect(success.allCreatedInstances, hasLength(1));
        final created = success.allCreatedInstances[0];
        expect(created.affectedPath, 'Device.NAT.PortMapping.3.');
        expect(created.initialParams['Protocol'], 'TCP');
        expect(created.initialParams['ExternalPort'], '80');
        expect(created.initialParams['InternalClient'], '192.168.1.100');
      });

      test('parseDeleteResult() should handle deleted instances correctly', () {
        // Arrange - mock response for DELETE operation with deleted instance
        final mockResponse = {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': [
            {
              'requestedPath': 'Device.NAT.PortMapping.3.',
              'success': true,
              'deletedInstances': [
                {'affectedPath': 'Device.NAT.PortMapping.3.'}
              ]
            }
          ]
        };

        // Act - parse DELETE result with deleted instances
        final result = UspResultParser.parseDeleteResult(mockResponse);

        // Assert - verify deleted instance path is preserved
        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;

        expect(success.allDeletedInstances, hasLength(1));
        expect(success.allDeletedInstances[0].affectedPath,
            'Device.NAT.PortMapping.3.');
      });

      test('createEmptySuccess() should return empty success result', () {
        // Act - create empty success result (no operations performed)
        final result = UspResultParser.createEmptySuccess<void>();

        // Assert - verify empty success semantics
        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, isEmpty);
        expect(success.hasAnySuccess, false); // No actual operations performed
        expect(success.isCompleteSuccess, true); // But no errors either
        expect(success.hasErrors, false);
      });

      test(
          'createFailureFromException() should convert exceptions to UspFailure',
          () {
        // Arrange - exception and requested path context
        final exception = Exception('Network connection timeout');
        const requestedPath = 'Device.WiFi.SSID.1.SSID';

        // Act - convert exception to structured failure
        final result = UspResultParser.createFailureFromException<void>(
          exception,
          requestedPath,
        );

        // Assert - verify exception is properly wrapped
        expect(result, isA<UspFailure>());
        final failure = result as UspFailure;

        expect(failure.errors, hasLength(1));
        expect(failure.errors[0].requestedPath, requestedPath);
        expect(failure.errors[0].errorCode, -1); // Default exception error code
        expect(failure.errors[0].errorMessage,
            contains('Network connection timeout'));
      });
    });

    group('Sealed Class Pattern Matching Tests', () {
      test('pattern matching should work with all result types', () {
        // Arrange - non-empty results for meaningful testing
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

        // Act & Assert - verify pattern matching works correctly
        for (final result in results) {
          final type = switch (result) {
            UspSuccess() => 'success',
            UspPartialSuccess() => 'partial',
            UspFailure() => 'failure',
          };

          // Use type-based assertions instead of runtime type checking
          if (result is UspSuccess) {
            expect(type, 'success');
            expect(
                result.hasAnySuccess, true); // Has actual successful operations
            expect(result.isCompleteSuccess, true);
            expect(result.hasErrors, false);
          } else if (result is UspPartialSuccess) {
            expect(type, 'partial');
            expect(
                result.hasAnySuccess, true); // Has actual successful operations
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
        // Arrange - test data with known counts
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

        // Act & Assert - verify data extraction from pattern matching
        for (final result in results) {
          final (successCount, errorCount) = switch (result) {
            UspSuccess(details: final details) => (details.length, 0),
            UspPartialSuccess(successes: final s, failures: final f) => (
                s.length,
                f.length
              ),
            UspFailure(errors: final errors) => (0, errors.length),
          };

          // Use type-based assertions instead of runtime type checking
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
        // Common USP error code classification tests
        final testCases = [
          (7004, true, false, false, false, false), // Parameter not writable
          (7005, false, true, false, false, false), // Invalid parameter name
          (7006, false, false, true, false, false), // Invalid parameter value
          (7026, false, false, false, true, false), // Parameter not found
          (7027, false, false, false, false, true), // Object not found
          (9999, false, false, false, false, false), // Unknown error
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
        // Network errors and unknown errors are retryable
        final retryableErrors = [7001, 7002, 7003, 9999];
        // Parameter errors are not retryable
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

        // Test isErrorCode method
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
        // Arrange - mock GET operation response
        final mockResponse = {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': [
            {
              'requestedPath': 'Device.WiFi.SSID.1.SSID',
              'success': true,
              'retrievedParams': {'SSID': 'TestNetwork'},
            }
          ]
        };

        // Act - parse GET result
        final result = UspResultParser.parseGetResult(mockResponse);

        // Assert - verify GET result structure
        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
        expect(success.details[0].requestedPath, 'Device.WiFi.SSID.1.SSID');
      });

      test('UspResultParser parseOperateResult should handle OPERATE operation',
          () {
        // Arrange - mock OPERATE operation response
        final mockResponse = {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': [
            {
              'requestedPath': 'Device.IP.Diagnostics.IPPing()',
              'success': true,
              'outputArgs': {'Status': 'Success', 'PacketsReceived': '4'},
            }
          ]
        };

        // Act - parse OPERATE result
        final result = UspResultParser.parseOperateResult(mockResponse);

        // Assert - verify OPERATE result structure
        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
        expect(
            success.details[0].requestedPath, 'Device.IP.Diagnostics.IPPing()');
      });
    });

    group('Edge Cases and Error Handling Tests', () {
      test('should handle empty results array', () {
        // Arrange - empty results array but overall success
        final mockResponse = {
          'overallSuccess': true,
          'hasAnySuccess': false,
          'hasErrors': false,
          'results': <Map<String, dynamic>>[]
        };

        // Act - parse empty results
        final result = UspResultParser.parseSetResult(mockResponse);

        // Assert - empty success with correct semantics
        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, isEmpty);
        expect(success.hasAnySuccess, false); // No operations performed
        expect(success.isCompleteSuccess, true); // But no errors
      });

      test('should handle missing optional fields in response', () {
        // Arrange - response with missing optional fields
        final mockResponse = {
          'overallSuccess': true,
          'results': [
            {
              'requestedPath': 'Device.Test.Path',
              'success': true,
              // Missing updatedInstances, createdInstances, etc.
            }
          ]
          // Missing hasAnySuccess, hasErrors
        };

        // Act - parse response with missing fields
        final result = UspResultParser.parseSetResult(mockResponse);

        // Assert - graceful handling of missing fields
        expect(result, isA<UspSuccess>());
        final success = result as UspSuccess;
        expect(success.details, hasLength(1));
        expect(success.details[0].updatedInstances, isNull);
      });

      test('should handle malformed error result', () {
        // Arrange - malformed error with missing errorCode/errorMessage
        final mockResponse = {
          'overallSuccess': false,
          'hasErrors': true,
          'results': [
            {
              'requestedPath': 'Device.Test.Path',
              'success': false,
              // Missing errorCode and errorMessage
            }
          ]
        };

        // Act - parse malformed error response
        final result = UspResultParser.parseSetResult(mockResponse);

        // Assert - graceful fallback for missing error details
        expect(result, isA<UspFailure>());
        final failure = result as UspFailure;
        expect(failure.errors, hasLength(1));
        expect(failure.errors[0].errorCode, -1); // Default fallback
        expect(failure.errors[0].errorMessage,
            'Unknown error'); // Default fallback
      });
    });
  });
}
