/// Test data builder for the Internet Settings reads: the USP GET responses
/// of `WanStatus`, the routing table the gateway comes from, the WAN IPv6
/// addresses and the DHCP clients a renew picks from.
///
/// The WAN interface, its address row and the routers sit on instance numbers
/// other than 1 and 2, so a read that still assumed a fixed row cannot pass.
class InternetSettingsTestData {
  static const lanInterface = 'Device.IP.Interface.3.';
  static const wanInterface = 'Device.IP.Interface.5.';

  /// `Device.IP.Interface.*.Alias`, with an unnamed interface beside lan/wan.
  static Map<String, dynamic> interfaceAliases({
    String lan = lanInterface,
    String wan = wanInterface,
  }) =>
      {
        '${lan}Alias': 'lan',
        '${wan}Alias': 'wan',
        'Device.IP.Interface.6.Alias': '',
      };

  /// The `WanStatus` GET on [wan]. [hasAddress] false is a WAN with no
  /// `IPv4Address` row (WAN down, FW 2.0.2 bridge mode).
  static Map<String, dynamic> wanStatus({
    String wan = wanInterface,
    String status = 'Up',
    String ipAddress = '203.0.113.1',
    String subnetMask = '255.255.255.0',
    String addressingType = 'DHCP',
    Object maxMtuSize = '1500',
    Object ipv6Enabled = false,
    bool hasAddress = true,
  }) =>
      {
        '${wan}Status': status,
        '${wan}MaxMTUSize': maxMtuSize,
        '${wan}IPv6Enable': ipv6Enabled,
        if (hasAddress) ...{
          '${wan}IPv4Address.3.IPAddress': ipAddress,
          '${wan}IPv4Address.3.SubnetMask': subnetMask,
          '${wan}IPv4Address.3.AddressingType': addressingType,
        },
      };

  /// `Device.Routing.Router.*` with two routers. Router 4 holds a LAN route
  /// and the default route on [defaultRouteInterface]; router 7 holds a
  /// second default route on another interface, which must not be picked.
  static Map<String, dynamic> routing({
    String gateway = '203.0.113.254',
    String defaultRouteInterface = 'Device.IP.Interface.5',
    bool hasDefaultRoute = true,
  }) {
    const r4 = 'Device.Routing.Router.4.';
    const r7 = 'Device.Routing.Router.7.';
    Map<String, dynamic> forwarding(String base, int i,
            {required String dest,
            required String gw,
            required String iface}) =>
        {
          '${base}IPv4Forwarding.$i.Enable': true,
          '${base}IPv4Forwarding.$i.DestIPAddress': dest,
          '${base}IPv4Forwarding.$i.DestSubnetMask':
              dest == '0.0.0.0' ? '0.0.0.0' : '255.255.255.0',
          '${base}IPv4Forwarding.$i.GatewayIPAddress': gw,
          '${base}IPv4Forwarding.$i.Interface': iface,
          '${base}IPv4Forwarding.$i.Origin': 'Static',
          '${base}IPv4Forwarding.$i.Alias': 'route-$i',
        };
    return {
      '${r4}Alias': 'cpe-1',
      ...forwarding(r4, 3,
          dest: '192.168.1.0',
          gw: '192.168.1.1',
          iface: 'Device.IP.Interface.3'),
      if (hasDefaultRoute)
        ...forwarding(r4, 6,
            dest: '0.0.0.0', gw: gateway, iface: defaultRouteInterface),
      '${r7}Alias': 'cpe-2',
      ...forwarding(r7, 9,
          dest: '0.0.0.0', gw: '198.18.0.1', iface: 'Device.IP.Interface.6'),
    };
  }

  /// `Device.DHCPv{4,6}.Client.` ([version] 4 or 6): a client on the LAN
  /// interface (row 3), and, when [hasWanClient], one on the WAN (row 6).
  static Map<String, dynamic> dhcpClients(int version,
      {bool hasWanClient = true}) {
    final base = 'Device.DHCPv$version.Client.';
    // DHCPv4 clients report a Status, DHCPv6 clients a DUID.
    final leaf = version == 4 ? 'Status' : 'DUID';
    final value = version == 4 ? 'Enabled' : '00:03:00:01:74:12:13:21:55:50';
    return {
      '${base}3.Enable': true,
      '${base}3.Interface': lanInterface,
      '${base}3.$leaf': value,
      if (hasWanClient) ...{
        '${base}6.Enable': true,
        // Without the trailing dot, as the router reports it.
        '${base}6.Interface':
            wanInterface.substring(0, wanInterface.length - 1),
        '${base}6.$leaf': value,
      },
    };
  }

  /// Answers the GETs of a renew: the interface aliases, the `WanStatus` of
  /// the WAN, and the DHCPv4 / DHCPv6 client tables.
  static Map<String, dynamic> renewAnswer(List<String> paths,
      {bool hasWanClient = true}) {
    if (paths.contains('Device.IP.Interface.*.Alias')) {
      return interfaceAliases();
    }
    if (paths.contains('${wanInterface}Status')) return wanStatus();
    for (final version in [4, 6]) {
      if (paths.any((p) => p.startsWith('Device.DHCPv$version.Client.'))) {
        return dhcpClients(version, hasWanClient: hasWanClient);
      }
    }
    return {};
  }

  /// The `WanIpv6Addresses` GET on [wan], one row per address, from row 3.
  static Map<String, dynamic> wanIpv6Addresses(List<String> addresses,
          {String wan = wanInterface}) =>
      {
        for (var i = 0; i < addresses.length; i++)
          '${wan}IPv6Address.${i + 3}.IPAddress': addresses[i],
      };
}
