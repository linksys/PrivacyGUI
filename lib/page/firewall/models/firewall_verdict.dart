/// How protected the network is, as the dashboard reports it (#1130).
///
/// One decision with two readers: the mascot's security dimension and the
/// Firewall card's badge, so the two cannot disagree. It looks at the SPI
/// firewall and DMZ only. The card also shows port forwarding and UPnP, but
/// neither changes the verdict: UPnP is on by default, so counting it would put
/// every router in a warning.
enum FirewallVerdict {
  /// Both SPI firewalls on, DMZ off.
  protected,

  /// IPv4 SPI firewall on and DMZ off, but IPv6 SPI firewall off.
  basic,

  /// IPv4 SPI firewall on, DMZ on.
  dmzActive,

  /// IPv4 SPI firewall off. Wins over DMZ.
  atRisk;

  static FirewallVerdict of({
    required bool ipv4SpiOn,
    required bool ipv6SpiOn,
    required bool dmzOn,
  }) {
    if (!ipv4SpiOn) return FirewallVerdict.atRisk;
    if (dmzOn) return FirewallVerdict.dmzActive;
    if (ipv6SpiOn) return FirewallVerdict.protected;
    return FirewallVerdict.basic;
  }
}
