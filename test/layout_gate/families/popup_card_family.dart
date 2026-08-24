/// The popup families: the degraded form a width produces, and the presentation it
/// opens (#1345).
///
/// The port of `dashboard_card_popup_overflow_test.dart`'s three sweeps — 312 of the
/// gate's 3,587 committed baseline cells — onto [runOverflowSweep]. Why the form is
/// pinned rather than provoked by a width, which cards are swept and which nine have
/// no popup form at all, stays documented where the sweeps are declared; this file is
/// the enumeration and the premises it declares, and nothing else. The *checking* of
/// those premises, and the *running* of [kPresentationOpener], left for
/// `card_sweep_cell.dart` at #1366.
///
/// ## Three families, because the dataset already records three groups
///
/// `popup.form`, `popup.dialog` and `popup.picked_dialog` — and
/// [OverflowSurfaceFamily.name] *is* that group name. They also differ in all three
/// of the ways §2 calls essential:
///
/// * **The card list.** `popup.form` and `popup.dialog` sweep the nine cards the grid
///   can put below [kPopupBelow] ([canReachPopupBand]); `popup.picked_dialog` sweeps
///   the seventeen a user can *pick* into popup ([canBePickedIntoPopup]). The eight
///   in the difference have a popup form production can show and no width sweep can
///   reach.
/// * **The box.** The width path leaves the cell whatever height the layout gave it;
///   a pick pins it to [UspWidgetSpecs.popupHeightRows] and puts that one row on a
///   full-height screen — the only sweep in the whole gate whose surface height is
///   not its card's box. See [kPopupSweepScreenRows].
/// * **What is measured after settling.** Two of the three tap the tile open, so the
///   dialog's own layout is inside the collection window. `popup.form` does not. Since
///   #1366 that difference is [CardSweepCell.openWith] on their cells rather than a
///   hook body, because a hook that *produces* the surface is one whose deletion
///   changes what 78 cells measure — silently, and past the coverage baseline.
///
/// All three cell ids already carried `locale` last, so this port renames nothing:
/// `./tool/overflow_baseline.sh check popup` is byte-identical across it.
///
/// ## No allowlist
///
/// `known_overflows.json` baselines the normal form's inherited debt. The popup form
/// is new code and starts clean, so there is no `CardSweepGate` here: the families
/// take the runner's own zero-tolerance verdict, and a failure is a regression in
/// this ticket's work rather than history.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../util/dashboard/dashboard_card_probe.dart';
import '../collector.dart';
import '../sweep.dart';
import 'card_sweep_cell.dart';

/// The narrowest width the grid produces for [spec] — the same case the #1183 gate
/// treats as the worst case. Null when a `MIN_SCREEN` filter has excluded every
/// realization, matching [widthCasesFor]'s empty return.
///
/// [minScreen] is passed through for one caller only: [popupBandEnumerationGaps]
/// needs the unfiltered inventory to say how much a filtered run dropped.
CardWidthCase? narrowestCaseFor(WidgetSpec spec, {double? minScreen}) {
  final cases = widthCasesFor(spec, minScreen: minScreen);
  return cases.isEmpty ? null : cases.first;
}

/// Whether the grid can make [spec] narrow enough to select its popup form.
///
/// A card the grid keeps above [kPopupBelow] has no popup form to sweep at any
/// width, whatever it declares — [densityForWidth] compares the *rendered* width
/// against the threshold, so a floor above it settles the question.
bool canReachPopupBand(WidgetSpec spec, {double? minScreen}) {
  final wc = narrowestCaseFor(spec, minScreen: minScreen);
  return wc != null && wc.cardWidth < kPopupBelow;
}

/// Whether the user can put [spec] into popup by *picking* it (#1299).
///
/// A different and larger inventory than [canReachPopupBand], which is why it is a
/// second predicate rather than a widened one. Reaching the band by width takes a
/// `minColumns` of 3, which nine cards have; picking popup is offered for every card
/// the template builds, which is all of them but `stats_panel`.
bool canBePickedIntoPopup(WidgetSpec spec) =>
    UspWidgetSpecs.selectableForms(spec.id).contains(CardDensity.popup);

/// Rows of viewport the picked sweep gives the screen.
///
/// Six rows is 800px — a laptop, and comfortably more than the tallest card's
/// declared 528px, so the presentation is measured against a screen that is not
/// itself the constraint. The tile inside it is still one row.
const int kPopupSweepScreenRows = 6;

/// Why a run enumerated fewer band cells than the pins claim, if it did.
///
/// The two width-path families size themselves from [canReachPopupBand], which reads
/// each spec's *own* narrowest realization — so a `MIN_SCREEN` floor does not merely
/// widen the box these sweep, it can lift a card above [kPopupBelow] and drop it out
/// of the sweep entirely. Without this the pin would fail on a filtered run, or
/// worse, be edited to match a subset and pass over 6 cards instead of 9.
///
/// Reported as a gap rather than a failure for the reason
/// [OverflowSurfaceFamily.enumerationGaps] gives; a filter that leaves *nothing* is
/// still a failure, which the runner decides ([overflowSweepCountAction]).
///
/// [kMinSupportedScreenWidth] is the unfiltered floor rather than 0: it is the floor
/// the framework commits to, and `narrowestRealizationOf` raises anything lower to it
/// anyway, so comparing against it is comparing against the real default.
List<String> popupBandEnumerationGaps() {
  final unfiltered = UspWidgetSpecs.all
      .where((s) => canReachPopupBand(s, minScreen: kMinSupportedScreenWidth))
      .length;
  final selected = UspWidgetSpecs.all.where(canReachPopupBand).length;
  if (selected == unfiltered) return const [];
  return [
    '--dart-define=MIN_SCREEN=${minScreenFilter.toStringAsFixed(0)} left '
        '$selected of $unfiltered cards able to reach the popup band: each card '
        'is swept at its narrowest realization at or above that floor, and a '
        'higher floor lifts some of them above the ${kPopupBelow}px threshold.',
  ];
}

/// The two width-path families' cells: the nine band cards at their own narrowest
/// realization, in [locales].
///
/// One function rather than the same comprehension twice, because the two families
/// differ in nothing else — [PopupFormFamily] takes all 26 locales and
/// [PopupDialogFamily] the three bounding ones, and both then measure a different
/// moment of the same coordinate. Written as a loop rather than a collection-`for`
/// so the width case and the row count are computed **once per card** instead of
/// once per cell: [narrowestCaseFor] runs `narrowestRealizationOf` over every
/// integer screen width from 320 to 2560 for each of the spec's three spans, and
/// the 26-locale family would otherwise pay that 52 times per card before anything
/// is pumped. `forced_form_card_family.dart` hoists its own cases for the same
/// reason.
/// [premises] and [openWith] are the two families' whole remaining difference in what
/// they claim, which is why they are parameters here rather than a second comprehension:
/// the width path is identical and the premise is not (#1366).
List<OverflowSweepCell> _bandCells(
  Iterable<Locale> locales, {
  List<CardWidgetPremise> premises = const [],
  CardSurfaceOpener? openWith,
}) {
  final cells = <OverflowSweepCell>[];
  for (final spec in UspWidgetSpecs.all.where(canReachPopupBand)) {
    final wc = narrowestCaseFor(spec)!;
    final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
    for (final locale in locales) {
      cells.add(CardSweepCell(
        axes: {'card': spec.id, 'px': wc.widthKey},
        locale: locale,
        cardId: spec.id,
        widthCase: wc,
        rows: rows,
        density: CardDensity.popup,
        widgetPremises: premises,
        openWith: openWith,
      ));
    }
  }
  return cells;
}

/// [PopupFormFamily]'s premise: the pinned density actually produced a popup form.
///
/// A card that bypasses the template reads its own width instead of the scope, so it
/// would silently keep its full form here — and a full form that has not overflowed
/// *yet* passes every overflow assertion in the sweep.
///
/// Not declared by the two dialog families on the same coordinate: what they measure is
/// the presentation, and their claim about the tile is that tapping it opens one, which
/// is [kPresentationOpener]'s own assertion rather than a second copy of this.
const List<CardWidgetPremise> kPopupFormPremise = [
  CardWidgetPremise.present(
    CardPopupForm,
    reason:
        'This sweep pins the popup density, and the popup form is what that '
        'is supposed to produce. A card that bypasses the template reads its own '
        'width instead of the scope and silently keeps its full form.',
  ),
];

/// The surface the two dialog families measure, declared on their cells (#1366).
///
/// It was their `onCardSettled`, and that is what made it deletable in silence — the
/// hook did not merely assert the premise, it *produced the thing being measured*.
/// Measured: both hooks emptied left the popup suite 80 of 80 green and
/// `./tool/overflow_baseline.sh check popup` reporting 347 cells identical, so 78 cells
/// silently measured the 122px tile [PopupFormFamily] already covers and no tool in the
/// family could see it. As a declaration the framework runs it, and
/// `dashboard_card_gate_test.dart` pins which families carry it.
///
/// Shared by [PopupDialogFamily] and [PickedPopupDialogFamily], which differ in the box
/// they open it from and in nothing about the opening.
const CardSurfaceOpener kPresentationOpener = CardSurfaceOpener(
  name: 'presentation',
  open: _openPresentation,
);

/// Taps the tile open, which is where the two dialog sweeps' measurement actually
/// happens.
///
/// Runs *inside* the collector, because [CardOverflowFamily.onCellSettled] does
/// (`sweep.dart` invariant 1 is what makes a second pump safe there) — so the dialog's
/// own overflow is collected against this cell. Moving it out would leave those sweeps
/// measuring the tile [PopupFormFamily] already measured.
Future<void> _openPresentation(WidgetTester tester, CardSweepCell card) async {
  await tester.tap(find.byType(CardPopupForm));
  await settleIgnoringAnimations(tester);
  // The presentation is the only way to read this card, so an empty or absent one
  // is a total loss of the card's content, not a cosmetic problem.
  expect(
    find.byType(AppDialog),
    findsOneWidget,
    reason: '${card.cardId}: tapping the popup form must open the dialog',
  );
}

/// The nine cards the grid can put below [kPopupBelow], in their popup form, at
/// their own narrowest realization. 9 cards × 26 locales = 234 cells.
///
/// Every shipped locale, unlike the two sweeps below: this is the popup form's only
/// measurement, so the string table is one of the things it is covering.
class PopupFormFamily extends CardOverflowFamily {
  const PopupFormFamily();

  @override
  String get name => 'popup.form';

  @override
  List<String> get axisNames => const ['card', 'px'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() => _bandCells(
        AppLocalizations.supportedLocales,
        premises: kPopupFormPremise,
      );

  @override
  List<String> enumerationGaps() => popupBandEnumerationGaps();

  /// Empty since #1366, and [kPopupFormPremise] is why.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {}
}

/// The same nine cards' *normal* form, inside the presentation the tile opens.
/// 9 cards × 3 locales = 27 cells.
///
/// Three locales rather than 26: this is a second pump of a coordinate
/// [PopupFormFamily] already covers in all of them, and what it adds is the dialog's
/// chrome and the fixed [kCardPresentationWidth], not the string table.
class PopupDialogFamily extends CardOverflowFamily {
  const PopupDialogFamily();

  @override
  String get name => 'popup.dialog';

  @override
  List<String> get axisNames => const ['card', 'px'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() => _bandCells(
        kCardTextBoundingLocales,
        openWith: kPresentationOpener,
      );

  @override
  List<String> enumerationGaps() => popupBandEnumerationGaps();

  /// Empty since #1366, and [kPresentationOpener] is why: the surface this family
  /// measures is now declared on its cells rather than opened by this body.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {}
}

/// The presentation opened from a *picked* popup tile. 17 cards × 3 locales = 51
/// cells.
///
/// [PopupDialogFamily] models the width path: the card degrades because the grid
/// made it narrow, and its cell keeps whatever height the layout gave it. A pick is
/// the other path, and it pins the box — `applyCardForms` writes
/// [UspWidgetSpecs.popupHeightRows], so the cell is one row whatever the card
/// declares it needs.
///
/// That height is a consequence of the degradation, so it must not be what the
/// presentation *undoing* the degradation is sized to. Sweeping the two heights
/// separately is what keeps the distinction visible: give this family the declared
/// height and every case passes while production shows a card in a box a third of its
/// height. The group was written failing — 51 of 51, by +11px to +91px, all `bottom`.
class PickedPopupDialogFamily extends CardOverflowFamily {
  const PickedPopupDialogFamily();

  @override
  String get name => 'popup.picked_dialog';

  @override
  List<String> get axisNames => const ['card', 'px'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() {
    // The tile the pick collapses the card to, not the card's own narrowest span:
    // a picked popup is `popupColumns` wide wherever the grid allows it. Fixed for
    // every card, which is why it is read once here — the call scans every screen
    // width from 320 to 2560 — and also why this family needs no enumeration gap:
    // a `MIN_SCREEN` floor moves the box without dropping a card.
    final wc = pickedTileCase();
    return [
      for (final spec in UspWidgetSpecs.all.where(canBePickedIntoPopup))
        for (final locale in kCardTextBoundingLocales)
          CardSweepCell(
            axes: {'card': spec.id, 'px': wc.widthKey},
            locale: locale,
            cardId: spec.id,
            widthCase: wc,
            // What the pick pins the cell to.
            rows: UspWidgetSpecs.popupHeightRows,
            // A full-height screen: the tile is short, the device is not.
            screenHeightRows: kPopupSweepScreenRows,
            density: CardDensity.popup,
            openWith: kPresentationOpener,
          ),
    ];
  }

  /// Empty since #1366, for the reason [PopupDialogFamily]'s is.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {}

  /// The one family here that does not take the runner's default verdict.
  ///
  /// The two heights in play are the whole point of the sweep, and neither is in the
  /// cell id: the coordinate says `px=122`, and the failure has to say that the tile
  /// is one row while the card declares several. Without it a reader sees a bottom
  /// overflow inside a dialog and has no reason to suspect the box was sized from the
  /// degradation.
  @override
  Future<String?> judgeCard(
    WidgetTester tester,
    CardSweepCell card,
    OverflowCellVerdict verdict,
  ) async {
    if (verdict.significant.isEmpty) return null;
    final spec = UspWidgetSpecs.getById(card.cardId)!;
    final declared = dashboardCardHeight(
      spec.getConstraints(DisplayMode.normal).minHeightRows,
    );
    return '${card.cardId} normal form overflowed inside the dialog opened from '
        'a picked popup tile. The tile is '
        '${dashboardCardHeight(UspWidgetSpecs.popupHeightRows)}px tall and this '
        'card declares ${declared}px: ${verdict.summary}';
  }
}
