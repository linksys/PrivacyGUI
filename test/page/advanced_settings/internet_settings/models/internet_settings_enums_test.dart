import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';

void main() {
  group('WanType', () {
    test('resolve returns correct WanType for valid string', () {
      expect(WanType.resolve('DHCP'), WanType.dhcp);
      expect(WanType.resolve('PPPoE'), WanType.pppoe);
      expect(WanType.resolve('PPTP'), WanType.pptp);
      expect(WanType.resolve('L2TP'), WanType.l2tp);
      expect(WanType.resolve('Telstra'), WanType.telstra);
      expect(WanType.resolve('DSLite'), WanType.dsLite);
      expect(WanType.resolve('Static'), WanType.static);
      expect(WanType.resolve('Bridge'), WanType.bridge);
      expect(WanType.resolve('WirelessBridge'), WanType.wirelessBridge);
      expect(WanType.resolve('WirelessRepeater'), WanType.wirelessRepeater);
    });

    test('resolve returns null for invalid string', () {
      expect(WanType.resolve('Invalid'), isNull);
      expect(WanType.resolve(''), isNull);
      expect(WanType.resolve('dhcp'), isNull); // case-sensitive
    });

    test('WanType has correct type property', () {
      expect(WanType.dhcp.type, 'DHCP');
      expect(WanType.pppoe.type, 'PPPoE');
      expect(WanType.pptp.type, 'PPTP');
      expect(WanType.l2tp.type, 'L2TP');
      expect(WanType.static.type, 'Static');
      expect(WanType.bridge.type, 'Bridge');
    });
  });

  group('WanIPv6Type', () {
    test('resolve returns correct WanIPv6Type for valid string', () {
      expect(WanIPv6Type.resolve('Automatic'), WanIPv6Type.automatic);
      expect(WanIPv6Type.resolve('Static'), WanIPv6Type.static);
      expect(WanIPv6Type.resolve('Bridge'), WanIPv6Type.bridge);
      expect(WanIPv6Type.resolve('6rd Tunnel'), WanIPv6Type.sixRdTunnel);
      expect(WanIPv6Type.resolve('SLAAC'), WanIPv6Type.slaac);
      expect(WanIPv6Type.resolve('DHCPv6'), WanIPv6Type.dhcpv6);
      expect(WanIPv6Type.resolve('PPPoE'), WanIPv6Type.pppoe);
      expect(WanIPv6Type.resolve('Pass-through'), WanIPv6Type.passThrough);
    });

    test('resolve returns null for invalid string', () {
      expect(WanIPv6Type.resolve('Invalid'), isNull);
      expect(WanIPv6Type.resolve(''), isNull);
      expect(WanIPv6Type.resolve('automatic'), isNull); // case-sensitive
    });

    test('WanIPv6Type has correct type property', () {
      expect(WanIPv6Type.automatic.type, 'Automatic');
      expect(WanIPv6Type.static.type, 'Static');
      expect(WanIPv6Type.bridge.type, 'Bridge');
      expect(WanIPv6Type.sixRdTunnel.type, '6rd Tunnel');
      expect(WanIPv6Type.slaac.type, 'SLAAC');
      expect(WanIPv6Type.dhcpv6.type, 'DHCPv6');
      expect(WanIPv6Type.pppoe.type, 'PPPoE');
      expect(WanIPv6Type.passThrough.type, 'Pass-through');
    });
  });

  group('IPv6rdTunnelMode', () {
    test('resolve returns correct IPv6rdTunnelMode for valid string', () {
      expect(IPv6rdTunnelMode.resolve('Disabled'), IPv6rdTunnelMode.disabled);
      expect(IPv6rdTunnelMode.resolve('Automatic'), IPv6rdTunnelMode.automatic);
      expect(IPv6rdTunnelMode.resolve('Manual'), IPv6rdTunnelMode.manual);
    });

    test('resolve returns null for invalid string', () {
      expect(IPv6rdTunnelMode.resolve('Invalid'), isNull);
      expect(IPv6rdTunnelMode.resolve(''), isNull);
      expect(IPv6rdTunnelMode.resolve('disabled'), isNull); // case-sensitive
    });

    test('IPv6rdTunnelMode has correct value property', () {
      expect(IPv6rdTunnelMode.disabled.value, 'Disabled');
      expect(IPv6rdTunnelMode.automatic.value, 'Automatic');
      expect(IPv6rdTunnelMode.manual.value, 'Manual');
    });
  });

  group('TaggingStatus', () {
    test('resolve returns correct TaggingStatus for valid string', () {
      expect(TaggingStatus.resolve('Tagged'), TaggingStatus.tagged);
      expect(TaggingStatus.resolve('Untagged'), TaggingStatus.untagged);
    });

    test('resolve returns null for invalid string', () {
      expect(TaggingStatus.resolve('Invalid'), isNull);
      expect(TaggingStatus.resolve(''), isNull);
      expect(TaggingStatus.resolve('tagged'), isNull); // case-sensitive
    });

    test('TaggingStatus has correct value property', () {
      expect(TaggingStatus.tagged.value, 'Tagged');
      expect(TaggingStatus.untagged.value, 'Untagged');
    });
  });

  group('PPPConnectionBehavior', () {
    test('resolve returns correct PPPConnectionBehavior for valid string', () {
      expect(PPPConnectionBehavior.resolve('ConnectOnDemand'),
          PPPConnectionBehavior.connectOnDemand);
      expect(PPPConnectionBehavior.resolve('KeepAlive'),
          PPPConnectionBehavior.keepAlive);
    });

    test('resolve returns null for invalid string', () {
      expect(PPPConnectionBehavior.resolve('Invalid'), isNull);
      expect(PPPConnectionBehavior.resolve(''), isNull);
      expect(
          PPPConnectionBehavior.resolve('keepalive'), isNull); // case-sensitive
    });

    test('resolve handles null input', () {
      expect(PPPConnectionBehavior.resolve(null), isNull);
    });

    test('PPPConnectionBehavior has correct value property', () {
      expect(PPPConnectionBehavior.connectOnDemand.value, 'ConnectOnDemand');
      expect(PPPConnectionBehavior.keepAlive.value, 'KeepAlive');
    });
  });

  group('PPTPIpAddressMode', () {
    test('has all expected values', () {
      expect(PPTPIpAddressMode.values, [
        PPTPIpAddressMode.dhcp,
        PPTPIpAddressMode.specify,
      ]);
    });

    test('can be compared for equality', () {
      expect(PPTPIpAddressMode.dhcp, PPTPIpAddressMode.dhcp);
      expect(PPTPIpAddressMode.specify, PPTPIpAddressMode.specify);
      expect(PPTPIpAddressMode.dhcp == PPTPIpAddressMode.specify, isFalse);
    });
  });
}
