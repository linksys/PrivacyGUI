import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

void main() {
  group('ServiceError toString', () {
    test('base class converts class name to human-readable format', () {
      expect('${const InvalidCredentialsError()}', 'Invalid credentials');
      expect('${const SessionTokenExpiredError()}', 'Session token expired');
      expect('${const NotAuthenticatedError()}', 'Not authenticated');
      expect('${const ResourceNotFoundError()}', 'Resource not found');
    });

    test('NetworkError appends message when present', () {
      expect('${const NetworkError(detail: 'Request timeout')}',
          'Network error: Request timeout');
      expect('${const NetworkError()}', 'Network');
    });

    test('ConnectivityError appends message when present', () {
      expect('${const ConnectivityError(detail: 'Connection refused')}',
          'Connectivity error: Connection refused');
      expect('${const ConnectivityError()}', 'Connectivity');
    });

    test('InvalidInputError shows field and message', () {
      expect(
          '${const InvalidInputError(field: 'destIp', detail: 'Invalid IP')}',
          'Invalid input: destIp: Invalid IP');
      expect('${const InvalidInputError(detail: 'bad value')}',
          'Invalid input: bad value');
      expect('${const InvalidInputError()}', 'Invalid input');
    });

    test('UnexpectedError appends message when present', () {
      expect('${const UnexpectedError(detail: 'bad data')}',
          'Unexpected error: bad data');
      expect('${const UnexpectedError()}', 'Unexpected');
    });

    test('ServiceNotInitializedError appends message when present', () {
      expect(
          '${const ServiceNotInitializedError(detail: 'USP service not available')}',
          'Service not initialized: USP service not available');
      expect(
          '${const ServiceNotInitializedError()}', 'Service not initialized');
    });
  });
}
