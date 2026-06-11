import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Connected devices list section.
///
/// Displays a list of devices with name, IP, MAC, and connection type.
class DevicesSection extends StatelessWidget {
  final List<Map<String, dynamic>> devices;
  final int? maxCount;

  const DevicesSection({
    super.key,
    required this.devices,
    this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return AppText.body('No connected devices found');
    }

    final displayDevices =
        maxCount != null ? devices.take(maxCount!).toList() : devices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final device in displayDevices) _buildDeviceRow(device),
        if (maxCount != null && devices.length > maxCount!)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: AppText.bodySmall(
              '... and ${devices.length - maxCount!} more',
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceRow(Map<String, dynamic> device) {
    final name = device['name'] as String? ?? 'Unknown Device';
    final ip = device['ip'] as String? ?? '';
    final connectionType = device['connectionType'] as String? ?? '';
    final downlinkRate = device['downlinkRate'] as int?; // bps
    final uplinkRate = device['uplinkRate'] as int?; // bps

    // Format speed for display
    String? speedText;
    if (downlinkRate != null || uplinkRate != null) {
      final down = _formatSpeed(downlinkRate);
      final up = _formatSpeed(uplinkRate);
      if (down != null && up != null) {
        speedText = '↓$down ↑$up';
      } else if (down != null) {
        speedText = '↓$down';
      } else if (up != null) {
        speedText = '↑$up';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppListTile(
        leading: Icon(_getDeviceIcon(name)),
        title: AppText.body(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ip.isNotEmpty) AppText.bodySmall(ip),
            if (speedText != null)
              AppText.bodySmall(speedText, color: Colors.grey),
          ],
        ),
        trailing:
            connectionType.isNotEmpty ? AppBadge(label: connectionType) : null,
      ),
    );
  }

  String? _formatSpeed(int? bps) {
    if (bps == null || bps == 0) return null;
    final mbps = bps / 1000000;
    if (mbps >= 1000) {
      return '${(mbps / 1000).toStringAsFixed(1)} Gbps';
    } else if (mbps >= 1) {
      return '${mbps.toStringAsFixed(1)} Mbps';
    } else {
      return '${(bps / 1000).toStringAsFixed(0)} Kbps';
    }
  }

  IconData _getDeviceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('iphone') || lower.contains('android')) {
      return Icons.phone_android;
    }
    if (lower.contains('mac') ||
        lower.contains('laptop') ||
        lower.contains('book')) {
      return Icons.laptop;
    }
    if (lower.contains('tv') || lower.contains('roku')) {
      return Icons.tv;
    }
    if (lower.contains('printer')) return Icons.print;
    if (lower.contains('camera')) return Icons.videocam;
    return Icons.devices;
  }
}
