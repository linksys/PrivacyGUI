/**
 * Device.Hosts.Host.* — ConnectedDevices (multi-instance + nested wildcard)
 * 3 devices: 1 wired active, 1 wireless active, 1 wireless inactive
 */
export const connectedDevicesData: Record<string, string> = {
  // Device 1 — wired, active
  'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:11:22:33',
  'Device.Hosts.Host.1.IPAddress': '192.168.1.100',
  'Device.Hosts.Host.1.HostName': 'desktop-pc',
  'Device.Hosts.Host.1.Active': 'true',
  'Device.Hosts.Host.1.Layer1Interface': 'Device.Ethernet.Interface.1.',
  'Device.Hosts.Host.1.AddressSource': 'DHCP',
  'Device.Hosts.Host.1.IPv6Address.1.IPAddress': 'fe80::aabb:ccff:fe11:2233',

  // Device 2 — wireless (5 GHz), active
  'Device.Hosts.Host.2.PhysAddress': '11:22:33:44:55:66',
  'Device.Hosts.Host.2.IPAddress': '192.168.1.101',
  'Device.Hosts.Host.2.HostName': 'smartphone',
  'Device.Hosts.Host.2.Active': 'true',
  'Device.Hosts.Host.2.Layer1Interface': 'Device.WiFi.SSID.1.',
  'Device.Hosts.Host.2.AddressSource': 'DHCP',
  'Device.Hosts.Host.2.IPv6Address.1.IPAddress': 'fe80::1122:33ff:fe44:5566',
  'Device.Hosts.Host.2.IPv6Address.2.IPAddress': '2001:db8::101',

  // Device 3 — wireless (2.4 GHz), inactive
  'Device.Hosts.Host.3.PhysAddress': 'DD:EE:FF:00:11:22',
  'Device.Hosts.Host.3.IPAddress': '192.168.1.102',
  'Device.Hosts.Host.3.HostName': 'tablet',
  'Device.Hosts.Host.3.Active': 'false',
  'Device.Hosts.Host.3.Layer1Interface': 'Device.WiFi.SSID.2.',
  'Device.Hosts.Host.3.AddressSource': 'DHCP',
};
