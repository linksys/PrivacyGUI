import 'package:privacy_gui/generated/lan_dhcp_pool.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';

import 'internet_settings_test_data.dart';

/// Test data builder for the LAN interface and its DHCP server pool.
///
/// The LAN interface, its address row and the pool sit on instance numbers
/// other than 1 and 2, so a read or write that still assumed `Interface.1` /
/// `Pool.1` cannot pass.
class LocalNetworkTestData {
  static const lanInterface = InternetSettingsTestData.lanInterface;
  static const lanPool = 'Device.DHCPv4.Server.Pool.4.';
  static const guestPool = 'Device.DHCPv4.Server.Pool.2.';

  // ---------------------------------------------------------------------------
  // Codegen models
  // ---------------------------------------------------------------------------

  static LanNetworkInfo createLanNetworkInfo({
    String hostName = 'MyRouter',
    bool ipv6Enabled = false,
    String ipAddress = '192.168.1.1',
    String subnetMask = '255.255.255.0',
  }) =>
      LanNetworkInfo(
        instancePath: lanInterface,
        hostName: hostName,
        ipv6Enabled: ipv6Enabled,
        ipv4Addresses: [
          LanIpv4Address(
            instancePath: '${lanInterface}IPv4Address.3.',
            ipAddress: ipAddress,
            subnetMask: subnetMask,
          ),
        ],
        ipv6Addresses: const [],
      );

  static LanDhcpPool createLanDhcpPool({
    bool dhcpEnabled = true,
    String minAddress = '192.168.1.100',
    String maxAddress = '192.168.1.200',
    int leaseTime = 86400,
    String dnsServers = '8.8.8.8,8.8.4.4',
  }) =>
      LanDhcpPool(
        instancePath: lanPool,
        dhcpEnabled: dhcpEnabled,
        minAddress: minAddress,
        maxAddress: maxAddress,
        leaseTime: leaseTime,
        dnsServers: dnsServers,
      );

  // ---------------------------------------------------------------------------
  // USP GET responses
  // ---------------------------------------------------------------------------

  /// `Device.DHCPv4.Server.Pool.*.Alias`: the guest pool comes first, so a
  /// lowest-row pick reads the wrong pool.
  static Map<String, dynamic> poolAliases() => {
        '${guestPool}Alias': 'cpe-2',
        '${lanPool}Alias': 'dhcp-lan',
      };

  /// The `LanNetworkInfo` GET. The first address row is the router address;
  /// a second row proves only the first is read.
  static Map<String, dynamic> lanInterfaceResponse({
    String hostName = 'MyRouter',
    Object ipv6Enabled = false,
    String ipAddress = '192.168.1.1',
    String subnetMask = '255.255.255.0',
    bool hasAddress = true,
  }) =>
      {
        'Device.DeviceInfo.HostName': hostName,
        '${lanInterface}IPv6Enable': ipv6Enabled,
        if (hasAddress) ...{
          '${lanInterface}IPv4Address.3.IPAddress': ipAddress,
          '${lanInterface}IPv4Address.3.SubnetMask': subnetMask,
          '${lanInterface}IPv4Address.7.IPAddress': '169.254.0.1',
          '${lanInterface}IPv4Address.7.SubnetMask': '255.255.0.0',
        },
      };

  /// The `LanDhcpPool` GET on [lanPool].
  static Map<String, dynamic> lanPoolResponse({
    Object dhcpEnabled = true,
    String minAddress = '192.168.1.100',
    String maxAddress = '192.168.1.200',
    Object leaseTime = '86400',
    String dnsServers = '8.8.8.8,8.8.4.4',
  }) =>
      {
        '${lanPool}Enable': dhcpEnabled,
        '${lanPool}MinAddress': minAddress,
        '${lanPool}MaxAddress': maxAddress,
        '${lanPool}LeaseTime': leaseTime,
        '${lanPool}DNSServers': dnsServers,
      };

  /// The pool rows every pool-table GET (`DhcpClients`, `DhcpReservations`)
  /// returns: the guest pool in front of the LAN pool.
  static Map<String, dynamic> poolRows() => {
        ...poolAliases(),
        '${guestPool}Interface': 'Device.IP.Interface.6',
        '${lanPool}Interface': 'Device.IP.Interface.3',
      };

  /// `DhcpReservations` with [lan] on the LAN pool, each `(mac, ip, enable)`
  /// on its own row from row 5, and one guest reservation on the guest pool
  /// that must not show as the LAN's.
  static Map<String, dynamic> reservationsResponse(
      List<(String, String, bool)> lan) {
    Map<String, dynamic> row(String pool, int i, (String, String, bool) r) => {
          '${pool}StaticAddress.$i.Enable': r.$3,
          '${pool}StaticAddress.$i.Chaddr': r.$1,
          '${pool}StaticAddress.$i.Yiaddr': r.$2,
        };
    return {
      ...poolRows(),
      ...row(guestPool, 3, ('GG:GG:GG:GG:GG:01', '192.168.3.50', true)),
      for (var i = 0; i < lan.length; i++) ...row(lanPool, i + 5, lan[i]),
    };
  }

  /// Answers every GET the LAN services issue, by the paths requested.
  ///
  /// [lanInterfaceGet] / [lanPoolGet] replace the default responses;
  /// [ipv6Addresses] is the LAN interface's `IPv6Address.` table.
  static Map<String, dynamic> answer(
    List<String> paths, {
    Map<String, dynamic>? lanInterfaceGet,
    Map<String, dynamic>? lanPoolGet,
    Map<String, dynamic> ipv6Addresses = const {},
  }) {
    if (paths.contains('Device.IP.Interface.*.Alias')) {
      return InternetSettingsTestData.interfaceAliases();
    }
    if (paths.contains('Device.DHCPv4.Server.Pool.*.Alias')) {
      return poolAliases();
    }
    if (paths.contains('${lanInterface}IPv6Address.')) {
      return ipv6Addresses;
    }
    if (paths.any((p) => p.startsWith(lanPool))) {
      return lanPoolGet ?? lanPoolResponse();
    }
    if (paths.any((p) => p.startsWith(lanInterface))) {
      return lanInterfaceGet ?? lanInterfaceResponse();
    }
    return {};
  }
}
