@Tags(['dashboard-card'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';

/// Firewall Overview readability (#1230).
///
/// ## Why this file exists alongside the #1183 gate
///
/// #1230 clears 21 coordinates two ways the gate cannot audit, both of which are
/// *removals*:
///
///   - The three rule metrics stop sitting three across once the card is too
///     narrow for that, and stack into full-width rows instead. The gate only
///     knows whether a row fits; three tiles of one character per line fit
///     perfectly (23.1px of text each at the narrowest realization, `ru` taking
///     8 lines to render one label).
///   - The donut and the protocol bar chart are **not drawn at all** when the
///     slot left for them cannot hold one. Absent content never overflows, so
///     the gate rewards deleting a chart exactly as much as fixing it — a
///     threshold accidentally set above the card's shipped height would leave the
///     gate green and the card empty. Nothing in `known_overflows.json` can
///     express "the picture is still there at 4 rows".
///
/// So each group below asserts on the rendered tree. Each was run against a
/// mutation of the code it guards, and each fired:
///
///   | mutation                                       | what failed                                                  |
///   |------------------------------------------------|--------------------------------------------------------------|
///   | `_kMetricsSideBySideMinWidth` 328 → 0 (i.e. the pre-#1230 card) | 33: shredded text (26 — every locale), three across @min and @preferred (2), footer + donut + ring + legend @min (5); 10 of the 33 trip `pumpAt`'s overflow first, by +7px to +26px |
///   | `_kMetricsSideBySideMinWidth` 328 → 600        | three across @desktop (1)                                    |
///   | `_kProtocolChartMinHeight` 70 → 200            | chart drawn @shipped height (3)                              |
///   | `_kDonutMinRingThickness` 10 → 60              | donut drawn @shipped height (3), ring fits its box (3)        |
///   | `sectionRadius:` → ui_kit's default 40         | ring fits its box (3)                                        |
///   | `_StackedMetrics` padding `sm` → block default | 12: `pumpAt` overflow @min in 6 locales (+3px `fi` to +7px `ru`, 10 tests), donut starved out even @shipped height (2) |
///   | stacked label `maxLines` 2 → 1                 | shredded text (5 — `es`, `es-AR`, `fi`, `nb`, `ru`)           |
///
/// Five of those seven leave the #1183 gate green while the card loses a chart
/// (2, 3, 4), draws a donut 40px wider than its box (5), or clips five locales'
/// labels mid-glyph (7) — clipping and absence are not overflow. Only 1 and 6
/// report an overflow, and 1 is simply the pre-#1230 card.
///
/// Overflow itself is the gate's job — both `firewall_overview` keys are gone
/// from `known_overflows.json` — with one exception, in `pumpAt`: the gate pumps
/// `minHeightRows` only, and at that height both #1230 sites are suppressed, so
/// the height where they actually render would otherwise be measured by nothing.
///
/// Tagged `dashboard-card` so it gates PRs: `run_tests.sh` excludes
/// `golden||loc||ui`, so a `ui`-tagged test here would block nothing.
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is one square em, so
    // what does and does not fit — and therefore what ellipsizes — is fiction.
    await loadAppFonts();
  });

  const cardId = 'firewall_overview';
  final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == cardId);
  final constraints = spec.getConstraints(DisplayMode.normal);

  /// The height the gate pumps: the card's declared minimum. #1230 keeps this at
  /// 3 rows rather than raising it (ticket AC 4), so this is the height the
  /// suppression thresholds actually fire at.
  final minRows = constraints.minHeightRows;

  /// The height the dashboard actually gives the card — `HeightStrategy.strict(4)`
  /// — read from the spec so this test follows the card if the strategy changes.
  final shippedRows = constraints.getPreferredHeightCells();

  /// The width cases the gate measures, narrowest first. Sourced from the same
  /// helper the gate uses, so this test cannot drift from the enforced widths.
  final narrowCases = widthCasesFor(spec);
  final narrowest =
      narrowCases.reduce((a, b) => a.cardWidth <= b.cardWidth ? a : b);

  /// A mainstream desktop realization — 1440px screen, the card's preferred span.
  final desktopCase = CardWidthCase(
    screenWidth: 1440,
    cardWidth: cardWidthAt(1440, constraints.preferredColumns),
    columnSpan: constraints.preferredColumns,
    label: 'desktop',
  );

  /// The #1183 gate's overflow tolerance, mirrored so the two agree on what
  /// counts. Sub-pixel shaping differences between local macOS and CI are below
  /// it; anything above is a real overflow.
  const gateTolerancePx = 2.0;

  /// Pumps the card once, as the gate does — one pump, real fonts — and fails on
  /// any overflow the gate would report.
  ///
  /// That last part is not redundant with the gate: the gate only ever pumps
  /// `minHeightRows`, and the shipped height is the only one where the donut's
  /// caption and fl_chart's axis strip are built at all. Without this, the two
  /// #1230 sites are overflow-checked only at the height where the content they
  /// live in is absent.
  Future<void> pumpAt(
    WidgetTester tester, {
    required CardWidthCase widthCase,
    required int rows,
    required int tabIndex,
    required Locale locale,
  }) async {
    final incidents = await probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: widthCase,
      cardHeightRows: rows,
      tabIndex: tabIndex,
      locale: locale,
    );
    final significant =
        incidents.where((i) => i.pixels > gateTolerancePx).toList();
    expect(
      significant.map((i) => '+${i.pixels}px ${i.side}').toList(),
      isEmpty,
      reason: '$cardId overflowed at ${widthCase.widthKey}px / $rows rows / '
          'tab $tabIndex / ${locale.toLanguageTag()}. The gate pumps '
          '$minRows rows only, so at $shippedRows rows this assertion is the '
          'only thing measuring it (#1230).',
    );
  }

  /// The three rule metrics, in order. Both arrangements render each metric as a
  /// [LayoutBlock] — the stacked rows are blocks, and so is `InfoGrid`'s tile —
  /// so their rectangles say which arrangement is on screen without either
  /// private widget having to be reachable from here.
  List<Rect> metricRects(WidgetTester tester) {
    final finder = find.byType(LayoutBlock);
    final rects = [
      for (var i = 0; i < finder.evaluate().length; i++)
        tester.getRect(finder.at(i)),
    ];
    expect(rects.length, 3,
        reason: 'expected exactly the three rule metrics (rules, port '
            'forwarding, DMZ); found ${rects.length}');
    return rects;
  }

  /// Bottom edge of the card's content area. The template gives tab content a
  /// fixed `Expanded` and does **not** scroll it, so content that does not fit
  /// is laid out over the footer instead of being clipped — visible here, and
  /// invisible to a width-only measurement.
  ///
  /// Measured as the top of the footer's own `Padding`, not the top of its
  /// divider: the footer holds the rule 12px below where the content ends, and
  /// borrowing those 12px would hide exactly the amount of growth this is meant
  /// to catch.
  double contentBottom(WidgetTester tester) {
    final divider = find.byType(AppDivider);
    expect(divider, findsWidgets,
        reason: 'the detail footer draws an AppDivider above its link; without '
            'it there is no way to locate the footer from here');
    final footer =
        find.ancestor(of: divider.first, matching: find.byType(Padding)).first;
    return tester.getRect(footer).top;
  }

  /// Every [Text] under the i-th metric, in tree order: label first, value
  /// second, in both arrangements.
  Finder metricTexts(int index) => find.descendant(
        of: find.byType(LayoutBlock).at(index),
        matching: find.byType(Text),
      );

  /// The legend's `target: count` entries.
  Finder legendEntries() =>
      find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains(':'),
          description: 'legend entry');

  /// The legend row itself, found through an entry rather than by taking the
  /// first [Wrap] in the tree — the tab bar is a `Wrap` too, and measuring it
  /// instead would make every "the legend fits" assertion pass against a row
  /// that is nowhere near the bottom of the card. `find.ancestor` returns
  /// ancestors innermost-first, so the first match is the legend's own `Wrap`.
  Rect legendRect(WidgetTester tester) {
    final entries = legendEntries();
    expect(entries, findsWidgets, reason: 'the legend rendered no entries');
    final wrap =
        find.ancestor(of: entries.first, matching: find.byType(Wrap)).first;
    return tester.getRect(wrap);
  }

  group('the rule metrics stack where three across cannot read (#1230)', () {
    for (final wc in narrowCases) {
      testWidgets('@${wc.label} ${wc.widthKey}px the three metrics stack',
          (tester) async {
        await pumpAt(tester,
            widthCase: wc,
            rows: minRows,
            tabIndex: 0,
            locale: const Locale('ru'));

        final metrics = metricRects(tester);
        for (var i = 1; i < metrics.length; i++) {
          expect(
            metrics[i].top,
            greaterThanOrEqualTo(metrics[i - 1].bottom),
            reason: 'at ${wc.widthKey}px three across leaves each label 23.1px '
                'of text — one character per line. Metric $i must start below '
                'metric ${i - 1}, not beside it (#1230).',
          );
        }
        for (final m in metrics) {
          expect(m.width, closeTo(metrics.first.width, 0.01),
              reason: 'stacked metrics each take the full content width');
        }
      });
    }
  });

  group('three across survives where it fits (#1230)', () {
    // Stacking is a narrow-width degradation, not a redesign: the designed grid
    // is what a mainstream desktop card still shows. A threshold raised past the
    // desktop realization would fail here.
    testWidgets('@desktop ${desktopCase.widthKey}px the metrics share a row',
        (tester) async {
      await pumpAt(tester,
          widthCase: desktopCase,
          rows: shippedRows,
          tabIndex: 0,
          locale: const Locale('ru'));

      final metrics = metricRects(tester);
      for (var i = 1; i < metrics.length; i++) {
        expect(metrics[i].top, closeTo(metrics.first.top, 0.01),
            reason: 'at ${desktopCase.widthKey}px all three metrics must still '
                'sit on one row');
        expect(metrics[i].left, greaterThan(metrics[i - 1].right),
            reason: 'metric $i must start after metric ${i - 1} ends');
      }
    });
  });

  group('no metric text is shredded at the narrowest width (#1230)', () {
    // The AC that the gate cannot express: "legible at 191px, not merely
    // overflow-free — no one-character-per-line label stacks, no clipped
    // mid-glyph text". Every shipped locale, because this is a claim about
    // localized strings and a sample would only prove it for the samples —
    // measured at the narrowest realization alone, since the budget grows with
    // the card and a wider case cannot fail where this one passes.
    //
    // Two independent failures, so two assertions:
    //
    //   - **Line count.** Re-laid out with a `TextPainter` at exactly the room
    //     the widget got, with no line cap, so it reports the lines the text
    //     *wants* rather than the lines it was allowed. This is what catches the
    //     unreadable case: three across gives each label 23.1px, which is one
    //     character per line — `ru` wants 8 lines — while `InfoGrid`'s tile sets
    //     no `maxLines` at all, so nothing is formally truncated and every
    //     ellipsis-based check passes. Stacked, the budget is 111.4-127.6px
    //     against a widest label of 143.2px (`ru`), so the worst case is a
    //     second line.
    //   - **Ellipsis.** The stacked row caps the label at two lines, which is
    //     only safe while two lines are enough; capping it at one would clip
    //     `ru`/`fi`/`nb`/`es` mid-glyph, and a clip is not an overflow.
    const maxLabelLines = 2;

    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      testWidgets('@${narrowest.widthKey}px $tag renders label and value whole',
          (tester) async {
        await pumpAt(tester,
            widthCase: narrowest, rows: minRows, tabIndex: 0, locale: locale);

        for (var i = 0; i < 3; i++) {
          final texts = metricTexts(i);
          expect(texts, findsNWidgets(2),
              reason: 'metric $i must render exactly a label and a value');
          for (var t = 0; t < 2; t++) {
            final paragraph = tester.renderObject<RenderParagraph>(texts.at(t));
            final content = tester.widget<Text>(texts.at(t)).data ?? '';
            final room = paragraph.size.width;

            final wanted = TextPainter(
              text: TextSpan(text: content, style: paragraph.text.style),
              textDirection: paragraph.textDirection,
              textScaler: paragraph.textScaler,
              locale: locale,
            )..layout(maxWidth: room);
            final lines = wanted.computeLineMetrics().length;
            wanted.dispose();

            expect(
              lines,
              lessThanOrEqualTo(maxLabelLines),
              reason: '"$content" needs $lines lines in the '
                  '${room.toStringAsFixed(1)}px it is given at '
                  '${narrowest.widthKey}px. Beyond $maxLabelLines the text is a '
                  'column of fragments, not a label — at this width the metrics '
                  'must be stacked, which gives every shipped locale a budget '
                  'it can wrap into (#1230).',
            );
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: '"$content" is ellipsized at ${narrowest.widthKey}px '
                  '(${room.toStringAsFixed(1)}px of room, $lines lines wanted). '
                  'Stacked labels must be allowed the lines they need rather '
                  'than clipped mid-glyph (#1230).',
            );
          }
        }
      });
    }
  });

  group('the height guards give the picture back at the shipped height (#1230)',
      () {
    // Suppressing a chart is how #1230 clears both the donut's overflow and
    // fl_chart's bottom-axis strip, and suppression is exactly what the gate
    // cannot see: an absent chart overflows nothing. These are the assertions
    // that stop the fix from degenerating into "delete the charts".
    for (final wc in [...narrowCases, desktopCase]) {
      testWidgets(
          '@${wc.label} ${wc.widthKey}px $shippedRows rows draws the '
          'donut and the bar chart', (tester) async {
        await pumpAt(tester,
            widthCase: wc,
            rows: shippedRows,
            tabIndex: 0,
            locale: const Locale('ru'));
        expect(find.byType(AppPieChart), findsOneWidget,
            reason: 'at the height the dashboard actually gives this card '
                '($shippedRows rows) the target-distribution donut must be '
                'drawn — the ring guard is for slots that cannot hold one, not '
                'for the shipped card (#1230). `ru` is the locale to assert on: '
                'measured across all 26, its two-line label makes it the only '
                'one under 157px here, and the box it gets at the narrowest '
                'width is 153px against a 140px floor. 13px is the whole '
                'margin, so anything that grows the metrics or the legend by '
                'more than that deletes the donut silently');
      });

      testWidgets(
          '@${wc.label} ${wc.widthKey}px $shippedRows rows draws the '
          'protocol chart', (tester) async {
        await pumpAt(tester,
            widthCase: wc,
            rows: shippedRows,
            tabIndex: 1,
            locale: const Locale('ru'));
        expect(find.byType(AppBarChart), findsOneWidget,
            reason: 'at $shippedRows rows the Ports tab must still draw its '
                'protocol distribution chart; the height guard exists only to '
                'keep fl_chart from painting a 22px axis strip into a 12px slot '
                '(#1230)');
      });
    }

    for (final wc in narrowCases) {
      testWidgets(
          '@${wc.label} ${wc.widthKey}px $minRows rows suppresses the donut',
          (tester) async {
        await pumpAt(tester,
            widthCase: wc,
            rows: minRows,
            tabIndex: 0,
            locale: const Locale('ru'));
        expect(find.byType(AppPieChart), findsNothing,
            reason: 'at the declared minimum height the donut slot measures '
                '17-37px at 191px and 52-57px at 288px across the 26 locales, '
                'against the 140px this theme needs for a ring at all — a '
                'clipped arc and a caption that does not fit, so nothing is '
                'drawn (#1230)');
      });

      testWidgets(
          '@${wc.label} ${wc.widthKey}px $minRows rows suppresses the chart',
          (tester) async {
        await pumpAt(tester,
            widthCase: wc,
            rows: minRows,
            tabIndex: 1,
            locale: const Locale('ru'));
        expect(find.byType(AppBarChart), findsNothing,
            reason: 'at the declared minimum height the chart slot is 12-37px, '
                'below the 22px fl_chart spends on the bottom axis alone '
                '(#1230)');
      });
    }
  });

  group('the legend carries every target while the donut is suppressed (#1230)',
      () {
    // The donut may be absent; the information may not. This is the claim that
    // makes suppression an acceptable degradation rather than a data loss.
    for (final wc in narrowCases) {
      testWidgets('@${wc.label} ${wc.widthKey}px every target is still named',
          (tester) async {
        await pumpAt(tester,
            widthCase: wc,
            rows: minRows,
            tabIndex: 0,
            locale: const Locale('ru'));

        // Three targets in the kitchen-sink fixture (Drop 3, Accept 1,
        // Reject 1), each rendered as `TARGET: count` in the legend.
        expect(legendEntries(), findsNWidgets(3),
            reason: 'with the donut suppressed the legend is the only thing '
                'left naming each rule target and its count (#1230)');
      });
    }
  });

  group('the content clears the footer at the minimum height (#1230)', () {
    // The stacked rows tighten their padding to 8px rather than take the block
    // default, and this is where that stops being a preference: at the card's
    // declared minimum height the Rules tab is *exactly* full — the legend's
    // bottom edge is the content's bottom edge to the pixel (318.0 in `fi`).
    // Restoring the default padding grows the three rows by 24px and pushes the
    // legend 3px past the footer, which the template neither scrolls nor clips.
    for (final wc in narrowCases) {
      testWidgets('@${wc.label} ${wc.widthKey}px the metrics and legend fit',
          (tester) async {
        await pumpAt(tester,
            widthCase: wc,
            rows: minRows,
            tabIndex: 0,
            locale: const Locale('fi'));

        final bottom = contentBottom(tester);
        expect(metricRects(tester).last.bottom, lessThanOrEqualTo(bottom),
            reason: 'the third metric row runs past the footer rule at '
                '$bottom; the stacked rows must fit the height the card gives '
                'its content (#1230)');
        expect(legendRect(tester).bottom, lessThanOrEqualTo(bottom),
            reason:
                'the legend runs past the footer rule at $bottom — with the '
                'donut suppressed it is the only thing naming each target, so '
                'it is the one row that must not be pushed off (#1230)');
      });
    }
  });

  group('the donut is never drawn larger than the box it was given (#1230)',
      () {
    // ui_kit takes the section radius from the call site and the centre-hole
    // radius from the theme, so the drawn diameter is `2 × (centre + ring)` and
    // ignores `size`. The default 40px ring against this theme's 60px centre
    // draws 200px into a 160px box — clipped on every side, and clipping is not
    // overflow, so the gate reports nothing.
    for (final wc in [...narrowCases, desktopCase]) {
      testWidgets('@${wc.label} ${wc.widthKey}px the ring fits the box',
          (tester) async {
        await pumpAt(tester,
            widthCase: wc,
            rows: shippedRows,
            tabIndex: 0,
            locale: const Locale('ru'));

        final finder = find.byType(AppPieChart);
        final chart = tester.widget<AppPieChart>(finder);
        final box = tester.getRect(finder);
        final centreRadius = AppDesignTheme.of(tester.element(finder))
            .chartStyle
            .pieCenterRadius;
        final sectionRadius = chart.sectionRadius;
        expect(sectionRadius, isNotNull,
            reason: 'the ring thickness must be sized from the slot, not left '
                'to ui_kit\'s default, or the drawn donut ignores its box');

        final drawn = 2 * (centreRadius + sectionRadius!);
        expect(
          drawn,
          lessThanOrEqualTo(math.min(box.width, box.height) + 0.01),
          reason: 'the donut draws ${drawn.toStringAsFixed(1)}px into a '
              '${box.width.toStringAsFixed(1)}x${box.height.toStringAsFixed(1)} '
              'box, so the ring is clipped (#1230)',
        );
        expect(box.bottom, lessThanOrEqualTo(contentBottom(tester) + 0.01),
            reason: 'the donut must sit above the footer rule');
      });
    }
  });
}
