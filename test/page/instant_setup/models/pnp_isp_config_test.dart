import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';

void main() {
  group('PnpIspConfig', () {
    test('default constructor creates DHCP config with empty fields', () {
      const config = PnpIspConfig();

      expect(config.type, IspConnectionType.dhcp);
      expect(config.pppUsername, '');
      expect(config.pppPassword, '');
      expect(config.staticIpAddress, '');
      expect(config.vlanEnabled, false);
      expect(config.vlanId, 0);
    });

    test('copyWith preserves unmodified fields', () {
      const original = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '192.168.1.100',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
        dnsServer1: '8.8.8.8',
      );

      final modified = original.copyWith(dnsServer2: '8.8.4.4');

      expect(modified.type, IspConnectionType.staticIp);
      expect(modified.staticIpAddress, '192.168.1.100');
      expect(modified.subnetMask, '255.255.255.0');
      expect(modified.defaultGateway, '192.168.1.1');
      expect(modified.dnsServer1, '8.8.8.8');
      expect(modified.dnsServer2, '8.8.4.4');
    });

    test('equality works correctly', () {
      const config1 = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
      );
      const config2 = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
      );
      const config3 = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'different',
        pppPassword: 'pass',
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('PPPoE+VLAN config stores vlan fields', () {
      const config = PnpIspConfig(
        type: IspConnectionType.pppoeVlan,
        pppUsername: 'user',
        pppPassword: 'pass',
        vlanEnabled: true,
        vlanId: 100,
      );

      expect(config.type, IspConnectionType.pppoeVlan);
      expect(config.vlanEnabled, true);
      expect(config.vlanId, 100);
    });
  });
}
