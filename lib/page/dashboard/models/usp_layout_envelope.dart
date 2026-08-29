import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';

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
///
/// A v3 payload's card-form picks are folded onto the items they describe on
/// decode — see [migratedPicks].
///
/// ## Value equality
///
/// Required of models by constitution §11.1, and here it buys exactly one thing:
/// "these bytes round-trip" becomes a single assertion over the whole payload
/// instead of a walk over `slotCounts` and each slot's list separately — a walk
/// that reads as coverage while omitting whichever slot count was added last. It
/// is *not* load-bearing for rebuilds the way [CardForms]'s is: no provider holds
/// an envelope, and both of its uses (encode at save, decode at load) are
/// transient. Kept because the thing it compares is a nested collection, which
/// identity would not compare usefully.
class UspLayoutEnvelope extends Equatable {
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
  /// Version 3 added the geometry a popup or compact pick implies, alongside a
  /// `forms` map naming the pick. Version 4 moves that pick onto the item it
  /// describes, in its `extra` payload (#1400), and drops the map.
  ///
  /// Both are bumps rather than additive fields because [tryDecode] rejects
  /// anything newer than it understands, and either payload read by the build
  /// before it renders geometry whose `isResizable` and raised `minW` it has no
  /// rule for — a card with no handles and no way to explain why. Falling back to
  /// the default layout is the better failure. v4 in particular would leave a v3
  /// build re-deriving that geometry from a `forms` map that is no longer there,
  /// i.e. undoing the pick while keeping the shape it justified.
  static const int currentVersion = 4;

  /// The version a payload carrying no *shaping* pick is still readable as — see
  /// [version] for why an explicit `normal` is not one.
  static const int versionWithoutForms = 2;

  const UspLayoutEnvelope(this.layouts, {this.migratedPicks = false});

  /// Serialised layouts by slot count. Keys outside [persistedSlotCounts] are
  /// preserved on decode so a build that renders fewer breakpoints cannot
  /// silently discard a layout a newer build wrote.
  ///
  /// Each item may carry a card-form pick under `extra` (#1400) — see
  /// [CardFormChoice.readFrom].
  final Map<int, List<dynamic>> layouts;

  /// Whether [tryDecode] moved a v3 `forms` map onto the items it described.
  ///
  /// The one-time migration #1400 owes an install that picked a form before the
  /// pick lived on the item. Folding the map in is all this class can do; the
  /// geometry has to be re-derived by the caller, because in v3 the stored
  /// geometry was never authoritative — it was recomputed from the `forms` map on
  /// every import — so trusting the bytes here would trust something the build
  /// that wrote them did not. See `UspSliverDashboardControllerNotifier`, which
  /// re-derives it once through [UspWidgetSpecs.applyPickedForms] and saves the
  /// result, and so pays for the migration once rather than on every load.
  ///
  /// Deliberately outside [props]: it describes where these layouts came from
  /// rather than what they are, and [encode] does not write it — so including it
  /// would make a migrated envelope unequal to the one its own bytes decode back
  /// to, which is the single assertion value equality exists here for.
  final bool migratedPicks;

  @override
  List<Object?> get props => [layouts];

  List<dynamic>? operator [](int slotCount) => layouts[slotCount];

  List<int> get slotCounts => layouts.keys.toList();

  /// Returns a copy with [slotCount]'s geometry replaced.
  ///
  /// Both copiers carry [migratedPicks] across. Rewriting a layout does not
  /// change where it came from, and the one caller of [mapLayouts] *is* the
  /// migration — an envelope that reported `false` there would leave the flag
  /// readable only off the object the transform was applied to, which is a trap
  /// for the next reader who quite reasonably asks the result.
  UspLayoutEnvelope withLayout(int slotCount, List<dynamic> layout) =>
      UspLayoutEnvelope({...layouts, slotCount: layout},
          migratedPicks: migratedPicks);

  /// Returns a copy with every layout replaced by [transform]'s result for it.
  ///
  /// The slot count is passed because every rule that rewrites a stored grid is a
  /// rule about how wide that grid is; a transform that did not get told would
  /// have to guess, and the guess that was wrong is #1293.
  UspLayoutEnvelope mapLayouts(
    List<dynamic> Function(int slotCount, List<dynamic> layout) transform,
  ) =>
      UspLayoutEnvelope({
        for (final entry in layouts.entries)
          entry.key: transform(entry.key, entry.value),
      }, migratedPicks: migratedPicks);

  /// The version this payload has to be stamped with.
  ///
  /// A stamp is a claim about what an older build would do with these bytes, so
  /// it belongs to the payload rather than to the build that wrote it. What v3
  /// and v4 both added that an older build cannot explain is the geometry a
  /// *shaping* pick writes — `isResizable: false`, a raised `minW` — so the stamp
  /// rises with the first popup or compact pick, which is exactly when an older
  /// build would start drawing cards with no handles and no rule for them.
  ///
  /// The test is "is any pick a shaping one" rather than "are there picks at
  /// all", because returning a card to normal is how the user *undoes* a form and
  /// it writes the spec's own bounds back — bytes a v2 build reads correctly.
  /// Keying the stamp on the mere presence of a pick pinned the payload above v2
  /// for the rest of the install's life the moment anyone tried popup once, which
  /// is the opposite of what this getter exists to do.
  ///
  /// That is what keeps a rollback to a pre-#1299 build cheap for everyone whose
  /// cards are all in their normal form, whether they never opened the control or
  /// tried it and changed their mind: [tryDecode] there rejects anything newer
  /// than it knows, and a rejection resets the dashboard they arranged. The picks
  /// themselves ride along either way, since an older build reading a v2-stamped
  /// payload ignores an `extra` key it has no field for, while this one needs it
  /// to keep honouring an explicit normal.
  int get version =>
      _hasFormBeyondNormal ? currentVersion : versionWithoutForms;

  /// Whether any pick in [layouts] implies geometry a build with no card-form
  /// rule has no explanation for.
  ///
  /// Only [CardDensity.popup] and [CardDensity.compact] do. An explicit
  /// [CardDensity.normal] pins the card against the width-derived form, but the
  /// geometry it writes — the spec's own bounds, `isResizable` back on — is
  /// exactly what a pre-#1299 build writes for itself, so a payload whose only
  /// picks are normal is still readable as one of those.
  ///
  /// Reads an item defensively rather than casting it, because [version] is on
  /// the *encode* path: it runs inside `_writeLayout`, behind the persistence
  /// queue, where a throw is logged and swallowed — so one non-map entry would
  /// quietly stop the dashboard saving for the rest of the session. [tryDecode]
  /// validates through `_isItemList` for the same reason, and only what it built
  /// is guaranteed to hold maps.
  bool get _hasFormBeyondNormal =>
      layouts.values.any((layout) => layout.any((item) =>
          switch (item is Map ? CardFormChoice.readFrom(item['extra']) : null) {
            null => false,
            final choice => choice.density != CardDensity.normal,
          }));

  String encode() => jsonEncode({
        'version': version,
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
    } catch (e) {
      return _reject('not JSON: $e');
    }

    // Legacy: a bare list of 12-column items.
    if (decoded is List) {
      if (!_isItemList(decoded)) {
        return _reject('legacy bare list holds a non-map item');
      }
      return UspLayoutEnvelope({desktopSlotCount: decoded});
    }

    if (decoded is! Map) {
      return _reject('top level is ${decoded.runtimeType}, not a map or list');
    }

    final version = decoded['version'];
    if (version is! int || version > currentVersion) {
      return _reject('version $version is not an int in 1..$currentVersion');
    }

    final rawLayouts = decoded['layouts'];
    if (rawLayouts is! Map) {
      return _reject('"layouts" is ${rawLayouts.runtimeType}, not a map');
    }

    final layouts = <int, List<dynamic>>{};
    for (final entry in rawLayouts.entries) {
      final slotCount = int.tryParse('${entry.key}');
      if (slotCount == null || slotCount < 1) {
        return _reject('slot count "${entry.key}" is not a positive integer');
      }
      final layout = entry.value;
      if (layout is! List || !_isItemList(layout)) {
        return _reject('layout at slot count $slotCount is not a list of maps');
      }
      layouts[slotCount] = layout;
    }

    // Absent for every payload written before v3 and after it (#1400), where the
    // pick rides on the item. Present only in the v3 window, and then it is the
    // authority — see [_foldLegacyPicks].
    final folded = _foldLegacyPicks(layouts, decoded['forms']);
    return UspLayoutEnvelope(
      folded ?? layouts,
      migratedPicks: folded != null,
    );
  }

  /// [layouts] with a v3 `forms` map written onto the items it describes, or null
  /// when there was nothing to move.
  ///
  /// Null rather than "the same layouts" so the caller can tell a migration from
  /// a no-op and only pay for it once. A `forms` key that is unreadable, empty, or
  /// names cards and grids this payload does not hold counts as nothing to move:
  /// there is no item to write the pick onto, so the alternative to dropping it is
  /// keeping the sibling map #1400 exists to delete.
  ///
  /// Every pick a v3 install could have made does have an item here, because a
  /// pick is made on the grid on screen and any save writes that grid. Even so the
  /// count of what was placed is logged against the count that was read, because
  /// this runs once per install and a silent shortfall would be invisible
  /// afterwards.
  static Map<int, List<dynamic>>? _foldLegacyPicks(
    Map<int, List<dynamic>> layouts,
    Object? rawForms,
  ) {
    if (rawForms is! Map || rawForms.isEmpty) return null;

    var placed = 0;
    final folded = <int, List<dynamic>>{};

    for (final entry in layouts.entries) {
      final choices = rawForms['${entry.key}'];
      if (choices is! Map || choices.isEmpty) continue;

      folded[entry.key] = entry.value.map((item) {
        final id = '${(item as Map)['id']}';
        final choice = CardFormChoice.tryFromJson(choices[id]);
        if (choice == null) return item;
        placed++;
        return {
          ...item.cast<String, dynamic>(),
          'extra': choice.writeInto(item['extra']),
        };
      }).toList();
    }

    if (placed == 0) return null;

    // Counted over the whole `forms` map rather than per grid, so the shortfall
    // includes picks filed under a slot count this payload has no layout for —
    // they have no item to land on anywhere.
    final offered = rawForms.values
        .fold(0, (sum, choices) => sum + (choices is Map ? choices.length : 0));
    if (placed < offered) {
      logger.w('[USP][Layout]: migrated $placed of $offered v3 card-form picks '
          'onto their items; the rest named a card or a grid this payload does '
          'not hold');
    }

    return {...layouts, ...folded};
  }

  /// Logs why [tryDecode] is giving up, then returns null for it to hand back.
  ///
  /// The caller can only report *that* the payload was unreadable — it receives
  /// a bare null — so without this the seven rejection paths above are
  /// indistinguishable in the field. That matters more here than the usual
  /// "log the exception" habit: a rejection silently discards the layout the
  /// user arranged and reseeds the default, so the reason is the only evidence
  /// left of what they lost. Which is also why it goes through `logger.w` and not
  /// `debugPrint` — the latter compiles out of a release build, i.e. out of every
  /// build a user could hit this in.
  static UspLayoutEnvelope? _reject(String reason) {
    logger.w('[USP][Layout]: tryDecode rejected the payload — $reason');
    return null;
  }

  static bool _isItemList(List<dynamic> layout) =>
      layout.every((item) => item is Map);
}
