/// Data domains that can be invalidated by SSE notifications.
///
/// Each domain corresponds to a TR-181 subtree. When an SSE notification
/// arrives for a domain, providers listening to [sseInvalidationProvider]
/// can selectively re-fetch only the affected data.
enum InvalidationDomain {
  /// Device.Hosts.Host. — device connect/disconnect
  connectedDevices,

  /// Device.WiFi.SSID. — SSID name, password, enable state
  wifiSsids,

  /// Device.WiFi.Radio. — channel, bandwidth, enable state
  wifiRadios,

  /// Device.NAT.PortMapping. — port forwarding rules
  portForwarding,

  /// Device.Firewall.Chain. — firewall rules
  firewallRules,

  /// Device.DHCPv4.Server.Pool.1.StaticAddress. — DHCP reservations
  dhcpReservations,

  /// Device.Firewall.DMZ. — DMZ configuration
  dmz,

  /// Device.Routing.Router.1.IPv4Forwarding. — static routes
  staticRouting,

  /// Device.WiFi.AccessPoint. — AP settings, security mode
  wifiAccessPoints,

  /// Device.DHCPv4.Server.Pool.1.Client. — DHCP lease changes
  dhcpClients,

  /// Device.WiFi.AccessPoint.*.AssociatedDevice. — WiFi device connect/disconnect
  wifiClients,

  /// Device.Ethernet.Interface. — Ethernet port status changes
  ethernetInterfaces,

  /// Device.IP.Interface.2. — WAN status changes (Up/Down, IP address)
  wanStatus,
}
