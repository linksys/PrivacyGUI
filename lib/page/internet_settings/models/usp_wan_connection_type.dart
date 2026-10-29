/// 1.0's PPP limits, which the firmware enforces (linksys/feed_usp#55 netmngr
/// 036, 037, 050; the Keep Alive interval since feed_usp#68): idle time 1–9999
/// minutes, Keep Alive "reconnect after" 20–180 seconds with 30 as 1.0's
/// default, and a user name and password of at most 255 characters.
const kPppIdleMinutesMin = 1;
const kPppIdleMinutesMax = 9999;
const kPppKeepAliveSecondsMin = 20;
const kPppKeepAliveSecondsMax = 180;
const kPppKeepAliveDefaultSeconds = 30;
const kPppCredentialMaxLength = 255;

/// The messages netmngr refuses a WAN write with (linksys/feed_usp#55, patches
/// 036 and 039; fault 7012, nothing written). Each is the refused leaf's whole
/// `errorMessage`, measured on 2.0.3.26102008. The service reads them off a
/// refusal and the page shows each with its own message.
class WanRefusalNames {
  static const invalidServer = 'Invalid server';
  static const invalidIpAddress = 'Invalid IP address';
  static const invalidPrefixLength = 'Invalid network prefix length';
  static const invalidGateway = 'Invalid gateway';
  static const invalidPrimaryDns = 'Invalid primary DNS server';
  static const invalidDns = 'Invalid DNS server';
  static const invalidMtu = 'Invalid MTU';

  static const all = [
    invalidServer,
    invalidIpAddress,
    invalidPrefixLength,
    invalidGateway,
    invalidPrimaryDns,
    invalidDns,
    invalidMtu,
  ];
}

/// WAN connection types supported via USP TR-181.
enum UspWanConnectionType {
  dhcp,
  staticIp,
  pppoe,
  ipoe,
  pptp,
  l2tp,
  bridge;

  /// Derive the connection type from the WAN interface's admin state and its
  /// `AddressingType`.
  ///
  /// [interfaceEnabled] is `Device.IP.Interface.{wan}.Enable` and is the single
  /// source of truth for bridge mode: the firmware's set handler for that one
  /// parameter is what folds the WAN device into `br-lan` and runs
  /// `bridge-mode-apply.sh enter|exit`, so `false` means bridge and nothing
  /// else does.
  ///
  /// [addressingType] then distinguishes the non-bridge modes:
  /// - `Static` → static IP
  /// - `IPCP`   → PPP-based (PPPoE / PPTP / L2TP, disambiguated by [lowerLayers])
  /// - `DHCP`   → DHCP
  /// - anything unrecognised, empty included → DHCP (safe fallback). An empty
  ///   value does NOT mean bridge: on this firmware writing
  ///   `AddressingType=""` never entered bridge mode — that set handler only
  ///   writes a uci option and never invokes the bridge script.
  ///
  /// [lowerLayers] disambiguates PPP-based protocols by checking the tunnel
  /// reference in `PPP.Interface.LowerLayers` (GRE → PPTP, L2TPv2 → L2TP).
  static UspWanConnectionType fromRawFields({
    required String addressingType,
    required bool interfaceEnabled,
    String lowerLayers = '',
  }) {
    if (!interfaceEnabled) return bridge;
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
        // Unrecognised (or transiently empty) value on an enabled interface:
        // fall back to DHCP rather than inventing a mode.
        return dhcp;
    }
  }

  /// Human-readable label.
  String get label => switch (this) {
        dhcp => 'Automatic Configuration - DHCP',
        staticIp => 'Static IP',
        pppoe => 'PPPoE',
        ipoe => 'IPoE',
        pptp => 'PPTP',
        l2tp => 'L2TP',
        bridge => 'Bridge Mode',
      };

  /// The TR-181 `AddressingType` value to write back.
  String get addressingTypeValue => switch (this) {
        ipoe => throw StateError('IPoE is configured through Auto-IPoE'),
        dhcp => 'DHCP',
        staticIp => 'Static',
        pppoe => 'IPCP',
        pptp => 'IPCP',
        l2tp => 'IPCP',
        // Never sent: bridge is entered and exited through
        // Device.IP.Interface.{wan}.Enable, not AddressingType.
        bridge => '',
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

  /// Whether this type runs PPP over a tunnel row: `GRE.Tunnel` for PPTP,
  /// `L2TPv2.Tunnel` for L2TP.
  bool get isTunnel => this == pptp || this == l2tp;
}
