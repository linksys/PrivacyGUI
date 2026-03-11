import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

String _formatSpeed(double bytesPerSec) {
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  var value = bytesPerSec;
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unitIndex]}';
}

/// WAN vs LAN stacked bar chart comparison.
class StatsTrafficComparisonSection extends ConsumerWidget {
  const StatsTrafficComparisonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: 'Traffic Comparison',
      subtitle: 'WAN vs LAN throughput over time',
      chartHeight: 260,
      child: state.history.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                'Collecting data...',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state.history),
    );
  }

  Widget _buildChart(
      BuildContext context, List<MultiInterfaceSnapshot> history) {
    final colorScheme = Theme.of(context).colorScheme;
    final latest = history.last;
    final wanRate =
        latest.interfaces[TrafficInterface.wan]?.totalBytesPerSec ?? 0;
    final lanRate =
        latest.interfaces[TrafficInterface.lan]?.totalBytesPerSec ?? 0;

    return Column(
      children: [
        Expanded(
          child: AppBarChart(
            series: [
              AppChartSeries(
                label: 'WAN',
                data: history
                    .map((s) =>
                        s.interfaces[TrafficInterface.wan]?.totalBytesPerSec ??
                        0.0)
                    .toList(),
                color: colorScheme.primary,
              ),
              AppChartSeries(
                label: 'LAN',
                data: history
                    .map((s) =>
                        s.interfaces[TrafficInterface.lan]?.totalBytesPerSec ??
                        0.0)
                    .toList(),
                color: colorScheme.secondary,
              ),
            ],
            stacked: true,
            yLabelFormatter: _formatSpeed,
            showTooltip: false,
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('WAN: ${_formatSpeed(wanRate)}'),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('LAN: ${_formatSpeed(lanRate)}'),
          ],
        ),
      ],
    );
  }
}
