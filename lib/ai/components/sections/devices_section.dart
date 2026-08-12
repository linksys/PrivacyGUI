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

    // Speed, as icon + text pairs. The direction markers are icons rather than
    // the U+2193/U+2191 characters this used to interpolate into a string: no
    // bundled font maps those codepoints, so the arrow only appeared if some
    // font happened to resolve it.
    final speedPairs = <({IconData icon, String text})>[
      for (final entry in [
        (icon: Icons.arrow_downward, speed: _formatSpeed(downlinkRate)),
        (icon: Icons.arrow_upward, speed: _formatSpeed(uplinkRate)),
      ])
        if (entry.speed != null) (icon: entry.icon, text: entry.speed!),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppListTile(
        leading: Icon(_getDeviceIcon(name)),
        title: AppText.body(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ip.isNotEmpty) AppText.bodySmall(ip),
            if (speedPairs.isNotEmpty)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xxs,
                children: [
                  for (final pair in speedPairs)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon.font(pair.icon, size: 12, color: Colors.grey),
                        AppGap.xxs(),
                        AppText.bodySmall(pair.text, color: Colors.grey),
                      ],
                    ),
                ],
              ),
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
