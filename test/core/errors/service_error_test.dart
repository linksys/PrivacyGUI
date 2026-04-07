import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

void main() {
  group('ServiceError toString', () {
    test('base class converts class name to human-readable format', () {
      expect('${const InvalidCredentialsError()}', 'Invalid credentials');
      expect('${const SessionTokenExpiredError()}', 'Session token expired');
      expect('${const NotAuthenticatedError()}', 'Not authenticated');
      expect('${const ResourceNotFoundError()}', 'Resource not found');
      expect('${const AdminAccountLockedError()}', 'Admin account locked');
    });

    test('preserves acronyms (VPN, IP, DNS, SSID, MAC, OTP)', () {
      expect('${const VPNNotConnectedError()}', 'VPN not connected');
      expect('${const InvalidIPAddressError()}', 'Invalid IP address');
      expect('${const InvalidPrimaryDNSServerError()}',
          'Invalid primary DNS server');
      expect('${const GuestSSIDConflictError()}', 'Guest SSID conflict');
      expect('${const InvalidMACAddressError()}', 'Invalid MAC address');
      expect('${const InvalidOtpError()}', 'Invalid otp');
    });

    test('NetworkError appends message when present', () {
      expect('${const NetworkError(message: 'Request timeout')}',
          'Network error: Request timeout');
      expect('${const NetworkError()}', 'Network');
    });

    test('ConnectivityError appends message when present', () {
      expect('${const ConnectivityError(message: 'Connection refused')}',
          'Connectivity error: Connection refused');
      expect('${const ConnectivityError()}', 'Connectivity');
    });

    test('InvalidInputError shows field and message', () {
      expect(
          '${const InvalidInputError(field: 'destIp', message: 'Invalid IP')}',
          'Invalid input: destIp: Invalid IP');
      expect('${const InvalidInputError(message: 'bad value')}',
          'Invalid input: bad value');
      expect('${const InvalidInputError()}', 'Invalid input');
    });

    test('UnexpectedError appends message when present', () {
      expect('${const UnexpectedError(message: 'bad data')}',
          'Unexpected error: bad data');
      expect('${const UnexpectedError()}', 'Unexpected');
    });
  });
}
