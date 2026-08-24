/// The forced-form families: the boxes a #1299 pick produces, which no drag could
/// (#1344).
///
/// The port of `dashboard_card_forced_form_overflow_test.dart`'s three sweeps — 75
/// of the gate's 3,587 committed baseline cells — onto [runOverflowSweep]. What
/// each sweep *is*, and why these two geometries are not dominated by the widths
/// the grid produces, stays documented where the sweeps are declared; this file is
/// the enumeration and the premise check, and nothing else.
///
/// ## Three families, because the dataset already records three groups
///
/// `forced_form.popup_tile`, `forced_form.skeleton` and `forced_form.compact_floor`
/// — and [OverflowSurfaceFamily.name] *is* that group name, so one class could not
/// have kept the 75 cell ids where they are. They also differ in the two ways §2
/// calls essential: the skeleton sweep pumps a widget rather than a card (its axis
/// is `variant`, not `card`), and the popup and compact sweeps each assert
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
/// re-captured with it. The other 69 rows are byte-identical, so the diff is six
/// renamed rows and nothing else — which is small enough to verify by eye, unlike
/// #1343's 1,898.
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
/// for four of the six.
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
            ),
      ];

  /// The sweep's premise: the pick actually produced a popup form.
  ///
  /// Eight of these cards had no reachable popup form before #1299, so this is the
  /// assertion that distinguishes "the tile fits" from "the card ignored the pick
  /// and its full form happens not to have overflowed yet".
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {
    expect(
      find.byType(CardPopupForm),
      findsOneWidget,
      reason: '${card.cardId} did not render the popup form. Eight of these '
          'cards had no reachable popup form before #1299 — one that bypasses '
          'the template would keep its full form inside a '
          '${forcedPopupTileCase.widthKey}px box, which is the overflow the '
          'parent epic exists to prevent',
    );
  }
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

/// The six cards a user can pick compact for, at the 261px floor the pick creates.
/// 6 cards × 3 locales = 18 cells.
///
/// The gate pumps only each spec's min / preferred / max spans — 3, 6 and 8 for all
/// six consumers — so the span #1299 makes their floor is pumped by nothing. For two
/// of the six the automatic rule would not select compact there at all, which is
/// what makes this sweep *forced* rather than merely un-pumped; the suite pins which
/// two.
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
            ),
      ];

  /// The sweep's premise, in the two halves available here.
  ///
  /// The compact form has no widget of its own to find — each of the six cards
  /// arranges its own — so the structural claim is that the card still went through
  /// the template that reads the density, and that it did not fall through to the
  /// popup form instead.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {
    expect(
      find.byType(DashboardCardTemplate),
      findsOneWidget,
      reason: '${card.cardId} must render through the card template; the '
          'density scope it reads is what selects the compact form',
    );
    expect(
      find.byType(CardPopupForm),
      findsNothing,
      reason: '${card.cardId}: compact is the middle band. Falling through to '
          'the popup form would satisfy every overflow assertion here while '
          'losing the card\'s content',
    );
  }
}
