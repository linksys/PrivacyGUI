import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// CPU usage histogram — 4 buckets (0-25%, 25-50%, 50-75%, 75-100%).
class StatsCpuDistributionSection extends ConsumerWidget {
  const StatsCpuDistributionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorState = ref.watch(uspSystemMonitorProvider);

    return StatsSectionCard(
      title: 'CPU Distribution',
      subtitle: 'CPU usage sample distribution',
      chartHeight: 260,
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

    final buckets = [0, 0, 0, 0]; // 0-25, 25-50, 50-75, 75-100
    for (final s in history) {
      final idx = (s.cpuPercent / 25).floor().clamp(0, 3);
      buckets[idx]++;
    }
    final maxBucket = buckets.reduce((a, b) => a > b ? a : b);
    final yMax = maxBucket < 1 ? 2.0 : (maxBucket + 2).toDouble();
    final yInterval = yMax <= 4 ? 1.0 : (yMax / 4).ceilToDouble();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 16),
            child: AppBarChart(
              series: [
                AppChartSeries(
                  label: 'CPU',
                  data: buckets.map((b) => b.toDouble()).toList(),
                  color: colorScheme.primary,
                ),
              ],
              xLabels: const ['0-25%', '25-50%', '50-75%', '75-100%'],
              yAxis: AppChartAxis(min: 0, max: yMax, interval: yInterval),
              yLabelFormatter: (v) => v.toInt().toString(),
              showValueLabels: true,
              valueLabelFormatter: (v) => v.toInt().toString(),
              showTooltip: false,
            ),
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('CPU usage samples: ${history.length}'),
          ],
        ),
      ],
    );
  }
}
