import 'package:privacy_gui/generated/data_elements_network.g.dart';

/// The `MultiAPDevice.Backhaul.LinkType` value that means "this node has no
/// backhaul" — i.e. it is the controller.
///
/// prplMesh reports it on the controller row. It is **information, not
/// absence**: a row saying `None` has answered the question, whereas a row with
/// an empty `LinkType` has not. Both mean "no backhaul link" for the purpose of
/// [hasMeshBackhaulLink], but only the former is a positive statement, which is
/// why the two are spelled out separately here rather than collapsed into a
/// single `isEmpty` test.
const meshBackhaulLinkTypeNone = 'none';

/// Whether [node] has a backhaul link of its own — i.e. it is an agent
/// (extender), not the controller (gateway).
///
/// Reads two fields, in this order:
///
/// 1. `MultiAPDevice.Backhaul.BackhaulDeviceID` — non-empty is *positive*
///    evidence of a parent, so it wins outright.
/// 2. `MultiAPDevice.Backhaul.LinkType` — `Ethernet`/`Wi-Fi` means a link,
///    [meshBackhaulLinkTypeNone] and empty both mean none.
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
  final parentId = node.backhaulBackhaulDeviceId?.trim() ?? '';
  if (parentId.isNotEmpty) return true;
  final linkType = node.backhaulLinkType?.trim() ?? '';
  if (linkType.isEmpty) return false;
  return linkType.toLowerCase() != meshBackhaulLinkTypeNone;
}

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
/// made one call the node a dead link and the other grade it on its RSSI. Both
/// now treat "link without medium" as a live link of unknown medium; see
/// `BackhaulInfo.hasInfo` for which field each half reads.
String? meshBackhaulLinkType(MeshNode node) {
  final linkType = node.backhaulLinkType?.trim() ?? '';
  if (linkType.isEmpty) return null;
  if (linkType.toLowerCase() == meshBackhaulLinkTypeNone) return null;
  return linkType;
}

/// Whether [mac] is the all-zero MAC, which prplMesh writes for a backhaul
/// address that does not exist.
///
/// Measured on the bench: `Radio.{i}.BackhaulSta.MACAddress` reads
/// `00:00:00:00:00:00` on a radio with no backhaul station, and every radio of
/// an Ethernet-backhauled node reads it. It is a sentinel, not an address —
/// treating it as one picks a "station MAC" for a node that has none and, in
/// Instant Privacy, writes an allow-list entry that can never match.
///
/// Separator- and case-insensitive on purpose: the two callers hold the value in
/// different spellings (one trims and uppercases, the other runs it through
/// `normalizeMac`), and a sentinel test that only recognises one spelling is the
/// same bug written twice. Empty is *not* unset — absence is a different state
/// and both callers test for it separately.
bool isUnsetMac(String? mac) {
  final hex = mac?.toUpperCase().replaceAll(RegExp('[^0-9A-F]'), '') ?? '';
  return hex.isNotEmpty && RegExp(r'^0+$').hasMatch(hex);
}

/// The Unix epoch, which prplMesh writes into DataElements timestamps that have
/// never been set.
///
/// Measured on the bench: `MultiAPDevice.Backhaul.Stats.TimeStamp` reads
/// `1970-01-01T00:00:00Z` on a node whose stats have not been collected.
/// `DateTime.tryParse` succeeds on it, so a staleness check reads "56 years
/// old" — a confident wrong answer — instead of "no reading".
final _epoch = DateTime.utc(1970);

/// How far from [_epoch] still counts as the sentinel.
///
/// Not slack for its own sake. The generated parser calls `DateTime.tryParse`
/// on firmware's string as-is, so the sentinel arrives in two shapes: with the
/// trailing `Z` it parses to the epoch exactly, and without one it parses as
/// *local* time — landing up to 14 hours either side of it, in 1969 for
/// positive offsets. An exact-equality guard catches the first spelling and
/// silently passes the second straight into staleness logic, which is the bug
/// this helper exists to prevent. Nothing a router legitimately reports lands
/// within a day of the epoch under either reading.
const _epochSlack = Duration(days: 1);

/// [timestamp] unless it is the epoch sentinel, in which case null.
///
/// Apply this to any DataElements timestamp before it reaches staleness or
/// freshness logic. Returning null rather than a boolean keeps the sentinel
/// check at the one place the value enters the app, instead of every place that
/// compares it.
DateTime? nonEpoch(DateTime? timestamp) {
  if (timestamp == null) return null;
  return timestamp.difference(_epoch).abs() < _epochSlack ? null : timestamp;
}
