/// The `Name` of the firewall chain holding the router's own rules.
///
/// `Device.Firewall.Chain.{i}.` holds one chain per rule source; on FLWRT 2.0
/// `Defaults Configuration` carries linksys/FWDEV#204's rules and the IPv6
/// port service rules, beside `UPnP Port Mapping (dynamic rules)`.
const defaultFirewallChainName = 'Defaults Configuration';

/// The default chain among [chains], or null when the router lists none.
///
/// Every generated table that lists chains (`FirewallChainRules`,
/// `Ipv6PortService`) is read through this, so UPnP's dynamic rules never
/// show as the router's own.
T? defaultFirewallChainOf<T>(Iterable<T> chains, String Function(T) nameOf) {
  for (final chain in chains) {
    if (nameOf(chain) == defaultFirewallChainName) return chain;
  }
  return null;
}
