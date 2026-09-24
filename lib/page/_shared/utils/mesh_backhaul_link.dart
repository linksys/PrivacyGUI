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

/// The `MultiAPDevice.Backhaul.LinkType` value that means "wired".
///
/// Lower-case because it is only ever compared through
/// [isMeshBackhaulEthernet], which case-folds. Firmware spells it `Ethernet`
/// today (the TR-181 enum spelling, and the same casing convention that gives
/// us `None`), so this is not compatibility with an observed build — it is the
/// rule already applied to [meshBackhaulLinkTypeNone], applied to the other
/// value of the same field instead of only to one of them.
const meshBackhaulLinkTypeEthernet = 'ethernet';

/// Whether [linkType] names a wired backhaul.
///
/// **The single medium test.** Four sites used to spell it `linkType ==
/// 'Ethernet'` (`BackhaulInfo.isEthernet`, `MeshNodeBackhaulUIModel.isWired`,
/// `UnifiedDiagnosticsService`'s `wired`, `node_detail_popup.dart`), so a build
/// spelling the value any other way would have classified a wired node as
/// wireless at all four at once — grading it on an RSSI it does not have and
/// drawing it a signal indicator. Case-folded and trimmed for the reason stated
/// on [isUnsetMac]: a value test that recognises one spelling is the same bug
/// written four times.
bool isMeshBackhaulEthernet(String? linkType) =>
    linkType?.trim().toLowerCase() == meshBackhaulLinkTypeEthernet;

/// Whether [linkType] names a medium at all, as opposed to saying there is none.
///
/// **The single "is there a medium" test**, and the companion to
/// [isMeshBackhaulEthernet]: that one answers *which* medium, this one answers
/// *whether*. Both are needed because `LinkType` has three states, not two —
/// a medium, the literal `None` (prplMesh's positive statement on the controller
/// row), and absent.
///
/// Written once because it was written twice and the two copies disagreed. Two
/// readers of the same field added in one commit — the tree subtitle and the detail
/// panel — spelled this differently, and the panel's version let `None` through to
/// be classified by [isMeshBackhaulEthernet], which answers `false` for it and so
/// drew `Wi-Fi` for a node that had just said it has no backhaul.
///
/// Case-folded and trimmed for the same reason [isMeshBackhaulEthernet] is: a value
/// test that recognises one spelling is the same bug written once per caller.
bool hasNamedMeshBackhaulMedium(String? linkType) {
  final normalised = linkType?.trim().toLowerCase() ?? '';
  return normalised.isNotEmpty && normalised != meshBackhaulLinkTypeNone;
}

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

/// [value] unless firmware left the field empty, in which case null.
///
/// The third of this file's absence sentinels, and the dullest: a DataElements
/// string leaf that has never been set arrives as `""` or as whitespace, not as
/// a missing key, so `??` on the raw value hands the empty string straight
/// through to a caller that asked for a fallback. Trims first because
/// `ManufacturerModel` and `BackhaulDeviceID` have both been observed padded.
///
/// Named for symmetry with [nonEpoch] and read the same way: "the value, unless
/// it is the sentinel".
///
/// `MeshNetworkBuilder` now uses this for its four identity merge chains, and an
/// earlier revision of this comment gave the opposite reason for keeping its
/// private non-trimming copy: that a whitespace-only value "has to keep losing
/// to a real value from another source". It is the other way round — in
/// `_nonEmpty(systemInfo?.model) ?? _nonEmpty(meshInfo?.model) ?? ''` an
/// untrimmed `' '` is non-empty, so it **wins** the `??` and lands whitespace in
/// `MasterNode.model` while the real value is never consulted. Trimming is what
/// makes the documented intent true. What survives of that copy is
/// `_nonEmptyRaw`, kept for the SSID chain only, where whitespace is part of
/// the value.
String? nonEmpty(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// [mac] unless it is absent, empty, or the all-zero sentinel — then null.
///
/// [nonEmpty] and [isUnsetMac] composed, because a MAC read off this subtree has
/// two ways of not being there and every site that reads one wants both. Three
/// sites did it by hand in different orders before this existed: the parent
/// device ID, the parent BSSID and the bSTA MAC.
String? nonUnsetMac(String? mac) {
  final value = nonEmpty(mac);
  return isUnsetMac(value) ? null : value;
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
///
/// **The measured field is not the guarded one.** `Backhaul.Stats.TimeStamp` has
/// no consumer in `lib/` — [nonEpoch]'s two call sites are both on
/// `MultiAPDevice.LastContactTime`, the timestamp that actually reaches
/// staleness logic. `LastContactTime` is guarded pre-emptively, on the grounds
/// that the same firmware writes both and only one of them is read today; the
/// bench reading above is why the sentinel is known to exist at all, not
/// evidence about the field being guarded.
final _epoch = DateTime.utc(1970);

/// How far from [_epoch] still counts as the sentinel.
///
/// Not slack for its own sake. The generated parser calls `DateTime.tryParse`
/// on firmware's string as-is, so the sentinel has two possible shapes: with the
/// trailing `Z` it parses to the epoch exactly, and without one it parses as
/// *local* time — landing up to 14 hours either side of it, in 1969 for positive
/// offsets. An exact-equality guard catches the first spelling and silently
/// passes the second straight into staleness logic, which is the bug this
/// helper exists to prevent.
///
/// Only the `Z` spelling has been observed on the bench; the zone-less one is
/// covered because tolerating it costs a constant, not because a build was seen
/// emitting it. 24 hours is that 14-hour worst case rounded up to a whole day —
/// nothing a router legitimately reports lands within a day of the epoch under
/// either reading, so there is no gain in being tighter.
///
/// Note that the window makes the *sentinel* robust, not the timestamp: a
/// zone-less real reading is still off by the local UTC offset by the time it
/// reaches us, and no app-side helper can recover that — the wall-clock digits
/// have to be re-read as UTC where they are parsed, which is generated code.
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
