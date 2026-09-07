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

  /// Device.IP.Interface.{wan}. — WAN status changes (Up/Down, IP address).
  /// The WAN instance is resolved by Alias, not hardcoded — see
  /// [wanInterfacePathProvider].
  wanStatus,
}

/// One SSE invalidation event: the [domain] that changed, plus a [seq] that
/// makes consecutive events for the *same* domain unequal.
///
/// Why the tag exists. `sseInvalidationProvider` used to emit a bare
/// [InvalidationDomain]. That made two consecutive events for one domain
/// `==`-equal, so whether the second one reached its listeners depended
/// entirely on the provider's notify policy — an undocumented contract that
/// riverpod 2.6.1 happens to satisfy (`StreamProvider` re-notifies on an equal
/// value) and that riverpod 3.x's `updateShouldNotify` unification to `==`
/// removes. Two rapid changes in one subtree — a second device joining, a
/// second port-mapping rule — would have collapsed into one refresh.
///
/// [seq] is monotonic per provider instance and carries no meaning beyond
/// being different from the previous one. It is preferred over a wrapper class
/// that deliberately omits `==` because that only works while nobody adds
/// value equality to it, and value equality is this repo's house idiom
/// (169 `Equatable` classes). A counter cannot be tampered into equality, and
/// it is loggable and assertable besides.
typedef InvalidationEvent = ({InvalidationDomain domain, int seq});
