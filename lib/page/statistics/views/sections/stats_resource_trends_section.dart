import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// CPU/Memory line chart with area fill + avg/peak stats.
class StatsResourceTrendsSection extends ConsumerWidget {
  const StatsResourceTrendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorState = ref.watch(uspSystemMonitorProvider);

    return StatsSectionCard(
      title: loc(context).resourceTrends,
      subtitle: loc(context).resourceTrendsSubtitle,
      chartHeight: 280,
      child: monitorState.history.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                loc(context).waitingForData,
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
                  label: loc(context).cpu,
                  data: cpuValues,
                  filled: true,
                  color: colorScheme.primary,
                ),
                AppChartSeries(
                  label: loc(context).memory,
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
        // DEGRADATION SHAPE (#1488) — two inflexible groups in a centred `Row`
        // overflowed 238px in 7 of 26 locales (worst `de`, 74px). A `Wrap`, which
        // works here only because the *longer* of the two groups fits 238px on its
        // own: `de`'s "Durchschn.: 49%  Spitze: 62%" is the longest single group
        // in any locale, and it is what the `de` readability guard measures. The
        // chart above is `Expanded`, so it yields the height.
        //
        // Both labels are percentages, so neither is `Flexible` or ellipsized —
        // an ellipsis in "Avg: 49%  Peak: 62%" would read as a different figure.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatsLegendDot(color: colorScheme.primary),
                AppGap.xs(),
                AppText.labelSmall(loc(context).avgPeak(avgCpu, peakCpu)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatsLegendDot(color: colorScheme.secondary),
                AppGap.xs(),
                AppText.labelSmall(loc(context).avg(avgMem)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
