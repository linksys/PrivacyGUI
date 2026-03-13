import 'package:privacy_gui/generated/wan_settings.g.dart';

/// WAN connection types supported via USP TR-181.
enum UspWanConnectionType {
  dhcp,
  staticIp,
  pppoe,
  bridge;

  /// Derive the connection type from raw [WanSettings] fields.
  ///
  /// `addressingType` is the primary signal; `bridgeEnabled` alone is NOT
  /// sufficient because `Device.Bridging.Bridge.1.Enable` is typically `true`
  /// on most routers (it controls the LAN-side L2 bridge, not WAN bridge mode).
  /// Bridge mode is only active when both `bridgeEnabled` is true AND
  /// `addressingType` is `DHCP` (or empty/unknown) — i.e. the router has
  /// explicitly been placed into bridge mode rather than a standard DHCP config.
  static UspWanConnectionType fromWanSettings(WanSettings wan) {
    switch (wan.addressingType) {
      case 'Static':
        return staticIp;
      case 'IPCP':
        return pppoe;
      case 'DHCP':
        return dhcp;
      default:
        // Only treat as bridge when addressingType is absent/unknown AND
        // bridgeEnabled is explicitly true.
        if (wan.bridgeEnabled && wan.addressingType.isEmpty) return bridge;
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
        bridge => 'DHCP', // bridge mode uses DHCP addressing internally
      };
}
