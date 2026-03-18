import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/usp_page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Real-time WAN upload/download speed tiles + dual-line chart.
class StatsTrafficMonitorSection extends ConsumerWidget {
  const StatsTrafficMonitorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: 'Traffic Monitor',
      subtitle: 'Real-time WAN upload/download speeds',
      chartHeight: 280,
      child: state.history.isEmpty
          ? _emptyState(context, 'Waiting for traffic data...')
          : _buildChart(context, state),
    );
  }

  Widget _buildChart(BuildContext context, TrafficAnalysisState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = state.history;
    final wan = history.last.interfaces[TrafficInterface.wan];
    final upload = wan?.uploadBytesPerSec ?? 0;
    final download = wan?.downloadBytesPerSec ?? 0;

    return Column(
      children: [
        // Speed tiles
        Row(
          children: [
            Expanded(
              child: _SpeedTile(
                label: 'Upload',
                icon: Icons.arrow_upward,
                bytesPerSec: upload,
                color: colorScheme.primary,
              ),
            ),
            AppGap.md(),
            Expanded(
              child: _SpeedTile(
                label: 'Download',
                icon: Icons.arrow_downward,
                bytesPerSec: download,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        AppGap.sm(),
        Expanded(
          child: AppLineChart(
            series: [
              AppChartSeries(
                label: 'Upload',
                data: history
                    .map((s) =>
                        s.interfaces[TrafficInterface.wan]?.uploadBytesPerSec ??
                        0.0)
                    .toList(),
                filled: true,
                color: colorScheme.primary,
              ),
              AppChartSeries(
                label: 'Download',
                data: history
                    .map((s) =>
                        s.interfaces[TrafficInterface.wan]
                            ?.downloadBytesPerSec ??
                        0.0)
                    .toList(),
                color: colorScheme.secondary,
              ),
            ],
            yLabelFormatter: _formatSpeed,
            tooltipFormatter: statsFormatSpeedTooltip,
            enableZoom: true,
          ),
        ),
        AppGap.sm(),
        Row(
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('Upload'),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Download'),
            const Spacer(),
            if (wan != null) ...[
              AppText.labelSmall(
                '\u2191 ${UspFormatters.formatBytes(wan.totalBytesSent)}',
                color: colorScheme.onSurfaceVariant,
              ),
              AppGap.md(),
              AppText.labelSmall(
                '\u2193 ${UspFormatters.formatBytes(wan.totalBytesReceived)}',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    return Center(
      child: AppText.bodyMedium(
        message,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SpeedTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final double bytesPerSec;
  final Color color;

  const _SpeedTile({
    required this.label,
    required this.icon,
    required this.bytesPerSec,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon.font(icon, size: 16, color: color),
        AppGap.xs(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall(label),
              AppText.titleSmall(_formatSpeed(bytesPerSec)),
            ],
          ),
        ),
      ],
    );
  }
}

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
