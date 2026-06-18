import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Ethernet ports status section.
///
/// Displays physical port status with connection state and speed.
class EthernetSection extends StatelessWidget {
  final List<Map<String, dynamic>> ports;

  const EthernetSection({
    super.key,
    required this.ports,
  });

  @override
  Widget build(BuildContext context) {
    if (ports.isEmpty) {
      return AppText.body('No ethernet ports found');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final port in ports) _buildPortRow(port),
      ],
    );
  }

  Widget _buildPortRow(Map<String, dynamic> port) {
    final label = port['label'] as String? ?? 'Port';
    final status = port['status'] as String? ?? 'Unknown';
    final speed = port['speed'] as String?;
    final isConnected =
        status.toLowerCase() == 'connected' || status.toLowerCase() == 'up';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.cable : Icons.cable_outlined,
            color: isConnected ? Colors.green : Colors.grey,
            size: 20,
          ),
          AppGap.sm(),
          SizedBox(
            width: 60,
            child: AppText.labelMedium(label),
          ),
          Expanded(
            child: AppText.body(status),
          ),
          if (speed != null && isConnected) AppBadge(label: speed),
        ],
      ),
    );
  }
}
