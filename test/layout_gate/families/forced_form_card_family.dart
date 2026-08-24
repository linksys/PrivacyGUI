/// The forced-form families: the boxes a #1299 pick produces, which no drag could
/// (#1344).
///
/// The port of `dashboard_card_forced_form_overflow_test.dart`'s three sweeps — 78
/// of the gate's committed baseline cells — onto [runOverflowSweep]. What each
/// sweep *is*, and why these two geometries are not dominated by the widths the
/// grid produces, stays documented where the sweeps are declared; this file is the
/// enumeration and the premises it declares, and nothing else. The *checking* of those
/// premises left for `card_sweep_cell.dart` at #1366 — see [kCompactFloorPremises] for
/// what the two `expect`s that used to be here were worth when they were deleted.
///
/// It was 75 at #1344. #1325 gave `dhcp_reservations` a `normalAbove`, which is
/// the predicate [UspWidgetSpecs.selectableForms] reads, so a seventh card became
/// pickable-compact and [ForcedCompactFloorFamily] grew by one card × 3 locales.
/// Nothing here named the card; the pin named the count, and it is what reported
/// the growth.
///
/// ## Three families, because the dataset already records three groups
///
/// `forced_form.popup_tile`, `forced_form.skeleton` and `forced_form.compact_floor`
/// — and [OverflowSurfaceFamily.name] *is* that group name, so one class could not
/// have kept the cell ids where they are. They also differ in the two ways §2
/// calls essential: the skeleton sweep pumps a widget rather than a card (its axis
/// is `variant`, not `card`), and the popup and compact sweeps each declare
/// something different about the tree they pumped.
///
/// ## The one cell id this port changes
///
/// The six skeleton cells were the gate's only coordinate whose id did not name its
/// locale. They are pumped in `en` and always were — the id simply never said so —
/// and the runner appends the locale to every cell id by construction
/// ([overflowSweepBaselineCell], which is deliberate: locale is a field on the cell,
/// not an axis a family may respell). So they re-key:
///
/// ```
/// forced_form.skeleton|variant=stats|px=122|rows=1             ← #1337's capture
/// forced_form.skeleton|variant=stats|px=122|rows=1|locale=en    ← from #1344 on
/// ```
///
/// That is a correction rather than lost coverage, and `forced_form.tsv` is
/// re-captured with it. The other 69 rows were byte-identical at #1344, so that
/// diff was six renamed rows and nothing else — small enough to verify by eye,
/// unlike #1343's 1,898. The #1325 merge adds three more rows on top of it, all
/// three `card=dhcp_reservations` under `forced_form.compact_floor`.
///
/// ## No allowlist, and no enumeration gaps
///
/// Nothing here is inherited debt — these boxes did not exist before #1299 — so
/// there is no `CardSweepGate`: the families take the runner's own zero-tolerance
/// verdict, and a failure is a regression rather than history.
///
/// [OverflowSurfaceFamily.enumerationGaps] stays empty for the same reason it is
/// empty on the chrome families: nothing narrows what these three enumerate. A
/// `MIN_SCREEN` floor does reach [narrowestRealizationOf], but the spans here are
/// **fixed constants** ([UspWidgetSpecs.popupColumns],
/// [UspWidgetSpecs.compactMinColumns]) rather than each spec's own, so a floor moves
/// the box every cell is measured at without changing how many cells there are. The
/// pin cannot see that, and it is not the pin's job to: the box is in the cell id as
/// `px=`, so `./tool/overflow_baseline.sh check forced_form` is what reports it.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';

import '../../util/dashboard/dashboard_card_probe.dart';
import '../sweep.dart';
import 'card_sweep_cell.dart';

/// The box a picked form collapses a card to, as a width case the harness accepts.
///
/// Derived from [UspWidgetSpecs.popupColumns] / [UspWidgetSpecs.compactMinColumns]
/// through the same enumeration the gate uses, so the widths here move with the
/// constants and with the grid rather than being restated. Null only when a
/// `MIN_SCREEN` filter has excluded the whole range, matching [widthCasesFor].
CardWidthCase? forcedFormCaseForSpan(int span, String label) {
  final narrowest = narrowestRealizationOf(span);
  if (narrowest == null) return null;
  return CardWidthCase(
    screenWidth: narrowest.screenWidth,
    cardWidth: narrowest.cardWidth,
    columnSpan: span,
    label: label,
  );
}

/// 122px by one row: two columns at the 320px screen floor.
///
/// A top-level `final` rather than a getter, for the reason `cardSweepLocales`
/// gives: the enumerations below read it once per cell, and a getter would re-run
/// the screen-width scan ~57 times before anything was pumped. Lazily initialised,
/// so the scan still happens on first use rather than at load.
final CardWidthCase forcedPopupTileCase =
    forcedFormCaseForSpan(UspWidgetSpecs.popupColumns, 'popup')!;

/// 261px: the four columns a picked compact card cannot go below.
final CardWidthCase forcedCompactFloorCase =
    forcedFormCaseForSpan(UspWidgetSpecs.compactMinColumns, 'compact floor')!;

/// The height a forced compact card is floored at, in rows.
///
/// `max` of the two, because [UspWidgetSpecs.compactMinHeightRows] is a floor
/// rather than a pin and every compact consumer already declares 2 or 3. Pumping
/// the constant alone would measure a shorter card than the floor actually permits
/// for the four that declare 3: `connected_devices`, `time_settings`,
/// `dhcp_reservations` and `network_health`.
///
/// Named rather than counted, because the count was wrong in both halves. This
/// read "four of the six" until the #1325 merge, when there were six consumers and
/// **three** of them declared 3 — `dhcp_reservations` is the fourth and was not a
/// consumer yet. The merge makes the numerator true and the denominator false at
/// the same time, which is exactly the drift a hand-count invites; the four ids are
/// the form of this claim that cannot drift.
int forcedCompactFloorRows(WidgetSpec spec) => math.max(
      spec.getConstraints(DisplayMode.normal).minHeightRows,
      UspWidgetSpecs.compactMinHeightRows,
    );

/// The cards a user can pick [density] for.
///
/// Shared with the suite, which pins both inventories: each sweep's size is
/// entirely a function of it, so a card that gains or loses a selectable form has
/// to be a failure rather than a silent change in coverage.
List<WidgetSpec> specsOfferingForm(CardDensity density) => UspWidgetSpecs.all
    .where((s) => UspWidgetSpecs.selectableForms(s.id).contains(density))
    .toList();

/// The six placeholders a card can show before its data arrives, at the largest
/// row count production asks each for — the pre-fix overflow grew with it.
const Map<String, CardSkeleton> kForcedFormSkeletonVariants = {
  'stats': CardSkeleton.stats(),
  'info': CardSkeleton.info(rows: 5),
  'list': CardSkeleton.list(rows: 4),
  'chart': CardSkeleton.chart(),
  'topology': CardSkeleton.topology(),
  'status': CardSkeleton.status(),
};

/// [ForcedPopupTileFamily]'s premise: the pick actually produced a popup form.
///
/// Eight of these cards had no reachable popup form before #1299, so this is what
/// distinguishes "the tile fits" from "the card ignored the pick and its full form
/// happens not to have overflowed yet". A `const` beside the enumeration rather than a
/// literal inside it, so the 51 cells share one list and the claim is readable without
/// unwrapping two loops.
///
/// The box is not named here even though the pre-#1366 hook named it: the failure prints
/// [CardSweepCell.widthLabel], which is `@popup 122px tab0` and comes from the width
/// case rather than from prose that could disagree with it.
const List<CardWidgetPremise> kPopupTilePremise = [
  CardWidgetPremise.present(
    CardPopupForm,
    reason: 'Eight of these cards had no reachable popup form before #1299. A '
        'card that bypasses the template keeps its full form inside the tile, '
        'which is the overflow the parent epic exists to prevent.',
  ),
];

/// [ForcedCompactFloorFamily]'s premise, in the two halves available here.
///
/// The compact form has no widget of its own to find — each of the seven cards arranges
/// its own — so the structural claim is that the card still went through the template
/// that reads the density, and that it did not fall through to the popup form instead.
///
/// Both halves matter, and the second is the one with teeth: measured against a defect
/// that made a pinned form be ignored, the pair took it from **7 killers to 0** when the
/// hook holding them was emptied (#1366). The popup form is *smaller* than the compact
/// one, so it fits the 261px box and every overflow assertion in the sweep passes while
/// the card's content is gone.
const List<CardWidgetPremise> kCompactFloorPremises = [
  CardWidgetPremise.present(
    DashboardCardTemplate,
    reason:
        'The density scope the card reads is what selects the compact form, '
        'and the template is what reads it — a card that bypassed the template '
        'sized itself from its own width instead.',
  ),
  CardWidgetPremise.absent(
    CardPopupForm,
    reason: 'Compact is the middle band. Falling through to the popup form '
        'satisfies every overflow assertion here while losing the card\'s '
        'content, because the popup form is the smaller of the two.',
  ),
];

/// Every card that can be picked into popup, in the 122×1 tile the pick produces.
/// 17 cards × 3 locales = 51 cells.
class ForcedPopupTileFamily extends CardOverflowFamily {
  const ForcedPopupTileFamily();

  @override
  String get name => 'forced_form.popup_tile';

  @override
  List<String> get axisNames => const ['card', 'px', 'rows'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() => [
        for (final spec in specsOfferingForm(CardDensity.popup))
          for (final locale in kCardTextBoundingLocales)
            CardSweepCell(
              axes: {
                'card': spec.id,
                'px': forcedPopupTileCase.widthKey,
                'rows': UspWidgetSpecs.popupHeightRows,
              },
              locale: locale,
              cardId: spec.id,
              widthCase: forcedPopupTileCase,
              rows: UspWidgetSpecs.popupHeightRows,
              density: CardDensity.popup,
              widgetPremises: kPopupTilePremise,
            ),
      ];

  /// Empty since #1366, and the premise above is why.
  ///
  /// It was this body, as a `find.byType` `expect` nothing required it to keep — the
  /// state #1364 measured one family over and #1366 measured here. The claim did not
  /// change; it is a value on the cell now, checked for every card family by
  /// [CardOverflowFamily.onCellSettled], and pinned by `dashboard_card_gate_test.dart`
  /// so deleting the declaration is as loud as deleting the check.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {}
}

/// The six loading placeholders in the same tile, in `en` alone. 6 cells.
///
/// Pumped directly rather than reached through a card, and that is the whole reason
/// this is a second family: a card only renders its skeleton in the frames before
/// its data arrives, and the shared fixture resolves most cards' data immediately.
/// Only `connected_devices` and `wifi_performance` had a loading frame to catch (94px
/// and 6px over), so 13 of the 15 cards that return a skeleton were covered by
/// fixture timing rather than by a test. On a cold boot every one of them has that
/// frame.
///
/// The input is a [CardSkeleton] under a popup scope, which is a fact about six
/// widgets and has nothing to do with locale or card data — hence one locale, and
/// hence `variant` as the axis where the other two families have `card`. The two
/// card cases in [ForcedPopupTileFamily] are what prove production puts the
/// skeleton under that scope at all.
class ForcedFormSkeletonFamily extends CardOverflowFamily {
  const ForcedFormSkeletonFamily();

  @override
  String get name => 'forced_form.skeleton';

  @override
  List<String> get axisNames => const ['variant', 'px', 'rows'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() => [
        for (final entry in kForcedFormSkeletonVariants.entries)
          CardSweepCell(
            axes: {
              'variant': entry.key,
              'px': forcedPopupTileCase.widthKey,
              'rows': UspWidgetSpecs.popupHeightRows,
            },
            // The one locale, and the one this sweep has always run in — see the
            // library header on the id that changes because of it.
            locale: const Locale('en'),
            // The id only keys the harness's geometry and tab pinning; the widget
            // under test is the override. The scope is built by hand rather than
            // through `density:` because that parameter drives
            // `cardDensityOverrideProvider`, which only the factory-built
            // `CardDensityHost` reads — and a `cardOverride` replaces the factory.
            cardId: 'connected_devices',
            cardOverride: CardDensityScope(
              density: CardDensity.popup,
              child: entry.value,
            ),
            widthCase: forcedPopupTileCase,
            rows: UspWidgetSpecs.popupHeightRows,
          ),
      ];

  /// Empty, and written out rather than defaulted away.
  ///
  /// The other two families check that the pick produced the form they are
  /// measuring, because a card could ignore it. There is nothing equivalent to
  /// check here: the widget under test *is* the override, so it is in the tree by
  /// construction, and a placeholder has no content to be readable — that is what
  /// makes it a placeholder. The readability question for this box belongs to the
  /// form the skeleton resolves into, which [ForcedPopupTileFamily] pumps.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {}
}

/// The seven cards a user can pick compact for, at the 261px floor the pick
/// creates. 7 cards × 3 locales = 21 cells.
///
/// The gate pumps only each spec's min / preferred / max spans — 3, 6 and 8 for six
/// of the seven — so the span #1299 makes their floor is pumped by nothing. For two
/// of the seven the automatic rule would not select compact there at all, which is
/// what makes this sweep *forced* rather than merely un-pumped; the suite pins which
/// two.
///
/// The seventh is `dhcp_reservations`, and it is the reason the suite's inventory is
/// a three-way partition rather than an emptiness: its own `minColumns` is 4, so the
/// gate's min-span case *is* this floor, in the compact form, in all 26 locales. Its
/// three cells here are duplicates and are kept anyway — see the suite header for
/// why excluding a card because another sweep happens to reach the same coordinate
/// opens a hole the moment a `normalAbove` or a `minColumns` moves.
class ForcedCompactFloorFamily extends CardOverflowFamily {
  const ForcedCompactFloorFamily();

  @override
  String get name => 'forced_form.compact_floor';

  @override
  List<String> get axisNames => const ['card', 'px', 'rows'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() => [
        for (final spec in specsOfferingForm(CardDensity.compact))
          for (final locale in kCardTextBoundingLocales)
            CardSweepCell(
              axes: {
                'card': spec.id,
                'px': forcedCompactFloorCase.widthKey,
                'rows': forcedCompactFloorRows(spec),
              },
              locale: locale,
              cardId: spec.id,
              widthCase: forcedCompactFloorCase,
              rows: forcedCompactFloorRows(spec),
              density: CardDensity.compact,
              widgetPremises: kCompactFloorPremises,
            ),
      ];

  /// Empty since #1366, and [kCompactFloorPremises] is why.
  ///
  /// This is the family the ticket was measured on: the two `expect`s that were here
  /// were killed by nothing when deleted, and were worth 7 killers when paired with a
  /// real defect. Declaring `expectedDensity: compact` would not have replaced them —
  /// the cells pin that density themselves, so the check would only read back the
  /// override, while the fall-through defect publishes a popup scope the card obeys.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {}
}
