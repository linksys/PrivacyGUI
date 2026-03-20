import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Packet loss percentage line chart over time.
class StatsPacketLossSection extends ConsumerWidget {
  const StatsPacketLossSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: 'Packet Loss',
      subtitle: 'WAN packet loss percentage over time',
      chartHeight: 280,
      child: state.history.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                'Enable traffic monitor for loss data',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state),
    );
  }

  Widget _buildChart(BuildContext context, TrafficAnalysisState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = state.history;

    final lossData = history.map((s) {
      final wan = s.interfaces[TrafficInterface.wan];
      return wan != null ? NetworkHealthHelpers.computeLossPercent(wan) : 0.0;
    }).toList();

    final avgLoss = lossData.isEmpty
        ? 0.0
        : lossData.reduce((a, b) => a + b) / lossData.length;
    final peakLoss = lossData.isEmpty ? 0.0 : lossData.reduce(math.max);

    final maxVal = lossData.isEmpty ? 1.0 : lossData.reduce(math.max);
    final yMax = maxVal < 0.1 ? 1.0 : maxVal * 1.3;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppLineChart(
              series: [
                AppChartSeries(
                  label: 'Loss',
                  data: lossData,
                  filled: true,
                  color: colorScheme.error,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: yMax),
              yLabelFormatter: (v) => '${v.toStringAsFixed(2)}%',
              tooltipFormatter: (label, v) =>
                  '$label: ${v.toStringAsFixed(3)}%',
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
              'Avg: ${avgLoss.toStringAsFixed(3)}%'
              '  Peak: ${peakLoss.toStringAsFixed(3)}%',
            ),
          ],
        ),
      ],
    );
  }
}
