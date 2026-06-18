import 'package:flutter/material.dart';
import '../ai_info_row.dart';

/// WAN connection status section.
///
/// Displays WAN status, connected devices count, and optional IP/connection type.
class WanSection extends StatelessWidget {
  final String wanStatus;
  final int? connectedDevices;
  final String? wanIp;
  final String? connectionType;

  const WanSection({
    super.key,
    required this.wanStatus,
    this.connectedDevices,
    this.wanIp,
    this.connectionType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AiInfoRow(label: 'WAN Status', value: wanStatus),
        if (connectedDevices != null)
          AiInfoRow(label: 'Connected Devices', value: '$connectedDevices'),
        if (wanIp != null) AiInfoRow(label: 'WAN IP', value: wanIp!),
        if (connectionType != null)
          AiInfoRow(label: 'Connection Type', value: connectionType!),
      ],
    );
  }
}
