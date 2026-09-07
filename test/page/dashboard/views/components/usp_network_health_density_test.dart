@Tags(['layout-gate'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/dashboard/text_readability_probe.dart';
import '../../../../util/overflow_probe.dart';

/// `network_health` density: which form the card selects, and what each form
/// owes the reader (#1291).
///
/// This card declares `normalAbove: 366`, the highest threshold in the set, and
/// it is the only one of the six whose density defect is a defect of **height**.
/// The other five run out of horizontal room and cut a token; this one runs out
/// of vertical room and shrinks the gauge's centre — the score and the tier — to
/// 52% in `de`. Nothing is cut, nothing overflows, and the reading is
/// unrecognisable anyway.
///
/// ## Why the existing suites cannot make this claim
///
///   - the #1183 gate asks whether a `RenderFlex` overflowed. It did, at three
///     coordinates (#1235: +21.0px `de`, +11.0px `ru`, +9.0px `th`), and
///     `BoxFit.scaleDown` closed all three by absorbing the overflow into the
///     scale. That is the trade the gate cannot see: the card went green because
///     the text got smaller, so greenness here is a *report* of the density
///     defect, not evidence against it.
///   - `usp_gauge_center_readability_test.dart` pins `CardDensity.normal` (a pin
///     #1291 had to add — see its `pumpAt`). It proves the centre never
///     truncates and never drops the tier when the normal form is selected; it
///     deliberately says nothing about when that is.
///   - `dashboard_card_popup_overflow_test.dart` pins `CardDensity.popup`, so it
///     proves the popup form fits, never that a card reaches it.
///
/// Nothing is pinned in the selection groups below: every case goes through
/// `UspWidgetFactory` and `CardDensityHost`'s own `LayoutBuilder`, which is the
/// production path. The two exceptions are in the last group, and they pin
/// normal deliberately to record *why* the threshold sits where it does.
///
/// ## The criterion: the height must stop binding, and a bounded label must not
/// be cut
///
/// "The centre scales 1.000" is not the criterion, because it is unreachable in
/// `ru`: «Удовлетворительный» makes the centre column 123px wide against a
/// 120px gauge, so `ru` sits at 0.973 at *every* width, desktop included. That
/// is a permanent width bind and no threshold can buy it back. What the
/// threshold can buy is the *height* bind — the 0.523 in `de` — so the
/// assertions below are `heightBinds` is false, plus a magnitude floor that
/// 0.973 clears and 0.523 does not.
///
/// The second half comes from #1289's rule: a **bounded** token must never be
/// cut, an unbounded one may. Every token in this card is bounded — the score is
/// at most 3 digits, the tier and the three metric labels are localized
/// constants — so nothing here is allowed to break mid-word, which is what
/// pushed the threshold up. Measured over a pinned-normal 1px sweep of
/// [200, 620] in all 26 locales, there are two floors:
///
///   - **scale floor 231** — the width above which the centre stops being
///     height-scaled (`de` 231, `th` 204, everything else already 1.000).
///   - **token floor 366** — the width above which no metric label breaks
///     inside a word (`da`/`nb`, «Forkastninger»).
///
/// 366 is the threshold because a threshold is the width at which the normal
/// form *earns* selection (§2.6f point 1), and below 366 it has not: it paints a
/// full-size score over a label reading «Forkast‑ / ninger». Widest failing + 1,
/// same derivation as #1288 and #1289.
///
/// ## What the compact form sheds, and why it is the whole row
///
/// The three-chip metric row costs 165px of the card's height — `gauge + row ==
/// 165px` at every width in all 26 locales — and in `de` it spends 142px of
/// that, leaving 23px for a centre column that needs 44. Dropping the row
/// returns the whole 165px, the gauge lays out at its declared 120×120, and the
/// centre scales 1.000.
///
/// #1275's `InfoGrid` treatment was measured against that rather than assumed:
/// stacked one-per-line it reads at 1.000 in 25 locales (112px block, 53px
/// gauge) but leaves `de` at **0.841**, still height-binding up to 215px, and it
/// caps the gauge at 53px everywhere — a ring that is no longer a ring. It buys
/// legibility with height, which is the right trade for `firewall_overview`'s
/// *width* defect and the wrong one here.
///
/// Dropping the row loses no reading: the Errors tab carries errors and discards
/// as avg + peak, and the Loss tab carries loss, so no metric's only home is
/// this row.
///
/// ## One gate change this needed
///
/// `dashboard_card_overflow_test.dart`'s tab-registry meta-test counted visible
/// tabs at `widthCasesFor(spec).first` — 191.375px. This card is the first
/// *tabbed* card to declare a threshold, so that pump now returns the popup
/// form, which has no tab bar, and the guard read 0 tabs as "the card lost its
/// tabs". It counts at the desktop width instead: how many tabs a card has is a
/// property of its whole form, and which form a width selects is this file's
/// claim, not a registry check's. Case count unchanged, fixture untouched.
///
/// ## Mutation ledger
///
/// Every assertion below was run against a mutation of the code it guards and
/// observed to fail. Measured against this file's 17 tests, `network_health`'s
/// 24 existing tests (of which `usp_gauge_center_readability_test.dart`'s 17 are
/// the closest neighbour), and the full 1644-test gate — each mutation applied
/// alone and reverted before the next:
///
///   | mutation                                     | this file | the gate | gauge centre |
///   |----------------------------------------------|-----------|----------|--------------|
///   | A `normalAbove` deleted from the spec        | 10 fail   | green    | green        |
///   | B `popupValue` deleted from the card         | 3 fail    | green    | green        |
///   | C the `if (!compact)` guard removed          | 6 fail    | green    | green        |
///   | D `normalAbove` 366 → 231 (the scale floor)  | 8 fail    | green    | green        |
///   | E the gauge translated 400px down            | 7 fail    | green    | green        |
///
/// Every row is green in both existing suites, which is the whole argument for
/// this file existing.
///
/// A is the ticket reverted: with no threshold every width selects normal, so
/// the declaration test, all three popup cases, the four compact-form cases and
/// both row-dropped cases go — and the card paints a 0.523 centre at 191px
/// again, which is exactly what the gate calls clean. The 7 survivors are the
/// ones that assert the *normal* form: the three desktop cases and the four
/// pinned derivation cases.
///
/// B is the narrowest and the one worth reading twice: with no `popupValue` the
/// popup form falls back to the card *title*, which renders, fits, and is clean.
/// A 191px card reading "Network Health" and nothing else is a working form that
/// says nothing, and it is indistinguishable from a correct one everywhere else
/// in this file.
///
/// C keeps the threshold and reverts the form. Its kills split in a way that is
/// worth the detail: at all four compact widths the metric labels are simply
/// *there* again (the `discards` assertion), and at 200px the geometry goes with
/// them — the gauge is back to 23px in `de` and the centre back to 0.52. At
/// 288px and above the row returns without the height bind returning, which is
/// the measurement that settles the threshold: what is broken up there is the
/// *label*, not the gauge, so the token floor has to be the one that sets it.
///
/// D is that settlement stated as a mutation — the threshold moved to the scale
/// floor, the number a "fix the gauge" reading of #1235 would have picked. It
/// fails the declaration bound (231 is below the 288px realization), hands the
/// whole upper compact band back to the normal form, and then fails the one test
/// that reads the declared number and looks at the label at it: in `da`, 231px
/// of card still breaks «Forkastninger» across two lines. A threshold that fixes
/// the metric it was named for and ships a broken word underneath is the failure
/// mode this file's last group exists to make loud.
///
/// E is the one row that is not about density at all — it is the check that
/// [expectInsideCardBox] is worth its lines. A `Transform.translate` moves the
/// gauge 400px down out of the card's box without changing a single layout
/// constraint, so no `RenderFlex` reports anything: the gate stays at 1644 and
/// the readability suite, which measures the centre's own box, stays at 17. The
/// seven kills are the four compact cases and the three desktop ones — every
/// case that claims the gauge is *there*, none of which would otherwise notice
/// that it is painted outside the card.
void main() {
  setUpAll(() async {
    // Real fonts: under Ahem every glyph is one square em, so the line counts
    // that decide the metric row's height — and therefore this whole ticket —
    // are fiction.
    await loadAppFonts();
  });

  const cardId = 'network_health';
  final spec = UspWidgetSpecs.getById(cardId)!;
  final constraints = spec.getConstraints(DisplayMode.normal);
  final heightRows = constraints.minHeightRows;

  /// The declared threshold, and a literal fallback used **only** so the file
  /// can still enumerate its cases when the declaration is missing.
  ///
  /// `spec.normalAbove!` would throw here — before a single test registers — and
  /// mutation A in the ledger above would have read as "the file fails to load"
  /// rather than as assertions about forms the card no longer selects. A suite
  /// that cannot describe the bug it catches is not much better than one that
  /// misses it, so the number is duplicated on purpose, and the first test in
  /// the file is the one that asserts the spec still declares it.
  final normalAbove = spec.normalAbove ?? 366.0;

  /// The widths the gate realizes (191.375px, 288.000px) and the desktop width
  /// it never pumps (512px), from the same helpers the gate uses.
  final narrowCases = widthCasesFor(spec);
  final desktopCase = desktopCaseFor(spec);
  final widestRealization =
      narrowCases.map((c) => c.cardWidth).reduce(math.max);

  /// The widths that exercise the compact band: its two edges and the one
  /// realization that lands inside it.
  ///
  /// 288px is a realization; 200px and `normalAbove − 2` are the band's own
  /// edges, which the grid can produce (a 3-column span on a 700px screen is
  /// 228.5px) but never does for *this* card's realizations. A band no test
  /// enters is a band whose contents were never seen. 330px is the interior
  /// sample, and it is the width at which `de`'s metric labels were still
  /// wrapping to three lines in the normal form.
  final compactWidths = <double>[kPopupBelow, 288.0, 330.0, normalAbove - 2];

  /// Same 2.0px tolerance as the #1183 gate, for the same reason: sub-pixel
  /// shaping differences between the mac and ubuntu rasterizers.
  const tolerancePx = 2.0;

  /// The magnitude floor from the criterion above. `ru`'s permanent width bind
  /// sits at 0.973 and `de`'s height bind sat at 0.523, so anything between the
  /// two separates them; 0.95 is that, with room for a rasterizer.
  const scaleFloor = 0.95;

  /// ## Which call sites keep the returned list, and why the rest drop it
  ///
  /// `probeCardOverflow` *intercepts* RenderFlex overflow into this list instead
  /// of failing the test, so a discarded return is a swallowed overflow and needs
  /// a reason (#1318). Every discard in this file is a `pin: CardDensity.normal`
  /// pump *below* the threshold — `normalAbove - 1`, the 191.4px realization, and
  /// the 230/231px scale-floor pair — and those cases exist to show the normal
  /// form is **broken** at those widths, which is what makes 366 a measurement.
  /// Asserting no overflow there would assert the opposite of the group's own
  /// claim.
  ///
  /// Where this card's normal form is production, `dashboard_card_overflow_test`'s
  /// `[normal band]` group sweeps it at 366px across all three tabs and 26
  /// locales, and monotonicity within a form makes that width dominate the wider
  /// ones (see `normalBandCaseFor`).
  Future<List<OverflowIncident>> pumpAt(
    WidgetTester tester, {
    required double cardWidth,
    required String label,
    Locale locale = const Locale('en'),
    CardDensity? pin,
  }) =>
      probeCardOverflow(
        tester,
        cardId: cardId,
        widthCase: CardWidthCase(
          // The screen is held at 1440px while the card width varies, which is
          // the same separation `CardDensityHost` makes: density comes from the
          // constraints the grid hands the card, never from the window.
          screenWidth: 1440,
          cardWidth: cardWidth,
          columnSpan: constraints.minColumns,
          label: label,
        ),
        cardHeightRows: heightRows,
        tabIndex: 0,
        locale: locale,
        density: pin,
      );

  /// Whether [finder]'s box sits inside the box the grid handed the card.
  ///
  /// ## Why not `cardContentViewport`
  ///
  /// AC 6 names that helper, and it is the right instrument for a *scrolling*
  /// card — but this card never scrolls its content in any of its three forms,
  /// and the helper cannot say so. It takes the shorter of exactly two
  /// `SingleChildScrollView`s, assuming one is the pump harness and the other is
  /// `DashboardCardTemplate`'s content. For a tabbed card the template returns
  /// its tab content *directly* (`dashboard_card_template.dart:340`, "charts
  /// need fixed space"), so the second scroll view in the tree is not the
  /// content at all — it is `AppTabs`' own horizontal scroller (`isScrollable:
  /// true`), a 44px strip. Measured: the helper returned 53.0–97.0 while the
  /// gauge occupied 141.5–261.5, i.e. it reported the tab bar. The popup form
  /// has no scroll view of its own either, so the count is 1 there and the
  /// helper's own precondition fires.
  ///
  /// So the frame that means something here is the card's box: everything in a
  /// tab lives inside a fixed `Expanded`, and the popup form inside the same
  /// `SizedBox`. Content taller than that box is a RenderFlex overflow, which
  /// [expectNoOverflow] already reads — but only for the Flex chain. A `Stack`
  /// child, a `Positioned`, or an `OverflowBox` paints outside its parent while
  /// reporting nothing, and the gauge centre *is* a `Stack` child, so this is
  /// the one axis where "fits" and "reported" can disagree — measured as row E
  /// of the ledger above: a paint-only 400px displacement of the gauge kills
  /// seven tests here and leaves both the gate and the readability suite green.
  /// Anchored on
  /// [CardDensityHost] because that is the card's own root in every form —
  /// including a pinned one, where it swaps the scope but keeps the box.
  ///
  /// Vertical containment only: horizontal is what the overflow incidents
  /// report, and the card's width is the axis the threshold is chosen on.
  void expectInsideCardBox(
    WidgetTester tester,
    Finder finder, {
    required String what,
    required String at,
  }) {
    final host = find.byType(CardDensityHost);
    expect(host, findsOneWidget,
        reason: 'the card is not wrapped in a CardDensityHost, so the box the '
            'grid handed it cannot be identified — and without a box, a '
            'containment assertion measured against nothing would pass.');
    final box = tester.getRect(host);
    final rect = tester.getRect(finder);
    expect(
        rect.top >= box.top - tolerancePx &&
            rect.bottom <= box.bottom + tolerancePx,
        isTrue,
        reason: '$what is outside the card at $at: it occupies '
            '${rect.top.toStringAsFixed(1)}–${rect.bottom.toStringAsFixed(1)} '
            'and the card is '
            '${box.top.toStringAsFixed(1)}–${box.bottom.toStringAsFixed(1)}. '
            'This is the failure that overflows nothing and still cannot be '
            'read (#1291 AC 6).');
  }

  void expectNoOverflow(List<OverflowIncident> incidents,
      {required String at}) {
    final significant = incidents.where((i) => i.pixels > tolerancePx).toList();
    expect(significant, isEmpty,
        reason: 'overflowed at $at:\n${significant.join('\n')}');
  }

  /// What the gauge actually gave its centre, and which dimension bound it.
  ///
  /// Derived from the box `AppGauge` hands `centreBuilder` — `RenderFittedBox`'s
  /// own incoming constraints — rather than from `applyPaintTransform`, whose
  /// `getMaxScaleOnAxis()` reported 1.000 for a 69×44 child in a 36×23 box, i.e.
  /// exactly the case this ticket is about. `fb.size / child.size` cannot
  /// attribute it either: `constrainSizeAndAttemptToPreserveAspectRatio` makes
  /// both ratios equal, so neither names the dimension that bound, and `ru`
  /// would read as a height bind no threshold could ever clear.
  ({double scale, bool heightBinds, Size avail, Size child, Size gauge})?
      readCentre(WidgetTester tester) {
    final gauge = find.byType(AppGauge);
    if (gauge.evaluate().isEmpty) return null;

    // Stated rather than assumed, because the instrument is the one thing here
    // that cannot report its own absence: with the `FittedBox` gone, `.first`
    // threw `Bad state: No element` in nine tests — a loud failure that says
    // nothing about legibility. `findsOneWidget` also makes `.first` exact if
    // `AppGauge` ever grows a second one internally.
    final fbFinder =
        find.descendant(of: gauge, matching: find.byType(FittedBox));
    expect(fbFinder, findsOneWidget,
        reason: 'the gauge centre is not wrapped in exactly one FittedBox, so '
            'nothing bounds the score + tier column to the circle it sits in. '
            'That column needs 44px and this card hands it as little as 23px '
            '(#1235), so removing the fit does not make the centre fit — it '
            'makes the overflow silent, because a non-positioned Stack child '
            'clips rather than reports.');
    final fb = tester.renderObject(fbFinder) as RenderFittedBox;
    final avail = fb.constraints.biggest;
    final child = fb.child!.size;
    final sH = avail.height / child.height;
    final sW = avail.width / child.width;
    return (
      // `BoxFit.scaleDown`'s own arithmetic.
      scale: math.min(1.0, math.min(sH, sW)),
      heightBinds: sH < 1.0 - 1e-6 && sH < sW - 1e-6,
      avail: avail,
      child: child,
      gauge: tester.getSize(gauge),
    );
  }

  group('the card declares a threshold, and where', () {
    test('normalAbove is declared and bounded by both realizations', () {
      expect(spec.normalAbove, isNotNull,
          reason: 'without a threshold this card claims it needs no degraded '
              'form, which #1240 recorded and #1291 measured to be false. Every '
              'group below asserts a form the card would no longer select.');

      expect(normalAbove, greaterThan(kPopupBelow),
          reason:
              'a threshold at or below $kPopupBelow leaves no compact band: '
              'every width under it selects popup, so the card drops straight '
              'from whole to one line with nothing in between '
              '(densityForWidth precedence rule 1).');

      // Same inversion `connected_devices` asserts, for the same kind of
      // reason: at 288px the normal form still spends 142px of `de`'s height on
      // metric labels, so this realization has to land in compact for the
      // compact form to be worth declaring.
      expect(normalAbove, greaterThanOrEqualTo(widestRealization),
          reason: 'a threshold below ${widestRealization.toStringAsFixed(1)}px '
              'leaves the widest realization the grid hands out in the normal '
              'form, which is the form #1291 measured as unreadable there.');

      expect(normalAbove, lessThan(desktopCase.cardWidth),
          reason: 'a threshold at or above the ${desktopCase.cardWidth}px '
              'desktop width degrades a card that has room — the compact form '
              'would ship to 1440px screens, dropping a metric row nobody was '
              'short of space for.');
    });
  });

  group('below 200px the card selects its popup form', () {
    final narrowest = narrowCases.first;

    for (final tag in ['en', 'de']) {
      testWidgets('@${narrowest.widthKey}px ($tag)', (tester) async {
        final locale = supportedLocaleFor(tag);
        final l10n = await AppLocalizations.delegate.load(locale);
        final incidents = await pumpAt(
          tester,
          cardWidth: narrowest.cardWidth,
          label: 'min',
          locale: locale,
        );
        expectNoOverflow(incidents, at: '${narrowest.widthKey}px ($tag)');

        expect(find.byType(CardPopupForm), findsOneWidget,
            reason: 'at ${narrowest.cardWidth.toStringAsFixed(1)}px the card '
                'still rendered its gauge and metric row. That width is below '
                '$kPopupBelow and #1291 measured what the centre gets there: '
                '23px of box for a 44px column, i.e. a score at 52% in $tag.');

        // The gauge is gone, not merely smaller. This is what separates popup
        // from compact, and it is the assertion mutation A trips first.
        expect(find.byType(AppGauge), findsNothing,
            reason: 'the popup form is still drawing a 120px gauge, so this is '
                'not the popup form');

        final popup = tester.widget<CardPopupForm>(find.byType(CardPopupForm));
        expect(popup.value, isNotNull,
            reason: 'no popupValue declared, so the card degrades to its own '
                'title. A card that declares a threshold must also declare the '
                'one value the threshold is protecting (#1288 §2.1).');
        expect(popup.value, isNot(l10n.networkHealth),
            reason: 'the popup value is the card title, which the popup form '
                'already shows above it — a 191px card saying '
                '"${l10n.networkHealth}" twice and nothing else is a working '
                'form that says nothing');
        expect(popup.value, matches(RegExp(r'^\d+$')),
            reason: 'the popup value is "${popup.value}", not the score. The '
                'score is the finer reading of the two the gauge centre holds, '
                'and it is the one that stays legible: «Mittelmäßig» and '
                '«Удовлетворительный» would import into the popup exactly the '
                'width problem the popup exists to escape (#1291 AC 3).');
        expect(find.text(popup.value!), findsOneWidget,
            reason: 'the declared value was not painted — declaring it and '
                'showing it are two different things');
        expectInsideCardBox(tester, find.text(popup.value!),
            what: 'the popup value', at: '${narrowest.widthKey}px ($tag)');
      });
    }

    testWidgets('the popup value is the reading the whole form shows',
        (tester) async {
      final narrow = await pumpAt(
        tester,
        cardWidth: narrowest.cardWidth,
        label: 'min',
      );
      expectNoOverflow(narrow, at: '${narrowest.widthKey}px');
      final value =
          tester.widget<CardPopupForm>(find.byType(CardPopupForm)).value!;

      // Re-pumped wide rather than asserted against a fixture-derived number:
      // the claim worth making is that the two forms agree, not that either
      // matches an arithmetic this test would have to duplicate.
      final wide = await pumpAt(
        tester,
        cardWidth: desktopCase.cardWidth,
        label: 'desktop',
      );
      expectNoOverflow(wide, at: '${desktopCase.widthKey}px');
      expect(find.text(value), findsWidgets,
          reason: 'the popup showed "$value" but the whole form does not paint '
              'it anywhere. The degraded form has to be the same reading in '
              'less space, not a different one (#1291 AC 3).');
    });
  });

  group('from 200px to the threshold the compact form returns the height', () {
    // `en` is the control, `de` the worst height bind (0.523), `th` the second
    // (0.795), and `ru` the permanent *width* bind (0.973) that the criterion
    // in the header exists to distinguish from the other three.
    for (final tag in ['en', 'de', 'th', 'ru']) {
      testWidgets('($tag) the gauge is whole and the metric row is not',
          (tester) async {
        final locale = supportedLocaleFor(tag);
        final l10n = await AppLocalizations.delegate.load(locale);

        for (final width in compactWidths) {
          final at = '${width.toStringAsFixed(0)}px ($tag)';
          final incidents = await pumpAt(tester,
              cardWidth: width, label: 'compact', locale: locale);
          expectNoOverflow(incidents, at: at);

          expect(find.byType(CardPopupForm), findsNothing,
              reason: 'at $at the card gave up its gauge entirely. $width is '
                  'at or above $kPopupBelow, so the compact form is what it '
                  'owes the user here — a gauge that fits, not a single line '
                  '(#1291 AC 6).');

          final r = readCentre(tester);
          expect(r, isNotNull, reason: 'no gauge at $at');

          expect(r!.gauge.height, closeTo(120, tolerancePx),
              reason:
                  'the gauge laid out ${r.gauge.height.toStringAsFixed(0)}px '
                  'tall at $at instead of its declared 120px, so something '
                  'above or below it is still eating the column. The metric '
                  'row is the only candidate and it cost 142px in `de` '
                  '(#1291 AC 4).');
          expect(r.gauge.width, closeTo(120, tolerancePx),
              reason: 'the gauge is ${r.gauge.width.toStringAsFixed(0)}px wide '
                  'at $at — the ring is not a ring');

          expect(r.heightBinds, isFalse,
              reason: 'the centre is still height-bound at $at: '
                  '${r.avail.height.toStringAsFixed(0)}px of box for a '
                  '${r.child.height.toStringAsFixed(0)}px column, scale '
                  '${r.scale.toStringAsFixed(3)}. That is #1235\'s defect '
                  'unfixed — the compact form exists to hand this height back '
                  '(#1291 AC 4).');
          expect(r.scale, greaterThan(scaleFloor),
              reason: 'the centre is painted at '
                  '${r.scale.toStringAsFixed(3)} at $at. `ru` sits at 0.973 '
                  'because its tier label is wider than the gauge, which no '
                  'width fixes; anything below $scaleFloor is the height '
                  'defect back (`de` measured 0.523 at 191px).');

          expectInsideCardBox(tester, find.byType(AppGauge),
              what: 'the gauge', at: at);

          // `discards` is the one metric label that is not also a tab label, so
          // it is the unambiguous handle on the row.
          expect(find.text(l10n.discards), findsNothing,
              reason: 'the metric row is still drawn at $at. It costs 165px of '
                  'the card with the gauge, its labels wrap to 6 lines in `de`, '
                  'and every reading in it also lives on the Errors and Loss '
                  'tabs (#1291 AC 4).');
        }
      });
    }

    for (final tag in ['en', 'de']) {
      testWidgets('($tag) the row is dropped whole, not shortened',
          (tester) async {
        final locale = supportedLocaleFor(tag);
        final l10n = await AppLocalizations.delegate.load(locale);
        final labels = [l10n.errors, l10n.discards, l10n.loss];

        // Counted against the whole form rather than asserted absolutely: two
        // of the three metric labels are also tab labels, so "one fewer than
        // the normal form has" is the claim that survives a tab bar change.
        await pumpAt(tester,
            cardWidth: desktopCase.cardWidth, label: 'desktop', locale: locale);
        final whole =
            labels.map((s) => find.text(s).evaluate().length).toList();

        await pumpAt(tester,
            cardWidth: widestRealization, label: 'compact', locale: locale);
        final degraded =
            labels.map((s) => find.text(s).evaluate().length).toList();

        for (var i = 0; i < labels.length; i++) {
          expect(degraded[i], whole[i] - 1,
              reason: 'the compact form kept ${degraded[i]} of the '
                  '${whole[i]} «${labels[i]}» the whole form paints. The row is '
                  'dropped entire — shortening it instead (#1275\'s stacked '
                  '`InfoGrid`) was measured at 0.841 in `de` and caps the gauge '
                  'at 53px in every locale (#1291 AC 4).');
        }
      });
    }
  });

  group('above the threshold the card is whole', () {
    // `da` is here because it is the locale the threshold was derived from:
    // «Forkastninger» is the token that pushed 366 past the scale floor.
    for (final tag in ['en', 'de', 'da']) {
      testWidgets('@${desktopCase.widthKey}px ($tag) everything is back',
          (tester) async {
        final locale = supportedLocaleFor(tag);
        final l10n = await AppLocalizations.delegate.load(locale);
        final at = '${desktopCase.widthKey}px ($tag)';
        final incidents = await pumpAt(
          tester,
          cardWidth: desktopCase.cardWidth,
          label: 'desktop',
          locale: locale,
        );
        expectNoOverflow(incidents, at: at);

        // A degradation that leaks upward is the failure mode a density
        // mechanism has and a fixed layout does not, so what compact sheds is
        // asserted back.
        final discards = find.text(l10n.discards);
        expect(discards, findsOneWidget,
            reason: 'the metric row is missing at $at, so the compact form '
                'leaked past its threshold — a 512px card has room for it');
        expectInsideCardBox(tester, discards, what: 'the metric row', at: at);
        expectInsideCardBox(tester, find.byType(AppGauge),
            what: 'the gauge', at: at);

        final row = find.ancestor(of: discards, matching: find.byType(Row));
        expect(row, findsWidgets, reason: 'the metric row is not a Row at $at');
        for (final label in [l10n.errors, l10n.discards, l10n.loss]) {
          final chip =
              find.descendant(of: row.first, matching: find.text(label));
          expect(chip, findsOneWidget,
              reason:
                  'the «$label» chip is missing from the metric row at $at');
          expect(tester.hasSplitToken(chip.first), isFalse,
              reason: '«$label» is broken inside a word at $at: it needs '
                  '${tester.widestTokenWidth(chip.first).toStringAsFixed(1)}px '
                  'for its widest token and the chip granted '
                  '${tester.paragraphOf(chip.first).size.width.toStringAsFixed(1)}px. '
                  'A metric label is a localized constant, i.e. a bounded '
                  'token, so cutting it is never the right trade (#1289\'s '
                  'rule, #1291 AC 6).');
          expect(tester.isTextClipped(chip.first), isFalse,
              reason: '«$label» is ellipsized at $at');
        }

        final r = readCentre(tester);
        expect(r, isNotNull, reason: 'no gauge at $at');
        expect(r!.heightBinds, isFalse,
            reason: 'the centre is height-bound at $at, on a card with 512px '
                'of width and three rows of height — the metric row is taking '
                'more than the whole form can pay for');
        expect(r.scale, greaterThan(scaleFloor),
            reason: 'the centre is painted at ${r.scale.toStringAsFixed(3)} at '
                '$at');
      });
    }
  });

  group('why the threshold is ${normalAbove.toStringAsFixed(0)}', () {
    // The two pinned cases in the file, and the only ones that record a
    // *failure* as the expected outcome: they are what make 366 a measurement
    // rather than a preference.

    testWidgets(
        'pinned normal @${(normalAbove - 1).toStringAsFixed(0)}px (da) '
        'still breaks a label mid-word', (tester) async {
      const tag = 'da';
      final locale = supportedLocaleFor(tag);
      final l10n = await AppLocalizations.delegate.load(locale);
      await pumpAt(
        tester,
        cardWidth: normalAbove - 1,
        label: 'normal-pinned',
        locale: locale,
        pin: CardDensity.normal,
      );

      final chip = find.text(l10n.discards);
      expect(chip, findsOneWidget);
      expect(tester.hasSplitToken(chip.first), isTrue,
          reason: 'the normal form seated «${l10n.discards}» whole at '
              '${(normalAbove - 1).toStringAsFixed(0)}px, so the token floor '
              'moved and the threshold is now higher than the measurement '
              'supports. Re-run the pinned-normal sweep (#1291 AC 1) and bring '
              'normalAbove down with it rather than degrading a form that '
              'reads.');
    });

    testWidgets(
        'pinned normal @${narrowCases.first.widthKey}px (de) paints the centre '
        'at half size', (tester) async {
      await pumpAt(
        tester,
        cardWidth: narrowCases.first.cardWidth,
        label: 'normal-pinned',
        locale: supportedLocaleFor('de'),
        pin: CardDensity.normal,
      );

      final r = readCentre(tester);
      expect(r, isNotNull);
      expect(r!.heightBinds, isTrue,
          reason: 'the normal form gave its centre the full height at '
              '${narrowCases.first.cardWidth.toStringAsFixed(1)}px in `de`, so '
              'the compact form is no longer buying anything at the narrowest '
              'realization it was declared for. That is #1235\'s coordinate; if '
              'it is gone, re-measure the scale floor (#1291 AC 1) before '
              'lowering the threshold.');
      expect(r.scale, lessThan(scaleFloor),
          reason: 'the centre scales ${r.scale.toStringAsFixed(3)} here, above '
              'the $scaleFloor floor the compact cases assert, so the two '
              'groups no longer measure different things. The ticket named '
              '0.52: ${r.avail.height.toStringAsFixed(0)}px of box for a '
              '${r.child.height.toStringAsFixed(0)}px column.');
    });

    // The scale floor, to the pixel, and the reason it is *not* the threshold.
    // 231 is 135px below the token floor, so a threshold set here would return
    // the gauge its height and still ship «Forkast‑ / ninger» underneath it —
    // the case §2.6f point 1 calls a form that has not earned selection.
    testWidgets('pinned normal (de) is height-bound at 230px and not at 231px',
        (tester) async {
      final readings = <double, bool>{};
      for (final width in [230.0, 231.0]) {
        await pumpAt(
          tester,
          cardWidth: width,
          label: 'normal-pinned',
          locale: supportedLocaleFor('de'),
          pin: CardDensity.normal,
        );
        final r = readCentre(tester);
        expect(r, isNotNull, reason: 'no gauge at ${width}px');
        readings[width] = r!.heightBinds;
      }

      expect(readings[230.0], isTrue,
          reason: 'the scale floor moved below 230px, so the sweep behind '
              '#1291 AC 1 no longer describes this card');
      expect(readings[231.0], isFalse,
          reason: 'the centre is still height-bound at 231px, so the scale '
              'floor moved *up* — re-measure it, and check it has not passed '
              'the ${normalAbove.toStringAsFixed(0)}px token floor that '
              'currently sets the threshold');
    });

    testWidgets(
        '@${normalAbove.toStringAsFixed(0)}px (da) the card selects normal and '
        'holds the label', (tester) async {
      const tag = 'da';
      final locale = supportedLocaleFor(tag);
      final l10n = await AppLocalizations.delegate.load(locale);
      final at = '${normalAbove.toStringAsFixed(0)}px ($tag)';
      final incidents = await pumpAt(
        tester,
        cardWidth: normalAbove,
        label: 'threshold',
        locale: locale,
      );
      expectNoOverflow(incidents, at: at);

      // The width the threshold names, unpinned: one pixel of card width is the
      // difference between the two cases, and it has to be the *selection* that
      // changes, not just the layout.
      final chip = find.text(l10n.discards);
      expect(chip, findsOneWidget,
          reason: 'the card is still in its compact form at exactly '
              'normalAbove — densityForWidth is inclusive at the boundary '
              '(width >= normalAbove selects normal)');
      expect(tester.hasSplitToken(chip.first), isFalse,
          reason: '«${l10n.discards}» is broken inside a word at $at, the '
              'width declared as the one where the normal form earns '
              'selection. Either the threshold is a pixel low or the chip lost '
              'room to something else (#1291 AC 6).');
    });
  });
}
