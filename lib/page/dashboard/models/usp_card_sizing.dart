import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_spec_registry.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

/// How big a card may be on a given grid: the arithmetic that brings a spec's
/// 12-column figures to the grid in front of the user, and the sizes a picked
/// card form makes legal there (#1299, #1400).
///
/// The two halves share a file because they call each other — [scaleLayout]
/// applies [applyPickedForms], and the form helpers scale through
/// `_scaleFromTwelfths` — so splitting them would turn one change into a
/// two-file change and make that helper public (#1311). Call sites read these
/// through `UspWidgetSpecs`, which forwards every public member.
abstract class UspCardSizing {
  UspCardSizing._();

  // ---------------------------------------------------------------------------
  // Layout Scaling
  // ---------------------------------------------------------------------------

  /// Converts a column span from a [fromCols]-wide grid to a [toCols]-wide one,
  /// never returning less than one column or more than the grid holds.
  ///
  /// Every column figure in a [WidgetSpec] is written for the 12-column grid, so
  /// anything comparing a live item against its spec has to bring the spec to the
  /// grid the item is actually on: read literally, `stats_panel`'s
  /// `minColumns: 6` would demand three quarters of an 8-column row, and more
  /// columns than a 4-column grid even has.
  static int scaleSpan(
    int span, {
    required int fromCols,
    required int toCols,
  }) =>
      (span * toCols / fromCols).round().clamp(1, toCols);

  /// [scaleSpan] from the 12-column grid every spec column figure is written for.
  ///
  /// Every caller inside this file scales *from* twelfths — that is what a
  /// [WidgetGridConstraints] column figure is — so `fromCols` was the same
  /// constant at all five sites and never once a variable. Only [scaleLayout]
  /// scales between two grids it is told about, and it keeps the general call.
  ///
  /// Named for the direction rather than made a default on [scaleSpan], so the day
  /// a figure is written against some other grid the compiler makes whoever wrote
  /// it say which one.
  static int _scaleFromTwelfths(int span, {required int toCols}) => scaleSpan(
        span,
        fromCols: UspLayoutEnvelope.desktopSlotCount,
        toCols: toCols,
      );

  /// The size a card has to be corrected to on a [slotCount]-wide grid, or null
  /// when the size it already has is allowed.
  ///
  /// The arithmetic lives here rather than in the resize handler because the
  /// grid-dependent part is the whole point: the column figures in
  /// [WidgetGridConstraints] describe the 12-column grid and mean nothing until
  /// [scaleSpan] brings them to the grid in front of the user. Row counts are
  /// absolute — a row is the same height on every grid — so they are compared
  /// as they are.
  ///
  /// Mobile widths are left alone rather than scaled: there the width is pinned
  /// by [lockToFullWidth], so a resize cannot have changed it and "correcting"
  /// it could only fight the lock.
  static ({int w, int h})? correctedSize(
    WidgetGridConstraints constraints, {
    required int w,
    required int h,
    required int slotCount,
  }) {
    var newW = w;
    var newH = h;

    if (slotCount > UspLayoutEnvelope.mobileSlotCount) {
      final minColumns =
          _scaleFromTwelfths(constraints.minColumns, toCols: slotCount);
      final maxColumns =
          _scaleFromTwelfths(constraints.maxColumns, toCols: slotCount);
      // Sequential rather than clamp(). WidgetGridConstraints asserts
      // min <= max, but a package widget's constraints are parsed from a remote
      // template and asserts are gone in release, so the one build where a bad
      // template could arrive is the one where clamp() would throw — inside a
      // gesture handler. Narrowing to the ceiling is the better failure.
      if (newW < minColumns) newW = minColumns;
      if (newW > maxColumns) newW = maxColumns;
    }

    if (newH < constraints.minHeightRows) newH = constraints.minHeightRows;
    if (newH > constraints.maxHeightRows) newH = constraints.maxHeightRows;

    if (newW == w && newH == h) return null;
    return (w: newW, h: newH);
  }

  /// Proportionally scales a serialised layout from [fromCols] to [toCols].
  ///
  /// * Tablet (12→8): `w=6` → `w=4`, preserving two-column pairs.
  /// * Mobile (12→4): delegates to [lockToFullWidth] — see there for why the
  ///   width stops being the user's to choose at all.
  /// * Constraints (minW / maxW) are scaled with the widths.
  /// * A card carrying a form pick gets the geometry that pick implies at
  ///   [toCols], not a scaled copy of the geometry it implied at [fromCols] —
  ///   see [applyPickedForms].
  ///
  /// That last step is why this is the seam #1400 moved the derivation to. A
  /// scale is proportional and a pin is not: [popupColumns] is two columns of
  /// however many there are, so scaling a pinned tile 12 → 8 gives it one, and
  /// scaling one 12 → 4 gives it nothing to be full-width *of*. Both are cases the
  /// user never chose and never would.
  static List<LayoutItem> scaleLayout(
    List<LayoutItem> layout,
    int fromCols,
    int toCols,
  ) {
    if (toCols <= UspLayoutEnvelope.mobileSlotCount) {
      // Forms first, then the lock, in the order [_applyCardForm] documents: the
      // two rules split the axes and the lock has the last word on the width.
      return lockToFullWidth(applyPickedForms(layout, toCols), toCols);
    }

    final scaled = layout.map((item) {
      // An unbounded cap scales to the whole target grid. Reading it off the
      // typed field is the #1310 fix for the trap this line used to hold: the
      // map form was `(map['maxW'] as num?)?.toInt() ?? fromCols`, which was
      // correct only because `toMap()` writes an infinite bound as `null` for
      // JSON validity. Handed a map that had not been through `toMap()` — which
      // `addWidget` did, with a spec declaring no constraints — the `as num?`
      // matched the `double.infinity` and `toInt()` threw `Unsupported
      // operation: Infinity or NaN toInt`. `isFinite` asks the question the
      // `??` was standing in for.
      final maxW = item.maxW.isFinite ? item.maxW.toInt() : fromCols;

      // Proportional scaling
      var newW = scaleSpan(item.w, fromCols: fromCols, toCols: toCols);
      var newX = (item.x * toCols / fromCols).round();
      if (newX + newW > toCols) newX = toCols - newW;
      if (newX < 0) {
        newX = 0;
        newW = toCols;
      }

      final newMinW = scaleSpan(item.minW, fromCols: fromCols, toCols: toCols);
      final newMaxW = scaleSpan(maxW, fromCols: fromCols, toCols: toCols)
          .clamp(newMinW, toCols);

      return item.copyWith(
        x: newX,
        w: newW,
        minW: newMinW,
        maxW: newMaxW.toDouble(),
      );
    }).toList();

    return applyPickedForms(scaled, toCols);
  }

  /// Pins every item in [layout] to the full width of a [cols]-wide grid.
  ///
  /// Below five columns there is no width worth choosing — every card is either
  /// full-width or unreadably narrow — so on mobile the width stops being
  /// editable instead of being merely defaulted. `minW == maxW == cols` is the
  /// whole of what enforces that, as of `sliver_dashboard` 2.6.0 (#1399): the
  /// resolver clamps the new width to `[minW, maxW]` *and then* clamps `x` into
  /// `[originalRight - maxW, originalRight - minW]`
  /// (`dashboard_controller_impl.dart:1932-1946` at 2.7.0; the same block was
  /// `:1828-1842` at 2.6.0 and is byte-identical between the two), which for a
  /// card pinned at both caps is the single value it already has. The left-hand
  /// handles are held by the second clamp and the right-hand ones by the first.
  ///
  /// 0.9.1 had only the first, so the left-hand handles moved `x` and the package
  /// trimmed the width to what was left of the row — `x: 1, w: 3` dragged inwards
  /// and `x: 0, w: 3` dragged outwards, on a grid where neither width was
  /// authorised. That is why this used to be backed by a watcher writing the live
  /// layout back; the watcher is gone, and `edit_mode_interactions_test.dart`
  /// samples every frame of a left-edge drag, its bottom-left diagonal and an
  /// arrow-key move to show the geometry is now never produced rather than
  /// corrected afterwards.
  ///
  /// Only the inward end of that second clamp is ours, which is worth knowing
  /// before reading those tests: its lower bound is
  /// `max(limitX, originalRight - maxW)`, and `limitX` is already 0 for a card at
  /// the left edge, so a card cannot be dragged out of the row whatever the caps
  /// say. `minW` is what stops it being dragged *in*.
  ///
  /// Rewriting both caps rather than only lowering `maxW` also repairs what a
  /// projection from a wider grid produces, in both directions. Scaling
  /// proportionally gave a card with `maxW: 8` at 12 columns a `maxW` of 3 at 4
  /// columns while its width was set to 4 — a width outside its own cap, which the
  /// first resize would have snapped down to 3 of 4 columns. And a spec that
  /// declares `minW: 6` for the desktop grid arrives with a floor wider than the
  /// whole phone grid, which is not a mis-size but a crash: the engine asserts
  /// `currentL.minW <= cols` (`layout_engine.dart:963`) while the page is
  /// building.
  static List<LayoutItem> lockToFullWidth(List<LayoutItem> layout, int cols) {
    return layout
        .map((item) => item.copyWith(
              x: 0,
              w: cols,
              minW: cols,
              maxW: cols.toDouble(),
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Card Forms (#1299) — the chosen density decides which sizes are legal, and
  // the choice rides on the item it shaped (#1400)
  // ---------------------------------------------------------------------------

  /// Cards that offer no [CardDensity.popup] entry.
  ///
  /// popup is central, not per card: [DashboardCardTemplate] renders
  /// [CardPopupForm] whenever the scope says popup, and its `value` falls back to
  /// the card title, so forcing popup renders on every card built through the
  /// template. `stats_panel` is the one registered card that is not — see the
  /// `'stats_panel' => UspStatsPanel()` arm of `UspWidgetFactory._buildCard` — so
  /// it has no popup path to force and its entry would be a control that visibly
  /// does nothing.
  static const Set<String> cardsWithoutPopupForm = {'stats_panel'};

  /// The footprint a popup tile collapses to on the 8- and 12-column grids.
  ///
  /// "Cannot be resized" needs a target. A card selected into popup is whatever
  /// size the user last dragged it to, and a locked 12-column icon-plus-value is
  /// both absurd and — with the handles gone — unrecoverable. Two columns is the
  /// 2×1 tile recorded as a decision on the issue before any of this was written
  /// (§2.6c item 1): the smallest footprint the popup form has content for, once
  /// [popupHeightRows] has taken the height.
  ///
  /// It sits *below* [kPopupBelow] on purpose, and this is where the two floors in
  /// this file are easy to confuse. Clearing 200px is [compactMinColumns]' job —
  /// §2.6c item 4 derives that figure, and it is why compact's floor is four
  /// columns rather than the three its consumers declare. The band below it is what
  /// popup is *for*: the form exists precisely because a label and a value stop
  /// fitting side by side there (§2.1). What makes a box this small safe to lock is
  /// not a width guarantee but [CardFormChoice.restoreW] — the previous box travels
  /// with the choice, because with the handles gone no gesture could recover it.
  static const int popupColumns = 2;

  /// The height a popup tile collapses to, on every grid.
  ///
  /// One row is the whole form: an icon, a label and a value on one line. On the
  /// 4-column grid this is the *only* axis popup touches — see [_applyCardForm]
  /// for why the width there belongs to [lockToFullWidth] instead.
  static const int popupHeightRows = 1;

  /// The narrowest a [CardDensity.compact] card may be shrunk to, in 12-column
  /// units.
  ///
  /// Four columns, not the three every compact consumer declares as its
  /// `minColumns`: a 3-column card is 191.4px at its narrowest realization (§1.5)
  /// and so falls *below* [kPopupBelow], which is the width at which §2.1 says a
  /// label and a value no longer fit side by side in any locale. Four columns is
  /// the smallest span guaranteed to clear 200px at every screen width, so it is
  /// the floor at which the reduced form still reads (§2.6c, §D3).
  static const int compactMinColumns = 4;

  /// The shortest a [CardDensity.compact] card may be shrunk to, in rows.
  ///
  /// A floor on the height axis as well, so "shrinking is refused" holds in both
  /// directions rather than only sideways. The figure is two rows — a title line
  /// and a content line — and it is deliberately not a *measured* raise: the
  /// compact form is shorter than normal, so a number above what each card
  /// already declares could only be invented, and §2.4 is explicit that an
  /// unmeasured constant must not be frozen into the code. Every one of the seven
  /// compact consumers already declares `minHeightRows` of 2 or 3, so today this
  /// floor is the mechanism without the raise; the raise it would apply is real
  /// the moment a card declares less.
  static const int compactMinHeightRows = 2;

  /// The forms the user may pick for the card [id], in menu order, or an empty
  /// list when the card offers no choice.
  ///
  /// [CardDensity.normal] appears only alongside something to return *from* — on
  /// its own it is not a choice, just the status quo with a control attached.
  /// [CardDensity.compact] appears only for the eight cards that read the density
  /// (`normalAbove != null` is the existing predicate); offered anywhere else it
  /// would render exactly the normal form, which is a control that visibly does
  /// nothing. Building compact forms for the other ten is card-own design work
  /// at #1288-#1291's scale and is out of this ticket's scope.
  static List<CardDensity> selectableForms(String id) {
    final spec = UspWidgetSpecRegistry.getById(id);
    // Package widgets load from a remote template and are not built through
    // DashboardCardTemplate, so neither form has a path on them.
    if (spec == null) return const [];

    final forms = <CardDensity>[
      if (spec.normalAbove != null) CardDensity.compact,
      if (!cardsWithoutPopupForm.contains(id)) CardDensity.popup,
    ];
    if (forms.isEmpty) return const [];
    return [CardDensity.normal, ...forms];
  }

  /// Writes [choice] onto [cardId] in [layout], geometry and pick together, for a
  /// [cols]-wide grid.
  ///
  /// The one place a pick is *made* (#1400). The pick is stored on the item, in
  /// [CardFormChoice.extraKey] under `extra`, and the geometry it makes legal is
  /// written in the same copy of the same map — so the two reach the pref, the
  /// snapshot and the undo history as one value. #1299 stored the pick in a
  /// sibling map and re-derived the geometry on every import to keep the two in
  /// step; there is nothing left to keep in step.
  ///
  /// Every card other than [cardId] is returned untouched, including its own pick:
  /// a form is picked for one card on one grid.
  static List<LayoutItem> withCardForm(
    List<LayoutItem> layout,
    String cardId,
    CardFormChoice choice, {
    required int cols,
  }) =>
      layout
          .map((item) => item.id != cardId
              ? item
              : _applyCardForm(
                  item.copyWith(extra: choice.writeInto(item.extra)),
                  cols: cols,
                  choice: choice,
                ))
          .toList();

  /// Re-derives the geometry every pick in [layout] makes legal, for a grid that
  /// is [cols] wide.
  ///
  /// Runs where geometry is *created* rather than on every import (#1400): the
  /// scale that derives a breakpoint nobody stored ([scaleLayout]), and the
  /// one-time migration of a payload that kept its picks in a sibling map. A
  /// stored grid's geometry was written by [withCardForm] at that grid's own
  /// column count and travels with the pick, so importing it needs no rule at
  /// all.
  ///
  /// It is the scale that needs one: [popupColumns] is an absolute span rather
  /// than a fraction of the grid, so a pinned tile scaled 12 → 8 would arrive one
  /// column wide. Re-deriving is applied to every pick and not only to popup
  /// because the point is that a derived grid's geometry is the pick's, whichever
  /// pick it is — and each arm is idempotent, so the ones the scale already got
  /// right cost a rewrite of the same values.
  ///
  /// Returns [layout] itself when no item carries a pick, which is how an install
  /// that never used the control stays byte-identical to one from before #1299.
  static List<LayoutItem> applyPickedForms(List<LayoutItem> layout, int cols) {
    List<LayoutItem>? formed;
    for (var i = 0; i < layout.length; i++) {
      final item = layout[i];
      final choice = CardFormChoice.readFrom(item.extra);
      if (choice == null) continue;
      formed ??= List<LayoutItem>.of(layout);
      formed[i] = _applyCardForm(item, cols: cols, choice: choice);
    }
    return formed ?? layout;
  }

  /// Writes into [map] the sizes [choice] makes legal on a [cols]-wide grid.
  ///
  /// This is the inversion #1299 is about. #1232 runs width → density; this runs
  /// density → the sizes that are legal:
  ///
  /// | picked | what changes |
  /// |---|---|
  /// | [CardDensity.popup] | `isResizable: false`, and the box is pinned to [popupColumns] × [popupHeightRows] |
  /// | [CardDensity.compact] | `minW`/`minH` raised to the floors, `isResizable` back on; the card grows to the floor if it was under it |
  /// | [CardDensity.normal] | the spec's own bounds, `isResizable` back on |
  ///
  /// `isStatic` is never touched: it also disables dragging, and reordering is the
  /// one edit a popup tile should keep.
  ///
  /// ## Two things this deliberately does not do
  ///
  /// It does not own the width on the 4-column grid. There popup asks to be small
  /// and the #1293 lock pins `x: 0, w: cols`; the two rules would overwrite each
  /// other, so each takes one axis — popup locks the height and stays full width,
  /// a short full-width bar, and [lockToFullWidth] runs after this and has the
  /// last word on `x`/`w`/`minW`/`maxW`. The values written here for mobile agree
  /// with the lock's on purpose, so the order of the two is not load-bearing.
  ///
  /// It does not re-promote a card whose width grew back past `normalAbove`. A
  /// chosen density is what renders or the choice does not stick, and a wide
  /// compact card is sparse, not broken.
  /// Returns [item] with the sizes [choice] makes legal on a [cols]-wide grid.
  ///
  /// Returns rather than mutates since #1310: the three helpers below wrote into
  /// a shared map, and their order mattered — the comment on the `compact` arm is
  /// about exactly that. A `LayoutItem` cannot be written into, so each helper now
  /// takes the previous one's result, which makes that sequence visible in the
  /// code instead of being a property of the argument.
  static LayoutItem _applyCardForm(
    LayoutItem item, {
    required int cols,
    required CardFormChoice choice,
  }) {
    final constraints =
        UspWidgetSpecRegistry.getById(item.id)?.constraints[DisplayMode.normal];

    switch (choice.density) {
      case CardDensity.popup:
        // Pinned as caps as well as with the flag. isResizable: false is what
        // removes the handles, but a `w` outside its own [minW, maxW] is the
        // shape that made #1293 permanent — correctBounds and setSlotCount both
        // read the caps — so the box states its size in every field that
        // describes it.
        final w = cols <= UspLayoutEnvelope.mobileSlotCount
            ? cols
            : popupColumns.clamp(1, cols);
        return _pinSpan(item, cols: cols, w: w, h: popupHeightRows)
            .copyWith(isResizable: false);

      case CardDensity.compact:
        // The spec's bounds back first, then the floor on top of them. Compact
        // only ever *raises* a floor, and [_applyFloors] lifts a cap no further
        // than the floor it just wrote — so reached from popup, whose pin wrote
        // `maxW`/`maxH` down to 2x1, a bare raise leaves the card capped at its
        // own new floor with no gesture able to widen it again. Restoring first
        // is what makes this arm independent of the arm before it, which is the
        // property the `normal` arm below states for itself.
        return _applyFloors(
          _applySpecBounds(item, cols: cols, constraints: constraints),
          cols: cols,
          constraints: constraints,
          floorColumns: compactMinColumns,
          floorHeightRows: compactMinHeightRows,
        ).copyWith(isResizable: true);

      case CardDensity.normal:
        // Not a pin: normal *removes* a constraint, so it puts back exactly the
        // bounds the card would have had if no form had ever been picked. That
        // has to be a restore rather than a floor — popup wrote `maxW`/`maxH`
        // down to pin the tile, and a rule that only ever raises minima would
        // leave the card un-widenable after it expanded again.
        return _applySpecBounds(item, cols: cols, constraints: constraints)
            .copyWith(isResizable: true);
    }
  }

  /// [item] with its box pinned to exactly [w] × [h] on a [cols]-wide grid, caps
  /// included.
  static LayoutItem _pinSpan(
    LayoutItem item, {
    required int cols,
    required int w,
    required int h,
  }) =>
      item.copyWith(
        w: w,
        minW: w,
        maxW: w.toDouble(),
        h: h,
        minH: h,
        maxH: h.toDouble(),
        // Shrinking cannot push a card off the right edge, but a stored layout can
        // arrive already overhanging — the pin is applied to whatever is on disk,
        // not only to a card the user just picked. The `x is! int` half of this
        // test is gone with the map: the field is typed now, so "not an int" is
        // not a state that can arrive (#1310).
        x: item.x + w > cols ? 0 : item.x,
      );

  /// Puts back the bounds [constraints] declares, scaled to a [cols]-wide grid,
  /// and pulls the card's own size inside them.
  ///
  /// The undo of [_pinSpan] and of [_applyFloors]: the only bounds a card with no
  /// constraint on it should carry are its spec's, which is also what
  /// [LayoutItemFactory.fromSpec] gives a freshly added card. Cards with no spec
  /// (package widgets, or ids this build does not ship) are left exactly as they
  /// are — there is nothing to restore them *to*, and inventing bounds for a card
  /// we cannot describe is how a layout we did not author gets rewritten.
  static LayoutItem _applySpecBounds(
    LayoutItem item, {
    required int cols,
    required WidgetGridConstraints? constraints,
  }) {
    if (constraints == null) return item;

    var next = item;

    // Mobile widths are left to [lockToFullWidth], as in [_applyFloors].
    if (cols > UspLayoutEnvelope.mobileSlotCount) {
      final minW = _scaleFromTwelfths(constraints.minColumns, toCols: cols);
      final maxW = _scaleFromTwelfths(constraints.maxColumns, toCols: cols)
          .clamp(minW, cols);
      next = next.copyWith(
        minW: minW,
        maxW: maxW.toDouble(),
        w: next.w.clamp(minW, maxW),
      );
    }

    // Rows are absolute — a row is the same height on every grid — so they are
    // restored as declared.
    final minH = constraints.minHeightRows;
    final maxH =
        constraints.maxHeightRows < minH ? minH : constraints.maxHeightRows;
    return next.copyWith(
      minH: minH,
      maxH: maxH.toDouble(),
      h: next.h.clamp(minH, maxH),
    );
  }

  /// [item] with its floors raised to the greater of its spec's bounds and the
  /// given floor, grown if it was already under the result.
  static LayoutItem _applyFloors(
    LayoutItem item, {
    required int cols,
    required WidgetGridConstraints? constraints,
    required int floorColumns,
    required int floorHeightRows,
  }) {
    var next = item;

    // Mobile widths are not scaled for the same reason [correctedSize] leaves
    // them alone: there the width is pinned by [lockToFullWidth], so anything
    // written here could only fight the lock.
    if (cols > UspLayoutEnvelope.mobileSlotCount) {
      final specMinW =
          _scaleFromTwelfths(constraints?.minColumns ?? 1, toCols: cols);
      final floorW = _scaleFromTwelfths(floorColumns, toCols: cols);
      final minW = (specMinW > floorW ? specMinW : floorW).clamp(1, cols);
      next = next.copyWith(
        minW: minW,
        w: next.w < minW ? minW : next.w,
        // A cap is lifted only when the floor has overtaken it, which is what
        // makes this a floor and not a pin. The map form spelled the absent-key
        // case out — `(map['maxW'] as num?)?.toDouble() ?? cols` — and then never
        // used it: `minW` is clamped to `cols`, so the fallback could not be below
        // the floor. On the typed field the comparison answers it directly,
        // because `double.infinity < minW` is false (#1310).
        maxW: next.maxW < minW ? minW.toDouble() : next.maxW,
      );
    }

    // Row counts are absolute — a row is the same height on every grid — so they
    // are used as they are, exactly as [correctedSize] does.
    final specMinH = constraints?.minHeightRows ?? 1;
    final minH = specMinH > floorHeightRows ? specMinH : floorHeightRows;
    return next.copyWith(
      minH: minH,
      h: next.h < minH ? minH : next.h,
      maxH: next.maxH < minH ? minH.toDouble() : next.maxH,
    );
  }
}
