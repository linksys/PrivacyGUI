import 'package:equatable/equatable.dart';

/// Read-only WAN/IPv6 fields displayed on the Internet Settings page
/// but NOT user-editable.
///
/// Decouples the model layer from codegen types (`WanSettings`, `Ipv6Settings`).
/// AUDIT, #1587 Phase 2 — which of these still belong here.
///
/// This whole object is populated by the same `service.fetch()` that fills the L2 form,
/// so every field in it is a PAGE-ENTRY SNAPSHOT. That is wrong for a value the user
/// cannot edit: the test is "can the user edit this?", and if not it should be read from
/// L1 so a push refreshes it.
///
/// | field                 | rendered by                          | status |
/// |-----------------------|--------------------------------------|--------|
/// | `staticIpAddress`     | status banner, Release & Renew        | **moved to L1** — both now read `wanDataProvider`. Same TR-181 parameter, but the copy a `wanStatus` push refreshes. This field is now UNUSED by the views and is kept only because `_buildReadOnlyInfo` still fills it; removing it is safe once nothing reads it |
/// | `pppConnectionStatus` | IPv4 section, PPPoE/PPTP/L2TP rows   | **still stale, deliberately not fixed here.** It comes from `Device.PPP.Interface.{i}.ConnectionStatus`, and L1 has no PPP data at all — `WanStatusUIModel` carries only status/ip/mask/addressingType. Fixing it means extending that model, which dashboard, Statistics and health scoring also consume, so it is a decision of its own rather than a follow-on. **A connection STATUS that does not update is the most surprising of these**, so it is worth doing |
/// | `dhcpv6Duid`          | IPv6 section                         | stale, low value. A DUID is stable for the life of the device |
/// | `hostName`            | bridge-mode redirect hint and dialog | stale, low value. Changes only when the user renames the router, which is not this page |
/// | `currentMacAddress`   | nothing — the MAC Clone row is commented out | dead; `_buildReadOnlyInfo` hardcodes `''` |
///
/// So two fields are still page-entry snapshots on purpose (`dhcpv6Duid`, `hostName`),
/// one is a known gap with a real cost (`pppConnectionStatus`), and one is dead.
class InternetSettingsReadOnlyInfo extends Equatable {
  /// Current WAN MAC address (may differ from configured MAC clone).
  final String currentMacAddress;

  /// PPP connection status string (e.g. 'Connected', 'Disconnected').
  final String pppConnectionStatus;

  /// DHCPv6 DUID (read-only, assigned by server).
  final String dhcpv6Duid;

  /// Current static IP address — displayed in the status banner and renew section.
  final String staticIpAddress;

  /// Router hostname (`Device.DeviceInfo.HostName`). Display-only; used to build
  /// the `https://<hostName>.local` bridge-mode management address.
  final String hostName;

  const InternetSettingsReadOnlyInfo({
    this.currentMacAddress = '',
    this.pppConnectionStatus = '',
    this.dhcpv6Duid = '',
    this.staticIpAddress = '',
    this.hostName = '',
  });

  @override
  List<Object?> get props => [
        currentMacAddress,
        pppConnectionStatus,
        dhcpv6Duid,
        staticIpAddress,
        hostName,
      ];
}
