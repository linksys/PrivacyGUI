import 'package:flutter/material.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/wifi_client_enricher.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';

class UspConnectedDevicesCard extends StatelessWidget {
  final List<ConnectedDevice> devices;
  final Map<String, WifiClientInfo> wifiClientMap;

  const UspConnectedDevicesCard({
    super.key,
    required this.devices,
    this.wifiClientMap = const {},
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

  Widget _buildDeviceRow(ConnectedDevice device) {
    final wifiInfo = wifiClientMap[device.macAddress.toUpperCase()];
    final isWifi = wifiInfo != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          UspStatusDot(isActive: device.isActive),
          AppGap.sm(),
          // Connection type icon
          _buildConnectionIcon(isWifi, wifiInfo, device.isActive),
          AppGap.sm(),
          // Name + MAC subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(
                  device.hostName.isNotEmpty
                      ? device.hostName
                      : device.macAddress,
                ),
                if (device.hostName.isNotEmpty)
                  Builder(builder: (context) {
                    return AppText.bodySmall(
                      device.macAddress,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    );
                  }),
              ],
            ),
          ),
          // Signal strength or connection type badge
          if (device.isActive && isWifi)
            _buildSignalBadge(wifiInfo.signalStrength)
          else if (device.isActive && !isWifi)
            Builder(builder: (context) {
              return AppText.bodySmall(
                'Wired',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              );
            }),
          AppGap.sm(),
          // IP address
          Builder(builder: (context) {
            return SizedBox(
              width: 130,
              child: AppText.bodySmall(
                device.ipAddress,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConnectionIcon(
      bool isWifi, WifiClientInfo? wifiInfo, bool isActive) {
    return Builder(builder: (context) {
      if (!isWifi) {
        return Icon(
          Icons.settings_ethernet,
          size: 18,
          color: isActive
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
        );
      }
      return Icon(
        _wifiIconForSignal(wifiInfo!.signalStrength),
        size: 18,
        color: isActive
            ? _signalColor(context, wifiInfo.signalStrength)
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

  static IconData _wifiIconForSignal(int rssi) {
    if (rssi >= -50) return Icons.wifi;
    if (rssi >= -60) return Icons.wifi_2_bar;
    if (rssi >= -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  static Color _signalColor(BuildContext context, int rssi) {
    final scheme = Theme.of(context).colorScheme;
    if (rssi >= -50) return Colors.green;
    if (rssi >= -60) return Colors.lightGreen;
    if (rssi >= -70) return Colors.orange;
    return scheme.error;
  }
}
