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
/// AC 5 is a claim about the whole card, so the Ports tab is swept for the same
/// two failures even though none of the 21 coordinates were there — its rows fit
/// at 191px, and fitting is not reading. One thing on it does not read, and the
/// cause is outside this card; the last test in the file records it with its
/// measurement rather than leaving it to a comment.
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
///
/// Seven of those eleven leave the #1183 gate green while the card loses a chart
/// (3, 4), asks for a 160px donut in a 157.4px slot (5), prints a clipped slice
/// label into a 20px ring (6), or clips text mid-glyph (8, 9) — clipping and
/// absence are not overflow. Only 1, 7 and 10 report an overflow, and 1 is simply
/// the pre-#1230 card.
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
  /// Anchored on a `MapsToRow` and walked up to the innermost enclosing [Column],
  /// which is the tab's root: taking the whole card instead would measure the tab
  /// labels and the detail link, which the template owns and which every card
  /// shares — a failure there is not this card's to fix.
  Finder portsTabTexts() => find.descendant(
        of: find
            .ancestor(
                of: find.byType(MapsToRow).first, matching: find.byType(Column))
            .first,
        matching: find.byType(Text),
      );

  /// The two halves of every mapping row, in tree order: `source -> target`.
  ///
  /// `MapsToRow` renders exactly two [Text]s and the count is asserted here, so a
  /// third one appearing inside it cannot quietly be read as a target.
  ({List<Text> sources, List<Text> targets}) mappingHalves(
      WidgetTester tester) {
    final rows = find.byType(MapsToRow);
    expect(rows, findsWidgets,
        reason: 'the Ports tab renders one MapsToRow per port-forwarding rule; '
            'without any there is nothing here to measure');
    final sources = <Text>[];
    final targets = <Text>[];
    for (var i = 0; i < rows.evaluate().length; i++) {
      final texts =
          find.descendant(of: rows.at(i), matching: find.byType(Text));
      expect(texts, findsNWidgets(2),
          reason: 'MapsToRow $i must render exactly a source and a target');
      sources.add(tester.widget<Text>(texts.first));
      targets.add(tester.widget<Text>(texts.last));
    }
    return (sources: sources, targets: targets);
  }

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
    // Everything the tab renders except the mapping target: the heading and the
    // DMZ target line are localized, and the port numbers and protocol badges are
    // not but a clipped port number is as unreadable as a clipped word. The one
    // thing *allowed* to wrap is the heading — 6 locales do, `pt_PT` wanting
    // 230.1px of a 157.4px row — so the same two-line budget as the metrics
    // applies.
    //
    // The mapping *target* is excluded, and not because it passes: at 191px it
    // gets 36.9-38.5px for 82.3-103.7px of text and is ellipsized in every locale.
    // That belongs to the test below it rather than here, for two reasons. It is
    // an IP and a port, byte-identical in all 26 locales, so a localization sweep
    // is the wrong instrument — one measurement proves as much as 26. And the
    // ellipsis is `MapsToRow`'s documented contract ("[target] is the part that
    // ellipsizes, since the source is short and bounded while the target is not"),
    // shared with seven other call sites; asserting it whole here would fail this
    // card for a decision taken in `row_blocks.dart`.
    const maxLines = 2;

    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      testWidgets('@${narrowest.widthKey}px $tag renders every row whole',
          (tester) async {
        await pumpAt(tester,
            widthCase: narrowest, rows: minRows, tabIndex: 1, locale: locale);

        final targets = mappingHalves(tester).targets;
        final texts = portsTabTexts();
        expect(texts, findsWidgets,
            reason: 'the Ports tab rendered no text at all — the fixture must '
                'carry port-forwarding rules for this to measure anything');

        for (var i = 0; i < texts.evaluate().length; i++) {
          final widget = tester.widget<Text>(texts.at(i));
          if (targets.any((t) => identical(t, widget))) continue;
          final content = widget.data ?? '';
          if (content.isEmpty) continue;
          final paragraph = tester.renderObject<RenderParagraph>(texts.at(i));
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
            lessThanOrEqualTo(maxLines),
            reason: '"$content" needs $lines lines in the '
                '${room.toStringAsFixed(1)}px it is given on the Ports tab at '
                '${narrowest.widthKey}px. Beyond $maxLines the row is a column '
                'of fragments (#1230).',
          );
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '"$content" is ellipsized on the Ports tab at '
                '${narrowest.widthKey}px (${room.toStringAsFixed(1)}px of room, '
                '$lines lines wanted) — clipped, which the gate cannot see '
                '(#1230).',
          );
        }
      });
    }
  });

  testWidgets(
      '@${narrowest.widthKey}px the mapping target is the one thing the row '
      'cannot show whole (#1230)', (tester) async {
    // The measurement the sweep above deliberately does not make, kept as a
    // ratchet rather than left to a comment. `en` alone: the strings are IPs and
    // ports, identical in every locale.
    //
    // The cause is not this card's leading. `MapsToRow` gives its two halves a
    // `Flexible` each and `RenderFlex` splits the room **evenly** between equal
    // flexes without handing back what the shorter one declines — measured: the
    // source takes its 30.7px and the target still gets exactly half, 38.5px of
    // the 77px the pair has. So the target's ceiling is half the row, whatever
    // else the row spends, and "192.168.1.105:27015" wants 103.7px: reading it
    // whole needs 227.4px of mapping, more than the whole 191px card. Measured
    // against the two card-side fixes and neither is enough on its own — the
    // mapping on a full-width line of its own still leaves the target 68.7px
    // (half of 137.4), and it costs 20px a rule, which overflows the 3-row
    // minimum this ticket may not raise (AC 4) by +11px to +36px unless the DMZ
    // list goes too.
    //
    // That makes it a `row_blocks.dart` decision, not a #1230 one, and it
    // contradicts `MapsToRow`'s own docstring: "[target] is the part that
    // ellipsizes, since the source is short and bounded while the target is not"
    // describes a layout that gives the bounded half its intrinsic width, not
    // half the row. Seven other call sites share it. This expectation is what
    // stops the limitation from being forgotten; the header table records the
    // combination that clears it.
    //
    // Both halves are asserted, in opposite directions. The source is the rule's
    // identity — which external port this row is about — and must survive; if it
    // ever ellipsizes the row has stopped saying anything at all.
    await pumpAt(tester,
        widthCase: narrowest,
        rows: minRows,
        tabIndex: 1,
        locale: const Locale('en'));

    final rows = find.byType(MapsToRow);
    final halves = mappingHalves(tester);

    for (var i = 0; i < halves.sources.length; i++) {
      final texts =
          find.descendant(of: rows.at(i), matching: find.byType(Text));
      final source = tester.renderObject<RenderParagraph>(texts.first);
      expect(
        source.didExceedMaxLines,
        isFalse,
        reason:
            '"${halves.sources[i].data}" — the external port of rule $i — is '
            'ellipsized at ${narrowest.widthKey}px. It is 28.7-33.3px of text: '
            'if the leading dot and badge have grown enough to clip it, the row '
            'no longer identifies its rule (#1230).',
      );

      final target = tester.renderObject<RenderParagraph>(texts.last);
      expect(
        target.didExceedMaxLines,
        isTrue,
        reason: '"${halves.targets[i].data}" now renders whole at '
            '${narrowest.widthKey}px — the known limitation this expectation '
            'records is fixed. Delete this test and drop the mapping-target '
            'exclusion from the sweep above, which then covers it in all 26 '
            'locales (#1230).',
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
