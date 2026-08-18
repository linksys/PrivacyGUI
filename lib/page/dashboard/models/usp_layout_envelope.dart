import 'dart:convert';

/// The persisted form of the USP dashboard layout: one serialised grid per
/// breakpoint, keyed by slot count.
///
/// ## Why the slot count has to be recorded
///
/// [DashboardController.exportLayout] returns coordinates in whatever slot count
/// the controller is on at that moment. The pref used to hold a bare list of
/// those coordinates with no note of which grid produced them, and load always
/// read them back as 12-column values. A save made on a phone therefore came
/// back on a laptop as a 12-column layout of 4-column cards — a third of their
/// width, with `minW`/`maxW` scaled down to match, which made the damage
/// permanent because those caps then blocked any attempt to widen the cards
/// again (#1293).
///
/// ## Compatibility
///
/// A legacy bare list decodes as the [desktopSlotCount] entry — that is what it
/// always was, since load created a 12-slot controller before importing. The
/// other breakpoints are left absent rather than guessed, so the caller can tell
/// "the user arranged this" from "we derived this" and re-derive the second kind
/// whenever the scaling rules change.
class UspLayoutEnvelope {
  /// Slot counts the dashboard renders and persists, matching the ui_kit
  /// breakpoint regimes (`GridLayoutContext.currentMaxColumns`).
  static const int desktopSlotCount = 12;
  static const int tabletSlotCount = 8;
  static const int mobileSlotCount = 4;

  /// Ordered widest-first: the desktop entry is the source the narrower grids
  /// are derived from, so it has to be read and seeded first.
  static const List<int> persistedSlotCounts = [
    desktopSlotCount,
    tabletSlotCount,
    mobileSlotCount,
  ];

  /// Bumped whenever the payload shape changes in a way older builds would
  /// misread. Version 1 is the implicit version of the legacy bare list.
  static const int currentVersion = 2;

  const UspLayoutEnvelope(this.layouts);

  /// Serialised layouts by slot count. Keys outside [persistedSlotCounts] are
  /// preserved on decode so a build that renders fewer breakpoints cannot
  /// silently discard a layout a newer build wrote.
  final Map<int, List<dynamic>> layouts;

  List<dynamic>? operator [](int slotCount) => layouts[slotCount];

  List<int> get slotCounts => layouts.keys.toList();

  /// Returns a copy with [slotCount]'s geometry replaced.
  UspLayoutEnvelope withLayout(int slotCount, List<dynamic> layout) =>
      UspLayoutEnvelope({...layouts, slotCount: layout});

  String encode() => jsonEncode({
        'version': currentVersion,
        'layouts': {
          for (final entry in layouts.entries)
            entry.key.toString(): entry.value,
        },
      });

  /// Parses [raw], or returns null when it cannot be read as layouts on known
  /// grids.
  ///
  /// Null means "fall back to the default layout", so the bar is deliberately
  /// low: anything importable is imported, including ids this build does not
  /// ship (they may be package widgets whose specs load later). What is rejected
  /// is only what cannot be placed at all — a payload from a future version, a
  /// slot count that is not a number, or items that are not maps. Importing
  /// those would either throw inside the grid or render a layout the user never
  /// arranged, and both are worse than starting from the default.
  static UspLayoutEnvelope? tryDecode(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }

    // Legacy: a bare list of 12-column items.
    if (decoded is List) {
      if (!_isItemList(decoded)) return null;
      return UspLayoutEnvelope({desktopSlotCount: decoded});
    }

    if (decoded is! Map) return null;

    final version = decoded['version'];
    if (version is! int || version > currentVersion) return null;

    final rawLayouts = decoded['layouts'];
    if (rawLayouts is! Map) return null;

    final layouts = <int, List<dynamic>>{};
    for (final entry in rawLayouts.entries) {
      final slotCount = int.tryParse('${entry.key}');
      if (slotCount == null || slotCount < 1) return null;
      final layout = entry.value;
      if (layout is! List || !_isItemList(layout)) return null;
      layouts[slotCount] = layout;
    }

    return UspLayoutEnvelope(layouts);
  }

  static bool _isItemList(List<dynamic> layout) =>
      layout.every((item) => item is Map);
}
