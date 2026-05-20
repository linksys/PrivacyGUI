import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

void main() {
  const baseForm = UspInternetSettingsForm(
    connectionType: UspWanConnectionType.dhcp,
    staticIpAddress: '10.0.0.1',
    subnetMask: '255.255.0.0',
    defaultGateway: '10.0.0.254',
    dnsServer1: '1.1.1.1',
    dnsServer2: '1.0.0.1',
    dnsServer3: '8.8.8.8',
    pppUsername: 'olduser',
    pppPassword: 'oldpass',
    pppoeServiceName: '',
    vlanEnabled: false,
    vlanId: 0,
    mtu: 1500,
    ipv6Enabled: true,
  );

  group('PnpIspConfig.uspConnectionType', () {
    test('dhcp maps to UspWanConnectionType.dhcp', () {
      const config = PnpIspConfig(type: IspConnectionType.dhcp);
      expect(config.uspConnectionType, UspWanConnectionType.dhcp);
    });

    test('pppoe maps to UspWanConnectionType.pppoe', () {
      const config = PnpIspConfig(type: IspConnectionType.pppoe);
      expect(config.uspConnectionType, UspWanConnectionType.pppoe);
    });

    test('pppoeVlan maps to UspWanConnectionType.pppoe', () {
      const config = PnpIspConfig(type: IspConnectionType.pppoeVlan);
      expect(config.uspConnectionType, UspWanConnectionType.pppoe);
    });

    test('staticIp maps to UspWanConnectionType.staticIp', () {
      const config = PnpIspConfig(type: IspConnectionType.staticIp);
      expect(config.uspConnectionType, UspWanConnectionType.staticIp);
    });
  });

  group('PnpIspConfig.applyTo', () {
    test('staticIp overwrites IP fields, preserves unrelated fields', () {
      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '192.168.1.100',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
        dnsServer1: '8.8.8.8',
        dnsServer2: '8.8.4.4',
      );

      final result = config.applyTo(baseForm);

      expect(result.connectionType, UspWanConnectionType.staticIp);
      expect(result.staticIpAddress, '192.168.1.100');
      expect(result.subnetMask, '255.255.255.0');
      expect(result.defaultGateway, '192.168.1.1');
      expect(result.dnsServer1, '8.8.8.8');
      expect(result.dnsServer2, '8.8.4.4');
      // Unrelated fields preserved
      expect(result.dnsServer3, '8.8.8.8');
      expect(result.mtu, 1500);
      expect(result.ipv6Enabled, true);
    });

    test('pppoe overwrites PPP fields, sets vlanEnabled=false', () {
      const config = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'myuser',
        pppPassword: 'mypass',
      );

      final result = config.applyTo(baseForm);

      expect(result.connectionType, UspWanConnectionType.pppoe);
      expect(result.pppUsername, 'myuser');
      expect(result.pppPassword, 'mypass');
      expect(result.vlanEnabled, false);
      expect(result.vlanId, 0);
      // Unrelated fields preserved
      expect(result.mtu, 1500);
    });

    test('pppoeVlan sets vlanEnabled=true and vlanId', () {
      const config = PnpIspConfig(
        type: IspConnectionType.pppoeVlan,
        pppUsername: 'vlanuser',
        pppPassword: 'vlanpass',
        vlanEnabled: true,
        vlanId: 100,
      );

      final result = config.applyTo(baseForm);

      expect(result.connectionType, UspWanConnectionType.pppoe);
      expect(result.pppUsername, 'vlanuser');
      expect(result.pppPassword, 'vlanpass');
      expect(result.vlanEnabled, true);
      expect(result.vlanId, 100);
    });

    test('empty fields preserve original values (do not overwrite with empty)',
        () {
      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '10.0.0.1',
        subnetMask: '255.255.255.0',
        defaultGateway: '10.0.0.254',
        dnsServer1: '',
        dnsServer2: '',
      );

      final result = config.applyTo(baseForm);

      // Empty PNP fields preserve original values
      expect(result.dnsServer1, '1.1.1.1');
      expect(result.dnsServer2, '1.0.0.1');
      // dnsServer3 always preserved from original
      expect(result.dnsServer3, '8.8.8.8');
    });

    test('does not modify pppoeServiceName (FW unsupported)', () {
      const config = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
        pppoeServiceName: 'should_be_ignored',
      );

      final result = config.applyTo(baseForm);

      // pppoeServiceName is not overwritten by applyTo
      expect(result.pppoeServiceName, baseForm.pppoeServiceName);
    });

    test('PPPoE with empty fields preserves original IP/DNS values', () {
      const config = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'newuser',
        pppPassword: 'newpass',
      );

      final result = config.applyTo(baseForm);

      // PPP fields overwritten
      expect(result.pppUsername, 'newuser');
      expect(result.pppPassword, 'newpass');
      // Static IP fields preserved (empty PNP fields don't overwrite)
      expect(result.staticIpAddress, '10.0.0.1');
      expect(result.subnetMask, '255.255.0.0');
      expect(result.defaultGateway, '10.0.0.254');
      expect(result.dnsServer1, '1.1.1.1');
    });
  });
}
