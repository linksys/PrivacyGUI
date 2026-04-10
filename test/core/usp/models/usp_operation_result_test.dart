import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/models/usp_operation_result.dart';

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
      expect(emptyResult.isCompleteSuccess, true); // But still complete success (no errors)
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

      expect(result.errorSummary, 'Device.WiFi.SSID.1.Enable: Parameter not writable');
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
          UspPartialSuccess(successes: final s, failures: final f) => (s.length, f.length),
          UspFailure(errors: final errors) => (0, errors.length),
        };
      }

      const successes = [
        UspSuccessDetail(requestedPath: 'path1'),
        UspSuccessDetail(requestedPath: 'path2'),
      ];
      const failures = [
        UspErrorDetail(requestedPath: 'path3', errorCode: 7004, errorMessage: 'error'),
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
    test('should parse complete success result', () {
      final rawResult = {
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

      final result = UspResultParser.parseSetResult(rawResult);

      expect(result, isA<UspSuccess>());
      final success = result as UspSuccess;
      expect(success.details, hasLength(1));
      expect(success.details.first.requestedPath, 'Device.WiFi.SSID.1.SSID');
      expect(success.allUpdatedInstances, hasLength(1));
      expect(success.allUpdatedInstances.first.affectedPath, 'Device.WiFi.SSID.1.');
    });

    test('should parse partial success result', () {
      final rawResult = {
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
            'requestedPath': 'Device.WiFi.SSID.1.Enable',
            'success': false,
            'errorCode': 7004,
            'errorMessage': 'Parameter not writable'
          }
        ]
      };

      final result = UspResultParser.parseSetResult(rawResult);

      expect(result, isA<UspPartialSuccess>());
      final partial = result as UspPartialSuccess;
      expect(partial.successes, hasLength(1));
      expect(partial.failures, hasLength(1));
      expect(partial.failures.first.errorCode, 7004);
    });

    test('should parse complete failure result', () {
      final rawResult = {
        'overallSuccess': false,
        'hasAnySuccess': false,
        'hasErrors': true,
        'results': [
          {
            'requestedPath': 'Device.Invalid.Path',
            'success': false,
            'errorCode': 7026,
            'errorMessage': 'Parameter not found'
          }
        ]
      };

      final result = UspResultParser.parseSetResult(rawResult);

      expect(result, isA<UspFailure>());
      final failure = result as UspFailure;
      expect(failure.errors, hasLength(1));
      expect(failure.errors.first.errorCode, 7026);
      expect(failure.errors.first.isParameterNotFound, true);
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