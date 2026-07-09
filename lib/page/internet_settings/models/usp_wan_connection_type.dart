/// WAN connection types supported via USP TR-181.
enum UspWanConnectionType {
  dhcp,
  staticIp,
  pppoe,
  pptp,
  l2tp,
  bridge;

  /// Derive the connection type from the WAN interface's `AddressingType`.
  ///
  /// [addressingType] is the single source of truth for WAN mode:
  /// - `Static` → static IP
  /// - `IPCP`   → PPP-based (PPPoE / PPTP / L2TP, disambiguated by [lowerLayers])
  /// - `DHCP`   → DHCP
  /// - empty → bridge mode (firmware sets `AddressingType=""` when the WAN
  ///   interface is placed into a transparent L2 bridge)
  /// - any other unrecognised value → DHCP (safe fallback; only an explicitly
  ///   empty value means bridge, so a future/transient value is not
  ///   misclassified as bridge).
  ///
  /// [lowerLayers] disambiguates PPP-based protocols by checking the tunnel
  /// reference in `PPP.Interface.LowerLayers` (GRE → PPTP, L2TPv2 → L2TP).
  ///
  /// `Device.Bridging.Bridge.{i}.Enable` is deliberately NOT consulted: it
  /// controls the LAN-side L2 bridge and is `true` on most routers regardless
  /// of WAN bridge mode.
  static UspWanConnectionType fromRawFields({
    required String addressingType,
    String lowerLayers = '',
  }) {
    switch (addressingType) {
      case 'Static':
        return staticIp;
      case 'IPCP':
        if (lowerLayers.contains('GRE.Tunnel')) return pptp;
        if (lowerLayers.contains('L2TPv2.Tunnel')) return l2tp;
        return pppoe;
      case 'DHCP':
        return dhcp;
      default:
        // Only an explicitly empty AddressingType signals bridge mode; any
        // other unknown value falls back to DHCP rather than misclassifying
        // as bridge.
        return addressingType.isEmpty ? bridge : dhcp;
    }
  }

  /// Human-readable label.
  String get label => switch (this) {
        dhcp => 'Automatic Configuration - DHCP',
        staticIp => 'Static IP',
        pppoe => 'PPPoE',
        pptp => 'PPTP',
        l2tp => 'L2TP',
        bridge => 'Bridge Mode',
      };

  /// The TR-181 `AddressingType` value to write back.
  String get addressingTypeValue => switch (this) {
        dhcp => 'DHCP',
        staticIp => 'Static',
        pppoe => 'IPCP',
        pptp => 'IPCP',
        l2tp => 'IPCP',
        bridge => '', // issue #14: empty string = proto=none
      };

  /// Minimum MTU accepted for this connection type (protocol-independent).
  int get mtuMin => 576;

  /// Maximum MTU accepted for this connection type. Varies by protocol
  /// overhead: PPPoE reserves 8 bytes (PPP header), PPTP/L2TP reserve 40 bytes
  /// (tunnel overhead); the rest use the Ethernet standard 1500.
  int get mtuMax => switch (this) {
        pppoe => 1492, // 1500 - 8 (PPP header)
        pptp || l2tp => 1460, // tunnel overhead
        _ => 1500, // Ethernet standard (DHCP, Static, Bridge)
      };

  /// Clamp [mtu] into this type's valid range: values already within
  /// `[mtuMin, mtuMax]` are kept; anything outside (too low or too high) falls
  /// back to [mtuMax]. Used when switching connection types so a previously
  /// valid MTU is preserved when it still fits, and reset to the max otherwise.
  int clampMtu(int mtu) => (mtu >= mtuMin && mtu <= mtuMax) ? mtu : mtuMax;

  /// Whether this type uses a PPP.Interface (credentials, LowerLayers).
  bool get isPppBased => this == pppoe || this == pptp || this == l2tp;

  /// The LowerLayers value for PPP.Interface when switching to this type.
  String? get pppLowerLayers => switch (this) {
        pppoe => 'Device.Ethernet.Link.2',
        pptp => 'Device.GRE.Tunnel.1.Interface.1',
        l2tp => 'Device.L2TPv2.Tunnel.1.Interface.1',
        _ => null,
      };
}
