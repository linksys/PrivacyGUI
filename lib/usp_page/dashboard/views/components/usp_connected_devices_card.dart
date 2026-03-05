import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';

class UspConnectedDevicesCard extends StatelessWidget {
  final List<DeviceUIModel> devices;

  const UspConnectedDevicesCard({
    super.key,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    final activeDevices = devices.where((d) => d.isActive).toList();
    final inactiveDevices = devices.where((d) => !d.isActive).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Connected Devices'),
              AppText.labelLarge(
                '${activeDevices.length} / ${devices.length}',
              ),
            ],
          ),
          AppGap.xl(),
          if (devices.isEmpty)
            AppText.bodyMedium('No devices found')
          else ...[
            if (activeDevices.isNotEmpty) ...[
              AppText.labelLarge('Online'),
              AppGap.sm(),
              ...activeDevices.map(_buildDeviceRow),
            ],
            if (inactiveDevices.isNotEmpty) ...[
              if (activeDevices.isNotEmpty) AppGap.lg(),
              AppText.labelLarge('Offline'),
              AppGap.sm(),
              ...inactiveDevices.map(_buildDeviceRow),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceRow(DeviceUIModel device) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          UspStatusDot(isActive: device.isActive),
          AppGap.sm(),
          _buildConnectionIcon(device),
          AppGap.sm(),
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(device.displayName),
                Builder(builder: (context) {
                  final subtitle = _buildSubtitle(device);
                  if (subtitle.isEmpty) return const SizedBox.shrink();
                  return AppText.bodySmall(
                    subtitle,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  );
                }),
              ],
            ),
          ),
          // Signal strength or connection type badge
          if (device.isActive && device.isWifi && device.signalStrength != null)
            _buildSignalBadge(device.signalStrength!)
          else if (device.isActive && !device.isWifi)
            Builder(builder: (context) {
              return AppText.bodySmall(
                'Ethernet',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              );
            }),
          AppGap.sm(),
          // IP address
          Builder(builder: (context) {
            return SizedBox(
              width: 130,
              child: AppText.bodySmall(
                device.ip,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Builds the subtitle line: "MAC · 5GHz MyNetwork · via MR7500"
  String _buildSubtitle(DeviceUIModel device) {
    final parts = <String>[];

    // MAC (only if hostname is shown as primary)
    if (device.hostName.isNotEmpty) parts.add(device.mac);

    // Band + SSID or Ethernet
    if (device.isWifi) {
      final bandSsid = [
        if (device.band != null && device.band!.isNotEmpty) device.band!,
        if (device.ssidName != null && device.ssidName!.isNotEmpty)
          device.ssidName!,
      ].join(' ');
      if (bandSsid.isNotEmpty) parts.add(bandSsid);
    } else if (device.isActive) {
      parts.add('Ethernet');
    }

    // Parent node
    if (device.parentNodeName != null) {
      parts.add('via ${device.parentNodeName}');
    }

    return parts.join(' · ');
  }

  Widget _buildConnectionIcon(DeviceUIModel device) {
    return Builder(builder: (context) {
      if (!device.isWifi) {
        return Icon(
          Icons.settings_ethernet,
          size: 18,
          color: device.isActive
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
        );
      }
      return Icon(
        _wifiIconForSignal(device.signalStrength),
        size: 18,
        color: device.isActive
            ? _signalColor(context, device.signalStrength)
            : Theme.of(context).colorScheme.onSurfaceVariant,
      );
    });
  }

  Widget _buildSignalBadge(int rssi) {
    return Builder(builder: (context) {
      return AppText.bodySmall(
        '$rssi dBm',
        color: _signalColor(context, rssi),
      );
    });
  }

  static IconData _wifiIconForSignal(int? rssi) {
    if (rssi == null) return Icons.wifi;
    if (rssi >= -50) return Icons.wifi;
    if (rssi >= -60) return Icons.wifi_2_bar;
    if (rssi >= -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  static Color _signalColor(BuildContext context, int? rssi) {
    final scheme = Theme.of(context).colorScheme;
    if (rssi == null) return scheme.onSurfaceVariant;
    if (rssi >= -50) return Colors.green;
    if (rssi >= -60) return Colors.lightGreen;
    if (rssi >= -70) return Colors.orange;
    return scheme.error;
  }
}
