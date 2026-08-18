import 'dart:convert';

import 'package:privacy_gui/page/dashboard/models/card_form_choice.dart';

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
  ///
  /// Version 3 adds the geometry a popup or compact pick implies. It is a bump
  /// rather than an additive field because [tryDecode] rejects anything newer
  /// than it understands, and a v2 build reading a v3 payload would render
  /// geometry whose `isResizable` and raised `minW` it has no rule for — a card
  /// with no handles and no way to explain why. Falling back to the default
  /// layout is the better failure.
  static const int currentVersion = 3;

  /// The version a payload carrying no *shaping* pick is still readable as — see
  /// [version] for why an explicit `normal` is not one.
  static const int versionWithoutForms = 2;

  const UspLayoutEnvelope(this.layouts, {this.forms = CardForms.empty});

  /// Serialised layouts by slot count. Keys outside [persistedSlotCounts] are
  /// preserved on decode so a build that renders fewer breakpoints cannot
  /// silently discard a layout a newer build wrote.
  final Map<int, List<dynamic>> layouts;

  /// The density each card was picked into, per breakpoint (#1299).
  ///
  /// Stored beside the geometry rather than in a pref of its own, and keyed by
  /// the same slot counts, because the geometry it implies — `isResizable`,
  /// `minW`, `minH` — is re-derived from it on every import. A pick in one file
  /// and the sizes it justifies in another is how the two drift apart; and a pick
  /// that was *not* keyed by breakpoint would repeat #1293 exactly, since
  /// "compact on a phone, normal on a laptop" is the case this exists for.
  final CardForms forms;

  List<dynamic>? operator [](int slotCount) => layouts[slotCount];

  List<int> get slotCounts => layouts.keys.toList();

  /// Returns a copy with [slotCount]'s geometry replaced.
  UspLayoutEnvelope withLayout(int slotCount, List<dynamic> layout) =>
      UspLayoutEnvelope({...layouts, slotCount: layout}, forms: forms);

  /// The version this payload has to be stamped with.
  ///
  /// A stamp is a claim about what an older build would do with these bytes, so
  /// it belongs to the payload rather than to the build that wrote it. What v3
  /// added that an older build cannot explain is the geometry a *shaping* pick
  /// writes — `isResizable: false`, a raised `minW` — so the stamp rises with the
  /// first popup or compact pick, which is exactly when an older build would
  /// start drawing cards with no handles and no rule for them.
  ///
  /// The test is [CardForms.hasFormBeyondNormal] rather than "are there picks at
  /// all", because returning a card to normal is how the user *undoes* a form and
  /// it writes the spec's own bounds back — bytes a v2 build reads correctly.
  /// Keying the stamp on the mere presence of a pick pinned the payload at v3 for
  /// the rest of the install's life the moment anyone tried popup once, which is
  /// the opposite of what this getter exists to do.
  ///
  /// That is what keeps a rollback to a pre-#1299 build cheap for everyone whose
  /// cards are all in their normal form, whether they never opened the control or
  /// tried it and changed their mind: [tryDecode] there rejects anything newer
  /// than it knows, and a rejection resets the dashboard they arranged. The picks
  /// themselves are still written either way — [encode] keys that on
  /// [CardForms.isNotEmpty] — since an older build simply ignores the key, while
  /// this one needs it to keep honouring an explicit normal.
  int get version =>
      forms.hasFormBeyondNormal ? currentVersion : versionWithoutForms;

  String encode() => jsonEncode({
        'version': version,
        'layouts': {
          for (final entry in layouts.entries)
            entry.key.toString(): entry.value,
        },
        // Omitted when nobody has picked a form, so an install that never used
        // the control writes the same bytes it wrote before #1299.
        if (forms.isNotEmpty) 'forms': forms.toJson(),
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

    // Absent for every payload written before v3, which decodes as "nobody has
    // picked a form" — the state every install is already in.
    return UspLayoutEnvelope(
      layouts,
      forms: CardForms.fromJson(decoded['forms']),
    );
  }

  static bool _isItemList(List<dynamic> layout) =>
      layout.every((item) => item is Map);
}
