/**
 * LAN — LanNetworkInfo (single-instance, Interface.1 + DHCP pool)
 * + IPv6 addresses from raw get()
 */
export const lanNetworkData: Record<string, string> = {
  // Base LAN (codegen: lan_network_info.g.dart)
  'Device.IP.Interface.1.IPv4Address.1.IPAddress': '192.168.1.1',
  'Device.IP.Interface.1.IPv4Address.1.SubnetMask': '255.255.255.0',
  'Device.DHCPv4.Server.Pool.1.Enable': 'true',
  'Device.DHCPv4.Server.Pool.1.MinAddress': '192.168.1.100',
  'Device.DHCPv4.Server.Pool.1.MaxAddress': '192.168.1.199',
  'Device.DHCPv4.Server.Pool.1.LeaseTime': '86400',
  'Device.DHCPv4.Server.Pool.1.DNSServers': '192.168.1.1',
  'Device.IP.Interface.1.IPv6Enable': 'false',

  // HostName is in system-info.ts (Device.DeviceInfo.HostName)

  // Raw get() in usp_lan_data_service.dart — LAN IPv6
  'Device.IP.Interface.1.IPv6Address.1.IPAddress': 'fe80::1',
};
