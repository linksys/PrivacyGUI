@Tags(['dashboard-card'])
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
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';

import '../../../util/app_test_fonts.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';

/// The boxes #1299 lets a user ask for, swept at the geometry the pick produces
/// (AC 11).
///
/// Every existing sweep pumps a width the *grid* chose. #1299 inverts that: the
/// user chooses the form and the form chooses the box, so two footprints now exist
/// that no drag could ever have produced and no file was measuring.
///
/// ## The two new geometries, and why they are not dominated
///
/// **A forced popup tile is 2 columns by 1 row.** Its narrowest realization is
/// 122.3px — 69px narrower than the 191.4px 3-column floor, which was the
/// narrowest width any card had ever been pumped at — and 120px tall against the
/// 2-4 rows every other sweep gives it. Both bounds move the wrong way at once,
/// and `dashboard_card_popup_overflow_test.dart` cannot cover it: that file pumps
/// each card at *its own* narrowest realization, which is a width the card's
/// `minColumns` permits. The pick overrides `minColumns`, so the box is smaller
/// than the spec would allow.
///
/// It also reaches cards that file skips entirely. Nine of the eighteen are
/// floored above [kPopupBelow] by their own `minColumns`, so no width selects
/// popup for them and that sweep leaves them out — correctly, then. A pick is not
/// a width, so eight of those nine (all but `stats_panel`, which has no popup
/// path) can now render a popup form, and this is the first file to render one.
///
/// **A forced compact card cannot go below 4 columns**, which realizes at 260.5px.
/// The #1183 gate pumps only each spec's min / preferred / max spans — 3, 6 and 8
/// for all six compact consumers — so the span this ticket makes their floor is
/// pumped by nothing. And for two of the six the automatic rule would not select
/// compact there at all: 260.5px is above `lan_info`'s 250 and `time_settings`'
/// 256, so those two render their compact form at that width only because the user
/// asked, which is exactly the "width the automatic rule would not select" the AC
/// names. The inventory below pins which two, rather than leaving it as prose.
///
/// ## What is deliberately not swept
///
/// **The mobile popup realization.** On the 4-column grid popup owns the height
/// only and the #1293 lock keeps the card full width, so the tile there is 288px
/// by 1 row: wider than the collapse case at the same height. Overflow is
/// monotonic in width, so it is strictly dominated — and `is dominated by the
/// collapse case` pins that claim against the geometry rather than asserting it in
/// a comment, so a change to either rule surfaces here instead of silently
/// dropping coverage.
///
/// **Compact above `normalAbove`.** A compact card can now be forced at any width
/// up to its 8-column maximum. Those widths are wider than its floor at the same
/// height, so they are dominated for overflow the same way. That the *form* still
/// renders there — decision 3 on the issue, a chosen density is not re-promoted by
/// widening — is a question about which form is selected rather than whether it
/// fits, and it is asserted at the `CardDensityHost` seam in
/// `test/page/dashboard/views/card_form_control_test.dart`.
///
/// **Twenty-three of the twenty-six locales.** The popup and compact forms are
/// already swept in all 26 at the widths the grid produces; the dimension this
/// file adds is the geometry and the card list, not the string table. So it takes
/// the same three the popup file's second pump takes, for the same reason: English
/// as the baseline, German for the longest Latin compounds, Traditional Chinese for
/// the widest glyphs.
///
/// ## No allowlist
///
/// `known_overflows.json` baselines the normal form's inherited debt at widths the
/// grid chose. Nothing here is inherited — these boxes did not exist before this
/// ticket — so a failure is this ticket's regression and there is nothing to
/// grandfather. AC 10 is the other half of that: the fixture is unchanged, and the
/// #1183 gate stays green.
///
/// ## Mutation table
///
/// The sweep's own assertions are already ratcheted — they fail on a real overflow,
/// which is what found the skeleton defect in the first place. So the rows are the
/// **fix** this file forced, applied to `card_skeleton.dart` and run against this
/// file.
///
/// | # | mutation | killed by |
/// |---|---|---|
/// | 1 | remove the popup branch (the pre-fix skeleton) | 10 — 4 variant tests + `connected_devices` and `wifi_performance` × 3 locales |
/// | 2 | the popup branch skips one variant (`_variant != list`) | 4 — the `list` variant and `connected_devices` × 3 |
/// | 3 | `_buildPopup` drops the `Flexible` around the value line | **survived** — equivalent today |
///
/// Row 1 is the measurement behind the fix: 94.0px over on `connected_devices`,
/// 6.0px on `wifi_performance`, and 4 of the 6 variants over on their own. Row 2 is
/// there because row 1 alone would also pass with the branch applied to a single
/// variant — the popup form is card-independent, and so is its placeholder.
///
/// Row 3 survives because the popup skeleton's content is 48px inside an 86px box,
/// so nothing is ever asked to shrink. The `Flexible` is kept anyway: it mirrors
/// `CardPopupForm`'s own shape, which is what keeps the placeholder and the form it
/// resolves into from jumping. Recorded rather than removed, and recorded rather
/// than left to look covered.

/// Locale identity, matching the other sweeps' key so test names line up.
String _localeTag(Locale l) => l.countryCode == null || l.countryCode!.isEmpty
    ? l.languageCode
    : '${l.languageCode}_${l.countryCode}';

/// Same tolerance the #1183 gate uses, for the same reason: sub-pixel shaping
/// differences between the mac and ubuntu rasterizers.
const double _tolerancePx = 2.0;

/// The three locales that bound the text. See the header.
const List<Locale> _locales = [
  Locale('en'),
  Locale('de'),
  Locale('zh', 'TW'),
];

/// The box a picked form collapses a card to, as a width case the probe accepts.
///
/// Derived from [UspWidgetSpecs.popupColumns] / [UspWidgetSpecs.compactMinColumns]
/// through the same enumeration the gate uses, so the widths here move with the
/// constants and with the grid rather than being restated. Null only when a
/// `MIN_SCREEN` filter has excluded the whole range, matching [widthCasesFor].
CardWidthCase? _caseForSpan(int span, String label) {
  final narrowest = narrowestRealizationOf(span);
  if (narrowest == null) return null;
  return CardWidthCase(
    screenWidth: narrowest.screenWidth,
    cardWidth: narrowest.cardWidth,
    columnSpan: span,
    label: label,
  );
}

/// The height a forced compact card is floored at, in rows.
///
/// `max` of the two, because [UspWidgetSpecs.compactMinHeightRows] is a floor
/// rather than a pin and every compact consumer already declares 2 or 3. Pumping
/// the constant alone would measure a shorter card than the floor actually permits
/// for four of the six.
int _compactFloorRows(WidgetSpec spec) => math.max(
      spec.getConstraints(DisplayMode.normal).minHeightRows,
      UspWidgetSpecs.compactMinHeightRows,
    );

/// The cards a user can pick [density] for.
List<WidgetSpec> _specsOffering(CardDensity density) => UspWidgetSpecs.all
    .where((s) => UspWidgetSpecs.selectableForms(s.id).contains(density))
    .toList();

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  final popupCase = _caseForSpan(UspWidgetSpecs.popupColumns, 'popup')!;
  final compactCase =
      _caseForSpan(UspWidgetSpecs.compactMinColumns, 'compact floor')!;

  group('what this file sweeps', () {
    test('is every card that can be picked into popup', () {
      // 17 of the 18: `stats_panel` is not built through DashboardCardTemplate,
      // so it has no popup form to force. An id disappearing from this list has
      // silently lost coverage here; the list appearing shorter than
      // `UspWidgetSpecs.all` minus one means a card stopped offering the form.
      expect(
        _specsOffering(CardDensity.popup).map((s) => s.id).toList(),
        UspWidgetSpecs.all
            .map((s) => s.id)
            .where((id) => !UspWidgetSpecs.cardsWithoutPopupForm.contains(id))
            .toList(),
      );
    });

    test('at a box narrower and shorter than any width the grid produces', () {
      // The argument that this sweep is not dominated by the existing ones. If a
      // spec ever floors itself below two columns this stops being true, and the
      // popup sweep would then already be covering this width.
      final narrowestGridWidth = UspWidgetSpecs.all
          .map(widthCasesFor)
          .where((cases) => cases.isNotEmpty)
          .map((cases) => cases.first.cardWidth)
          .reduce(math.min);

      expect(popupCase.cardWidth, lessThan(narrowestGridWidth),
          reason: 'a picked popup tile is ${popupCase.widthKey}px against the '
              'grid\'s narrowest ${narrowestGridWidth.toStringAsFixed(1)}px');
      expect(
        UspWidgetSpecs.popupHeightRows,
        lessThanOrEqualTo(UspWidgetSpecs.all
            .map((s) => s.getConstraints(DisplayMode.normal).minHeightRows)
            .reduce(math.min)),
        reason: 'and no taller than the shortest card the grid places',
      );
    });

    test('and the mobile popup rule is dominated by the collapse case', () {
      // The skip justification for the 4-column grid, pinned. Popup takes the
      // height there and #1293's lock keeps the width, so the tile is full width
      // at the same one row. Wider at equal height is dominated, because overflow
      // is monotonic in width — the premise every "one width per span" claim in
      // this suite rests on.
      const mobileScreen = kMinSupportedScreenWidth;
      final mobileColumns = gridColumnsForWidth(mobileScreen);
      expect(mobileColumns, UspLayoutEnvelope.mobileSlotCount);
      final mobileWidth = cardWidthAt(mobileScreen, mobileColumns);

      expect(mobileWidth, greaterThan(popupCase.cardWidth),
          reason: 'if the mobile rule ever produces a narrower tile than the '
              'collapse, it is the worst case and this file must sweep it '
              'instead');
    });

    test('compact\'s new floor is a span the gate never pumps', () {
      for (final spec in _specsOffering(CardDensity.compact)) {
        expect(
          widthCasesFor(spec).map((c) => c.columnSpan),
          isNot(contains(UspWidgetSpecs.compactMinColumns)),
          reason: '${spec.id}: the gate pumps min/preferred/max spans, and '
              '#1299 makes ${UspWidgetSpecs.compactMinColumns} columns the '
              'floor of the compact form. If the spec now declares that span, '
              'the gate covers this width and the sweep below is redundant',
        );
      }
    });

    test('and for two of the six the rule there would say normal', () {
      // Which cards make this file's compact sweep *forced* rather than merely
      // un-pumped. Named rather than counted: the two are the cards whose
      // threshold sits below the 4-column realization, and a spec edit that moves
      // a threshold across it changes the meaning of the sweep.
      final ruleSaysNormal = _specsOffering(CardDensity.compact)
          .where((s) =>
              densityForWidth(
                  width: compactCase.cardWidth, normalAbove: s.normalAbove) ==
              CardDensity.normal)
          .map((s) => s.id)
          .toList();

      expect(ruleSaysNormal, ['lan_info', 'time_settings'],
          reason: 'at ${compactCase.widthKey}px these are the cards production '
              'would render in their normal form, so a pick is the only way to '
              'see their compact form at this width — AC 11\'s "a width the '
              'automatic rule would not select". The other four are already in '
              'their compact band here, and are swept for the geometry alone');
    });
  });

  group('a forced popup tile', () {
    for (final spec in _specsOffering(CardDensity.popup)) {
      for (final locale in _locales) {
        final tag = _localeTag(locale);
        testWidgets(
            '${spec.id} is clean at ${popupCase.widthKey}x'
            '${UspWidgetSpecs.popupHeightRows} ($tag)', (tester) async {
          final incidents = await probeCardOverflow(
            tester,
            cardId: spec.id,
            widthCase: popupCase,
            cardHeightRows: UspWidgetSpecs.popupHeightRows,
            tabIndex: 0,
            locale: locale,
            density: CardDensity.popup,
          );

          expect(
            find.byType(CardPopupForm),
            findsOneWidget,
            reason: '${spec.id} did not render the popup form. Eight of these '
                'cards had no reachable popup form before #1299 — one that '
                'bypasses the template would keep its full form inside a '
                '${popupCase.widthKey}px box, which is the overflow the parent '
                'epic exists to prevent',
          );

          final significant =
              incidents.where((i) => i.pixels > _tolerancePx).toList();
          expect(
            significant,
            isEmpty,
            reason: '${spec.id} popup form overflowed the picked box '
                '($tag):\n${significant.join('\n')}',
          );
        });
      }
    }
  });

  group('the loading state at the picked box', () {
    // Found by the sweep above, and the reason this group exists rather than
    // being covered by it: a card only renders its skeleton in the frames before
    // its data arrives, and the shared fixture resolves most cards' data
    // immediately. Only `connected_devices` and `wifi_performance` had a loading
    // frame to catch (94px and 6px over), so 13 of the 15 cards that return a
    // skeleton were covered by fixture timing rather than by the test. On a cold
    // boot every one of them has that frame.
    //
    // So the variants are pumped directly, one test each: the input is a
    // [CardSkeleton] under a popup scope, which is a fact about six widgets and
    // has nothing to do with locale or card data. The two card cases above are
    // what prove production puts the skeleton under that scope at all.
    //
    // `rows` is the largest count production asks each variant for, since the
    // pre-fix overflow grew with it.
    const variants = <String, CardSkeleton>{
      'stats': CardSkeleton.stats(),
      'info': CardSkeleton.info(rows: 5),
      'list': CardSkeleton.list(rows: 4),
      'chart': CardSkeleton.chart(),
      'topology': CardSkeleton.topology(),
      'status': CardSkeleton.status(),
    };

    variants.forEach((name, skeleton) {
      testWidgets('$name fits the ${popupCase.widthKey}px tile',
          (tester) async {
        final incidents = await probeCardOverflow(
          tester,
          // The id only keys the harness's geometry and tab pinning; the widget
          // under test is the override. The scope is built by hand rather than
          // through `density:` because that parameter drives
          // `cardDensityOverrideProvider`, which only the factory-built
          // `CardDensityHost` reads — and a `cardOverride` replaces the factory.
          cardId: 'connected_devices',
          cardOverride: CardDensityScope(
            density: CardDensity.popup,
            child: skeleton,
          ),
          widthCase: popupCase,
          cardHeightRows: UspWidgetSpecs.popupHeightRows,
          tabIndex: 0,
          locale: const Locale('en'),
        );

        final significant =
            incidents.where((i) => i.pixels > _tolerancePx).toList();
        expect(
          significant,
          isEmpty,
          reason: 'the $name skeleton overflowed the picked box:\n'
              '${significant.join('\n')}',
        );
      });
    });
  });

  group('a forced compact card at its floor', () {
    for (final spec in _specsOffering(CardDensity.compact)) {
      final rows = _compactFloorRows(spec);
      for (final locale in _locales) {
        final tag = _localeTag(locale);
        testWidgets(
            '${spec.id} is clean at ${compactCase.widthKey}x$rows ($tag)',
            (tester) async {
          final incidents = await probeCardOverflow(
            tester,
            cardId: spec.id,
            widthCase: compactCase,
            cardHeightRows: rows,
            tabIndex: 0,
            locale: locale,
            density: CardDensity.compact,
          );

          // The compact form has no widget of its own to find — each of the six
          // cards arranges its own — so the structural claim available here is
          // that the card still went through the template that reads the density.
          expect(
            find.byType(DashboardCardTemplate),
            findsOneWidget,
            reason: '${spec.id} must render through the card template; the '
                'density scope it reads is what selects the compact form',
          );
          expect(
            find.byType(CardPopupForm),
            findsNothing,
            reason:
                '${spec.id}: compact is the middle band. Falling through to '
                'the popup form would satisfy every overflow assertion here '
                'while losing the card\'s content',
          );

          final significant =
              incidents.where((i) => i.pixels > _tolerancePx).toList();
          expect(
            significant,
            isEmpty,
            reason: '${spec.id} compact form overflowed at its floor '
                '($tag):\n${significant.join('\n')}',
          );
        });
      }
    }
  });
}
