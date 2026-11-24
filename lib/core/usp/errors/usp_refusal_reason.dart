/// Why the router refused a write, when its firmware names the reason.
///
/// linksys/FWDEV#204's firewall and NAT checks put an error name at the start
/// of the refused leaf's USP error message, under a fault code that says only
/// that the value was refused: `ErrorRulesOverlap: external port 18080 is
/// already forwarded.`, code 7012 (measured on FLWRT 2.0.3.26100921,
/// 2026-10-12). The name is the part the user can act on.
///
/// It is read once, where a failure enters the app: `UspResultParser` for a
/// write's envelope and `mapUspErrorToServiceError` for a thrown error. Above
/// the USP layer only this type is read, never the router's text; the
/// localizer maps each value to its own message.
///
/// Port Forwarding, Port Triggering, DMZ and Firewall share the first eight
/// names. IPv6 Port Service (FWDEV#204, 2026-10-14) shares three of them and
/// adds the last four. Static routes and WAN settings carry other names and
/// read them in their own services (`refusalNameIn`).
enum UspRefusalReason {
  /// Ports overlap another rule on the same protocol (`Both` counts as TCP
  /// and UDP).
  rulesOverlap('ErrorRulesOverlap'),

  /// The list is full.
  tooManyRules('ErrorTooManyRules'),

  /// The rule's device address is not a LAN host.
  invalidInternalServerIpAddress('ErrorInvalidInternalServerIPAddress'),

  /// The description is longer than the router keeps: 32 bytes for NAT
  /// rules, 64 for IPv6 port services.
  descriptionTooLong('ErrorDescriptionTooLong'),

  /// The DMZ host's IP address is not valid.
  invalidDestinationIpAddress('ErrorInvalidDestinationIPAddress'),

  /// The DMZ host's MAC address is not valid.
  invalidDestinationMacAddress('ErrorInvalidDestinationMACAddress'),

  /// The DMZ host is set by both IP and MAC; the other one must be cleared
  /// first.
  multipleDestinations('ErrorMultipleDestinations'),

  /// The DMZ source range is a reserved one.
  invalidSourceRestriction('ErrorInvalidSourceRestriction'),

  /// An IPv6 port service with no port.
  noPortRanges('ErrorNoPortRanges'),

  /// An IPv6 port service whose start port is above its end port.
  invalidPortRange('ErrorInvalidPortRange'),

  /// An IPv6 port service with a port above 65535.
  invalidPort('ErrorInvalidPort'),

  /// Another firewall rule already has this description. FL-WRT finds a rule
  /// by its name, so names are unique across every firewall rule.
  descriptionInUse('ErrorDescriptionInUse'),

  /// The router named no reason, or one this app does not know.
  unknown(null);

  const UspRefusalReason(this.errorName);

  /// The name as the firmware writes it; null for [unknown].
  final String? errorName;

  /// The reason [errorMessage] names, or [unknown].
  ///
  /// The name is matched whole, so `ErrorInvalidPortRange` is never read as
  /// `ErrorInvalidPort`. When the WASM client wraps the router's answer in its
  /// own transport text (`… Received error response: <message> (code: N)`),
  /// the router's message is what follows that marker, and the name is
  /// looked for at its start. That wrapper is the only shape a router message
  /// takes in a thrown error, which is why `mapUspErrorToServiceError` can
  /// read a reason at all; a bare name ends at the client's ` (code: N)`.
  static UspRefusalReason fromErrorMessage(String errorMessage) {
    final at = errorMessage.indexOf(_clientWrapper);
    final routerMessage = at < 0
        ? errorMessage
        : errorMessage.substring(at + _clientWrapper.length);
    final name = _leadingName.firstMatch(routerMessage)?.group(1);
    if (name == null) return unknown;
    for (final reason in values) {
      if (reason.errorName == name) return reason;
    }
    return unknown;
  }

  static const _clientWrapper = 'Received error response: ';
  static final _leadingName = RegExp(r'^(Error[A-Za-z]+)\b');
}
