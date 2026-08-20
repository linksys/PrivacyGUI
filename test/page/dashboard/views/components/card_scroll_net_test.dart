@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_scroll_region.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:ui_kit_library/ui_kit.dart'
    show AppCard, AppGauge, AppPieChart, AppTabs;

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/overflow_probe.dart';

/// Which tabbed-card tabs sit in the scroll net, and what the three conversions
/// cost (#1296, extending #1267).
///
/// ## Why this file exists
///
/// #1267 gave one tab — WiFi Performance's Channels — a scrolling content region
/// so content taller than the card had somewhere to go instead of being painted
/// outside it. #1296 is that decision taken over the remaining five tabbed cards,
/// one measured tab at a time, and it needs a home for two claims the #1183 gate
/// cannot make:
///
///  1. **The net is installed where the table says it is.** A scrolling region
///     reports no RenderFlex overflow however tall its content grows, so the gate
///     is green with the net present *and* green with the net absent until the
///     content actually spills. The membership table below is therefore executable
///     rather than prose: `netTabs` is the same table as the density design's
///     §2.10g point 5, and `the net is where the table says it is` walks all 20
///     tabs of all six tabbed cards against it.
///  2. **The conversion cost nothing.** Opting a tab in means deleting a vertical
///     `Expanded`/`Flexible` — flex needs a bounded height to divide and a scroll
///     view has none — so a tab is only convertible if that flex was distributing
///     air rather than sizing anything. Each conversion below pins the number that
///     made it safe: a donut that is 180px at 4 rows and at 8, a pair of gauges
///     that are width-bound at every width the grid produces.
///
/// ## The three conversions, and the four declines
///
/// Measured at every width the grid gives each card, at 4 and 8 rows, in all 26
/// locales (468 pumped cases, recorded in §2.10j):
///
///   | card / tab                     | verdict | the measurement                 |
///   |--------------------------------|---------|---------------------------------|
///   | wifi_performance   t2 Channels | in      | #1267                           |
///   | device_analytics   t0 Overview | in      | donut 180px @ 4 rows and @ 8    |
///   | traffic_analysis   t2 Distrib. | in      | donut 180px, 67px of slack      |
///   | system_status      t0 Monitor  | in      | gauges width-bound: 72.7 / 100  |
///   | network_health     t0 Health   | **out** | gauge grows 87 → 120px with box |
///   | firewall_overview  t0/t1       | **out** | 15–39px leftover slot           |
///   | the other 13 tabs              | **out** | chart height *is* the card's     |
///
/// The declines are not laziness — they are the same measurement reaching the
/// opposite answer. `AppGauge` **respects** its incoming constraints (unlike
/// `AppPieChart`, which derives its geometry from `size:` and ignores its box), so
/// network_health's `Expanded` is load-bearing: the gauge renders 87px in `de` at
/// the narrowest normal-form width and 99–103px at the desktop realization. Taking
/// the flex away would let it grow to its natural 120px and push 17–33px of the
/// metric row below the fold **on arrival**, at the height the card actually
/// ships. The only fix for that is a taller card (`minHeightRows`), which #1296
/// explicitly excludes. Same for the 13 chart tabs, where the chart's height *is*
/// the card's (285 → 829px between 4 and 8 rows): unbounded, they would render at
/// whatever intrinsic height the chart library picks and the card would scroll on
/// arrival at every width.
///
/// ## Mutation ledger
///
/// Each verdict was verified to fail under a mutation of the code it guards. The
/// gate column is the mutated card's own coordinates in
/// `dashboard_card_overflow_test.dart` (209 for each of the three converted
/// cards, 157 for network_health); "green" means every one of them passed, i.e.
/// the gate cannot see the mutation at all.
///
///   | mutation                                        | this file | the gate |
///   |-------------------------------------------------|-----------|----------|
///   | `scrollable: false` on device_analytics t0       | 47 fail   | green    |
///   | `scrollable: false` on traffic_analysis t2       | 47 fail   | green    |
///   | `scrollable: false` on system_status t0          | 45 fail   | green    |
///   | convert network_health t0 (flag + drop its flex) | 41 fail   | green    |
///
/// Two of these rows are worth reading past their numbers.
///
/// **system_status is 45, not 47** — the two `gauges are width-bound` tests pass
/// under its mutation, and they are supposed to: the gauge row is a non-flex child
/// of a `Column`, so it receives an unbounded height whether or not the region
/// scrolls, and the diameters are identical either way. That is the losslessness
/// claim itself, so a mutation that changed those numbers would mean the
/// conversion had a cost after all.
///
/// **The last row is the one this file exists for.** Converting the tab that was
/// declined costs the gate nothing — all 157 network_health coordinates stay green,
/// because content that used to be squeezed now simply scrolls — while 41 tests
/// here fail. The decisive six are the desktop-width arrival assertions: the tab
/// scrolls at the height the card actually ships. (26 of the 41 are the narrowest
/// realization reporting no region at all, which is an artifact rather than a
/// signal — at 191px this card is in its degraded score form and has no tabs to
/// put in a net. A card with a `normalAbove` threshold and a conversion would want
/// its arrival sweep to start above that threshold.)
void main() {
  setUpAll(() async {
    // Real fonts: content height per locale is the measurement this whole file is
    // made of, and under Ahem every glyph is one square em, so the heights would
    // be fiction.
    await loadAppFonts();
  });

  // --- The membership table --------------------------------------------------

  /// The scroll net's membership, by card id → the tab indices that opt in.
  ///
  /// This is §2.10g point 5's table in executable form. An empty set is a
  /// deliberate decline, not an omission — see the file header for each one's
  /// measurement — and a card missing from this map fails the meta-test below
  /// rather than being silently skipped.
  const netTabs = <String, Set<int>>{
    'wifi_performance': {2}, // Channels — #1267
    'device_analytics': {0}, // Overview — #1296
    'traffic_analysis': {2}, // Distribution — #1296
    'system_status': {0}, // Monitor — #1296
    'network_health': <int>{}, // declined: the gauge grows with its box
    'firewall_overview': <int>{}, // declined: 15–39px leftover slot
  };

  /// The conversions #1296 made, as (card, tab) pairs. Derived from [netTabs]
  /// minus #1267's, so a fifth conversion cannot be added to one table and
  /// forgotten in the other.
  const converted = <(String, int)>[
    ('device_analytics', 0),
    ('traffic_analysis', 2),
    ('system_status', 0),
  ];

  /// The locales the non-narrowest widths are swept at: the six whose content is
  /// tallest on these three tabs, from the 26-locale pass. `el` and `de` are the
  /// worst on device_analytics and system_status respectively, `vi` on
  /// traffic_analysis; `en` is here as the control that shows the load is
  /// geometric rather than translation-bound.
  const stressLocales = ['en', 'de', 'el', 'ru', 'vi', 'ja'];

  Locale localeFor(String tag) =>
      AppLocalizations.supportedLocales.firstWhere((l) {
        final t = l.countryCode == null || l.countryCode!.isEmpty
            ? l.languageCode
            : '${l.languageCode}_${l.countryCode}';
        return t == tag;
      });

  String tagOf(Locale l) => l.countryCode == null || l.countryCode!.isEmpty
      ? l.languageCode
      : '${l.languageCode}_${l.countryCode}';

  WidgetSpec specOf(String cardId) =>
      UspWidgetSpecs.all.firstWhere((s) => s.id == cardId);

  /// One pump, as the gate does — see `probeCardOverflow` on why re-pumping in a
  /// single test silently suppresses overflows.
  Future<List<OverflowIncident>> pump(
    WidgetTester tester, {
    required String cardId,
    required CardWidthCase widthCase,
    required int tabIndex,
    required int rows,
    required Locale locale,
  }) =>
      probeCardOverflow(
        tester,
        cardId: cardId,
        widthCase: widthCase,
        cardHeightRows: rows,
        tabIndex: tabIndex,
        locale: locale,
      );

  /// Whether the pumped card wrapped its content in the scroll net.
  ///
  /// Asserted on [CardScrollRegion] rather than on `CardTab.scrollable`, because
  /// `DashboardCardTemplate.tabbed`'s tab list is private — and because the flag
  /// is not the claim. The claim is that the *selected* tab's content ends up in a
  /// scrolling region, which is a conjunction of the flag, the template's
  /// per-tab OR, and the tab actually being the one on screen.
  Finder netFinder() => find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(CardScrollRegion),
      );

  /// Every `Text` **inside the scrolling region** that painted a non-empty
  /// string — the strings a "below the fold" or "reachable by scrolling" question
  /// is about.
  ///
  /// Scoped to the region rather than to [AppCard] on measurement: two of these
  /// three cards render `DashboardCardTemplate`'s detail footer, which is chrome
  /// pinned *below* the scroll region (57–58px below its bottom edge at every
  /// width, in all 26 locales). Asking whether "View details" is inside the
  /// content viewport is asking the wrong question about the wrong widget — it
  /// never was and is not supposed to be — and 82 of these tests failed on it
  /// before the scope was narrowed. Asserted non-empty at each call site so the
  /// narrowing cannot quietly turn the loop into a no-op.
  List<Text> regionTexts(WidgetTester tester) => tester
      .widgetList<Text>(
          find.descendant(of: netFinder(), matching: find.byType(Text)))
      .where((t) => t.data != null && t.data!.isNotEmpty)
      .toList();

  group('the net is where the table says it is (§2.10g point 5)', () {
    test('every tabbed card is classified', () {
      // The gate's own meta-test keeps `kTabbedCardTabCounts` honest against the
      // cards; this keeps the net table honest against that. A seventh tabbed
      // card must be measured and classified, not defaulted — defaulting is how
      // the "opted out" table went stale enough to need #1296 in the first place.
      expect(netTabs.keys.toSet(), kTabbedCardTabCounts.keys.toSet(),
          reason: 'the scroll-net table and the tab registry disagree about '
              'which cards are tabbed. A new tabbed card needs a measured '
              'verdict here (and a row in the density design §2.10g point 5).');

      netTabs.forEach((cardId, tabs) {
        for (final tab in tabs) {
          expect(tab, lessThan(tabCountFor(cardId)),
              reason: '$cardId has no tab $tab, so this entry opts in a tab '
                  'that does not exist and asserts nothing.');
        }
      });

      expect(converted.map((c) => c.$1).toSet().length, 3,
          reason: 'the conversion list drifted from the three cards #1296 '
              'measured.');
      for (final (cardId, tab) in converted) {
        expect(netTabs[cardId], contains(tab),
            reason: '$cardId t$tab is listed as converted but is not in the '
                'net table.');
      }
    });

    // Swept at the desktop realization rather than the narrowest, because this
    // group is about *membership*, and a narrow width would drag in the density
    // forms: below its `normalAbove` a card renders no tabs at all
    // (network_health at 191.4px is the score form), so half the sweep would be
    // asserting the absence of a net on a card that is not showing tabs.
    for (final cardId in netTabs.keys) {
      final spec = specOf(cardId);
      final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
      for (var tab = 0; tab < tabCountFor(cardId); tab++) {
        final inNet = netTabs[cardId]!.contains(tab);
        testWidgets(
            '$cardId t$tab is ${inNet ? 'in' : 'out of'} the net at the desktop '
            'width', (tester) async {
          await pump(tester,
              cardId: cardId,
              widthCase: desktopCaseFor(spec),
              tabIndex: tab,
              rows: rows,
              locale: localeFor('en'));

          // The tabs are actually on screen, so `findsNothing` below means "this
          // tab is out of the net" and not "the card degraded and there is no
          // tab here to be in it".
          expect(find.byType(AppTabs), findsOneWidget,
              reason: '$cardId is not rendering its tab bar at the desktop '
                  'width, so nothing here measures tab membership.');

          if (inNet) {
            expect(netFinder(), findsOneWidget,
                reason: '$cardId t$tab is opted into the scroll net in the '
                    'table above but renders no `CardScrollRegion`. Check '
                    '`CardTab.scrollable` at its '
                    '`DashboardCardTemplate.tabbed(...)` call site.');
            expect(cardContentScrollShortfall(tester), isNotNull,
                reason: 'a `CardScrollRegion` is present but exposes no '
                    'vertical scroll position, so the shortfall reading every '
                    'other test in this file depends on is unavailable.');
          } else {
            expect(netFinder(), findsNothing,
                reason: '$cardId t$tab has been opted into the scroll net '
                    'without a row in the table above. Opting in is not free: '
                    'the tab must be measured first (a vertical `Expanded` '
                    'inside a scroll view throws, and a chart with no '
                    'meaningful minimum height scrolls on arrival). Record the '
                    'measurement in §2.10j and add it here.');
          }
        });
      }
    }
  });

  group('a converted tab arrives with nothing below the fold', () {
    // The strong claim, and the one that separates a conversion from a
    // capitulation: scrolling is the net for shapes no fixture predicts, not the
    // reading experience for hardware we ship. `shortfall == 0` at the card's own
    // `minHeightRows` says the tab still fits where it ships; `isNotNull` says
    // there is a net underneath it anyway.
    //
    // Both readings are invisible to the gate. `isNotNull` in particular was
    // *vacuous* on these six cards until #1296 fixed `cardContentScrollShortfall`
    // — a tabbed card always carries a horizontal scroll view for its tab strip,
    // so the reading was 0.0 rather than null with the net absent. See that
    // function's doc.
    for (final (cardId, tab) in converted) {
      final spec = specOf(cardId);
      final c = spec.getConstraints(DisplayMode.normal);
      final narrowest = widthCasesFor(spec, minScreen: 0).first;
      final otherWidths = [
        ...widthCasesFor(spec, minScreen: 0).skip(1),
        desktopCaseFor(spec),
      ];

      void arrival(CardWidthCase width, Locale locale) {
        testWidgets(
            '$cardId t$tab @ ${width.label} ${width.widthKey}px in '
            '${tagOf(locale)}', (tester) async {
          final incidents = await pump(tester,
              cardId: cardId,
              widthCase: width,
              tabIndex: tab,
              rows: c.minHeightRows,
              locale: locale);

          expect(incidents, isEmpty,
              reason: 'this coordinate is overflowing, which a scrolling '
                  'region cannot do by growing — so something inside the tab '
                  'is overflowing horizontally, or a fixed-height child is '
                  'taller than a box that is still bounded: '
                  '${incidents.join(', ')}');

          final shortfall = cardContentScrollShortfall(tester);
          expect(shortfall, isNotNull,
              reason: '$cardId t$tab has no scrolling content region, so '
                  'content taller than the card has nowhere to go — it is '
                  'painted outside the box again. Check `CardTab.scrollable` '
                  'at the card\'s `DashboardCardTemplate.tabbed(...)` call '
                  'site.');
          expect(shortfall, 0.0,
              reason: '$cardId t$tab has to be scrolled at the card\'s own '
                  'minimum size (${c.minHeightRows} rows, '
                  '${dashboardCardHeight(c.minHeightRows).toStringAsFixed(0)}px), '
                  'so part of it is below the fold on arrival. If that is '
                  'deliberate, the card\'s `minHeightRows` is the thing to '
                  'change — not this number.');

          // Exactly one vertical region inside the card, which is what makes the
          // shortfall above attributable to the tab's own content rather than to
          // whichever scroll view happened to be found first.
          final viewport = cardContentViewport(tester);
          final texts = regionTexts(tester);
          expect(texts, isNotEmpty,
              reason: 'the scrolling region rendered no text at all, so the '
                  'loop below asserts nothing.');
          for (final t in texts) {
            final rect = tester.getRect(find.byWidget(t));
            expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + 1.0),
                reason: '"${t.data}" ends '
                    '${(rect.bottom - viewport.bottom).toStringAsFixed(1)}px '
                    'below the content viewport while the shortfall reads 0 — '
                    'so it is outside the box, not scrollable to.');
          }
        });
      }

      // The narrowest realization in all 26 locales: the coordinate where the
      // content is tallest relative to its box, and the one #1296 step 1 asks
      // for.
      for (final locale in AppLocalizations.supportedLocales) {
        arrival(narrowest, locale);
      }
      // Every other width the gate pumps, plus the desktop realization, at the
      // six tallest locales. Wider is monotonically easier for a *vertical*
      // shortfall — rows that wrapped at 260px fit on one line at 512px — so the
      // 26-locale sweep is spent where it can fail.
      for (final width in otherWidths) {
        for (final tag in stressLocales) {
          arrival(width, localeFor(tag));
        }
      }
    }
  });

  group('the net carries load below the card\'s shipped height', () {
    // A net with no load on it is untested (#1267's own words), and two of these
    // three tabs cannot be loaded by *width*: their content is short and their
    // card is 528px tall, so no locale makes them spill. Below 200px the
    // traffic_analysis tab develops horizontal overflows instead, which measures
    // a different defect entirely.
    //
    // So the load comes from the box: one grid row below each card's
    // `minHeightRows` — the height equivalent of the gate's sub-production stress
    // widths (`stats_section_probe.dart`'s idiom). This is deliberately a height
    // the dashboard never gives these cards, and that is what makes it a
    // degradation guard rather than a coordinate: it asks "when the content does
    // exceed the box, is the answer scrolling or is it paint outside the box?"
    //
    // `rows: 1` was measured and is unusable — the card's own chrome (header, tab
    // bar, footer) overflows a 120px box by 71–93px, so the reading would be
    // about the template, not the tab.
    for (final (cardId, tab) in converted) {
      final spec = specOf(cardId);
      final c = spec.getConstraints(DisplayMode.normal);
      final narrowest = widthCasesFor(spec, minScreen: 0).first;
      final rows = c.minHeightRows - 1;

      for (final tag in stressLocales) {
        testWidgets(
            '$cardId t$tab scrolls at $rows rows in $tag, and stays reachable',
            (tester) async {
          final incidents = await pump(tester,
              cardId: cardId,
              widthCase: narrowest,
              tabIndex: tab,
              rows: rows,
              locale: localeFor(tag));

          expect(incidents, isEmpty,
              reason: 'content taller than the card is overflowing instead of '
                  'scrolling — the tab is no longer opted in, or something in '
                  'it fills vertically again: ${incidents.join(', ')}');

          final shortfall = cardContentScrollShortfall(tester);
          expect(shortfall, isNotNull,
              reason: 'no scrolling content region, so this content is '
                  'painted outside the card.');
          expect(shortfall, greaterThan(0.0),
              reason: 'the content fits a box one row shorter than the card '
                  'ships at, so this test no longer loads the mechanism it '
                  'exists to test. Lower the row count rather than deleting '
                  'the assertion — and check `rows: 1` is still unusable.');

          // Silent scrolling is the "clean but unreadable" failure this epic
          // keeps meeting. The thumb only paints when there is extent to scroll
          // (`ScrollbarPainter.paint` returns early otherwise), so asserting the
          // widget is present asserts the affordance appears exactly here and
          // costs nothing on the cards that fit.
          expect(
              find.descendant(
                  of: find.byType(AppCard), matching: find.byType(Scrollbar)),
              findsOneWidget,
              reason: 'the scrolling region has no scrollbar, so the content '
                  'past the fold is hidden with nothing on screen saying so.');

          // Reachable = inside the viewport plus what can be scrolled to.
          // Content past that is laid out and unreachable at every offset, which
          // looks exactly like scrolling and is not.
          final viewport = cardContentViewport(tester);
          final reachableBottom = viewport.bottom + shortfall!;
          final texts = regionTexts(tester);
          expect(texts, isNotEmpty,
              reason: 'the scrolling region rendered no text at all, so the '
                  'loop below asserts nothing.');
          for (final t in texts) {
            final rect = tester.getRect(find.byWidget(t));
            expect(rect.bottom, lessThanOrEqualTo(reachableBottom + 1.0),
                reason: '"${t.data}" ends '
                    '${(rect.bottom - reachableBottom).toStringAsFixed(1)}px '
                    'past the furthest the user can scroll, so it cannot be '
                    'read at any offset. Scrollable extent: '
                    '${(viewport.height + shortfall).toStringAsFixed(1)}px.');
          }
        });
      }
    }
  });

  group('the conversion changed no picture', () {
    // What made each of these three tabs convertible: the child the deleted flex
    // used to hold does not grow with the box, so the flex was distributing air.
    // These are the numbers that claim is made of — pinned here, because "the
    // donut is a fixed size" is exactly the kind of statement that silently stops
    // being true when a chart component gains an intrinsic-height mode.
    //
    // The air itself does move: `CardScrollRegion(fillViewport: true)` gives the
    // content the viewport height as a *floor* with no ceiling, so the `Column`
    // packs to the top and the spare height collects at the bottom of the card
    // instead of being spread around the picture. That is the established look —
    // #1267's Channels tab has rendered that way since it converted — and it is
    // why the tests below assert the child's *size*, not its centre.

    for (final (cardId, tab) in [
      ('device_analytics', 0),
      ('traffic_analysis', 2)
    ]) {
      final spec = specOf(cardId);
      final c = spec.getConstraints(DisplayMode.normal);
      for (final rows in [c.minHeightRows, c.maxHeightRows]) {
        testWidgets('$cardId t$tab keeps its 180px donut at $rows rows',
            (tester) async {
          await pump(tester,
              cardId: cardId,
              widthCase: desktopCaseFor(spec),
              tabIndex: tab,
              rows: rows,
              locale: localeFor('en'));

          final pie = find.descendant(
              of: find.byType(AppCard), matching: find.byType(AppPieChart));
          expect(pie, findsOneWidget);
          final rect = tester.getRect(pie);
          expect(rect.width, closeTo(180.0, 0.5),
              reason: '`AppPieChart` derives its geometry from `size:` and '
                  'ignores the box it is given — that is what made the '
                  'vertical flex around it removable. A different width here '
                  'means it no longer does, and the conversion has to be '
                  're-measured.');
          expect(rect.height, closeTo(180.0, 0.5),
              reason: 'the donut grew with its box, so the flex this '
                  'conversion deleted was sizing it after all.');

          // The air is spare, not scrolled: at the card's maximum height the
          // extra 544px collects below the content rather than pushing anything
          // past the viewport.
          expect(cardContentScrollShortfall(tester), 0.0,
              reason: 'the tab scrolls at $rows rows, which is taller than it '
                  'ships at — `fillViewport` is meant to floor the content at '
                  'the viewport height, not stretch it past it.');
        });
      }
    }

    // system_status's gauges are the opposite reading from network_health's, and
    // the reason one card converted and the other did not: `AppGauge` respects
    // its constraints, so the only safe conversion is one where the *width* term
    // is what binds. Here it always is — `math.min` picks
    // `(maxWidth - AppSpacing.md) / 2` at the narrow end and the natural 100px
    // above it — and the height term, now permanently unbounded, never
    // participates. Both numbers were measured identical before and after the
    // flip.
    for (final (label, width, expected) in [
      ('the narrowest card', 'narrowest', 72.7),
      ('the desktop card', 'desktop', 100.0),
    ]) {
      testWidgets('system_status t0 gauges are width-bound at $label',
          (tester) async {
        final spec = specOf('system_status');
        final c = spec.getConstraints(DisplayMode.normal);
        final widthCase = width == 'narrowest'
            ? widthCasesFor(spec, minScreen: 0).first
            : desktopCaseFor(spec);

        await pump(tester,
            cardId: 'system_status',
            widthCase: widthCase,
            tabIndex: 0,
            rows: c.minHeightRows,
            locale: localeFor('en'));

        final gauges = find.descendant(
            of: find.byType(AppCard), matching: find.byType(AppGauge));
        expect(gauges, findsNWidgets(2));
        final first = tester.getRect(gauges.at(0));
        final second = tester.getRect(gauges.at(1));

        for (final rect in [first, second]) {
          expect(rect.width, closeTo(expected, 0.5),
              reason: 'the gauge is ${rect.width.toStringAsFixed(1)}px wide at '
                  'the ${widthCase.widthKey}px card, not $expected. #1296 '
                  'removed this row\'s `Expanded` on the measurement that the '
                  'width term is the binding one at every realization; if that '
                  'changed, the tab is no longer safely in the net.');
          expect(rect.height, closeTo(rect.width, 0.5),
              reason: 'the gauge is no longer square, so the unbounded height '
                  'it now receives is reaching it.');
        }
        expect((first.width - second.width).abs(), lessThan(0.5),
            reason: 'the two gauges are different sizes, so one of them is '
                'being sized by something other than the shared '
                '`LayoutBuilder` reading.');

        // The readability of what is *inside* those circles is
        // `usp_gauge_center_readability_test.dart`'s (#1234 AC4); this is only
        // the geometry the conversion rests on.
      });
    }
  });

  group('the loudest decline rests on a measurement', () {
    // network_health t0 is the tab a reader would convert next: it has the same
    // shape as system_status t0 — `Expanded(Center(AppGauge(...)))` — and the same
    // flag would compile. It is out anyway, and the difference is one number.
    //
    // `AppGauge` **respects** its incoming constraints. On system_status the
    // binding term is the *width* (two circles in one row), so the height that
    // `Expanded` supplied was never used and taking it away changed nothing. Here
    // there is one circle, `size: 120` is above what the box grants, and the box
    // is what wins: 87px in `de` at the narrowest normal-form realization
    // (366.3px, below which the card is not showing tabs at all), 99–103px at the
    // desktop realization. Unbind that height and the gauge grows to its declared
    // 120px, pushing 17–33px of the metric row below the fold **at the height the
    // card ships** — which the arrival assertion above forbids, and which only a
    // taller `minHeightRows` would fix. #1296 excludes card heights.
    //
    // So the decline is a live measurement, not a preference, and this test is
    // where it stays live: if `AppGauge` ever stops reading its box (the way
    // `AppPieChart` never has), the premise is gone and the tab should be
    // re-measured for conversion. That is what a failure here means — not "make
    // the number pass".
    for (final tag in ['en', 'de']) {
      testWidgets('network_health t0 gauge is sized by its box in $tag',
          (tester) async {
        final spec = specOf('network_health');
        final c = spec.getConstraints(DisplayMode.normal);
        final incidents = await pump(tester,
            cardId: 'network_health',
            widthCase: desktopCaseFor(spec),
            tabIndex: 0,
            rows: c.minHeightRows,
            locale: localeFor(tag));
        expect(incidents, isEmpty,
            reason: 'the declined tab is overflowing at the desktop width, '
                'which is a defect of its own: ${incidents.join(', ')}');

        final gauge = find.descendant(
            of: find.byType(AppCard), matching: find.byType(AppGauge));
        expect(gauge, findsOneWidget);
        final rect = tester.getRect(gauge);

        // 120 wide and 103 tall at this width in `en` — the two readings of one
        // circle, and the whole decline is in the gap between them. The width is
        // the declared `size: 120` untouched, so nothing about this gauge is
        // width-bound (the opposite of system_status's pair, and why that pair
        // converted). The height is what `Expanded` rations, and it is rationing
        // 17px of it here.
        expect(rect.width, closeTo(120.0, 0.5),
            reason: 'the gauge is no longer laying out at its declared '
                '`size: 120` in width, so the width has become a binding term '
                'too and this decline\'s reasoning — that the *height* is the '
                'one the flex supplies — needs re-deriving.');
        expect(rect.height, lessThan(115.0),
            reason: 'the gauge is rendering at (or within 5px of) its full '
                'declared 120px height, so its box is no longer the binding '
                'constraint — either the card grew or `AppGauge` stopped '
                'reading its constraints. The decline recorded in §2.10j was '
                'measured on exactly this gap (17px here, 33px at the '
                'narrowest normal-form width): with the gap gone, the tab is a '
                'conversion candidate again and should be re-measured rather '
                'than left declined on a stale number.');
        expect(rect.height, greaterThan(60.0),
            reason: 'the gauge has been squeezed past anything this test '
                'measured (87px was the worst reading, in `de` at the 366px '
                'card); a reading this small is a different defect and belongs '
                'to #1291\'s threshold, not here.');
      });
    }
  });
}
