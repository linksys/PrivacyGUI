import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

void main() {
  group('UspInternetSettingsForm', () {
    group('defaults', () {
      const form = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );

      test('connectionType is required and stored', () {
        expect(form.connectionType, UspWanConnectionType.dhcp);
      });

      test('string fields default to empty', () {
        expect(form.staticIpAddress, '');
        expect(form.subnetMask, '');
        expect(form.defaultGateway, '');
        expect(form.dnsServer1, '');
        expect(form.dnsServer2, '');
        expect(form.dnsServer3, '');
        expect(form.pppUsername, '');
        expect(form.pppPassword, '');
        expect(form.pppoeServiceName, '');
        expect(form.serverAddress, '');
        expect(form.wanMacAddress, '');
        expect(form.ipv6rdPrefix, '');
        expect(form.ipv6rdBorderRelay, '');
      });

      test('connectionTrigger defaults to AlwaysOn', () {
        expect(form.connectionTrigger, 'AlwaysOn');
      });

      test('numeric fields default to zero', () {
        expect(form.idleDisconnectTime, 0);
        expect(form.lcpEchoInterval, 0);
        expect(form.vlanId, 0);
        expect(form.mtu, 0);
        expect(form.ipv6rdIpv4MaskLength, 0);
      });

      test('boolean fields default to false', () {
        expect(form.vlanEnabled, isFalse);
        expect(form.ipv6Enabled, isFalse);
        expect(form.dhcpv6Enabled, isFalse);
        expect(form.ipv6rdEnabled, isFalse);
      });
    });

    group('copyWith', () {
      const base = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.pptp,
        serverAddress: 'vpn.example.com',
        pppUsername: 'user',
        mtu: 1460,
      );

      test('returns an equal instance when no overrides are given', () {
        expect(base.copyWith(), equals(base));
      });

      test('overrides only the specified field', () {
        final updated = base.copyWith(serverAddress: 'new.example.com');
        expect(updated.serverAddress, 'new.example.com');
        // Untouched fields are preserved.
        expect(updated.connectionType, base.connectionType);
        expect(updated.pppUsername, base.pppUsername);
        expect(updated.mtu, base.mtu);
      });

      test('updates each field independently', () {
        expect(
          base
              .copyWith(connectionType: UspWanConnectionType.l2tp)
              .connectionType,
          UspWanConnectionType.l2tp,
        );
        expect(base.copyWith(staticIpAddress: '10.0.0.1').staticIpAddress,
            '10.0.0.1');
        expect(base.copyWith(subnetMask: '255.255.255.0').subnetMask,
            '255.255.255.0');
        expect(base.copyWith(defaultGateway: '10.0.0.254').defaultGateway,
            '10.0.0.254');
        expect(base.copyWith(dnsServer1: '8.8.8.8').dnsServer1, '8.8.8.8');
        expect(base.copyWith(dnsServer2: '8.8.4.4').dnsServer2, '8.8.4.4');
        expect(base.copyWith(dnsServer3: '1.1.1.1').dnsServer3, '1.1.1.1');
        expect(base.copyWith(pppPassword: 'secret').pppPassword, 'secret');
        expect(base.copyWith(pppoeServiceName: 'svc').pppoeServiceName, 'svc');
        expect(base.copyWith(connectionTrigger: 'OnDemand').connectionTrigger,
            'OnDemand');
        expect(base.copyWith(idleDisconnectTime: 30).idleDisconnectTime, 30);
        expect(base.copyWith(lcpEchoInterval: 10).lcpEchoInterval, 10);
        expect(base.copyWith(vlanEnabled: true).vlanEnabled, isTrue);
        expect(base.copyWith(vlanId: 100).vlanId, 100);
        expect(base.copyWith(mtu: 1492).mtu, 1492);
        expect(base.copyWith(wanMacAddress: 'AA:BB:CC:DD:EE:FF').wanMacAddress,
            'AA:BB:CC:DD:EE:FF');
        expect(base.copyWith(ipv6Enabled: true).ipv6Enabled, isTrue);
        expect(base.copyWith(dhcpv6Enabled: true).dhcpv6Enabled, isTrue);
        expect(base.copyWith(ipv6rdEnabled: true).ipv6rdEnabled, isTrue);
        expect(base.copyWith(ipv6rdPrefix: '2001:db8::/32').ipv6rdPrefix,
            '2001:db8::/32');
        expect(
            base.copyWith(ipv6rdIpv4MaskLength: 16).ipv6rdIpv4MaskLength, 16);
        expect(base.copyWith(ipv6rdBorderRelay: '192.0.2.1').ipv6rdBorderRelay,
            '192.0.2.1');
      });
    });

    group('equality (dirty-check contract)', () {
      const base = UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp,
      );

      test('two instances with identical fields are equal', () {
        const other = UspInternetSettingsForm(
          connectionType: UspWanConnectionType.dhcp,
        );
        expect(base, equals(other));
        expect(base.hashCode, other.hashCode);
      });

      // Guards the dirty-check contract: every field must participate in
      // equality via `props`. If a field is added to the model but omitted
      // from `props`, changing it would not mark the form dirty — this loop
      // fails when that happens.
      test('every field participates in equality', () {
        final mutations = <UspInternetSettingsForm>[
          base.copyWith(connectionType: UspWanConnectionType.pppoe),
          base.copyWith(staticIpAddress: 'x'),
          base.copyWith(subnetMask: 'x'),
          base.copyWith(defaultGateway: 'x'),
          base.copyWith(dnsServer1: 'x'),
          base.copyWith(dnsServer2: 'x'),
          base.copyWith(dnsServer3: 'x'),
          base.copyWith(pppUsername: 'x'),
          base.copyWith(pppPassword: 'x'),
          base.copyWith(pppoeServiceName: 'x'),
          base.copyWith(connectionTrigger: 'OnDemand'),
          base.copyWith(idleDisconnectTime: 1),
          base.copyWith(lcpEchoInterval: 1),
          base.copyWith(serverAddress: 'x'),
          base.copyWith(vlanEnabled: true),
          base.copyWith(vlanId: 1),
          base.copyWith(mtu: 1),
          base.copyWith(wanMacAddress: 'x'),
          base.copyWith(ipv6Enabled: true),
          base.copyWith(dhcpv6Enabled: true),
          base.copyWith(ipv6rdEnabled: true),
          base.copyWith(ipv6rdPrefix: 'x'),
          base.copyWith(ipv6rdIpv4MaskLength: 1),
          base.copyWith(ipv6rdBorderRelay: 'x'),
        ];

        // Sanity: one mutation per field declared on the model.
        expect(mutations.length, 24);

        for (final mutated in mutations) {
          expect(mutated, isNot(equals(base)));
        }
      });
    });
  });
}
