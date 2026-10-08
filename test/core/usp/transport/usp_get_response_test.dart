import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/transport/usp_get_response.dart';

Map<String, Object> response({
  bool success = true,
  Map<String, Object?> data = const {},
  Map<String, Object> errors = const {},
}) =>
    {
      'success': success,
      'result': {'data': data, if (errors.isNotEmpty) 'error': errors},
    };

void main() {
  test('successful GET preserves flat values', () {
    expect(
        decodeUspGetResponse(response(data: {
          'Device.X.Name': 'router',
          'Device.X.Count': 1,
          'Device.X.Empty': null,
        })),
        {
          'Device.X.Name': 'router',
          'Device.X.Count': '1',
          'Device.X.Empty': '',
        });
  });

  for (final success in [true, false]) {
    test('empty results remain empty (success=$success)', () {
      expect(decodeUspGetResponse(response(success: success)), isEmpty);
    });
    test('optional unsupported paths retain partial reads ($success)', () {
      expect(
          decodeUspGetResponse(response(
            success: success,
            data: success ? {'Device.X.Name': 'router'} : {},
            errors: {
              'Device.X.Optional': {
                'errorCode': 7026,
                'errorMessage': 'Path does not exist',
              },
            },
          )),
          success ? {'Device.X.Name': 'router'} : isEmpty);
    });
    test('fulfilled HTTP 401 is thrown even with partial data ($success)', () {
      expect(
        () => decodeUspGetResponse(response(
          success: success,
          data: success ? {'Device.X.Name': 'router'} : {},
          errors: {
            'Device.X.Optional': {'errorCode': 7026},
            'Device.X.Status': {
              'errorCode': 9999.0,
              'errorMessage': 'Transport error: HTTP error: HTTP 401',
            },
          },
        )),
        throwsA(predicate<Object>((error) =>
            error.toString().contains('HTTP 401') &&
            mapUspErrorToServiceError(error) is NotAuthenticatedError)),
      );
    });
  }

  test('nested HTTP 401 remains available to authentication recovery', () {
    expect(
      () => decodeUspGetResponse(response(success: false, errors: {
        'Device.X.Status': {
          'errorCode': 9999,
          'errorMessage':
              'Transport error: Transport error: HTTP error: HTTP 401',
        },
      })),
      throwsA(predicate<Object>((error) =>
          error.toString().contains('HTTP 401') &&
          mapUspErrorToServiceError(error) is NotAuthenticatedError)),
    );
  });

  for (final message in [
    'Transport error: HTTP error: HTTP 503',
    'Transport error: Request timeout',
    'HTTP error: HTTP 503',
  ]) {
    test('transport failure remains a network error: $message', () {
      expect(
        () => decodeUspGetResponse(response(success: false, errors: {
          'Device.X.Status': {'errorCode': '9999', 'errorMessage': message},
        })),
        throwsA(predicate<Object>(
            (error) => mapUspErrorToServiceError(error) is NetworkError)),
      );
    });
  }

  for (final sample in [
    (
      message: 'Protocol error: Decoding error: Received error response: '
          'Permission denied (code: 9001)',
      expected: isA<UnauthorizedError>().having((e) => e.code, 'code', 9001),
    ),
    (
      message: 'Protocol error: Decoding error: Received error response: '
          'Invalid parameter (code: 7005)',
      expected: isA<InvalidInputError>().having((e) => e.code, 'code', 7005),
    ),
    (
      message: 'Protocol error: Decoding error: Received error response: '
          'Path does not exist (code: 7026)',
      expected:
          isA<ResourceNotFoundError>().having((e) => e.code, 'code', 7026),
    ),
    (
      message: 'Protocol error: Decoding error: Empty response data',
      expected: isA<UnexpectedError>(),
    ),
    (
      message: 'Authentication error: Session expired',
      expected: isA<SessionTokenExpiredError>(),
    ),
    (
      message: 'Validation error: Invalid path',
      expected: isA<InvalidInputError>(),
    ),
  ]) {
    test('9999 preserves the underlying failure: ${sample.message}', () {
      expect(
        () => decodeUspGetResponse(response(success: false, errors: {
          'Device.X.Status': {
            'errorCode': 9999,
            'errorMessage': 'Transport error: ${sample.message}',
          },
        })),
        throwsA(predicate<Object>((error) =>
            sample.expected.matches(mapUspErrorToServiceError(error), {}))),
      );
    });
  }

  test('9999 unwraps only the category prefix, not text inside a failure', () {
    expect(
      () => decodeUspGetResponse(response(success: false, errors: {
        'Device.X.Status': {
          'errorCode': 9999,
          'errorMessage': 'Transport error: Transport error: HTTP error: '
              'HTTP 503: Protocol error: downstream unavailable',
        },
      })),
      throwsA(predicate<Object>(
          (error) => mapUspErrorToServiceError(error) is NetworkError)),
    );
  });

  test('a transport error without a message still fails', () {
    expect(
      () => decodeUspGetResponse(response(success: false, errors: {
        'Device.X.Status': {'errorCode': 9999},
      })),
      throwsA(predicate<Object>(
          (error) => mapUspErrorToServiceError(error) is NetworkError)),
    );
  });

  for (final malformed in [
    null,
    [],
    {},
    {'result': {}},
    {
      'result': {'data': []}
    }
  ]) {
    test('malformed response does not impersonate missing settings: $malformed',
        () {
      expect(
        () => decodeUspGetResponse(malformed),
        throwsA(predicate<Object>(
            (error) => mapUspErrorToServiceError(error) is UnexpectedError)),
      );
    });
  }
}
