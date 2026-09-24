import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// How this app grades the edge into a node, from a radio reading.
///
/// ui_kit 3.4.0 stopped deriving strength itself — it used to threshold dBm at
/// -50 and -70 internally, which a general graph has no input for — so the
/// classification is the consumer's. [getWifiSignalLevel] stays the single source
/// of truth for *where* the boundaries sit; this is only the last step, mapping a
/// level onto the four appearances the kit authors.
///
/// It lives in one place because two callers had written it separately and they
/// **disagreed**: the topology builder mapped `good`→`good` and `fair`→`weak`,
/// while the AI section's copy shifted everything a rank brighter
/// (`good`→`strong`, `fair`→`good`). The divergence predates the 3.4.0 migration
/// and survived it because both were renamed rather than reconciled.
///
/// The 1:1 mapping wins, because that is what the rest of the app already does:
/// `wifi_ui.dart` renders `excellent`→"Excellent", `good`→"Good", `fair`→"Fair".
/// A graph edge reading one rank stronger than the label beside it is the kind of
/// disagreement a viewer notices and cannot explain.
EdgeStrength? edgeStrengthFromRssi(int? rssi) {
  if (rssi == null) return EdgeStrength.unknown;
  return edgeStrengthFromLevel(getWifiSignalLevel(rssi));
}

/// The strength for an already-classified [level].
///
/// Exposed beside [edgeStrengthFromRssi] for a caller that has a level in hand
/// rather than a dBm figure.
///
/// Two arms are worth stating rather than reading past:
///
/// - **`poor` maps to `unknown`, not to a fifth grade.** `EdgeStrength` has four
///   members and the kit authors a style per member; a reading too weak to grade
///   and a reading absent both land on the neutral one. That is the behaviour the
///   app shipped before 3.4.0 too.
/// - **`wired` maps to null.** Wiredness is the *kind* axis ([EdgeKind.direct]),
///   which is exactly why 3.4.0 deleted the old `stable` member from the quality
///   enum. A direct edge's strength is never read.
EdgeStrength? edgeStrengthFromLevel(NodeSignalLevel level) {
  return switch (level) {
    NodeSignalLevel.excellent => EdgeStrength.strong,
    NodeSignalLevel.good => EdgeStrength.good,
    NodeSignalLevel.fair => EdgeStrength.weak,
    NodeSignalLevel.poor => EdgeStrength.unknown,
    NodeSignalLevel.none => EdgeStrength.unknown,
    NodeSignalLevel.wired => null,
  };
}
