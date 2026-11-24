import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// CPU vs WAN traffic rate dual-axis line chart.
class StatsCorrelationSection extends ConsumerWidget {
  const StatsCorrelationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorState = ref.watch(uspSystemMonitorProvider);
    final trafficState = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: loc(context).cpuTrafficCorrelation,
      subtitle: loc(context).cpuUsageVsWanTrafficRate,
      chartHeight: 280,
      child: _buildContent(context, monitorState, trafficState),
    );
  }

  Widget _buildContent(BuildContext context, SystemMonitorState monitorState,
      TrafficAnalysisState trafficState) {
    final colorScheme = Theme.of(context).colorScheme;

    if (monitorState.history.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          loc(context).waitingForData,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (trafficState.history.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          loc(context).enableTrafficMonitorForCorrelation,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final sysHistory = monitorState.history;
    final cpuData = sysHistory.map((s) => s.cpuPercent.toDouble()).toList();
    final trafficData = _alignTrafficToSystem(sysHistory, trafficState.history);

    final maxTraffic =
        trafficData.isEmpty ? 1.0 : trafficData.reduce((a, b) => a > b ? a : b);
    final trafficMax = maxTraffic < 1 ? 1.0 : maxTraffic * 1.2;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppLineChart(
              series: [
                AppChartSeries(
                  label: loc(context).cpu,
                  data: cpuData,
                  filled: true,
                  color: colorScheme.primary,
                ),
                AppChartSeries(
                  label: loc(context).trafficRate,
                  data: trafficData,
                  dashed: true,
                  color: colorScheme.tertiary,
                  useSecondaryAxis: true,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: 100, interval: 25),
              yLabelFormatter: (v) => '${v.toInt()}%',
              secondaryYAxis: AppChartAxis(min: 0, max: trafficMax),
              secondaryYLabelFormatter: (v) => _formatRate(v),
              tooltipFormatter: (label, v) {
                if (label == 'CPU') return '$label: ${v.toStringAsFixed(1)}%';
                return '$label: ${_formatRate(v)}';
              },
              enableZoom: true,
            ),
          ),
        ),
        AppGap.sm(),
        // Explicit entries rather than `AppChartLegend.line`, because the labels
        // here are not the series labels: on a dual-axis chart each label names
        // the scale it is read against (#1324, kit #30). The marks are the ones
        // the chart draws — a filled stroke for CPU, and a dashed stroke for the
        // traffic rate — with point markers, since `showDots` is at its default.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            AppChartLegendEntry.seriesName(
              mark: const ChartMark.lineFilled(dot: true),
              color: colorScheme.primary,
              label: loc(context).cpuPercentLabel,
            ),
            AppChartLegendEntry.seriesName(
              mark: const ChartMark.line(dashed: true, dot: true),
              color: colorScheme.tertiary,
              label: loc(context).trafficRateBytesPerSec,
            ),
          ],
        ),
      ],
    );
  }

  List<double> _alignTrafficToSystem(
    List<SystemSnapshot> sysHistory,
    List<MultiInterfaceSnapshot> trafficHistory,
  ) {
    return sysHistory.map((sys) {
      final closest = trafficHistory.reduce((a, b) =>
          (a.timestamp.difference(sys.timestamp).abs() <
                  b.timestamp.difference(sys.timestamp).abs())
              ? a
              : b);
      final wan = closest.interfaces[TrafficInterface.wan];
      return (wan?.uploadBytesPerSec ?? 0) + (wan?.downloadBytesPerSec ?? 0);
    }).toList();
  }

  static String _formatRate(double bytesPerSec) {
    if (bytesPerSec >= 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    if (bytesPerSec >= 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${bytesPerSec.toStringAsFixed(0)} B/s';
  }
}
