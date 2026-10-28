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
          mtu: 1500,
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
          mtu: 1500,
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
          mtu: 1500,
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
          mtu: 1500,
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
          mtu: 1500,
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
          mtu: 1500,
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
          mtu: 1500,
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
          mtu: 1500,
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
          mtu: 1492,
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid when username is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pppoe,
          pppUsername: '',
          pppPassword: 'pass',
          mtu: 1492,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when password is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pppoe,
          pppUsername: 'user',
          pppPassword: '',
          mtu: 1492,
        );
        expect(validateForm(form), isFalse);
      });
    });

    group('PPTP connection type', () {
      test('valid with server, username, and password', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pptp,
          serverAddress: '203.0.113.10',
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1460,
        );
        expect(validateForm(form), isTrue);
      });

      test('valid with IP address as server', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pptp,
          serverAddress: '10.0.0.1',
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1460,
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid when server address is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pptp,
          serverAddress: '',
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1460,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when username is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pptp,
          serverAddress: '203.0.113.10',
          pppUsername: '',
          pppPassword: 'pass',
          mtu: 1460,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when password is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pptp,
          serverAddress: '203.0.113.10',
          pppUsername: 'user',
          pppPassword: '',
          mtu: 1460,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when OnDemand with zero idle time', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pptp,
          serverAddress: '203.0.113.10',
          pppUsername: 'user',
          pppPassword: 'pass',
          connectionTrigger: 'OnDemand',
          idleDisconnectTime: 0,
          mtu: 1460,
        );
        expect(validateForm(form), isFalse);
      });

      test('valid when OnDemand with positive idle time', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pptp,
          serverAddress: '203.0.113.10',
          pppUsername: 'user',
          pppPassword: 'pass',
          connectionTrigger: 'OnDemand',
          idleDisconnectTime: 300,
          mtu: 1460,
        );
        expect(validateForm(form), isTrue);
      });
    });

    group('L2TP connection type', () {
      test('valid with server, username, and password', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.l2tp,
          serverAddress: '203.0.113.20',
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1460,
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid when server address is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.l2tp,
          serverAddress: '',
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1460,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid with invalid server format', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.l2tp,
          serverAddress: 'has spaces bad',
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1460,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid with a hostname server (FW 036 takes IPv4 only)', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.l2tp,
          serverAddress: 'l2tp.example.com',
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1460,
        );
        expect(validateForm(form), isFalse);
      });
    });

    group('PPP fields (PPPoE / PPTP / L2TP)', () {
      const pppoe = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
        mtu: 1492,
      );

      test('OnDemand takes 1 to 9999 minutes', () {
        final onDemand = pppoe.copyWith(connectionTrigger: 'OnDemand');
        expect(validateForm(onDemand.copyWith(idleDisconnectTime: 1)), isTrue);
        expect(
            validateForm(onDemand.copyWith(idleDisconnectTime: 9999)), isTrue);
        expect(validateForm(onDemand.copyWith(idleDisconnectTime: 10000)),
            isFalse);
      });

      test('Keep Alive ignores the idle time', () {
        expect(
            validateForm(pppoe.copyWith(
                connectionTrigger: 'AlwaysOn', idleDisconnectTime: 0)),
            isTrue);
      });

      test('Keep Alive takes an interval of 20 to 180 seconds', () {
        bool valid(int seconds) =>
            validateForm(pppoe.copyWith(lcpEchoInterval: seconds));
        expect(valid(19), isFalse);
        expect(valid(20), isTrue);
        expect(valid(180), isTrue);
        expect(valid(181), isFalse);
      });

      test('the interval is not checked on On Demand', () {
        expect(
            validateForm(pppoe.copyWith(
                connectionTrigger: 'OnDemand',
                idleDisconnectTime: 5,
                lcpEchoInterval: 5)),
            isTrue);
      });

      test('user name and password take at most 255 characters', () {
        final long = 'a' * 256;
        expect(validateForm(pppoe.copyWith(pppUsername: 'a' * 255)), isTrue);
        expect(validateForm(pppoe.copyWith(pppUsername: long)), isFalse);
        expect(validateForm(pppoe.copyWith(pppPassword: long)), isFalse);
      });
    });

    group('validateStaticIpv4 (Static WAN and PPTP underlay, FW 036 / 039)',
        () {
      Map<String, String> check({
        String ip = '198.51.100.10',
        String mask = '255.255.255.0',
        String gateway = '198.51.100.1',
        String dns1 = '8.8.8.8',
        String dns2 = '',
        String dns3 = '',
      }) =>
          validateStaticIpv4(
              ipAddress: ip,
              subnetMask: mask,
              gateway: gateway,
              dns1: dns1,
              dns2: dns2,
              dns3: dns3);

      test('a complete, consistent address passes', () {
        expect(check(), isEmpty);
      });

      test('the IP is required, IPv4 and not reserved', () {
        expect(
            check(ip: '')[StaticIpv4Field.ipAddress], WanFieldErrors.required);
        expect(check(ip: '198.51.100')[StaticIpv4Field.ipAddress],
            WanFieldErrors.invalidIp);
        expect(
            check(
                ip: '127.0.0.5',
                gateway: '127.0.0.1')[StaticIpv4Field.ipAddress],
            WanFieldErrors.reservedIp);
      });

      test('the IP is neither the network nor the broadcast address', () {
        expect(check(ip: '198.51.100.0')[StaticIpv4Field.ipAddress],
            WanFieldErrors.invalidIp);
        expect(check(ip: '198.51.100.255')[StaticIpv4Field.ipAddress],
            WanFieldErrors.invalidIp);
      });

      test('the mask is contiguous and /8 to /31', () {
        expect(check(mask: '255.0.255.0')[StaticIpv4Field.subnetMask],
            WanFieldErrors.invalidMask);
        expect(check(mask: '254.0.0.0')[StaticIpv4Field.subnetMask],
            WanFieldErrors.invalidMask);
        expect(check(mask: '255.255.255.255')[StaticIpv4Field.subnetMask],
            WanFieldErrors.invalidMask);
        expect(check(ip: '10.0.0.10', mask: '255.0.0.0', gateway: '10.0.0.1'),
            isEmpty);
      });

      test('a /31 has no network or broadcast address', () {
        expect(
            check(
                ip: '198.51.100.0',
                mask: '255.255.255.254',
                gateway: '198.51.100.1'),
            isEmpty);
      });

      test('the gateway is required, in the subnet, and not the IP', () {
        expect(check(gateway: '')[StaticIpv4Field.gateway],
            WanFieldErrors.required);
        expect(check(gateway: '198.51.101.1')[StaticIpv4Field.gateway],
            WanFieldErrors.invalidGateway);
        expect(check(gateway: '198.51.100.10')[StaticIpv4Field.gateway],
            WanFieldErrors.invalidGateway);
        expect(check(gateway: '198.51.100.255')[StaticIpv4Field.gateway],
            WanFieldErrors.invalidGateway);
      });

      test('DNS 1 is required; no DNS server is reserved', () {
        expect(check(dns1: '')[StaticIpv4Field.dns1], WanFieldErrors.required);
        expect(check(dns1: '0.0.0.0')[StaticIpv4Field.dns1],
            WanFieldErrors.reservedIp);
        expect(check(dns2: '224.0.0.251')[StaticIpv4Field.dns2],
            WanFieldErrors.reservedIp);
        expect(
            check(dns3: 'bad')[StaticIpv4Field.dns3], WanFieldErrors.invalidIp);
        expect(check(dns2: '', dns3: ''), isEmpty);
      });

      test('validateForm applies it to the Static WAN', () {
        const form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.staticIp,
          staticIpAddress: '198.51.100.10',
          subnetMask: '255.255.255.0',
          defaultGateway: '198.51.101.1',
          dnsServer1: '8.8.8.8',
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
        expect(validateForm(form.copyWith(defaultGateway: '198.51.100.1')),
            isTrue);
      });
    });

    group('PPTP static underlay', () {
      const pptp = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.pptp,
        serverAddress: '203.0.113.10',
        pppUsername: 'user',
        pppPassword: 'pass',
        mtu: 1460,
      );
      final staticUnderlay = pptp.copyWith(
        underlayStatic: true,
        underlayIpAddress: '198.51.100.10',
        underlaySubnetMask: '255.255.255.0',
        underlayGateway: '198.51.100.1',
        underlayDns1: '8.8.8.8',
      );

      test('a DHCP underlay checks none of the underlay fields', () {
        expect(validateForm(pptp.copyWith(underlayIpAddress: 'junk')), isTrue);
      });

      test('a static underlay passes with a consistent address set', () {
        expect(validateForm(staticUnderlay), isTrue);
      });

      test('a static underlay is checked as a Static WAN', () {
        expect(
            validateForm(staticUnderlay.copyWith(underlayGateway: '10.0.0.1')),
            isFalse);
        expect(
            validateForm(staticUnderlay.copyWith(underlayDns1: '')), isFalse);
      });

      test('the Static WAN fields play no part on PPTP', () {
        // On PPTP they hold the tunnel address the router reports.
        expect(validateForm(staticUnderlay.copyWith(staticIpAddress: 'junk')),
            isTrue);
      });

      test('L2TP never checks the underlay (the page offers it on PPTP only)',
          () {
        expect(
            validateForm(staticUnderlay.copyWith(
                connectionType: UspWanConnectionType.l2tp,
                underlayGateway: '10.0.0.1')),
            isTrue);
      });
    });

    group('validateIdleMinutes', () {
      test('1 to 9999', () {
        expect(validateIdleMinutes(0), WanFieldErrors.outOfRange);
        expect(validateIdleMinutes(1), isNull);
        expect(validateIdleMinutes(9999), isNull);
        expect(validateIdleMinutes(10000), WanFieldErrors.outOfRange);
      });
    });

    group('validateKeepAliveInterval', () {
      test('20 to 180', () {
        expect(validateKeepAliveInterval(19), WanFieldErrors.outOfRange);
        expect(validateKeepAliveInterval(20), isNull);
        expect(validateKeepAliveInterval(180), isNull);
        expect(validateKeepAliveInterval(181), WanFieldErrors.outOfRange);
      });
    });

    group('validatePppCredential', () {
      test('required, at most 255 characters', () {
        expect(validatePppCredential(''), WanFieldErrors.required);
        expect(validatePppCredential('a' * 255), isNull);
        expect(validatePppCredential('a' * 256), WanFieldErrors.tooLong);
      });
    });

    group('validateTunnelServer', () {
      test('accepts a public IPv4 address', () {
        expect(validateTunnelServer('203.0.113.10'), isNull);
      });

      test('requires a value', () {
        expect(validateTunnelServer(''), WanFieldErrors.required);
      });

      test('refuses a hostname', () {
        expect(
            validateTunnelServer('vpn.example.com'), WanFieldErrors.invalidIp);
      });

      // 1.0 util.isReservedAddress: 0/8, 127/8, 169.254/16, 224/4, 240/4.
      for (final reserved in [
        '0.1.2.3',
        '127.0.0.1',
        '169.254.10.1',
        '224.0.0.1',
        '239.255.255.250',
        '240.0.0.1',
        '255.255.255.255',
      ]) {
        test('refuses reserved $reserved', () {
          expect(validateTunnelServer(reserved), WanFieldErrors.reservedIp);
        });
      }

      test('accepts the addresses just outside the reserved blocks', () {
        expect(validateTunnelServer('1.0.0.1'), isNull);
        expect(validateTunnelServer('126.255.255.254'), isNull);
        expect(validateTunnelServer('169.253.255.255'), isNull);
        expect(validateTunnelServer('223.255.255.254'), isNull);
      });
    });

    group('PPTP/L2TP MTU validation', () {
      test('valid at maximum 1460', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pptp,
          serverAddress: '203.0.113.10',
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1460,
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid above 1460', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pptp,
          serverAddress: '203.0.113.10',
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1492,
        );
        expect(validateForm(form), isFalse);
      });
    });

    group('Bridge connection type', () {
      test('always valid', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.bridge,
          mtu: 1500,
        );
        expect(validateForm(form), isTrue);
      });
    });

    group('IPv6 6rd tunnel validation', () {
      test('valid when 6rd is disabled', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: false,
          mtu: 1500,
        );
        expect(validateForm(form), isTrue);
      });

      test('valid when 6rd is enabled with required fields', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '2001:db8::/32',
          ipv6rdIpv4MaskLength: 16,
          ipv6rdBorderRelay: '192.0.2.1',
          mtu: 1500,
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
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when 6rd prefix is not CIDR format', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '2001:db8::', // missing /prefix
          ipv6rdIpv4MaskLength: 16,
          ipv6rdBorderRelay: '192.0.2.1',
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when 6rd border relay is not valid IPv4', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '2001:db8::/32',
          ipv6rdIpv4MaskLength: 16,
          ipv6rdBorderRelay: '192.0.2', // incomplete
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when 6rd mask length exceeds 32', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '2001:db8::/32',
          ipv6rdIpv4MaskLength: 33,
          ipv6rdBorderRelay: '192.0.2.1',
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when 6rd prefix is loopback address', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '::1/128',
          ipv6rdIpv4MaskLength: 0,
          ipv6rdBorderRelay: '192.0.2.1',
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when 6rd prefix is multicast address', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: 'ff02::1/64',
          ipv6rdIpv4MaskLength: 0,
          ipv6rdBorderRelay: '192.0.2.1',
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when 6rd prefix is unspecified address', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '::/0',
          ipv6rdIpv4MaskLength: 0,
          ipv6rdBorderRelay: '192.0.2.1',
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
      });

      test('invalid when 6rd border relay is empty', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          ipv6rdEnabled: true,
          ipv6rdPrefix: '2001:db8::/32',
          ipv6rdIpv4MaskLength: 16,
          ipv6rdBorderRelay: '',
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
      });
    });

    group('MTU validation', () {
      test('valid in range 576-1500', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 1400,
        );
        expect(validateForm(form), isTrue);
      });

      test('valid at minimum 576', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 576,
        );
        expect(validateForm(form), isTrue);
      });

      test('valid at maximum 1500', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 1500,
        );
        expect(validateForm(form), isTrue);
      });

      test('valid PPPoE at maximum 1492', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pppoe,
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1492,
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid PPPoE above 1492', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.pppoe,
          pppUsername: 'user',
          pppPassword: 'pass',
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
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

      group('auto mode', () {
        // In auto mode [mtu] is whatever the device reported, so the range check
        // must not apply — otherwise a device sitting on an out-of-range
        // effective MTU would make the page unsaveable with nothing to fix.
        test('valid with an out-of-range MTU below the minimum', () {
          final form = UspInternetSettingsForm(
            connectionType: UspWanConnectionType.dhcp,
            mtu: 500,
            mtuAuto: true,
          );
          expect(validateForm(form), isTrue);
        });

        test('valid with an MTU above the type maximum', () {
          final form = UspInternetSettingsForm(
            connectionType: UspWanConnectionType.pppoe,
            pppUsername: 'user',
            pppPassword: 'pass',
            mtu: 1500, // exceeds PPPoE's 1492 — irrelevant in auto mode
            mtuAuto: true,
          );
          expect(validateForm(form), isTrue);
        });

        test('still enforces the other optional fields', () {
          final form = UspInternetSettingsForm(
            connectionType: UspWanConnectionType.dhcp,
            mtu: 1500,
            mtuAuto: true,
            wanMacAddress: 'not-a-mac',
          );
          expect(validateForm(form), isFalse);
        });
      });
    });

    group('MAC address validation', () {
      test('valid when empty (no clone)', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          wanMacAddress: '',
          mtu: 1500,
        );
        expect(validateForm(form), isTrue);
      });

      test('valid with colon-separated MAC', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          wanMacAddress: 'AA:BB:CC:DD:EE:FF',
          mtu: 1500,
        );
        expect(validateForm(form), isTrue);
      });

      test('valid with dash-separated MAC', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          wanMacAddress: 'AA-BB-CC-DD-EE-FF',
          mtu: 1500,
        );
        expect(validateForm(form), isTrue);
      });

      test('invalid with bad MAC format', () {
        final form = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
          wanMacAddress: 'not-a-mac',
          mtu: 1500,
        );
        expect(validateForm(form), isFalse);
      });
    });
  });
}
