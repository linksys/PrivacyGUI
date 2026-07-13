import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Backhaul connection info for slave mesh nodes.
///
/// Describes how a slave node connects to its parent (WiFi or Ethernet).
class BackhaulInfo with EquatableMixin, DiagnosticNamed {
  /// Media type description, e.g., "IEEE 802.11ax", "Ethernet".
  final String mediaType;

  /// Link type: "Wi-Fi" or "Ethernet".
  final String? linkType;

  /// PHY rate in Mbps.
  final int phyRate;

  /// Signal strength in dBm (RSSI). Null for Ethernet backhaul.
  final int? signalStrength;

  /// Uplink data rate in kbps.
  final int? uplinkRate;

  /// Downlink data rate in kbps.
  final int? downlinkRate;

  /// Parent node's device ID (MAC).
  final String? parentNodeId;

  /// Parent node's BSSID the slave connects to.
  final String? parentBssid;

  /// Last contact time in ISO 8601 format.
  final String? lastContactTime;

  /// Raw AL ID from DataElements (parent node MAC).
  final String? backhaulAlId;

  /// Backhaul interface MAC address.
  final String? backhaulMacAddress;

  const BackhaulInfo({
    required this.mediaType,
    this.linkType,
    this.phyRate = 0,
    this.signalStrength,
    this.uplinkRate,
    this.downlinkRate,
    this.parentNodeId,
    this.parentBssid,
    this.lastContactTime,
    this.backhaulAlId,
    this.backhaulMacAddress,
  });

  /// Whether the backhaul is Ethernet (wired).
  bool get isEthernet => linkType == 'Ethernet';

  /// Whether the backhaul is WiFi (wireless).
  bool get isWifi => !isEthernet;

  /// Whether backhaul info is available.
  bool get hasInfo => mediaType.isNotEmpty;

  @override
  List<Object?> get props => [
        mediaType,
        linkType,
        phyRate,
        signalStrength,
        uplinkRate,
        downlinkRate,
        parentNodeId,
        parentBssid,
        lastContactTime,
        backhaulAlId,
        backhaulMacAddress,
      ];

  @override
  String get diagnosticName => 'BackhaulInfo';

  @override
  Map<String, Object?> get namedProps => {
        'mediaType': mediaType,
        'linkType': linkType,
        'phyRate': phyRate,
        'signalStrength': signalStrength,
        'uplinkRate': uplinkRate,
        'downlinkRate': downlinkRate,
        'parentNodeId': parentNodeId,
        'parentBssid': parentBssid,
        'lastContactTime': lastContactTime,
        'backhaulAlId': backhaulAlId,
        'backhaulMacAddress': backhaulMacAddress,
      };
}
