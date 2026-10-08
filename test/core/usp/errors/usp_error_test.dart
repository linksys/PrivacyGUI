import 'dart:convert';
import 'dart:io';

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
    // #1533: a refused synchronous Operate. usp-client 0.13.0 reports it as
    // `success: false` with the agent's code in band, and `UspClient
    // .extractOperateResult` throws it in this shape. Before that it read as a
    // success, so a router-refused firmware chunk completed normally.
    //
    // The type matters as much as the code: `UnexpectedError` — the fallthrough
    // this used to take — renders as "something went wrong", which is what a
    // network blip looks like too. A refusal is the router answering, not the
    // network failing.
    test('maps a refused Operate (7022) to UspCompleteFailureError', () {
      const raw = 'Operate failed: Operation error: '
          'Device.LocalAgent.X_LINKSYS_Download() refused: Command Failure '
          '(code: 7022)';

      final mapped = mapUspErrorToServiceError(raw);

      expect(mapped, isA<UspCompleteFailureError>());
      expect(mapped.code, 7022);
      expect(mapped.toString(), contains('Command Failure'));
      expect(mapped.toString(),
          contains('Device.LocalAgent.X_LINKSYS_Download()'));
      expect(mapped, isNot(isA<NetworkError>()));
      expect(mapped, isNot(isA<ConnectivityError>()));
    });

    test('an operation error without a known code still is not a network error',
        () {
      const raw = 'Operate failed: Operation error: the command refused: '
          'the router gave no reason';
      final mapped = mapUspErrorToServiceError(raw);

      expect(mapped, isNot(isA<NetworkError>()));
      expect(mapped, isNot(isA<ConnectivityError>()));
    });

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

  group('native Operate error contract', () {
    final cases = jsonDecode(
      File('test/web/usp_native_operate_errors.json').readAsStringSync(),
    ) as List<dynamic>;
    for (final entry in cases) {
      final fixture = entry as Map<String, dynamic>;
      test(fixture['name'] as String, () {
        final raw = fixture['error'] as String;
        final parsed = parseUspError(raw);
        expect(parsed, isNotNull);
        expect(parsed!.operation, 'Operate');
        expect(parsed.category.name, fixture['category']);
        expect(parsed.faultCode, fixture['faultCode']);
        expect(parsed.httpStatus, fixture['httpStatus']);
        final mapped = mapUspErrorToServiceError(raw);
        expect(mapped.runtimeType.toString(), fixture['serviceError']);
        if (mapped is UspCompleteFailureError) {
          expect(mapped.failures.single.errorCode, fixture['faultCode']);
        } else {
          expect(mapped.code, fixture['faultCode'] ?? fixture['httpStatus']);
        }
      });
    }
  });

  group('isUnansweredTransportFailure', () {
    // Both messages are the per-path `errorMessage` the WASM client returned on
    // FLWRT 2.0.2 (2026-10-05). Both carry `errorCode: 9999`, which is why the
    // message has to decide.
    test('is true when the browser never got an answer', () {
      expect(
        isUnansweredTransportFailure(
          'Transport error: Transport error: HTTP error: error sending request: '
          'JsValue(TypeError: Failed to fetch\nTypeError: Failed to fetch)',
        ),
        isTrue,
      );
    });

    test('is false when the router answered with a refusal', () {
      expect(
        isUnansweredTransportFailure(
          'Transport error: Protocol error: Decoding error: Received error '
          'response: ProcessSet_AllowPartialFalse: Allow partial=false not '
          'supported across more than one USP Service (code: 7005)',
        ),
        isFalse,
      );
    });

    test('is false for a message it does not recognise', () {
      // Fails closed: an unknown error is reported, not assumed to have landed.
      expect(isUnansweredTransportFailure('Something else entirely'), isFalse);
    });
  });
}
