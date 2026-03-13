import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// CPU/Memory line chart with area fill + avg/peak stats.
class StatsResourceTrendsSection extends ConsumerWidget {
  const StatsResourceTrendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorState = ref.watch(uspSystemMonitorProvider);

    return StatsSectionCard(
      title: 'Resource Trends',
      subtitle: 'CPU and memory usage over time',
      chartHeight: 280,
      child: monitorState.history.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                'Waiting for data...',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, monitorState),
    );
  }

  Widget _buildChart(BuildContext context, dynamic monitorState) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = monitorState.history as List;
    final cpuValues =
        history.map<double>((s) => s.cpuPercent.toDouble()).toList();
    final memValues =
        history.map<double>((s) => s.memoryPercent.toDouble()).toList();

    final avgCpu = cpuValues.isEmpty
        ? 0
        : (cpuValues.reduce((a, b) => a + b) / cpuValues.length).round();
    final peakCpu = cpuValues.isEmpty
        ? 0
        : cpuValues.reduce((a, b) => a > b ? a : b).round();
    final avgMem = memValues.isEmpty
        ? 0
        : (memValues.reduce((a, b) => a + b) / memValues.length).round();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppLineChart(
              series: [
                AppChartSeries(
                  label: 'CPU',
                  data: cpuValues,
                  filled: true,
                  color: colorScheme.primary,
                ),
                AppChartSeries(
                  label: 'Memory',
                  data: memValues,
                  color: colorScheme.secondary,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: 100, interval: 25),
              yLabelFormatter: (v) => '${v.toInt()}%',
              tooltipFormatter: statsFormatPercentTooltip,
              enableZoom: true,
            ),
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('Avg: $avgCpu%  Peak: $peakCpu%'),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Avg: $avgMem%'),
          ],
        ),
      ],
    );
  }
}
