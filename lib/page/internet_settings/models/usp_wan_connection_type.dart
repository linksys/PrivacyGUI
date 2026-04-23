/// WAN connection types supported via USP TR-181.
enum UspWanConnectionType {
  dhcp,
  staticIp,
  pppoe,
  bridge;

  /// Derive the connection type from raw WAN field values.
  ///
  /// [addressingType] is the primary signal; [bridgeEnabled] alone is NOT
  /// sufficient because `Device.Bridging.Bridge.1.Enable` is typically `true`
  /// on most routers (it controls the LAN-side L2 bridge, not WAN bridge mode).
  /// Bridge mode is only active when both `bridgeEnabled` is true AND
  /// `addressingType` is `DHCP` (or empty/unknown) — i.e. the router has
  /// explicitly been placed into bridge mode rather than a standard DHCP config.
  static UspWanConnectionType fromRawFields({
    required String addressingType,
    required bool bridgeEnabled,
  }) {
    switch (addressingType) {
      case 'Static':
        return staticIp;
      case 'IPCP':
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
        bridge => 'Bridge Mode',
      };

  /// The TR-181 `AddressingType` value to write back.
  String get addressingTypeValue => switch (this) {
        dhcp => 'DHCP',
        staticIp => 'Static',
        pppoe => 'IPCP',
        bridge => '', // issue #14: empty string = proto=none
      };
}
