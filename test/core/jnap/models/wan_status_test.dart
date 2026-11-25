import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';

/// `GetWANStatus` output as JSON text from a router online over DHCP with a
/// SLAAC IPv6 WAN. The IPv6 part is from test/test_data/.
const _dualStackText = '''
{
  "supportedWANTypes": ["DHCP", "Static", "PPPoE", "PPTP", "L2TP", "Bridge"],
  "supportedIPv6WANTypes": ["Automatic", "PPPoE", "Pass-through"],
  "supportedWANCombinations": [
    {"wanType": "DHCP", "wanIPv6Type": "Automatic"},
    {"wanType": "PPPoE", "wanIPv6Type": "PPPoE"}
  ],
  "isDetectingWANType": false,
  "detectedWANType": "DHCP",
  "wanStatus": "Connected",
  "wanConnection": {
    "wanType": "DHCP",
    "ipAddress": "220.133.10.20",
    "networkPrefixLength": 24,
    "gateway": "220.133.10.254",
    "mtu": 1500,
    "dhcpLeaseMinutes": 1440,
    "dnsServer1": "168.95.1.1",
    "dnsServer2": "8.8.8.8"
  },
  "wanIPv6Status": "Connected",
  "wanIPv6Connection": {
    "wanType": "SLAAC",
    "networkInfo": {
      "ipAddress": "2001:b011:7001:0761:e831:9b30:ca98:9a58",
      "gateway": "fe80:0000:0000:0000:d2f0:dbff:fe89:5800",
      "dnsServer1": "2001:b000:0168:0000:0000:0000:0000:0002",
      "dnsServer2": "2001:b000:0168:0000:0000:0000:0000:0001"
    }
  },
  "linkLocalIPv6Address": "fe80:0000:0000:0000:3223:03ff:fe2e:afee",
  "macAddress": "30:23:03:2E:AF:EE"
}
''';

/// The same router before its WAN is up: no connection, and a router that
/// lists no IPv6 types.
const _offlineText = '''
{
  "supportedWANTypes": ["DHCP", "Static", "PPPoE"],
  "detectedWANType": "DHCP",
  "wanStatus": "Connecting",
  "wanIPv6Status": "Disconnected",
  "macAddress": "30:23:03:2E:AF:EE"
}
''';

void main() {
  group('RouterWANStatus', () {
    test('reads the status the dashboard and Internet settings show', () {
      final status = RouterWANStatus.fromJson(_dualStackText);

      expect(status.wanStatus, 'Connected');
      expect(status.detectedWANType, 'DHCP');
      expect(status.macAddress, '30:23:03:2E:AF:EE');
      final ipv4 = status.wanConnection!;
      expect(ipv4.ipAddress, '220.133.10.20');
      expect(ipv4.networkPrefixLength, 24);
      expect(ipv4.gateway, '220.133.10.254');
      expect(ipv4.mtu, 1500);
      expect(ipv4.dhcpLeaseMinutes, 1440);
      expect([ipv4.dnsServer1, ipv4.dnsServer2, ipv4.dnsServer3],
          ['168.95.1.1', '8.8.8.8', null]);
      expect(status.wanIPv6Status, 'Connected');
      expect(status.wanIPv6Connection?.wanType, 'SLAAC');
      final ipv6 = status.wanIPv6Connection!.networkInfo!;
      expect(ipv6.ipAddress, '2001:b011:7001:0761:e831:9b30:ca98:9a58');
      expect(ipv6.gateway, 'fe80:0000:0000:0000:d2f0:dbff:fe89:5800');
      expect(ipv6.dhcpLeaseMinutes, isNull);
      expect(status.supportedWANTypes, hasLength(6));
      expect(
          status.supportedIPv6WANTypes, ['Automatic', 'PPPoE', 'Pass-through']);
      expect(
          status.supportedWANCombinations.last,
          const SupportedWANCombination(
              wanType: 'PPPoE', wanIPv6Type: 'PPPoE'));
    });

    test('reads a WAN that is not up, on a router with no IPv6 types', () {
      final status = RouterWANStatus.fromJson(_offlineText);

      expect(status.wanStatus, 'Connecting');
      expect(status.wanConnection, isNull);
      expect(status.wanIPv6Connection, isNull);
      expect(status.supportedIPv6WANTypes, isEmpty);
      expect(status.supportedWANCombinations, isEmpty);
    });

    test('writes back what it read, leaving out what the router did not give',
        () {
      final status = RouterWANStatus.fromJson(_offlineText);

      expect(status.toMap(), {
        'macAddress': '30:23:03:2E:AF:EE',
        'detectedWANType': 'DHCP',
        'wanStatus': 'Connecting',
        'wanIPv6Status': 'Disconnected',
        'supportedWANTypes': ['DHCP', 'Static', 'PPPoE'],
        'supportedIPv6WANTypes': <String>[],
        'supportedWANCombinations': <Object>[],
      });
      expect(RouterWANStatus.fromJson(status.toJson()), status);
    });

    test('writes back the IPv6 WAN it read', () {
      final status = RouterWANStatus.fromJson(_dualStackText);

      expect(status.toMap()['wanIPv6Connection'], {
        'wanType': 'SLAAC',
        'networkInfo': {
          'ipAddress': '2001:b011:7001:0761:e831:9b30:ca98:9a58',
          'gateway': 'fe80:0000:0000:0000:d2f0:dbff:fe89:5800',
          'dhcpLeaseMinutes': null,
          'dnsServer1': '2001:b000:0168:0000:0000:0000:0000:0002',
          'dnsServer2': '2001:b000:0168:0000:0000:0000:0000:0001',
          'dnsServer3': null,
        },
      });
    });

    test('survives a trip through JSON text', () {
      final status = RouterWANStatus.fromJson(_dualStackText);

      final restored = RouterWANStatus.fromJson(status.toJson());

      expect(restored, status);
      expect(restored.wanIPv6Connection?.networkInfo?.dnsServer2,
          '2001:b000:0168:0000:0000:0000:0000:0001');
    });

    test('copyWith changes only what it names', () {
      final status = RouterWANStatus.fromJson(_dualStackText);

      final down = status.copyWith(wanStatus: 'Disconnected');

      expect(down.wanStatus, 'Disconnected');
      expect(down.wanConnection, status.wanConnection);
      expect(down, isNot(status));
      expect(down.copyWith(wanStatus: 'Connected'), status);
    });
  });

  group('the parts of a WAN status', () {
    final status = RouterWANStatus.fromJson(_dualStackText);

    test('the IPv4 connection', () {
      final ipv4 = status.wanConnection!;

      expect(ipv4.toMap(), {
        'wanType': 'DHCP',
        'ipAddress': '220.133.10.20',
        'networkPrefixLength': 24,
        'gateway': '220.133.10.254',
        'mtu': 1500,
        'dhcpLeaseMinutes': 1440,
        'dnsServer1': '168.95.1.1',
        'dnsServer2': '8.8.8.8',
      });
      expect(WANConnectionInfo.fromJson(ipv4.toJson()), ipv4);
      final static = ipv4.copyWith(wanType: 'Static', dnsServer3: '1.1.1.1');
      expect((static.wanType, static.dnsServer3), ('Static', '1.1.1.1'));
      expect(static.ipAddress, '220.133.10.20');
    });

    test('the IPv6 connection and its network', () {
      final ipv6 = status.wanIPv6Connection!;
      final network = ipv6.networkInfo!;

      expect(IPv6NetworkInfo.fromJson(network.toJson()), network);
      expect(ipv6.copyWith(wanType: 'Automatic').networkInfo, network);
      final leased = network.copyWith(dhcpLeaseMinutes: 60);
      expect(leased.dhcpLeaseMinutes, 60);
      expect(leased.ipAddress, network.ipAddress);
      expect(
          WANIPv6ConnectionInfo.fromMap(const {'wanType': 'Pass-through'})
              .networkInfo,
          isNull);
    });

    test('the IPv6 connection survives a trip through JSON text', () {
      final ipv6 = status.wanIPv6Connection!;

      expect(WANIPv6ConnectionInfo.fromJson(ipv6.toJson()), ipv6);
    });

    test('a supported combination', () {
      final combination = status.supportedWANCombinations.first;

      expect(
          combination.toMap(), {'wanType': 'DHCP', 'wanIPv6Type': 'Automatic'});
      expect(
          SupportedWANCombination.fromJson(combination.toJson()), combination);
      expect(combination.copyWith(wanIPv6Type: 'Pass-through').wanType, 'DHCP');
    });
  });
}
