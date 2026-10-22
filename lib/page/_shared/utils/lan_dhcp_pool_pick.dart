/// The `Alias` of the DHCP server pool serving the LAN.
///
/// `Device.DHCPv4.Server.Pool.{i}.` holds one pool per network; on FLWRT 2.0
/// the LAN one is `dhcp-lan` and the guest one `cpe-2` (Architecture #110).
/// The codegen's `LanDhcpPool` resolves the same Alias.
const lanDhcpPoolAlias = 'dhcp-lan';

/// The LAN pool among [pools], or null when the router lists none.
///
/// Every generated table that lists pools (`DhcpClients`,
/// `DhcpReservations`) is read through this, so the guest pool's leases and
/// reservations never show as the LAN's.
T? lanDhcpPoolOf<T>(Iterable<T> pools, String Function(T pool) aliasOf) {
  for (final pool in pools) {
    if (aliasOf(pool) == lanDhcpPoolAlias) return pool;
  }
  return null;
}
