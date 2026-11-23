/// The [MeshNode] / [DataElementsNetwork] half of the mesh backhaul helpers:
/// the controller / agent discriminator and the parent and medium readers.
/// They read generated types, so they live in `services/` (constitution 5.4.3,
/// #1833); the string helpers they share with views and models stay in
/// `_shared/utils/mesh_backhaul_link.dart`.
library;

import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_node_identity.dart';

/// Whether [node] has a backhaul link of its own — i.e. it is an agent
/// (extender), not the controller (gateway).
///
/// Reads two fields, in this order:
///
/// 1. `MultiAPDevice.Backhaul.BackhaulDeviceID` — a usable parent MAC is
///    *positive* evidence of a parent, so it wins outright. Read through
///    [nonUnsetMac]: this field is a MAC in the same `MultiAPDevice.Backhaul`
///    object as the bench-measured all-zero sentinel (see [isUnsetMac]), and
///    taking `00:00:00:00:00:00` at face value here makes the **controller** an
///    agent whose parent is an address nothing can resolve.
/// 2. `MultiAPDevice.Backhaul.LinkType` — `Ethernet`/`Wi-Fi` means a link,
///    [meshBackhaulLinkTypeNone] and empty both mean none.
///
/// Order is not evaluation order for its own sake: it is what happens when
/// firmware contradicts itself. A row carrying both a parent ID and
/// `LinkType = None` is an agent, because a parent is a thing observed and
/// `None` is a thing asserted.
///
/// Both are absent-tolerant on purpose. Before FL-WRT 2.0 this question was
/// answered by `Device.{i}.BackhaulALID` / `BackhaulMediaType` /
/// `BackhaulPHYRate`, none of which exist in the prplMesh schema (PrivacyGUI
/// #1555) — and the failure mode of getting it wrong is not cosmetic: a
/// controller misread as an agent becomes an orphan node with a parent it can
/// never resolve, and an agent misread as the controller loses its backhaul
/// card entirely.
///
/// `MultiAPDevice.AssocIEEE1905DeviceRef` is deliberately not consulted: it was
/// removed from the definition in usp_framework#57, and even when it existed
/// some firmware (verified on M60TB-EU 1.0.18) left it empty on connected
/// agents. `EasyMeshAgentOperationMode` is unreliable for the same reason.
bool hasMeshBackhaulLink(MeshNode node) {
  if (meshBackhaulParentId(node) != null) return true;
  final linkType = node.backhaulLinkType?.trim() ?? '';
  if (linkType.isEmpty) return false;
  return linkType.toLowerCase() != meshBackhaulLinkTypeNone;
}

/// The key [isMeshController] compares node IDs by, taken from
/// `Device.WiFi.DataElements.Network.ControllerID` ([controllerId]) — or null
/// when that ID cannot decide anything for [network].
///
/// Null when the read failed or returned nothing, when it holds the all-zero
/// sentinel, and when it names no node in [network]: a stale or foreign value
/// must not turn the real controller into an agent. With a null key
/// [isMeshController] falls back to [hasMeshBackhaulLink].
///
/// Computed once per read and handed to [isMeshController] for each node, so
/// the "is it listed" scan is not repeated per node.
String? meshControllerKey(String? controllerId, DataElementsNetwork network) {
  final key = _meshNodeKey(controllerId);
  if (key == null) return null;
  return network.items.any((n) => _meshNodeKey(n.id) == key) ? key : null;
}

/// Whether [node] is the controller (the gateway).
///
/// **The single controller test.** `MeshTopologyBuilder` (which the topology
/// and the PnP wizard both build from) and the diagnostics backhaul check ask
/// it, and they must agree: the two disagreeing is how a node ends up an
/// extender on the topology and the controller in diagnostics, which then
/// skips its backhaul as "the router".
///
/// With [controllerKey] (from [meshControllerKey]) the node with that ID is
/// the controller and every other node is an agent, backhaul evidence or not.
/// Without it the controller is the node with no backhaul link
/// ([hasMeshBackhaulLink]). That fallback builds an agent whose backhaul is not
/// filled in yet — just joined, or re-associating — as a second controller,
/// which is why `ControllerID` decides whenever it can (#1688 review).
bool isMeshController(MeshNode node, String? controllerKey) =>
    controllerKey != null
        ? _meshNodeKey(node.id) == controllerKey
        : !hasMeshBackhaulLink(node);

/// A node or controller ID as [isMeshController] compares it: separators
/// stripped and upper-cased, or null when absent, blank, or the all-zero
/// sentinel. `ControllerID` and `Device.{i}.ID` are separate leaves, so the
/// comparison must not depend on them sharing a spelling.
String? _meshNodeKey(String? id) {
  final mac = nonUnsetMac(id);
  if (mac == null) return null;
  final key = meshNodeMacKey(mac);
  return key.isEmpty ? null : key;
}

/// The node's parent device ID — the controller or upstream agent it is
/// attached to — or null when firmware reported none.
///
/// One reader for `MultiAPDevice.Backhaul.BackhaulDeviceID`, shared by
/// [hasMeshBackhaulLink] and by both consumers that put the value on a model,
/// so the question "does this node have a parent?" cannot be answered one way
/// by the discriminator and another way by the record it builds.
String? meshBackhaulParentId(MeshNode node) =>
    nonUnsetMac(node.backhaulBackhaulDeviceId);

/// The node's backhaul medium as firmware reports it, or null when it reports
/// none.
///
/// Returns the raw `LinkType` string (trimmed) so callers keep firmware's own
/// spelling for display; [meshBackhaulLinkTypeNone] and empty both collapse to
/// null. Classifying that string into wired/wireless is #1464's job, not this
/// helper's — it stays a single source for *whether* there is a medium.
///
/// **This being null does not mean there is no link.** [hasMeshBackhaulLink] can
/// be true while this returns null — a node with a known parent whose `LinkType`
/// firmware left empty — and every consumer has to decide what to do with that
/// node. They must not decide it separately: keying `BackhaulInfo.hasInfo` on
/// the medium while `UnifiedDiagnosticsService` defaulted the medium to Wi-Fi
/// made one call the node a dead link and the other grade it on its RSSI.
///
/// **The null must survive to the view.** Both halves now treat "link without
/// medium" as a live link of *unknown* medium, and both carry the null that far:
/// `BackhaulInfo.linkType` and `MeshBackhaulNodeRecord.linkType` are nullable
/// and the three view sites print `unknown`. An earlier revision of this change
/// defaulted the diagnostics half to `'Wi-Fi'` at the point of reading, and the
/// value went onto the record and into two tiles — so node detail said `unknown`
/// and the diagnostics tile said `Wi-Fi` about the same node in the same
/// session. A sentence here claimed the two agreed while that was shipping,
/// which is the argument for pinning a cross-file invariant with a test
/// (`backhaul_info_test.dart`, `unified_diagnostics_service_test.dart`) rather
/// than a doc comment: prose cannot fail.
String? meshBackhaulLinkType(MeshNode node) {
  final linkType = node.backhaulLinkType?.trim() ?? '';
  if (linkType.isEmpty) return null;
  if (linkType.toLowerCase() == meshBackhaulLinkTypeNone) return null;
  return linkType;
}
