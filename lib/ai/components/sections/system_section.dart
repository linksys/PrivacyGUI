import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../ai_info_row.dart';

/// System resources section.
///
/// Displays CPU usage, memory usage, and uptime.
class SystemSection extends StatelessWidget {
  final int cpuPercent;
  final int memoryPercent;
  final String? uptime;

  const SystemSection({
    super.key,
    required this.cpuPercent,
    required this.memoryPercent,
    this.uptime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGaugeColumn(loc(context).cpu, cpuPercent),
            ),
            AppGap.md(),
            Expanded(
              child: _buildGaugeColumn(loc(context).memory, memoryPercent),
            ),
          ],
        ),
        if (uptime != null) ...[
          AppGap.md(),
          AiInfoRow(label: loc(context).uptime, value: uptime!),
        ],
      ],
    );
  }

  Widget _buildGaugeColumn(String label, int percent) {
    final color = _getGaugeColor(percent);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
              AppText.titleMedium('$percent%'),
            ],
          ),
        ),
        AppGap.sm(),
        AppText.labelMedium(label),
      ],
    );
  }

  Color _getGaugeColor(int percent) {
    if (percent >= 80) return Colors.red;
    if (percent >= 60) return Colors.orange;
    return Colors.green;
  }
}
