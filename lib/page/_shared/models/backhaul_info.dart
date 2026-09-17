import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';

/// Backhaul connection info for slave mesh nodes.
///
/// Describes how a slave node connects to its parent (WiFi or Ethernet).
class BackhaulInfo with EquatableMixin, DiagnosticNamed {
  /// Link type: "Wi-Fi" or "Ethernet". Null when firmware reports no backhaul
  /// medium — either because it reported `None` or because it reported nothing.
  ///
  /// This is the **only** medium field. `BackhaulMediaType` (e.g.
  /// "IEEE 802.11ax") and `BackhaulPHYRate` used to sit alongside it, sourced
  /// from `Device.{i}.Backhaul*`, which the prplMesh schema does not define
  /// (#1555). Neither has a replacement, so there is no longer a second field
  /// that can disagree with this one.
  final String? linkType;

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

  /// The node's own station-side backhaul MAC — the address its parent's AP
  /// sees, and the one MAC filtering is checked against.
  ///
  /// Sourced from `Radio.{i}.BackhaulSta.MACAddress` since #1555; the
  /// `Device.{i}.BackhaulMACAddress` it used to come from is not in the
  /// prplMesh schema. Null when the node has no wireless backhaul station.
  final String? backhaulMacAddress;

  const BackhaulInfo({
    this.linkType,
    this.signalStrength,
    this.uplinkRate,
    this.downlinkRate,
    this.parentNodeId,
    this.parentBssid,
    this.lastContactTime,
    this.backhaulMacAddress,
  });

  /// A node that is in the topology but reports no backhaul medium.
  ///
  /// Named rather than spelled `BackhaulInfo()` at each site so the state reads
  /// as deliberate: it is a legitimate result (see [hasInfo]), not a
  /// placeholder someone forgot to fill in.
  static const none = BackhaulInfo();

  /// Whether the backhaul is Ethernet (wired).
  ///
  /// Routed through the shared predicate so this, `MeshNodeBackhaulUIModel`'s
  /// `isWired`, the diagnostics grader and the topology popup all read the field
  /// the same way — four hand-written `== 'Ethernet'` comparisons would misread
  /// the same spelling in the same direction at the same time.
  bool get isEthernet => isMeshBackhaulEthernet(linkType);

  /// Whether the backhaul is WiFi (wireless).
  ///
  /// Requires actual backhaul data ([hasInfo]): an absent backhaul is neither
  /// Ethernet nor WiFi, so it must not be reported as wireless. Without the
  /// [hasInfo] guard `!isEthernet` treats a null [linkType] as WiFi and
  /// fabricates a wireless backhaul for a node we have no backhaul data for
  /// (#1430).
  ///
  /// True for a link whose medium firmware left empty, because that is a link
  /// and it is not Ethernet. [linkType] stays null there, so the interface tile
  /// renders `unknown` rather than claiming a medium — see [hasInfo].
  bool get isWifi => hasInfo && !isEthernet;

  /// Whether this node has a backhaul link at all.
  ///
  /// **"There is a link", not "firmware named its medium".** The distinction is
  /// the bug this getter was rewritten to close (#1555): keying on [linkType]
  /// alone made a node with a known parent and an empty `LinkType` read as
  /// having *no* backhaul, so `usp_topology_builder` painted it 0.0 — a dead
  /// link — while `UnifiedDiagnosticsService`, which defaults the same node's
  /// medium to Wi-Fi, graded it on its RSSI. Same node, same fields, two
  /// answers; exactly the class of disagreement `hasMeshBackhaulLink` exists to
  /// prevent one layer up, leaking back in through the medium.
  ///
  /// So this keys on the same evidence the controller/agent discriminator does:
  /// a medium, **or** a parent. Both are fields firmware produces
  /// (`MultiAPDevice.Backhaul.LinkType` and `.BackhaulDeviceID`), which is what
  /// AC3 asks for, and neither is the deleted `mediaType`.
  ///
  /// It used to key on `mediaType` while [isEthernet] keyed on [linkType], which
  /// made "Ethernet with no medium" representable and let *those* two disagree —
  /// the state `usp_topology_builder` had to order its arms around. That one is
  /// gone for good: [isEthernet] and the medium half of this getter now read the
  /// same field.
  bool get hasInfo =>
      (linkType != null && linkType!.isNotEmpty) ||
      (parentNodeId != null && parentNodeId!.isNotEmpty);

  @override
  List<Object?> get props => [
        linkType,
        signalStrength,
        uplinkRate,
        downlinkRate,
        parentNodeId,
        parentBssid,
        lastContactTime,
        backhaulMacAddress,
      ];

  @override
  String get diagnosticName => 'BackhaulInfo';

  @override
  Map<String, Object?> get namedProps => {
        'linkType': linkType,
        'signalStrength': signalStrength,
        'uplinkRate': uplinkRate,
        'downlinkRate': downlinkRate,
        'parentNodeId': parentNodeId,
        'parentBssid': parentBssid,
        'lastContactTime': lastContactTime,
        'backhaulMacAddress': backhaulMacAddress,
      };
}
