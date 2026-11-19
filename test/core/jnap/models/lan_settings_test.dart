import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';

/// `GetLANSettings` output as a router sends it, with every optional DHCP
/// server filled in.
const _routerLan = <String, dynamic>{
  'minNetworkPrefixLength': 16,
  'maxNetworkPrefixLength': 30,
  'minAllowedDHCPLeaseMinutes': 1,
  'maxAllowedDHCPLeaseMinutes': 525600,
  'maxDHCPReservationDescriptionLength': 63,
  'hostName': 'Linksys00042',
  'ipAddress': '192.168.1.1',
  'networkPrefixLength': 24,
  'isDHCPEnabled': true,
  'dhcpSettings': {
    'firstClientIPAddress': '192.168.1.100',
    'lastClientIPAddress': '192.168.1.149',
    'leaseMinutes': 1440,
    'dnsServer1': '8.8.8.8',
    'dnsServer2': '8.8.4.4',
    'dnsServer3': '1.1.1.1',
    'winsServer': '192.168.1.10',
    'reservations': [
      {
        'macAddress': 'AA:BB:CC:DD:EE:01',
        'ipAddress': '192.168.1.120',
        'description': 'NAS',
      },
    ],
  },
};

void main() {
  group('RouterLANSettings', () {
    test('reads the router output and writes it back unchanged', () {
      expect(RouterLANSettings.fromMap(_routerLan).toMap(), _routerLan);
    });

    test('reads the fields the local network page shows', () {
      final settings = RouterLANSettings.fromMap(_routerLan);

      expect(settings.ipAddress, '192.168.1.1');
      expect(settings.networkPrefixLength, 24);
      expect(settings.dhcpSettings.firstClientIPAddress, '192.168.1.100');
      expect(settings.dhcpSettings.reservations.single.description, 'NAS');
      expect(settings.maxAllowedDHCPLeaseMinutes, 525600);
    });

    test('accepts a router that gives no maximum lease time', () {
      final output = Map.of(_routerLan)..remove('maxAllowedDHCPLeaseMinutes');

      final settings = RouterLANSettings.fromMap(output);

      expect(settings.maxAllowedDHCPLeaseMinutes, isNull);
      expect(settings.toMap(), output);
    });

    test('survives a trip through JSON text', () {
      final settings = RouterLANSettings.fromMap(_routerLan);

      expect(RouterLANSettings.fromJson(settings.toJson()), settings);
    });

    test('copyWith changes only what it names', () {
      final settings = RouterLANSettings.fromMap(_routerLan);

      final renamed = settings.copyWith(hostName: 'Den');

      expect(renamed.hostName, 'Den');
      expect(renamed.copyWith(hostName: 'Linksys00042'), settings);
    });
  });

  group('DHCPSettings', () {
    final dhcpOutput = _routerLan['dhcpSettings'] as Map<String, dynamic>;

    test('leaves out the servers the router has none for', () {
      final output = Map.of(dhcpOutput)
        ..remove('dnsServer2')
        ..remove('dnsServer3')
        ..remove('winsServer');

      final settings = DHCPSettings.fromMap(output);

      expect(settings.dnsServer2, isNull);
      expect(settings.toMap(), output);
    });

    test('survives a trip through JSON text', () {
      final settings = DHCPSettings.fromMap(dhcpOutput);

      expect(DHCPSettings.fromJson(settings.toJson()), settings);
    });

    test('copyWith changes only what it names', () {
      final settings = DHCPSettings.fromMap(dhcpOutput);

      final changed =
          settings.copyWith(leaseMinutes: 60, dnsServer1: '9.9.9.9');

      expect(changed.leaseMinutes, 60);
      expect(changed.dnsServer1, '9.9.9.9');
      expect(changed.copyWith(leaseMinutes: 1440, dnsServer1: '8.8.8.8'),
          settings);
    });
  });

  group('DHCPReservation', () {
    const reservation = DHCPReservation(
      macAddress: 'AA:BB:CC:DD:EE:01',
      ipAddress: '192.168.1.120',
      description: 'NAS',
    );

    test('survives a trip through JSON text', () {
      expect(jsonDecode(reservation.toJson()), {
        'macAddress': 'AA:BB:CC:DD:EE:01',
        'ipAddress': '192.168.1.120',
        'description': 'NAS',
      });
      expect(DHCPReservation.fromJson(reservation.toJson()), reservation);
    });

    test('copyWith changes only what it names', () {
      expect(reservation.copyWith(description: 'TV').description, 'TV');
      expect(reservation.copyWith(description: 'TV').macAddress,
          'AA:BB:CC:DD:EE:01');
    });
  });
}
