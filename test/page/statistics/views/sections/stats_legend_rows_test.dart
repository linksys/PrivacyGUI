@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_cpu_distribution_section.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_device_distribution_section.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_resource_trends_section.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_signal_quality_section.dart';

import '../../../../mocks/provider_overrides/mock_statistics.dart';
import '../../../../mocks/test_data/scenes/statistics_scene_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/text_readability_probe.dart';
import '../../../../util/overflow_probe.dart';
import '../../../../util/statistics/stats_section_probe.dart';

/// Overflow + readability guards for the four legend rows on the Statistics
/// page's **Devices and System** tabs (#1488).
///
/// ## Why this file exists
///
/// Golden CI reported one overflow — `stats_signal_quality_section.dart:100`,
/// 30px at a 480px screen in `ru`. Re-measuring the page found **four**
/// overflowing `Row`s across 35 of 468 cells, 34 of them at 320px, which golden
/// CI has no device for. Every one was the same construction as the row #1252
/// fixed one tab over (`stats_traffic_monitor_legend_test.dart`): a legend `Row`
/// with `MainAxisAlignment.center` and N inflexible children, no `Wrap` and no
/// `Flexible`.
///
/// The gate could not see them either, for a different reason: it swept tab 0
/// only, so these eleven sections were never laid out at any width. That hole is
/// #1489, which lands the 468-cell sweep this file's four sites live in. **These
/// guards are not that sweep** — they are the per-section pins that say *what
/// shape* was chosen and that the labels stayed readable, at the four narrow
/// screens the page really produces and in the locales each site was measured
/// worst in.
///
/// ## One file, four sites
///
/// Rather than four near-identical copies of #1252's file. The four sites share
/// the fixture, the pump and both verdicts, and differ in exactly two things —
/// the section widget and the labels that must stay whole — so they are a table
/// ([_sites]), not four files. That is the same call #1270 made when the third
/// copy of this pump appeared.
///
/// ## The degradation is per site, and that is not a hedge
///
/// `Wrap` can only reflow where there is more than one group, and the four sites
/// do not have more than one group each:
///
///   | site                    | groups | degradation                        |
///   |-------------------------|-------:|------------------------------------|
///   | signal quality          | 4 (data-driven) | `Wrap`                    |
///   | device distribution     | 3      | `Wrap`                             |
///   | resource trends         | 2      | `Wrap`                             |
///   | cpu distribution        | **1**  | `Flexible` + bounded `maxLines`    |
///
/// The last row is the one that makes the table load-bearing. Its `Row` holds a
/// single dot and a single `cpuUsageSamples(...)` label; `Wrap` hands each child
/// loose constraints, so a label wider than the row overflows inside a `Wrap`
/// exactly as it does inside a `Row`. That site needs the *text* to wrap, not the
/// row — and a PR that applied `Wrap` four times would leave `fr` / `fr_CA` red.
/// [_wrapSites] and [_softWrapSite] are therefore judged by different groups
/// below.
///
/// ## Readability, per rule 4 of the layout-gate skill
///
/// Every overflow assertion here has a readability assertion beside it, because
/// all four labels carry **numbers**: "Excellent: 2", "WiFi: 5", "Avg: 49%",
/// "CPU usage samples: 10". An ellipsis lands mid-number and a half-shown
/// statistic misinforms in a way a missing one does not (density design §2.10a
/// point 2), so the chosen degradations move text rather than dropping it, and
/// the groups below assert that: every label whole, unellipsized, not clipped,
/// and the reflow bounded to two lines at the production floor.
///
/// ## Mutation ledger
///
/// Every group here was shown to fail under a mutation of the code it guards — a
/// layout test that cannot fail is worse than none, because it reports the shape
/// as pinned (precedent: `stats_traffic_monitor_legend_test.dart`).
///
///   | mutation                                       | what failed                 |
///   |------------------------------------------------|-----------------------------|
///   | all four rows at their pre-fix shape            | 14 overflow cells @288px    |
///   | signal quality `Wrap(spacing: 200)` → 4 runs    | 4 bounded-reflow tests      |
///   | cpu label `maxLines: 2` → `1`                   | 2 clipped tests (fr, fr_CA) |
///   | cpu label's `Flexible` + `maxLines` removed      | 3 line-capped tests         |
///
/// The last two rows are the pair worth reading together: the cap must exist (a
/// lone unflexed label cannot yield, so it would grow the legend into the chart)
/// **and** must be high enough for French. One assertion cannot hold both ends.
void main() {
  setUpAll(() async {
    // Real fonts: text widths — and therefore overflow — are meaningless under
    // the Ahem block font.
    await loadAppFonts();
  });

  /// Pumps one section once through the shared Statistics harness. Every site
  /// gets `gateStatisticsOverrides()` — the same scene #1489's two new gate cases
  /// sweep — so a green cell here and a green cell there are about one fixture.
  Future<List<OverflowIncident>> overflowsAt(
    WidgetTester tester, {
    required Widget section,
    required double screenWidth,
    required String tag,
  }) =>
      probeSectionOverflow(
        tester,
        section: section,
        screenWidth: screenWidth,
        locale: supportedLocaleFor(tag),
        overrides: gateStatisticsOverrides(),
      );

  for (final site in _sites) {
    group('${site.name} legend row is clean (#1488)', () {
      // The locales this site was measured worst in, not a fixed set: the four
      // sites fail in four different locale sets (26 / 7 / 5 / 2 of 26), and a
      // shared list would be either mostly inert or mostly missing.
      for (final tag in site.locales) {
        for (final screen in narrowStatsScreens) {
          testWidgets(
            'no overflow at ${sectionWidthFor(screen).toStringAsFixed(0)}px '
            'section (${screen.toStringAsFixed(0)}px screen) in $tag',
            (tester) async {
              final overflows = await overflowsAt(
                tester,
                section: site.section(),
                screenWidth: screen,
                tag: tag,
              );
              expect(
                overflows,
                isEmpty,
                reason: '${site.name} legend overflows in $tag at a '
                    '${screen.toStringAsFixed(0)}px screen '
                    '(${sectionWidthFor(screen).toStringAsFixed(0)}px section): '
                    '${overflows.join(', ')}',
              );
            },
          );
        }
      }
    });
  }

  // The coordinate golden CI reported, asserted directly rather than by
  // implication (#1488 AC4). 480px is not in [narrowStatsScreens] — the list
  // holds the widths the *page* pinches at — and 320px is the stricter case
  // anyway (238px of row against 398px), so this test proves nothing 320px does
  // not. What it pins is the report: `ru` at a 480px screen measured +30.0px at
  // `stats_signal_quality_section.dart:100`, byte-identical to CI's, so it is the
  // one cell that can say "the ticket's own bug is gone" rather than "the row is
  // clean where we chose to look".
  testWidgets(
    'the golden-CI report no longer reproduces: signal quality is clean in ru '
    'at a 480px screen (#1488 AC4)',
    (tester) async {
      final overflows = await overflowsAt(
        tester,
        section: const StatsSignalQualitySection(),
        screenWidth: 480.0,
        tag: 'ru',
      );
      expect(
        overflows,
        isEmpty,
        reason: 'this is the golden-CI coordinate itself (+30.0px before the '
            'fix): ${overflows.join(', ')}',
      );
    },
  );

  group('the reflowed legends stay readable (#1488)', () {
    // One test per (site, locale) at the production floor only: 320px is where 34
    // of the 35 measured cells were, it is the narrowest realization the row ever
    // gets, and a legend legible at 238px is legible at 537px.
    for (final site in _wrapSites) {
      for (final tag in site.locales) {
        testWidgets('${site.name}: every label is whole in $tag',
            (tester) async {
          await overflowsAt(
            tester,
            section: site.section(),
            screenWidth: 320.0,
            tag: tag,
          );
          final l10n = await AppLocalizations.delegate.load(
            supportedLocaleFor(tag),
          );

          final tops = <double>[];
          for (final label in site.labels(l10n)) {
            final finder = find.text(label);
            expect(
              finder,
              findsOneWidget,
              reason: '${site.name} must still render "$label" in $tag — the '
                  '`Wrap` moves a group to the next line, it may not drop it',
            );
            final text = tester.widget<Text>(finder);
            expect(
              text.overflow,
              isNot(TextOverflow.ellipsis),
              reason: '"$label" must never ellipsize: it ends in a count, and '
                  'an ellipsis lands mid-number',
            );
            expect(
              text.maxLines,
              isNull,
              reason: '"$label" must not be line-capped — the row reflows, the '
                  'label does not',
            );
            expect(
              tester.isTextClipped(finder),
              isFalse,
              reason: '"$label" was clipped in $tag at 320px',
            );
            if (!kLocalesWithoutWordSpaces.contains(tag)) {
              expect(
                tester.hasSplitToken(finder),
                isFalse,
                reason: '"$label" broke mid-word in $tag at 320px — granted '
                    '${tester.paragraphOf(finder).size.width.toStringAsFixed(1)}px, '
                    'widest token '
                    '${tester.widestTokenWidth(finder).toStringAsFixed(1)}px',
              );
            }
            tops.add(tester.getTopLeft(finder).dy);
          }

          // The bounded-reflow half of rule 4: "it stopped overflowing" is
          // satisfied by a legend shredded into one group per line. Runs are
          // counted off the labels' own y positions, clustered at 2px, because
          // `Wrap` exposes no run count.
          expect(
            _runCount(tops),
            lessThanOrEqualTo(2),
            reason: '${site.name} legend took more than two lines in $tag at '
                '320px (label tops: $tops)',
          );
        });
      }
    }

    for (final tag in _softWrapSite.locales) {
      testWidgets(
        '${_softWrapSite.name}: the label soft-wraps within its line budget '
        'in $tag',
        (tester) async {
          await overflowsAt(
            tester,
            section: _softWrapSite.section(),
            screenWidth: 320.0,
            tag: tag,
          );
          final l10n = await AppLocalizations.delegate.load(
            supportedLocaleFor(tag),
          );
          final label = _softWrapSite.labels(l10n).single;
          final finder = find.text(label);

          expect(
            finder,
            findsOneWidget,
            reason: 'the sample count ("$label") is this section\'s only '
                'legend — soft-wrapping it may not drop it',
          );
          final text = tester.widget<Text>(finder);
          expect(
            text.overflow,
            isNot(TextOverflow.ellipsis),
            reason: '"$label" ends in the sample count; an ellipsis would eat '
                'the number this legend exists to state',
          );
          expect(
            text.maxLines,
            isNotNull,
            reason: 'the label must be line-capped: it is the only child that '
                'can yield, so an uncapped one would grow the legend into the '
                'chart instead of overflowing',
          );
          expect(
            text.maxLines,
            lessThanOrEqualTo(2),
            reason:
                'two lines is the budget — the chart above it is `Expanded` '
                'and yields the height, but not without limit',
          );
          expect(
            tester.isTextClipped(finder),
            isFalse,
            reason: '"$label" hit its `maxLines` cap in $tag at 320px, so the '
                'cap is too low for this string',
          );
          expect(
            tester.textLineCount(finder),
            lessThanOrEqualTo(text.maxLines!),
            reason: '"$label" painted on more lines than its cap allows',
          );
          if (!kLocalesWithoutWordSpaces.contains(tag)) {
            expect(
              tester.hasSplitToken(finder),
              isFalse,
              reason: '"$label" broke mid-word in $tag at 320px — granted '
                  '${tester.paragraphOf(finder).size.width.toStringAsFixed(1)}px, '
                  'widest token '
                  '${tester.widestTokenWidth(finder).toStringAsFixed(1)}px',
            );
          }
        },
      );
    }
  });
}

/// One of the four legend rows #1488 measured.
class _LegendSite {
  /// Names the section in test names and failure prose.
  final String name;

  /// Built per test, never shared: one pump per tree (see [probeSectionOverflow]).
  final Widget Function() section;

  /// The locale tags this site overflowed in, worst first. Per-site because the
  /// four sites' failing sets are 26 / 7 / 5 / 2 of 26 locales.
  final List<String> locales;

  /// The legend labels that must survive the degradation whole, derived from the
  /// same fixture the section is pumped with rather than hard-coded — a
  /// hand-written expectation would drift from `statistics_scene_data.dart` and
  /// the test would fail for the wrong reason.
  final List<String> Function(AppLocalizations l10n) labels;

  const _LegendSite({
    required this.name,
    required this.section,
    required this.locales,
    required this.labels,
  });
}

/// The fixture's own device distribution — the section reads exactly this.
final _distribution = testDeviceAnalyticsState.current!;

/// The CPU/memory figures `StatsResourceTrendsSection` computes, derived the way
/// it derives them so a fixture edit moves both together.
final _cpu =
    testSystemMonitorState.history.map((s) => s.cpuPercent.toDouble()).toList();
final _mem = testSystemMonitorState.history
    .map((s) => s.memoryPercent.toDouble())
    .toList();

final _sites = <_LegendSite>[
  // 26 of 26 locales at 320px, plus `ru` at 480px — which is the coordinate
  // golden CI reported (30.0px), so the four worst locales here are the top four
  // of the whole measurement: ru 190, th 136, es 125, pl 119.
  //
  // Four and not all 26, though this is the site where all 26 failed: what this
  // suite adds over the gate is *readability* — no ellipsis, no clipped label, no
  // mid-word break, at most two runs — and that costs a pump per (site, locale).
  // Overflow itself is held for all 26 by `page.statistics_devices`, which sweeps
  // this section at 9 widths × 26 locales (`page_surface_cases.dart`), so the 22
  // not listed here are measured, just not for legibility. These four are the
  // widest realizations of the row, so a regression in it reddens here first.
  _LegendSite(
    name: 'signal quality',
    section: () => const StatsSignalQualitySection(),
    locales: const ['ru', 'th', 'es', 'pl'],
    labels: (l10n) => [
      '${l10n.excellent}: ${_distribution.signalLevelDistribution[3]}',
      '${l10n.good}: ${_distribution.signalLevelDistribution[2]}',
      '${l10n.fair}: ${_distribution.signalLevelDistribution[1]}',
      '${l10n.poor}: ${_distribution.signalLevelDistribution[0]}',
    ],
  ),
  // 5 of 26 at 320px — de, el, es, es_AR, fi; worst `el` at 28px.
  _LegendSite(
    name: 'device distribution',
    section: () => const StatsDeviceDistributionSection(),
    locales: const ['el', 'de', 'es', 'fi'],
    labels: (l10n) => [
      l10n.wifiCount(_distribution.wifiCount),
      l10n.wiredCount(_distribution.wiredCount),
      l10n.nOffline(_distribution.offlineCount),
    ],
  ),
  // 7 of 26 at 320px — ar, de, fi, fr_CA, id, it, nb; worst `de` at 74px, which
  // is also the case that decides whether `Wrap` is enough here: `de`'s
  // `avgPeak` is the longest single group of the two, so if it did not fit 238px
  // on its own no reflow would help.
  _LegendSite(
    name: 'resource trends',
    section: () => const StatsResourceTrendsSection(),
    locales: const ['de', 'fi', 'fr_CA', 'it'],
    labels: (l10n) => [
      l10n.avgPeak(
        (_cpu.reduce((a, b) => a + b) / _cpu.length).round(),
        _cpu.reduce((a, b) => a > b ? a : b).round(),
      ),
      l10n.avg((_mem.reduce((a, b) => a + b) / _mem.length).round()),
    ],
  ),
  _softWrapSite,
];

/// The one site `Wrap` cannot fix — a single dot and a single label.
///
/// 2 of 26 locales at 320px (fr, fr_CA, ~26px). `de` is measured clean and is
/// pinned anyway: its `cpuUsageSamples` is the longest string after French's, so
/// it is the case a wording change would break next.
final _softWrapSite = _LegendSite(
  name: 'cpu distribution',
  section: () => const StatsCpuDistributionSection(),
  locales: const ['fr', 'fr_CA', 'de'],
  labels: (l10n) =>
      [l10n.cpuUsageSamples(testSystemMonitorState.history.length)],
);

/// The three sites whose degradation is a `Wrap`.
///
/// Split by identity, not by [_LegendSite.name]: the name is display prose for test
/// names and failure output, so a wording change to it would silently put the
/// soft-wrap site into this list — where the assertions are `maxLines` is null and the
/// run count is at most 2, both of which are false of it by design.
final _wrapSites =
    _sites.where((s) => !identical(s, _softWrapSite)).toList(growable: false);

/// How many lines a `Wrap` laid its groups out on, from the groups' own label
/// tops.
///
/// `Wrap` reports no run count and `RenderWrap` exposes none, so this clusters
/// the y positions instead. The 2px tolerance is for cross-run noise only: with
/// `runSpacing: AppSpacing.xs` and a label ~14px tall the pitch between two real
/// runs is ≥ 18px, so no cluster can swallow one.
int _runCount(List<double> tops) {
  final runs = <double>[];
  for (final top in tops) {
    if (!runs.any((r) => (r - top).abs() <= 2.0)) runs.add(top);
  }
  return runs.length;
}
