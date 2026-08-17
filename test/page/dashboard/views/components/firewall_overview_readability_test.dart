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
import '../../../../util/text_run_metrics.dart';

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
/// AC 5 is a claim about the whole card, so the Ports tab is swept for the same
/// two failures even though none of the 21 coordinates were there — its rows fit
/// at 191px, and fitting is not reading. One thing on it did not read: the port
/// mapping's target was ellipsized in every locale, by a cap that `MapsToRow`
/// imposed on all ten of its render sites. #1286 fixed that at the source and
/// this card gave the mapping a line of its own to spend it on; the last test in
/// the file is the measurement, kept rather than deleted with the ratchet it
/// replaced.
///
/// So each group below asserts on the rendered tree. Each was run against a
/// mutation of the code it guards, and each fired:
///
///   | mutation                                       | what failed                                                  |
///   |------------------------------------------------|--------------------------------------------------------------|
///   | 1. `_kMetricsSideBySideMinWidth` 328 → 0 (i.e. the pre-#1230 card) | 33: shredded text (26 — every locale), three across @min and @preferred (2), footer + donut + ring + legend @min (5); 10 of the 33 trip `pumpAt`'s overflow first, by +7px to +26px |
///   | 2. `_kMetricsSideBySideMinWidth` 328 → 600     | three across @desktop (1)                                    |
///   | 3. `_kProtocolChartMinHeight` 70 → 200         | chart drawn @shipped height (3)                              |
///   | 4. `_kDonutMinRingThickness` 10 → 60           | donut drawn @shipped height (3), ring fits its box (3)        |
///   | 5. `size: diameter` → the themed design diameter, ignoring the slot | ring fits its box (1 — @min only; 191px is the one width whose slot, 157.4px, is under the 160px this theme designs for) |
///   | 6. `showLabels: false` → `true`                | ring fits its box (3)                                        |
///   | 7. `_StackedMetrics` padding `sm` → block default | 12: `pumpAt` overflow @min in 6 locales (+3px `fi` to +7px `ru`, 10 tests), donut starved out even @shipped height (2) |
///   | 8. stacked label `maxLines` 2 → 1              | shredded text (5 — `es`, `es-AR`, `fi`, `nb`, `ru`)          |
///   | 9. Ports heading `maxLines: 1`                 | Ports tab shredded text (6 — `da`, `pl`, `pt`, `pt-PT`, `ru`, `sv`, the locales whose heading wraps) |
///   | 10. the mapping on a full-width line of its own | 29: `pumpAt` overflow @min in all 26 locales (+11px to +36px bottom) and @preferred in one, chart suppression @min (2) — the +20px a rule costs is what AC 4 forbids |
///   | 11. 10, plus the DMZ list dropped, plus `MapsToRow`'s source given its intrinsic width instead of half the row | mapping target ratchet (1), and nothing else — the combination that would let this card show a target whole, measured clean |
///   | 12. `_kMappingInlineMinWidth` → 0, i.e. the mapping back inline at 191px | 27: Ports tab shredded text (26 — every locale), and the half-the-row measurement, which reports 41.4px of a 97.1px run |
///   | 13. the stacked mapping indented 16px under the badge, `MapsToRow.maxLines` back at 1 | 27: Ports tab shredded text (26), and target-whole — 86.1px of the 103.7px `192.168.1.105:27015` asks for, in a 141.4px run |
///   | 14. 13 with `maxLines` left at 2                | **nothing** — the run breaks after the arrow instead, and the target renders whole on the second line (measured: all its boxes at `top: 18`, one line, paragraph 32px tall). Recorded because it is the reason `maxLines: 2` is what makes the one-line fit safe rather than the 0.4px of slack |
///   | 15. the Ports heading boxed to 72px             | `pumpAt` overflow @min in 26 locales (+4px `el`) — it never reaches the text assertions, which is why 13 rather than this proves the target-whole one |
///   | 16. the protocol badge label boxed to 12px      | `pumpAt` overflow @min in 26 locales — Flutter breaks an over-long token per grapheme rather than overflowing its line, so the badge grew taller instead of spilling sideways |
///
/// Nine of those sixteen leave the #1183 gate green while the card loses a chart
/// (3, 4), asks for a 160px donut in a 157.4px slot (5), prints a clipped slice
/// label into a 20px ring (6), or clips text mid-glyph (8, 9, 12, 13) — clipping
/// and absence are not overflow, and an ellipsized target overflows nothing. Only
/// 1, 7, 10, 15 and 16 report an overflow, and 1 is simply the pre-#1230 card.
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

  /// Every [Text] in the Ports tab's own content, tab bar and footer excluded.
  ///
  /// Anchored on the `MapsToRow`s and walked up to the innermost [Column] that
  /// encloses *all* of them, which is the tab's root: taking the whole card
  /// instead would measure the tab labels and the detail link, which the template
  /// owns and which every card shares — a failure there is not this card's to fix.
  ///
  /// "All of them" is the part that has to be said out loud. This used to take the
  /// innermost enclosing `Column` of the first row full stop, and #1286 made a
  /// rule render as a `Column` of its own below `_kMappingInlineMinWidth` — a
  /// leading line, then the mapping. So the innermost `Column` became *one rule*,
  /// and the sweep silently narrowed from the whole tab to rule 1 of 3. It passed
  /// while rule 2's target was ellipsized by 17.6px, which is precisely the defect
  /// it exists to catch. Counting the rows in scope is what makes that a failure
  /// rather than a green run.
  Finder portsTabTexts() {
    final rows = find.byType(MapsToRow);
    final rowCount = rows.evaluate().length;
    expect(rowCount, greaterThan(0),
        reason: 'the Ports tab rendered no mapping rows to anchor on');
    // `find.ancestor` returns ancestors innermost-first, so this walks outwards.
    final columns =
        find.ancestor(of: rows.first, matching: find.byType(Column));
    for (var i = 0; i < columns.evaluate().length; i++) {
      final scope = columns.at(i);
      if (find.descendant(of: scope, matching: rows).evaluate().length ==
          rowCount) {
        return find.descendant(of: scope, matching: find.byType(Text));
      }
    }
    fail('no Column encloses all $rowCount mapping rows — the Ports tab must '
        'render its rules under one Column for this sweep to be scoped to it');
  }

  /// One record per mapping row on the Ports tab: the paragraph it renders as,
  /// and the two operands that went into it.
  ///
  /// Since #1286 a `MapsToRow` is **one** paragraph — `source`, an arrow
  /// [WidgetSpan], `target` — and not two [Text]s. That is the fix itself: a
  /// single run lays the source out at its intrinsic width and leaves the rest to
  /// the target, where two equal-flex `Flexible`s capped the target at half the
  /// row whatever the source spent. So there is no `.first`/`.last` half to take
  /// any more, and the count is asserted at 1 so that a `Text` reappearing inside
  /// the row cannot quietly be measured as if it were the target.
  ///
  /// The operands come off the widget rather than out of the span tree: they are
  /// the same strings either way, and reading them from the widget keeps the
  /// helper independent of how many spans the arrow costs.
  List<({RenderParagraph paragraph, String source, String target})> mappingRuns(
      WidgetTester tester) {
    final rows = find.byType(MapsToRow);
    expect(rows, findsWidgets,
        reason: 'the Ports tab renders one MapsToRow per port-forwarding rule; '
            'without any there is nothing here to measure');
    final runs =
        <({RenderParagraph paragraph, String source, String target})>[];
    for (var i = 0; i < rows.evaluate().length; i++) {
      final row = tester.widget<MapsToRow>(rows.at(i));
      final texts =
          find.descendant(of: rows.at(i), matching: find.byType(Text));
      expect(texts, findsOneWidget,
          reason: 'MapsToRow $i must render the pair as a single paragraph — '
              'that is what stops the target being capped at half the row '
              '(#1286); found ${texts.evaluate().length} Texts');
      runs.add((
        paragraph: tester.renderObject<RenderParagraph>(texts),
        source: row.source,
        target: row.target,
      ));
    }
    return runs;
  }

  // `paintedWidth` and `intrinsicWidth` come from `test/util/text_run_metrics.dart`.
  // They lived here first, and moved out when `maps_to_row_test.dart` needed the
  // same three functions — including `operandStyle`, whose trap (the root span
  // carries the container's 14px, not the 12px the operands are drawn in) both
  // files walked into independently.

  /// The card's `_kDonutMinRingThickness`, mirrored — it is private to `lib/`.
  const minRingThicknessPx = 10.0;

  /// What fl_chart was actually handed: the hole and ring radii in logical px,
  /// and the per-slice titles.
  ///
  /// Since ui_kit v2.34.11 both radii are derived from the box inside
  /// `AppPieChart`, so the card's own arguments no longer describe the drawing:
  /// reading `AppPieChart.sectionRadius` back would assert only that this file
  /// agrees with itself. The titles come from here for a related reason —
  /// `showLabels` becomes `title: ''` on every section and fl_chart paints slice
  /// labels onto its canvas rather than as [Text] widgets, so nothing in the
  /// widget tree can see them.
  ///
  /// fl_chart is ui_kit's dependency and not this app's, so its types are reached
  /// dynamically rather than imported — the price of measuring the drawing instead
  /// of the request.
  ({double hole, double ring, List<String> titles}) drawnDonut(
      WidgetTester tester) {
    final pie = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'PieChart',
        description: 'fl_chart PieChart');
    expect(pie, findsOneWidget,
        reason: 'AppPieChart draws through exactly one fl_chart PieChart; '
            'without it there is nothing here to measure');
    final dynamic data = (tester.widget(pie) as dynamic).data;
    final sections = data.sections as List;
    final rings =
        sections.map<double>((s) => (s as dynamic).radius as double).toList();
    return (
      hole: data.centerSpaceRadius as double,
      ring: rings.reduce(math.max),
      titles:
          sections.map<String>((s) => (s as dynamic).title as String).toList(),
    );
  }

  testWidgets('the fonts these measurements were taken in are the app\'s own',
      (tester) async {
    // Every claim in this file is a claim about pixels, so every one of them
    // rests on the card having been laid out in the fonts it ships with. Two
    // things can take that away, and neither shows up as a failure anywhere
    // else — the suite would stay green while measuring a different typeface.
    //
    //   - The font *file* is gone: a ui_kit ref bump moves the pub-cache path,
    //     or an `.otf` gets renamed. `loadAppFonts` throws on that, which is the
    //     right place for it — one check protects every caller — and it is not
    //     catchable from here, because `FontLoader` registers the family even
    //     with no bytes in it, after which the engine serves its own block font.
    //   - The *family name* no longer matches: the file loads under a name
    //     nothing asks for, the style's family is unresolvable, and the engine
    //     substitutes silently. That is this test.
    //
    // Two measurements, because the substitution has two shapes. Both were taken
    // by renaming `loadAppFonts`'s registration to
    // `NeueHaasGrotTextRoundRENAMED` and reading what the card then measured:
    //
    //   - Nothing to substitute — none of this card's styles carries a
    //     `fontFamilyFallback` — so the block font is what gets served, at one em
    //     per glyph: `192.168.1.101:80` went from 83.3px to exactly 192.0px
    //     (12.0 x 16 characters). Across the whole Ports tab the mutation
    //     measured 1.000-1.045 em per glyph, so the assertion is a ratio rather
    //     than an exact signature — the real font is at 0.43 em, nowhere near.
    //   - Something to substitute — `lib/app.dart` does hand the text theme a CJK
    //     `fontFamilyFallback`, and if it reaches these styles the same rename
    //     lands on Noto instead, which measures like any proportional font and
    //     would slip past a ratio check. So the width is also required to differ
    //     from what Noto measures the same string at (95.2px against NeueHaas's
    //     83.3px — both real fonts, ~14% apart, and only one of them the app's).
    //
    // `en`, and the mapping target specifically, because it is pure ASCII: for
    // Cyrillic, Arabic, Thai and CJK the app falls back to Noto *by design*, and
    // one em per ideograph is what CJK legitimately measures — both assertions
    // would be backwards there.
    //
    // Pumped through the probe rather than `pumpAt`, dropping the overflow
    // incidents: a wrong typeface reflows the card, so `pumpAt` would fail on the
    // overflow before reaching the identification, which is the one failure that
    // says *why*. Overflow at this coordinate is asserted below, so ignoring it
    // here loses nothing.
    await probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: narrowest,
      cardHeightRows: minRows,
      tabIndex: 1,
      locale: const Locale('en'),
    );

    final run = mappingRuns(tester).first;
    final paragraph = run.paragraph;
    final content = run.target;
    // Since #1286 the pair is one paragraph, and the style the operands render in
    // is one level below its root — see [operandStyle]. Reading the root instead
    // would identify the *container's* typeface, which is not what drew this.
    final style = operandStyle(paragraph);
    expect(style.fontSize, isNotNull,
        reason: 'the mapping target must carry a resolved style with a font '
            'size, or there is nothing here to identify');

    double widthUnder(TextStyle textStyle) {
      final painter = TextPainter(
        text: TextSpan(text: content, style: textStyle),
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
      )..layout();
      final width = painter.maxIntrinsicWidth;
      painter.dispose();
      return width;
    }

    final measured = widthUnder(style);
    // `copyWith` keeps the style's `package` and the `fontFamily` getter
    // re-composes the prefix, so this asks for whichever of `NotoSans` /
    // `packages/ui_kit_library/NotoSans` the style's own package implies —
    // `loadAppFonts` registers both.
    final noto = widthUnder(
      style.copyWith(fontFamily: 'NotoSans', fontFamilyFallback: const []),
    );
    final oneEm = style.fontSize! * content.length;

    expect(
      measured,
      lessThan(oneEm * 0.9),
      reason: '"$content" measured ${measured.toStringAsFixed(1)}px, which is '
          '${(measured / oneEm).toStringAsFixed(3)} em per glyph — a block font, '
          'not a proportional one. The style asks for '
          '${style.fontFamily} and nothing is registered under that name, so '
          'every pixel in this file is fiction. `loadAppFonts` throws when a '
          'font *file* is missing, so what is left is a name mismatch: check '
          'that ui_kit still calls its family NeueHaasGrotTextRound (#1230).',
    );

    expect(
      noto,
      lessThan(oneEm * 0.9),
      reason: 'the reference measurement is itself fictional: "$content" under '
          'NotoSans came out at ${noto.toStringAsFixed(1)}px, '
          '${(noto / oneEm).toStringAsFixed(3)} em per glyph. The Noto files '
          'under test/fonts/ did not load, so the check below cannot identify '
          'anything (#1230).',
    );

    expect(
      measured,
      isNot(closeTo(noto, 0.5)),
      reason: '"$content" measured ${measured.toStringAsFixed(1)}px, which is '
          'what NotoSans measures it at — the app\'s own family did not '
          'resolve and the engine fell back to the CJK fallback chain. It is a '
          'real font, so the numbers look plausible, but they are the wrong '
          'typeface: check that ui_kit still calls its family '
          'NeueHaasGrotTextRound and that `loadAppFonts` registers that name '
          '(#1230).',
    );
  });

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

  group('no Ports tab text is shredded at the narrowest width (#1230)', () {
    // AC 5 is about the card, and the card has two tabs. The sweep above covers
    // the Rules tab because that is where the 15 card-own coordinates were; this
    // one covers the other half of the same claim, where the gate again says
    // nothing — the Ports tab's rows fit at 191px, and fitting is not reading.
    //
    // Everything the tab renders, mapping run included: the heading and the DMZ
    // target line are localized, and the port numbers and protocol badges are not
    // but a clipped port number is as unreadable as a clipped word. The one thing
    // *allowed* to wrap is the heading — 6 locales do, `pt_PT` wanting 230.1px of
    // a 157.4px row — so the same two-line budget as the metrics applies.
    //
    // The mapping target used to be **excluded** here, with the measurement kept
    // as a ratchet below: at 191px it got 36.9-38.5px for 82.3-103.7px of text and
    // was ellipsized in every locale, because `MapsToRow` split its row between
    // two equal-flex `Flexible`s. #1286 fixed that in `row_blocks.dart` and the
    // card gave the mapping a line of its own to spend, so the exclusion is gone.
    // Whether the target is whole is asserted *by width* in the test below rather
    // than by the ellipsis flag here — see `hasPlaceholder` for why the flag
    // cannot answer it.
    const maxLines = 2;

    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      testWidgets('@${narrowest.widthKey}px $tag renders every row whole',
          (tester) async {
        await pumpAt(tester,
            widthCase: narrowest, rows: minRows, tabIndex: 1, locale: locale);

        final texts = portsTabTexts();
        expect(texts, findsWidgets,
            reason: 'the Ports tab rendered no text at all — the fixture must '
                'carry port-forwarding rules for this to measure anything');

        for (var i = 0; i < texts.evaluate().length; i++) {
          final paragraph = tester.renderObject<RenderParagraph>(texts.at(i));
          final span = paragraph.text;
          final content = span.toPlainText(includePlaceholders: false);
          if (content.isEmpty) continue;
          final room = paragraph.size.width;

          // The mapping run carries an inline arrow placeholder, and is measured
          // by the test below instead of here. Rebuilding it in a `TextPainter`
          // would mean handing the placeholder's dimensions back in, and the
          // reason not to fall back on `didExceedMaxLines` alone for it is the
          // point of the `widest` assertion below: an IP and a port have no break
          // opportunity in them, so a run that does not fit is not a run that
          // needs a second line — it stays one line and loses its tail to the
          // ellipsis, with the flag still false. Measured: at 141.4px of room
          // `27015 → 192.168.1.105:27015` painted 86.1px of the target's 103.7px
          // and every locale here passed.
          final hasPlaceholder = span.toPlainText().length != content.length;
          if (!hasPlaceholder) {
            final wanted = TextPainter(
              text: TextSpan(text: content, style: span.style),
              textDirection: paragraph.textDirection,
              textScaler: paragraph.textScaler,
              locale: locale,
            )..layout(maxWidth: room);
            final metrics = wanted.computeLineMetrics();
            final lines = metrics.length;
            final widest =
                metrics.map((m) => m.width).fold<double>(0, math.max);
            wanted.dispose();

            expect(
              lines,
              lessThanOrEqualTo(maxLines),
              reason: '"$content" needs $lines lines in the '
                  '${room.toStringAsFixed(1)}px it is given on the Ports tab at '
                  '${narrowest.widthKey}px. Beyond $maxLines the row is a column '
                  'of fragments (#1230).',
            );

            // The other half of "nothing was cut", and the half the ellipsis flag
            // does not cover: a token with no break opportunity in it — a port, an
            // IP, a URL — overflows its line rather than taking another, so the
            // line count stays inside the budget and `didExceedMaxLines` stays
            // false while the tail is replaced by an ellipsis. Laid out with no
            // maxLines and no ellipsis, the widest line is what the text really
            // wants; anything over the room it has was cut on screen.
            expect(
              widest,
              lessThanOrEqualTo(room + 0.5),
              reason: '"$content" wants ${widest.toStringAsFixed(1)}px on its '
                  'widest line and has ${room.toStringAsFixed(1)}px on the Ports '
                  'tab at ${narrowest.widthKey}px — the excess is ellipsized, and '
                  'it cannot wrap out of it because there is no break opportunity '
                  'in it (#1230).',
            );
          }
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '"$content" is ellipsized on the Ports tab at '
                '${narrowest.widthKey}px (${room.toStringAsFixed(1)}px of room) '
                '— clipped, which the gate cannot see (#1230).',
          );
        }
      });
    }
  });

  testWidgets(
      '@${narrowest.widthKey}px the mapping target takes more than half the '
      'row (#1286)', (tester) async {
    // The measurement that replaced a ratchet. It used to assert that the target
    // is ellipsized here and could not be otherwise — `MapsToRow` gave its two
    // halves a `Flexible` each, and `RenderFlex` splits the room **evenly**
    // between equal flexes without handing back what the shorter one declines, so
    // the source took its 30.7px and the target still got exactly half, 38.5px of
    // the 77px the pair had. Its own failure message asked for this test to be
    // deleted the day the target rendered whole. #1286 made that day: the pair is
    // one paragraph now, so the source takes its intrinsic width by document order
    // and the target gets the rest.
    //
    // "Whole" is asserted by the 26-locale sweep above, which no longer excludes
    // the target. What is asserted here is the *shape* of the fix rather than the
    // outcome — that the target holds more than half the run — because a card-side
    // change that widened the row would satisfy "whole" while leaving the even
    // split in place, and the split is what has nine other render sites.
    //
    // `en` alone: the strings are an IP and a port, byte-identical in all 26
    // locales, so one measurement proves what 26 would.
    //
    // The source is checked in the other direction. It is the rule's identity —
    // which external port this row is about — and in a single run an ellipsis can
    // only reach it once the whole row is narrower than the source itself. Reading
    // its painted width back is what shows it was laid out at its intrinsic width
    // and not squeezed to a share.
    await pumpAt(tester,
        widthCase: narrowest,
        rows: minRows,
        tabIndex: 1,
        locale: const Locale('en'));

    final runs = mappingRuns(tester);

    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      final room = run.paragraph.size.width;
      final sourceWidth = paintedWidth(run.paragraph, 0, run.source.length);
      // `source`, then one U+FFFC standing in for the arrow, then `target`.
      final targetStart = run.source.length + 1;
      final targetWidth = paintedWidth(
          run.paragraph, targetStart, targetStart + run.target.length);

      expect(
        sourceWidth,
        closeTo(intrinsicWidth(run.paragraph, run.source), 0.5),
        reason: '"${run.source}" — the external port of rule $i — was painted '
            '${sourceWidth.toStringAsFixed(1)}px wide in a '
            '${room.toStringAsFixed(1)}px run, not the '
            '${intrinsicWidth(run.paragraph, run.source).toStringAsFixed(1)}px '
            'it asks for. In one paragraph the source takes its intrinsic width '
            'by document order; a shortfall means it is back to being allocated '
            'a share of the row (#1286).',
      );

      expect(
        targetWidth,
        greaterThan(room / 2),
        reason: '"${run.target}" was painted '
            '${targetWidth.toStringAsFixed(1)}px of a '
            '${room.toStringAsFixed(1)}px run — at or under half, which is the '
            'ceiling the two equal-flex `Flexible`s used to impose. The source '
            'spends only ${sourceWidth.toStringAsFixed(1)}px, so the rest '
            'belongs to the target (#1286).',
      );

      // AC 1, measured rather than inferred: the target is painted at its own
      // intrinsic width, i.e. no glyph of it was traded for an ellipsis. The
      // sweep above reaches the same conclusion from `didExceedMaxLines`; this
      // says it in pixels, so a failure names the shortfall.
      expect(
        targetWidth,
        closeTo(intrinsicWidth(run.paragraph, run.target), 0.5),
        reason: '"${run.target}" was painted '
            '${targetWidth.toStringAsFixed(1)}px of the '
            '${intrinsicWidth(run.paragraph, run.target).toStringAsFixed(1)}px '
            'it asks for, in a ${room.toStringAsFixed(1)}px run whose source '
            'spends ${sourceWidth.toStringAsFixed(1)}px. The rest of it is an '
            'ellipsis, which is what #1286 exists to remove.',
      );
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
    // Measured on what fl_chart was handed, not on what this card passed in.
    // ui_kit ≤ v2.34.10 took the ring from the call site and the hole from the
    // theme, so the drawn diameter was `2 × (centre + ring)` and ignored `size` —
    // the default 40px ring against a 60px hole drew 200px into a 160px box,
    // clipped on every side, and clipping is not overflow so the gate reported
    // nothing. v2.34.11 derives both radii from the box
    // (linksys/privacyGUI-UI-kit#22), which is why the `sectionRadius` this card
    // used to compute is gone — and why reading the card's own inputs back would
    // now assert nothing about what is painted.
    for (final wc in [...narrowCases, desktopCase]) {
      testWidgets('@${wc.label} ${wc.widthKey}px the ring fits the box',
          (tester) async {
        await pumpAt(tester,
            widthCase: wc,
            rows: shippedRows,
            tabIndex: 0,
            locale: const Locale('ru'));

        final finder = find.byType(AppPieChart);
        final box = tester.getRect(finder);
        final slot = tester.getRect(
            find.ancestor(of: finder, matching: find.byType(Center)).first);
        final geometry = drawnDonut(tester);
        final drawn = 2 * (geometry.hole + geometry.ring);

        expect(
          math.max(box.width, box.height),
          lessThanOrEqualTo(math.min(slot.width, slot.height) + 0.01),
          reason: 'the donut asked for a '
              '${box.width.toStringAsFixed(1)}x${box.height.toStringAsFixed(1)} '
              'box inside a '
              '${slot.width.toStringAsFixed(1)}x${slot.height.toStringAsFixed(1)} '
              'slot — the size must come from the slot, not from the theme '
              '(#1230)',
        );
        expect(
          drawn,
          lessThanOrEqualTo(math.min(box.width, box.height) + 0.01),
          reason: 'the donut draws ${drawn.toStringAsFixed(1)}px '
              '(${geometry.hole.toStringAsFixed(1)}px hole + '
              '${geometry.ring.toStringAsFixed(1)}px ring) into a '
              '${box.width.toStringAsFixed(1)}x${box.height.toStringAsFixed(1)} '
              'box, so the ring is clipped (#1230)',
        );
        expect(
          geometry.ring,
          greaterThanOrEqualTo(minRingThicknessPx - 0.01),
          reason: 'the ring is ${geometry.ring.toStringAsFixed(1)}px thick, '
              'below the ${minRingThicknessPx.toStringAsFixed(0)}px the card '
              'draws a donut for at all — at this thickness it reads as an '
              'outline and should have been suppressed instead (#1230)',
        );

        expect(
          geometry.titles,
          everyElement(isEmpty),
          reason: 'a slice label is painted inside the ring, which at '
              '${geometry.ring.toStringAsFixed(1)}px would be a clipped '
              'duplicate of the legend below — `showLabels: false` is what '
              'suppresses it, and fl_chart paints these onto its canvas rather '
              'than as widgets, so the tree cannot see them (#1230)',
        );

        // v2.34.11 shrinks the *hole* when the box cannot hold the themed
        // radius, so the caption is no longer guaranteed the 60px it is sized
        // against — ui_kit says as much on `centerWidget`. The caption is the
        // only text inside the chart, so its two [Text]s are the whole of what
        // must fit in the hole.
        final texts = find.descendant(of: finder, matching: find.byType(Text));
        expect(texts, findsNWidgets(2),
            reason: 'the only text inside the donut is its own caption — a '
                'count and the word for it. ${texts.evaluate().length} found, '
                'so the caption has changed and the radius measured below is no '
                'longer the one that matters (#1230)');
        var caption = tester.getRect(texts.at(0));
        for (var i = 1; i < texts.evaluate().length; i++) {
          caption = caption.expandToInclude(tester.getRect(texts.at(i)));
        }
        final halfDiagonal = math.sqrt(
            math.pow(caption.width / 2, 2) + math.pow(caption.height / 2, 2));
        expect(
          halfDiagonal,
          lessThanOrEqualTo(geometry.hole + 0.01),
          reason: 'the caption needs a ${halfDiagonal.toStringAsFixed(1)}px '
              'radius and the hole is ${geometry.hole.toStringAsFixed(1)}px, so '
              'it spills onto the ring it is centred in (#1230)',
        );

        expect(box.bottom, lessThanOrEqualTo(contentBottom(tester) + 0.01),
            reason: 'the donut must sit above the footer rule');
      });
    }
  });
}
