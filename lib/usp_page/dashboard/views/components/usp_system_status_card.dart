import 'package:flutter/material.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';

class UspSystemStatusCard extends StatelessWidget {
  final SystemInfo info;

  const UspSystemStatusCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final cpuPercent = info.cpuUsage.clamp(0, 100);
    final memUsedKb = (info.totalMemory - info.freeMemory).clamp(0, info.totalMemory);
    final memPercent =
        info.totalMemory > 0 ? (memUsedKb / info.totalMemory * 100).round() : 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('System Status'),
          AppGap.xl(),
          UspInfoRow(label: 'Uptime', value: _formatUptime(info.uptime)),
          AppGap.md(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGauge(
                context,
                value: cpuPercent.toDouble(),
                label: 'CPU',
                display: '$cpuPercent%',
              ),
              _buildGauge(
                context,
                value: memPercent.toDouble(),
                label: 'Memory',
                display: '$memPercent%',
              ),
            ],
          ),
          AppGap.sm(),
          Center(
            child: AppText.bodySmall(
              '${info.freeMemory} / ${info.totalMemory} KB free',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(
    BuildContext context, {
    required double value,
    required String label,
    required String display,
  }) {
    return AppGauge(
      value: value,
      size: 100,
      centerBuilder: (ctx, v) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleMedium(display),
          AppText.bodySmall(label),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
