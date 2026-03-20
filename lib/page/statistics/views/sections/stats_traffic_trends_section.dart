import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dual-axis line chart: Bytes/s (left) + Packets/s (right).
class StatsTrafficTrendsSection extends ConsumerWidget {
  const StatsTrafficTrendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: 'Traffic Trends',
      subtitle: 'Bytes/s and Packets/s dual-axis view',
      chartHeight: 280,
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

    final byteRates = history
        .map((s) => s.interfaces[TrafficInterface.wan]?.totalBytesPerSec ?? 0.0)
        .toList();
    final packetRates = history
        .map((s) =>
            s.interfaces[TrafficInterface.wan]?.totalPacketsPerSec ?? 0.0)
        .toList();

    final bytesMax =
        _niceMaxBytes(byteRates.isEmpty ? 0 : byteRates.reduce(math.max));
    final packetsMax =
        _niceMaxPackets(packetRates.isEmpty ? 0 : packetRates.reduce(math.max));

    return Column(
      children: [
        Expanded(
          child: AppLineChart(
            series: [
              AppChartSeries(
                label: 'Bytes/s',
                data: byteRates,
                filled: true,
                color: colorScheme.primary,
              ),
              AppChartSeries(
                label: 'Pkts/s',
                data: packetRates,
                dashed: true,
                color: colorScheme.tertiary,
                useSecondaryAxis: true,
              ),
            ],
            yAxis: AppChartAxis(min: 0, max: bytesMax),
            yLabelFormatter: _formatBytesLabel,
            secondaryYAxis: AppChartAxis(min: 0, max: packetsMax),
            secondaryYLabelFormatter: _formatPacketsLabel,
            tooltipFormatter: (label, v) {
              if (label == 'Bytes/s') return _formatBytesLabel(v);
              return '$label: ${_formatPacketsLabel(v)}';
            },
            enableZoom: true,
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('Bytes/s'),
            AppGap.lg(),
            Container(width: 16, height: 2, color: colorScheme.tertiary),
            AppGap.xs(),
            AppText.labelSmall('Pkts/s'),
          ],
        ),
      ],
    );
  }
}

double _niceMaxBytes(double rawMax) {
  if (rawMax <= 0) return 1024;
  const steps = [
    1024.0,
    10240.0,
    102400.0,
    524288.0,
    1048576.0,
    5242880.0,
    10485760.0,
    52428800.0,
    104857600.0,
    1073741824.0,
  ];
  for (final step in steps) {
    if (rawMax <= step) return step;
  }
  return rawMax * 1.1;
}

double _niceMaxPackets(double rawMax) {
  if (rawMax <= 0) return 100;
  const steps = [100.0, 500.0, 1000.0, 5000.0, 10000.0, 50000.0, 100000.0];
  for (final step in steps) {
    if (rawMax <= step) return step;
  }
  return rawMax * 1.1;
}

String _formatBytesLabel(double bytesPerSec) {
  if (bytesPerSec >= 1048576) {
    final mb = bytesPerSec / 1048576;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB/s';
  } else if (bytesPerSec >= 1024) {
    final kb = bytesPerSec / 1024;
    return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB/s';
  }
  return '${bytesPerSec.toStringAsFixed(0)} B/s';
}

String _formatPacketsLabel(double pktsPerSec) {
  if (pktsPerSec >= 1000) return '${(pktsPerSec / 1000).toStringAsFixed(1)}K';
  return pktsPerSec.toStringAsFixed(0);
}
