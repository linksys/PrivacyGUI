import 'package:flutter/material.dart';
import 'package:privacy_gui/ai/utils/speed_markers.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
      return AppText.body(loc(context).noConnectedDevicesFound);
    }

    final displayDevices =
        maxCount != null ? devices.take(maxCount!).toList() : devices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final device in displayDevices) _buildDeviceRow(context, device),
        if (maxCount != null && devices.length > maxCount!)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: AppText.bodySmall(
              loc(context).nMore(devices.length - maxCount!),
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceRow(BuildContext context, Map<String, dynamic> device) {
    final name = device['name'] as String? ?? loc(context).unknownDevice;
    final ip = device['ip'] as String? ?? '';
    final connectionType = device['connectionType'] as String? ?? '';
    final downlinkRate = device['downlinkRate'] as int?; // bps
    final uplinkRate = device['uplinkRate'] as int?; // bps

    final speedPairs =
        speedMarkersFor(downlink: downlinkRate, uplink: uplinkRate);

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
