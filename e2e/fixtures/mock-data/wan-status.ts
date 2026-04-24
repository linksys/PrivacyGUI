/**
 * WAN status — WanStatus (single-instance, Interface.2)
 * + IPv4 forwarding (gateway) + IPv6 addresses
 */
export const wanStatusData: Record<string, string> = {
  // Base WAN (codegen: wan_status.g.dart)
  'Device.IP.Interface.2.Status': 'Up',
  'Device.IP.Interface.2.IPv4Address.1.IPAddress': '203.0.113.42',
  'Device.IP.Interface.2.IPv4Address.1.SubnetMask': '255.255.255.0',
  'Device.IP.Interface.2.IPv4Address.1.AddressingType': 'DHCP',
  'Device.IP.Interface.2.MaxMTUSize': '1500',
  'Device.IP.Interface.2.IPv6Enable': 'true',

  // Raw get() in usp_wan_data_service.dart — gateway routing
  'Device.Routing.Router.1.IPv4Forwarding.1.DestIPAddress': '0.0.0.0',
  'Device.Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress': '203.0.113.1',
  'Device.Routing.Router.1.IPv4Forwarding.1.Interface': 'Device.IP.Interface.2.',

  // WAN IPv6 addresses
  'Device.IP.Interface.2.IPv6Address.1.IPAddress': '2001:db8:wan::42',
};
