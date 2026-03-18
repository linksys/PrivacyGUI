import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/usp_page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/usp_page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// CPU vs WAN traffic rate dual-axis line chart.
class StatsCorrelationSection extends ConsumerWidget {
  const StatsCorrelationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorState = ref.watch(uspSystemMonitorProvider);
    final trafficState = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: 'CPU-Traffic Correlation',
      subtitle: 'CPU usage vs WAN traffic rate',
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
          'Waiting for data...',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (trafficState.history.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'Enable traffic monitor for correlation data',
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
                  label: 'CPU',
                  data: cpuData,
                  filled: true,
                  color: colorScheme.primary,
                ),
                AppChartSeries(
                  label: 'Traffic',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('CPU %'),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.tertiary),
            AppGap.xs(),
            AppText.labelSmall('Traffic rate'),
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
