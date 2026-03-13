import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/network_health_helpers.dart';
import 'package:privacy_gui/usp_page/dashboard/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Error/discard rate area chart over time.
class StatsErrorRatesSection extends ConsumerWidget {
  const StatsErrorRatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: 'Network Error Rates',
      subtitle: 'WAN error and discard rates over time',
      chartHeight: 280,
      child: state.history.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                'Enable traffic monitor for error data',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state),
    );
  }

  Widget _buildChart(BuildContext context, TrafficAnalysisState state) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  label: 'Errors',
                  data: errorData,
                  filled: true,
                  color: colorScheme.error,
                ),
                AppChartSeries(
                  label: 'Discards',
                  data: discardData,
                  color: Colors.orange,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.error),
            AppGap.xs(),
            AppText.labelSmall(
              'Avg: ${NetworkHealthHelpers.formatFaultRate(avgErr)}'
              '  Peak: ${NetworkHealthHelpers.formatFaultRate(peakErr)}',
            ),
            AppGap.lg(),
            StatsLegendDot(color: Colors.orange),
            AppGap.xs(),
            AppText.labelSmall(
              'Avg: ${NetworkHealthHelpers.formatFaultRate(avgDisc)}',
            ),
          ],
        ),
      ],
    );
  }
}
