import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/dhcp_lease.dart';

/// A lease from `GetDHCPClientLeases` output, as JSON text.
const _laptopText = '''
{
  "macAddress": "F2:B7:56:06:DD:D9",
  "ipAddress": "192.168.1.50",
  "expiration": "2026-11-18T13:00:00Z",
  "hostName": "laptop",
  "clientID": "01:F2:B7:56:06:DD:D9"
}
''';

/// A lease for a client that gave no host name.
const _iotText = '''
{
  "macAddress": "A4:83:E7:36:4C:22",
  "ipAddress": "192.168.1.99",
  "expiration": "2026-11-18T13:05:00Z",
  "clientID": "A4:83:E7:36:4C:22"
}
''';

void main() {
  test('reads a lease and the host name the client gave', () {
    final lease = DhcpLease.fromJson(_laptopText);

    expect(lease.macAddress, 'F2:B7:56:06:DD:D9');
    expect(lease.ipAddress, '192.168.1.50');
    expect(lease.expiration, '2026-11-18T13:00:00Z');
    expect(lease.hostName, 'laptop');
    expect(lease.clientID, '01:F2:B7:56:06:DD:D9');
  });

  test('reads a lease without a host name', () {
    final lease = DhcpLease.fromJson(_iotText);

    expect(lease.hostName, isNull);
    expect(lease.toMap(), {
      'macAddress': 'A4:83:E7:36:4C:22',
      'ipAddress': '192.168.1.99',
      'expiration': '2026-11-18T13:05:00Z',
      'hostName': null,
      'clientID': 'A4:83:E7:36:4C:22',
    });
  });

  test('survives a trip through JSON text', () {
    final lease = DhcpLease.fromJson(_laptopText);

    expect(DhcpLease.fromJson(lease.toJson()), lease);
    expect(lease, isNot(DhcpLease.fromJson(_iotText)));
  });

  test('copyWith changes only what it names', () {
    final lease = DhcpLease.fromJson(_laptopText);

    final renewed = lease.copyWith(expiration: '2026-11-19T13:00:00Z');

    expect(renewed.expiration, '2026-11-19T13:00:00Z');
    expect(renewed.ipAddress, lease.ipAddress);
    expect(renewed.copyWith(expiration: '2026-11-18T13:00:00Z'), lease);
  });
}
