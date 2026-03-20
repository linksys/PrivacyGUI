import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_form_validator.dart';

void main() {
  group('validateForm', () {
    group('DHCP connection type', () {
      test('always valid', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
        );
        expect(validateForm(form), isTrue);
      });
    });

    group('Static IP connection type', () {
      test('valid with all required fields', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.staticIp,
          staticIpAddress: '192.168.1.100',
          subnetMask: '255.255.255.0',
          defaultGateway: '192.168.1.1',
          dnsServer1: '8.8.8.8',
        );
        expect(validateForm(form), isTrue);
      });

      test('valid with optional DNS servers', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.staticIp,
          staticIpAddress: '192.168.1.100',
          subnetMask: '255.255.255.0',
          defaultGateway: '192.168.1.1',
          dnsServer1: '8.8.8.8',
          dnsServer2: '8.8.4.4',
          dnsServer3: '1.1.1.1',
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid when IP address is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.staticIp,
          staticIpAddress: '',
          subnetMask: '255.255.255.0',
          defaultGateway: '192.168.1.1',
          dnsServer1: '8.8.8.8',
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when subnet mask is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.staticIp,
          staticIpAddress: '192.168.1.100',
          subnetMask: '',
          defaultGateway: '192.168.1.1',
          dnsServer1: '8.8.8.8',
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid with bad IP format', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.staticIp,
          staticIpAddress: '999.999.999.999',
          subnetMask: '255.255.255.0',
          defaultGateway: '192.168.1.1',
          dnsServer1: '8.8.8.8',
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid with bad subnet mask', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.staticIp,
          staticIpAddress: '192.168.1.100',
          subnetMask: '255.255.0.255', // non-contiguous
          defaultGateway: '192.168.1.1',
          dnsServer1: '8.8.8.8',
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when optional DNS2 has bad format', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.staticIp,
          staticIpAddress: '192.168.1.100',
          subnetMask: '255.255.255.0',
          defaultGateway: '192.168.1.1',
          dnsServer1: '8.8.8.8',
          dnsServer2: 'bad',
        );
        expect(validateForm(form), isFalse);
      });
    });

    group('PPPoE connection type', () {
      test('valid with username and password', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pppoe,
          pppUsername: 'user',
          pppPassword: 'pass',
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid when username is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pppoe,
          pppUsername: '',
          pppPassword: 'pass',
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when password is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pppoe,
          pppUsername: 'user',
          pppPassword: '',
        );
        expect(validateForm(form), isFalse);
      });
    });

    group('Bridge connection type', () {
      test('always valid', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.bridge,
        );
        expect(validateForm(form), isTrue);
      });
    });

    group('IPv6 6rd tunnel validation', () {
      test('valid when 6rd is disabled', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: false,
        );
        expect(validateForm(form), isTrue);
      });

      test('valid when 6rd is enabled with required fields', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '2001:db8::',
          ipv6rdIpv4MaskLength: 16,
          ipv6rdBorderRelay: '192.0.2.1',
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid when 6rd is enabled with empty prefix', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '',
          ipv6rdIpv4MaskLength: 16,
          ipv6rdBorderRelay: '192.0.2.1',
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when 6rd mask length exceeds 32', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '2001:db8::',
          ipv6rdIpv4MaskLength: 33,
          ipv6rdBorderRelay: '192.0.2.1',
        );
        expect(validateForm(form), isFalse);
      });
    });

    group('MTU validation', () {
      test('valid when auto (0)', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 0,
        );
        expect(validateForm(form), isTrue);
      });

      test('valid in range 576-1500', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 1400,
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid when below 576', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 500,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when above 1500', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 1600,
        );
        expect(validateForm(form), isFalse);
      });
    });

    group('MAC address validation', () {
      test('valid when empty (no clone)', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          wanMacAddress: '',
        );
        expect(validateForm(form), isTrue);
      });

      test('valid with colon-separated MAC', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          wanMacAddress: 'AA:BB:CC:DD:EE:FF',
        );
        expect(validateForm(form), isTrue);
      });

      test('valid with dash-separated MAC', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          wanMacAddress: 'AA-BB-CC-DD-EE-FF',
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid with bad MAC format', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          wanMacAddress: 'not-a-mac',
        );
        expect(validateForm(form), isFalse);
      });
    });
  });
}
