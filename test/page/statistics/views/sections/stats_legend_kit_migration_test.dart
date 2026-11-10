import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_correlation_section.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_error_rates_section.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_traffic_trends_section.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/provider_overrides/mock_statistics.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/dashboard/text_readability_probe.dart';
import '../../../../util/statistics/stats_section_probe.dart';

/// Pins the three declared visible changes of #1324 — the statistics legend
/// moving onto the kit's `AppChartLegend` / `AppChartLegendEntry` / `ChartMark`.
///
/// - (a) The two dashed series are keyed by a dashed `ChartMark.line`, the ink
///   the chart actually draws, instead of a solid bar / a dot.
/// - (b) The dual-axis right-hand series' label names its unit, on the
///   statistics page and on the dashboard System Status card.
/// - (c) The error-rates `discards` series and its legend use the theme's
///   warning colour instead of a hard-coded `Colors.orange`.
///
/// Every test here is red on the base (`ecd85d61d`): there the marks are a
/// `Container` / a `StatsLegendDot`, no `AppChartLegendEntry` exists on the
/// statistics page, the unit-bearing label does not exist, and the discards
/// colour is `Colors.orange`.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  final locale = supportedLocaleFor('en');

  Future<void> pumpSection(WidgetTester tester, Widget section) async {
    await probeSectionOverflow(
      tester,
      section: section,
      screenWidth: 1280,
      locale: locale,
      overrides: gateStatisticsOverrides(),
    );
  }

  List<AppChartLegendEntry> entries(WidgetTester tester) => tester
      .widgetList<AppChartLegendEntry>(find.byType(AppChartLegendEntry))
      .toList();

  AppChartLegendEntry entryLabelled(WidgetTester tester, String label) {
    final all = entries(tester);
    final matches = all.where((e) => e.label == label).toList();
    expect(matches, hasLength(1),
        reason: 'expected exactly one legend entry labelled "$label"; '
            'rendered entries: ${all.map((e) => e.label).toList()}');
    return matches.single;
  }

  group('(a) dashed series are keyed by a dashed stroke (#1324)', () {
    testWidgets('traffic trends: packets/s entry is a dashed line',
        (tester) async {
      await pumpSection(tester, const StatsTrafficTrendsSection());
      final l = await AppLocalizations.delegate.load(locale);

      final packets = entryLabelled(tester, l.packetsPerSec);
      expect(packets.mark.shape, ChartMarkShape.stroke);
      expect(packets.mark.dashed, isTrue);
      // The chart leaves `showDots` at its default (true), so the legend
      // carries the point marker too.
      expect(packets.mark.dot, isTrue);

      // The solid bytes/s series stays solid.
      final bytes = entryLabelled(tester, l.bytesPerSec);
      expect(bytes.mark.dashed, isFalse);
    });

    testWidgets('correlation: traffic-rate entry is a dashed line',
        (tester) async {
      await pumpSection(tester, const StatsCorrelationSection());
      final l = await AppLocalizations.delegate.load(locale);

      final traffic = entryLabelled(tester, l.trafficRateBytesPerSec);
      expect(traffic.mark, const ChartMark.line(dashed: true, dot: true));

      final cpu = entryLabelled(tester, l.cpuPercentLabel);
      expect(cpu.mark.dashed, isFalse);
    });
  });

  group('(b) dual-axis right-hand label names its unit (#1324)', () {
    testWidgets('statistics correlation section', (tester) async {
      await pumpSection(tester, const StatsCorrelationSection());
      final l = await AppLocalizations.delegate.load(locale);

      final traffic = entryLabelled(tester, l.trafficRateBytesPerSec);
      expect(traffic.label, contains(l.bytesPerSec),
          reason: 'the right-hand series must name the unit the secondary '
              'axis is read in');
      expect(entries(tester).where((e) => e.label == l.trafficRate), isEmpty,
          reason: 'the bare, unit-less label must be gone from this legend');
    });

    testWidgets('dashboard System Status correlation tab', (tester) async {
      final narrowest = narrowestRealizationOf(3, minScreen: 0)!;
      await probeCardOverflow(
        tester,
        cardId: 'system_status',
        widthCase: CardWidthCase(
          screenWidth: narrowest.screenWidth,
          cardWidth: narrowest.cardWidth,
          columnSpan: 3,
          label: 'min',
        ),
        cardHeightRows: 3,
        tabIndex: 3,
        locale: locale,
      );
      final l = await AppLocalizations.delegate.load(locale);

      final traffic = entryLabelled(tester, l.trafficRateBytesPerSec);
      expect(traffic.label, contains(l.bytesPerSec));
    });
  });

  group('(c) discards uses the theme warning colour (#1324)', () {
    testWidgets('chart series and legend mark', (tester) async {
      await pumpSection(tester, const StatsErrorRatesSection());
      final l = await AppLocalizations.delegate.load(locale);

      final ctx = tester.element(find.byType(StatsErrorRatesSection));
      final warning =
          Theme.of(ctx).extension<AppColorScheme>()!.semanticWarning;
      expect(warning, isNot(Colors.orange),
          reason: 'premise: the theme warning colour must differ from the old '
              'hard-coded orange, or this test proves nothing');

      final chart = tester.widget<AppLineChart>(find.byType(AppLineChart));
      final discards = chart.series.singleWhere((s) => s.label == l.discards);
      expect(discards.color, warning);

      // The discards legend entry is the second one (errors, then discards).
      final legend = entries(tester);
      expect(legend, hasLength(2));
      expect(legend[1].color, warning);
      expect(legend[1].color, isNot(Colors.orange));
    });
  });
}
