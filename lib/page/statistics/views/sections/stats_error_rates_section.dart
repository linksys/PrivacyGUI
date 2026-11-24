import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Error/discard rate area chart over time.
class StatsErrorRatesSection extends ConsumerWidget {
  const StatsErrorRatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: loc(context).networkErrorRates,
      subtitle: loc(context).networkErrorRatesSubtitle,
      chartHeight: 280,
      child: state.history.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                loc(context).enableTrafficMonitorForErrorData,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state),
    );
  }

  Widget _buildChart(BuildContext context, TrafficAnalysisState state) {
    final colorScheme = Theme.of(context).colorScheme;
    // The discards series uses the theme's warning colour, with the same
    // fallback as `app_menu_card.dart` (#1324).
    final discardColor =
        Theme.of(context).extension<AppColorScheme>()?.semanticWarning ??
            Colors.orange;
    final history = state.history;

    final errorData = history
        .map(
            (s) => s.interfaces[TrafficInterface.wan]?.totalErrorsPerSec ?? 0.0)
        .toList();
    final discardData = history
        .map((s) =>
            s.interfaces[TrafficInterface.wan]?.totalDiscardsPerSec ?? 0.0)
        .toList();

    final avgErr = errorData.isEmpty
        ? 0.0
        : errorData.reduce((a, b) => a + b) / errorData.length;
    final peakErr = errorData.isEmpty ? 0.0 : errorData.reduce(math.max);
    final avgDisc = discardData.isEmpty
        ? 0.0
        : discardData.reduce((a, b) => a + b) / discardData.length;

    final allValues = [...errorData, ...discardData];
    final maxVal = allValues.isEmpty ? 1.0 : allValues.reduce(math.max);
    final yMax = maxVal < 0.1 ? 1.0 : maxVal * 1.3;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppLineChart(
              series: [
                AppChartSeries(
                  label: loc(context).errors,
                  data: errorData,
                  filled: true,
                  color: colorScheme.error,
                ),
                AppChartSeries(
                  label: loc(context).discards,
                  data: discardData,
                  color: discardColor,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: yMax),
              yLabelFormatter: (v) => v.toStringAsFixed(1),
              tooltipFormatter: statsFormatRateTooltip,
              enableZoom: true,
            ),
          ),
        ),
        AppGap.sm(),
        // Value-bearing labels, so `.statistic` (never clipped). The marks are
        // the chart's strokes — filled for errors, plain for discards — with
        // point markers, since `showDots` is at its default (#1324).
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            AppChartLegendEntry.statistic(
              mark: const ChartMark.lineFilled(dot: true),
              color: colorScheme.error,
              label: 'Avg: ${NetworkHealthHelpers.formatFaultRate(avgErr)}'
                  '  Peak: ${NetworkHealthHelpers.formatFaultRate(peakErr)}',
            ),
            AppChartLegendEntry.statistic(
              mark: const ChartMark.line(dot: true),
              color: discardColor,
              label: 'Avg: ${NetworkHealthHelpers.formatFaultRate(avgDisc)}',
            ),
          ],
        ),
      ],
    );
  }
}
