import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_lan_settings.dart';

/// `SetLANSettings` input, with the DHCP server on.
const _input = <String, dynamic>{
  'ipAddress': '192.168.1.1',
  'networkPrefixLength': 24,
  'hostName': 'Linksys00042',
  'isDHCPEnabled': true,
  'dhcpSettings': {
    'firstClientIPAddress': '192.168.1.100',
    'lastClientIPAddress': '192.168.1.149',
    'leaseMinutes': 1440,
    'reservations': <Map<String, dynamic>>[],
  },
};

void main() {
  group('SetRouterLANSettings', () {
    test('reads the input and writes it back unchanged', () {
      expect(SetRouterLANSettings.fromMap(_input).toMap(), _input);
    });

    test('sends no DHCP settings when it has none', () {
      const settings = SetRouterLANSettings(
        ipAddress: '192.168.1.1',
        networkPrefixLength: 24,
        hostName: 'Linksys00042',
        isDHCPEnabled: false,
      );

      expect(settings.toMap(), {
        'ipAddress': '192.168.1.1',
        'networkPrefixLength': 24,
        'hostName': 'Linksys00042',
        'isDHCPEnabled': false,
      });
      expect(SetRouterLANSettings.fromMap(settings.toMap()), settings);
    });

    test('survives a trip through JSON text', () {
      final settings = SetRouterLANSettings.fromMap(_input);

      expect(SetRouterLANSettings.fromJson(settings.toJson()), settings);
    });

    test('copyWith changes only what it names', () {
      final settings = SetRouterLANSettings.fromMap(_input);

      final moved = settings.copyWith(ipAddress: '10.0.1.1');

      expect(moved.ipAddress, '10.0.1.1');
      expect(moved.dhcpSettings, isA<DHCPSettings>());
      expect(moved.copyWith(ipAddress: '192.168.1.1'), settings);
    });
  });
}
