import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';

void main() {
  group('parseUspError', () {
    test('parses Protocol error with fault code 7026', () {
      const raw =
          'Set failed: Protocol error: Decoding error: Received error response: '
          'CheckPathProperties: Path (Device.Bogus) does not exist in the schema (code: 7026)';

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.operation, 'Set');
      expect(result.category, UspErrorCategory.protocol);
      expect(result.faultCode, 7026);
      expect(result.httpStatus, isNull);
      expect(result.message, contains('Decoding error'));
    });

    test('parses Protocol error with fault code 7004', () {
      const raw =
          'Add failed: Protocol error: Decoding error: Received error response: '
          'CheckPathProperties: Path (Device.DeviceInfo) is not a multi-instance object (code: 7004)';

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.operation, 'Add');
      expect(result.category, UspErrorCategory.protocol);
      expect(result.faultCode, 7004);
    });

    test('parses Transport error with HTTP status', () {
      const raw = 'Delete failed: Transport error: HTTP error: HTTP 504';

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.operation, 'Delete');
      expect(result.category, UspErrorCategory.transport);
      expect(result.httpStatus, 504);
      expect(result.faultCode, isNull);
    });

    test('parses Authentication error', () {
      const raw = 'Login failed: Authentication error: Invalid credentials';

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.operation, 'Login');
      expect(result.category, UspErrorCategory.auth);
      expect(result.message, 'Invalid credentials');
    });

    test('parses Validation error', () {
      const raw =
          "Get failed: Validation error: Path must start with 'Device.'";

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.operation, 'Get');
      expect(result.category, UspErrorCategory.validation);
      expect(result.message, "Path must start with 'Device.'");
    });

    test('parses Transport error with Connection refused', () {
      const raw = 'Get failed: Transport error: Connection refused';

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.category, UspErrorCategory.transport);
      expect(result.message, 'Connection refused');
      expect(result.httpStatus, isNull);
    });

    test('parses Transport error with Request timeout', () {
      const raw = 'Set failed: Transport error: Request timeout';

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.category, UspErrorCategory.transport);
      expect(result.message, 'Request timeout');
    });

    test('parses Authentication error with Session expired', () {
      const raw = 'Get failed: Authentication error: Session expired';

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.category, UspErrorCategory.auth);
      expect(result.message, 'Session expired');
    });

    test('parses Operation error with Path not found', () {
      const raw =
          'Get failed: Operation error: Path not found: Device.Bogus.Path';

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.category, UspErrorCategory.operation);
      expect(result.message, contains('Path not found'));
    });

    test('parses Operation error with read-only', () {
      const raw =
          'Set failed: Operation error: Parameter is read-only: Device.DeviceInfo.Manufacturer';

      final result = parseUspError(raw);

      expect(result, isNotNull);
      expect(result!.category, UspErrorCategory.operation);
      expect(result.message, contains('read-only'));
    });

    test('returns null for non-USP error string', () {
      expect(parseUspError('some random error'), isNull);
      expect(parseUspError(''), isNull);
      expect(parseUspError(42), isNull);
    });

    test('preserves rawError', () {
      const raw = 'Get failed: Validation error: Path cannot be empty';
      final result = parseUspError(raw);
      expect(result!.rawError, raw);
      expect(result.toString(), raw);
    });
  });

  group('mapUspErrorToServiceError', () {
    test('maps auth Invalid credentials to InvalidCredentialsError', () {
      const raw = 'Login failed: Authentication error: Invalid credentials';
      expect(mapUspErrorToServiceError(raw), isA<InvalidCredentialsError>());
    });

    test('maps auth Session expired to SessionTokenExpiredError', () {
      const raw = 'Get failed: Authentication error: Session expired';
      expect(mapUspErrorToServiceError(raw), isA<SessionTokenExpiredError>());
    });

    test('maps auth Invalid token to InvalidSessionTokenError', () {
      const raw = 'Get failed: Authentication error: Invalid token: bad_token';
      expect(mapUspErrorToServiceError(raw), isA<InvalidSessionTokenError>());
    });

    test('maps auth Permission denied to UnauthorizedError', () {
      const raw = 'Set failed: Authentication error: Permission denied';
      expect(mapUspErrorToServiceError(raw), isA<UnauthorizedError>());
    });

    test('maps auth Authentication required to NotAuthenticatedError', () {
      const raw = 'Get failed: Authentication error: Authentication required';
      expect(mapUspErrorToServiceError(raw), isA<NotAuthenticatedError>());
    });

    test('maps Transport HTTP 401 to NotAuthenticatedError', () {
      const raw = 'Get failed: Transport error: HTTP error: HTTP 401';
      expect(mapUspErrorToServiceError(raw), isA<NotAuthenticatedError>());
    });

    test('maps Transport HTTP 504 to NetworkError', () {
      const raw = 'Delete failed: Transport error: HTTP error: HTTP 504';
      expect(mapUspErrorToServiceError(raw), isA<NetworkError>());
    });

    test('maps Transport Connection refused to ConnectivityError', () {
      const raw = 'Get failed: Transport error: Connection refused';
      expect(mapUspErrorToServiceError(raw), isA<ConnectivityError>());
    });

    test('maps Transport Request timeout to NetworkError', () {
      const raw = 'Set failed: Transport error: Request timeout';
      expect(mapUspErrorToServiceError(raw), isA<NetworkError>());
    });

    test('maps Protocol fault 7026 to ResourceNotFoundError', () {
      const raw =
          'Set failed: Protocol error: Decoding error: Received error response: '
          'CheckPathProperties: Path (Device.Bogus) does not exist in the schema (code: 7026)';
      expect(mapUspErrorToServiceError(raw), isA<ResourceNotFoundError>());
    });

    test('maps Protocol fault 7004 to InvalidInputError', () {
      const raw =
          'Add failed: Protocol error: Decoding error: Received error response: '
          'CheckPathProperties: Path (Device.DeviceInfo) is not a multi-instance object (code: 7004)';
      expect(mapUspErrorToServiceError(raw), isA<InvalidInputError>());
    });

    test('maps Protocol fault 7005 to InvalidInputError', () {
      const raw =
          'Set failed: Protocol error: Decoding error: Received error response: '
          'SetFailed: Invalid parameter name (code: 7005)';
      expect(mapUspErrorToServiceError(raw), isA<InvalidInputError>());
    });

    test('maps Protocol fault 7006 to InvalidInputError', () {
      const raw =
          'Set failed: Protocol error: Decoding error: Received error response: '
          'SetFailed: Invalid parameter value (code: 7006)';
      expect(mapUspErrorToServiceError(raw), isA<InvalidInputError>());
    });

    test('maps Protocol fault 7027 to ResourceNotFoundError', () {
      const raw =
          'Delete failed: Protocol error: Decoding error: Received error response: '
          'DeleteFailed: Object does not exist (code: 7027)';
      expect(mapUspErrorToServiceError(raw), isA<ResourceNotFoundError>());
    });

    test('maps Protocol fault 9001 to UnauthorizedError', () {
      const raw =
          'Set failed: Protocol error: Decoding error: Received error response: '
          'SetFailed: Request denied (code: 9001)';
      expect(mapUspErrorToServiceError(raw), isA<UnauthorizedError>());
    });

    test('maps Protocol fault 9005 to ResourceNotFoundError', () {
      const raw =
          'Get failed: Protocol error: Decoding error: Received error response: '
          'InvalidParam: Invalid parameter name (code: 9005)';
      expect(mapUspErrorToServiceError(raw), isA<ResourceNotFoundError>());
    });

    test('maps Protocol fault 9008 to InvalidInputError', () {
      const raw =
          'Set failed: Protocol error: Decoding error: Received error response: '
          'SetFailed: Non-writable parameter (code: 9008)';
      expect(mapUspErrorToServiceError(raw), isA<InvalidInputError>());
    });

    test('maps Operation Path not found to ResourceNotFoundError', () {
      const raw =
          'Get failed: Operation error: Path not found: Device.Bogus.Path';
      expect(mapUspErrorToServiceError(raw), isA<ResourceNotFoundError>());
    });

    test('maps Operation read-only to InvalidInputError', () {
      const raw =
          'Set failed: Operation error: Parameter is read-only: Device.DeviceInfo.Manufacturer';
      expect(mapUspErrorToServiceError(raw), isA<InvalidInputError>());
    });

    test('maps Validation error to InvalidInputError', () {
      const raw =
          "Get failed: Validation error: Path must start with 'Device.'";
      expect(mapUspErrorToServiceError(raw), isA<InvalidInputError>());
    });

    test('maps non-USP error to UnexpectedError', () {
      expect(mapUspErrorToServiceError('random error'), isA<UnexpectedError>());
    });

    test('maps non-string error to UnexpectedError', () {
      expect(mapUspErrorToServiceError(42), isA<UnexpectedError>());
    });

    test('maps Protocol error without fault code to UnexpectedError', () {
      const raw = 'Get failed: Protocol error: Malformed message: bad data';
      expect(mapUspErrorToServiceError(raw), isA<UnexpectedError>());
    });
  });
}
