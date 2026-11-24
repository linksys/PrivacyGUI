import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
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
      title: loc(context).trafficComparison,
      subtitle: loc(context).trafficComparisonSubtitle,
      chartHeight: 260,
      child: state.history.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                loc(context).collectingData,
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
                label: loc(context).wan,
                data: history
                    .map((s) =>
                        s.interfaces[TrafficInterface.wan]?.totalBytesPerSec ??
                        0.0)
                    .toList(),
                color: colorScheme.primary,
              ),
              AppChartSeries(
                label: loc(context).lan,
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
            tooltipFormatter: statsFormatSpeedTooltip,
          ),
        ),
        AppGap.sm(),
        // Value-bearing labels, so `.statistic` (never clipped). The mark is
        // the bar chart's block (#1324).
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            AppChartLegendEntry.statistic(
              mark: const ChartMark.block(),
              color: colorScheme.primary,
              label: loc(context).wanSpeed(_formatSpeed(wanRate)),
            ),
            AppChartLegendEntry.statistic(
              mark: const ChartMark.block(),
              color: colorScheme.secondary,
              label: loc(context).lanSpeed(_formatSpeed(lanRate)),
            ),
          ],
        ),
      ],
    );
  }
}
