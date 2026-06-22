/// WAN connection types supported via USP TR-181.
enum UspWanConnectionType {
  dhcp,
  staticIp,
  pppoe,
  pptp,
  l2tp,
  bridge;

  /// Derive the connection type from raw WAN field values.
  ///
  /// [addressingType] is the primary signal; [lowerLayers] disambiguates
  /// PPP-based protocols (PPPoE vs PPTP vs L2TP) by checking the tunnel
  /// reference in PPP.Interface.LowerLayers.
  ///
  /// [bridgeEnabled] alone is NOT sufficient because
  /// `Device.Bridging.Bridge.1.Enable` is typically `true` on most routers
  /// (it controls the LAN-side L2 bridge, not WAN bridge mode).
  static UspWanConnectionType fromRawFields({
    required String addressingType,
    required bool bridgeEnabled,
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
        // Only treat as bridge when addressingType is absent/unknown AND
        // bridgeEnabled is explicitly true.
        // TODO: This detection is fragile — bridgeEnabled (Device.Bridging.
        // Bridge.1.Enable) is typically always true on most routers (LAN-side
        // L2 bridge). Proper detection should check whether the WAN interface
        // is configured as a bridge port via Device.Bridging.Bridge.{i}.Port.
        if (bridgeEnabled && addressingType.isEmpty) return bridge;
        return dhcp;
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
