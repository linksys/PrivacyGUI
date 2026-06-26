/// WAN connection types supported via USP TR-181.
enum UspWanConnectionType {
  dhcp,
  staticIp,
  pppoe,
  bridge;

  /// Derive the connection type from the WAN interface's `AddressingType`.
  ///
  /// This is the single source of truth for WAN mode:
  /// - `Static` → static IP
  /// - `IPCP`   → PPPoE
  /// - `DHCP`   → DHCP
  /// - empty / anything else → bridge mode (firmware sets `AddressingType=""`
  ///   when the WAN interface is placed into a transparent L2 bridge).
  ///
  /// `Device.Bridging.Bridge.{i}.Enable` is deliberately NOT consulted: it
  /// controls the LAN-side L2 bridge and is `true` on most routers regardless
  /// of WAN bridge mode.
  static UspWanConnectionType fromRawFields({required String addressingType}) {
    switch (addressingType) {
      case 'Static':
        return staticIp;
      case 'IPCP':
        return pppoe;
      case 'DHCP':
        return dhcp;
      default:
        return bridge;
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
