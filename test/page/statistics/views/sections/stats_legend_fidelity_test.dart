import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_connection_trends_section.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_system_gauges_section.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_wifi_speed_section.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/provider_overrides/mock_statistics.dart';
import '../../../../mocks/test_data/scenes/statistics_scene_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/text_readability_probe.dart';
import '../../../../util/statistics/stats_section_probe.dart';

/// Pins two properties of the #1324 legend migration that no other test
/// reached (validity audit round 1, mutants M3 / M4):
///
/// - **M3**: the CPU & Memory gauge legend stays start-aligned. A `Wrap`
///   shrinks to its content and the parent `Column` centres it, so without the
///   full-width box the legend drifts to the middle of the card.
/// - **M4**: a legend derived from a chart's `series` list keys *every*
///   series the chart draws. Dropping one (e.g. `series.take(1)`) must fail.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  final locale = supportedLocaleFor('en');

  Future<void> pumpSection(
    WidgetTester tester,
    Widget section, {
    List<Override>? overrides,
  }) async {
    await probeSectionOverflow(
      tester,
      section: section,
      screenWidth: 1280,
      locale: locale,
      overrides: overrides ?? gateStatisticsOverrides(),
    );
  }

  List<AppChartLegendEntry> entries(WidgetTester tester) => tester
      .widgetList<AppChartLegendEntry>(find.byType(AppChartLegendEntry))
      .toList();

  group('M3: CPU & Memory gauge legend is start-aligned (#1324)', () {
    testWidgets('both entries sit on one run at the content start edge',
        (tester) async {
      await pumpSection(tester, const StatsSystemGaugesSection());

      final legendFinder = find.byType(AppChartLegendEntry);
      expect(legendFinder, findsNWidgets(2),
          reason: 'premise: the CPU and Memory entries must render');

      // The uptime row spans the section content width, so its edges are the
      // content edges the legend must share.
      final contentLeft = tester.getTopLeft(find.byType(UspInfoRow)).dx;
      final contentRight = tester.getTopRight(find.byType(UspInfoRow)).dx;
      final first = tester.getRect(legendFinder.at(0));
      final second = tester.getRect(legendFinder.at(1));

      expect(contentRight - contentLeft,
          greaterThan((first.width + second.width) * 2),
          reason: 'premise: the section is wide enough that a centred legend '
              'would sit visibly away from the start edge');

      expect(first.left, moreOrLessEquals(contentLeft, epsilon: 0.5),
          reason: 'the first legend entry must start at the content start '
              'edge, not be centred in the column');
      expect(second.top, moreOrLessEquals(first.top, epsilon: 0.5),
          reason: 'at 1280px both entries fit on one run');
      expect(second.left, greaterThan(first.right),
          reason: 'the Memory entry follows the CPU entry on the same run');
    });
  });

  group('M4: series-derived legends key every series the chart draws (#1324)',
      () {
    // The gate scene carries no WiFi clients, so the wifi-speed chart (and
    // its legend) never renders there. This scene adds two active clients.
    List<Override> wifiClientOverrides() => statisticsOverrides(
          trafficState: testTrafficState,
          deviceAnalyticsState: testDeviceAnalyticsState,
          systemMonitorState: testSystemMonitorState,
          systemInfoData: testSystemInfoData,
          portForwardingData: testPortForwardingData,
          wifiData: WifiData(
            codegenContext: testWifiData.codegenContext,
            radioModels: testWifiData.radioModels,
            wifiClientMap: const {
              'AA:BB:CC:DD:EE:01': WifiClientUIModel(
                macAddress: 'AA:BB:CC:DD:EE:01',
                signalStrength: -50,
                noise: -90,
                lastDataDownlinkRate: 300000,
                lastDataUplinkRate: 120000,
                active: true,
              ),
              'AA:BB:CC:DD:EE:02': WifiClientUIModel(
                macAddress: 'AA:BB:CC:DD:EE:02',
                signalStrength: -60,
                noise: -90,
                lastDataDownlinkRate: 150000,
                lastDataUplinkRate: 40000,
                active: true,
              ),
            },
          ),
        );

    void expectLegendMatchesChart(WidgetTester tester) {
      final chart = tester.widget<AppBarChart>(find.byType(AppBarChart));
      final chartLabels = chart.series.map((s) => s.label).toList();
      expect(chartLabels, hasLength(greaterThanOrEqualTo(2)),
          reason: 'premise: the chart must draw at least two series, or '
              'dropping one could not be detected');

      final legend = entries(tester);
      expect(legend.map((e) => e.label).toList(), chartLabels,
          reason: 'the legend must key every series the chart drew, in order');
      for (var i = 0; i < legend.length; i++) {
        expect(legend[i].color, chart.series[i].color,
            reason: 'entry $i must use its series colour');
      }
    }

    testWidgets('wifi speed legend', (tester) async {
      await pumpSection(tester, const StatsWifiSpeedSection(),
          overrides: wifiClientOverrides());
      expectLegendMatchesChart(tester);
    });

    testWidgets('connection trends legend', (tester) async {
      await pumpSection(tester, const StatsConnectionTrendsSection());
      expectLegendMatchesChart(tester);
    });
  });
}
