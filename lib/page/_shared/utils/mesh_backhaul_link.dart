/// The string helpers for `MultiAPDevice.Backhaul` values: link type, MAC and
/// timestamp sentinels. No generated types, so views and models may call them.
/// The functions that read a `MeshNode` or `DataElementsNetwork` are in
/// `_shared/services/mesh_node_backhaul.dart` (#1833).
library;

/// The `MultiAPDevice.Backhaul.LinkType` value that means "this node has no
/// backhaul" — i.e. it is the controller.
///
/// prplMesh reports it on the controller row. It is **information, not
/// absence**: a row saying `None` has answered the question, whereas a row with
/// an empty `LinkType` has not. Both mean "no backhaul link" for the purpose of
/// `hasMeshBackhaulLink`, but only the former is a positive statement, which is
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
