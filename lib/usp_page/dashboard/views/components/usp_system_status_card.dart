import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';

class UspSystemStatusCard extends StatelessWidget {
  final SystemInfoUIModel info;

  const UspSystemStatusCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('System Status'),
          AppGap.xl(),
          UspInfoRow(label: 'Uptime', value: info.formattedUptime),
          AppGap.md(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGauge(
                context,
                value: info.cpuPercent.toDouble(),
                label: 'CPU',
                display: '${info.cpuPercent}%',
              ),
              _buildGauge(
                context,
                value: info.memoryPercent.toDouble(),
                label: 'Memory',
                display: '${info.memoryPercent}%',
              ),
            ],
          ),
          AppGap.sm(),
          Center(
            child: AppText.bodySmall(
              '${info.formattedUsedMemory} / ${info.formattedTotalMemory} used',
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
}
