/**
 * DHCP data — reservations + clients
 * Minimal placeholder for dashboard/LAN rendering
 */

/** Device.DHCPv4.Server.Pool.1.StaticAddress.* — DHCP Reservations */
export const dhcpReservationsData: Record<string, string> = {
  'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Enable': 'true',
  'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Chaddr': 'AA:BB:CC:11:22:33',
  'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Yiaddr': '192.168.1.100',
};

/** Device.DHCPv4.Server.Pool.1.Client.* — DHCP Clients */
export const dhcpClientsData: Record<string, string> = {
  'Device.DHCPv4.Server.Pool.1.Client.1.Chaddr': 'AA:BB:CC:11:22:33',
  'Device.DHCPv4.Server.Pool.1.Client.1.Active': 'true',
  'Device.DHCPv4.Server.Pool.1.Client.1.IPv4Address.1.IPAddress': '192.168.1.100',
  'Device.DHCPv4.Server.Pool.1.Client.1.IPv4Address.1.LeaseTimeRemaining': '2026-04-23T14:30:00Z',

  'Device.DHCPv4.Server.Pool.1.Client.2.Chaddr': '11:22:33:44:55:66',
  'Device.DHCPv4.Server.Pool.1.Client.2.Active': 'true',
  'Device.DHCPv4.Server.Pool.1.Client.2.IPv4Address.1.IPAddress': '192.168.1.101',
  'Device.DHCPv4.Server.Pool.1.Client.2.IPv4Address.1.LeaseTimeRemaining': '2026-04-23T10:00:00Z',
};
