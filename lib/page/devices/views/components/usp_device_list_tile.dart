import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A tappable tile showing device summary info for the device list.
class UspDeviceListTile extends StatelessWidget {
  final DeviceUIModel device;
  final VoidCallback? onTap;

  const UspDeviceListTile({
    super.key,
    required this.device,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          UspStatusDot(isActive: device.isActive),
          AppGap.sm(),
          _buildConnectionIcon(context),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(device.displayName),
                Builder(builder: (ctx) {
                  final subtitle = _buildSubtitle();
                  if (subtitle.isEmpty) return const SizedBox.shrink();
                  return AppText.bodySmall(
                    subtitle,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  );
                }),
              ],
            ),
          ),
          if (device.isActive && device.isWifi && device.signalStrength != null)
            _buildSignalBadge(context)
          else if (device.isActive && !device.isWifi)
            AppText.bodySmall(
              'Ethernet',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          AppGap.sm(),
          SizedBox(
            width: context.colWidth(2),
            child: AppText.bodySmall(
              device.ip,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppIcon.font(
            Icons.chevron_right,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (device.hostName.isNotEmpty) parts.add(device.mac);
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
    if (device.parentNodeName != null) {
      parts.add('via ${device.parentNodeName}');
    }
    return parts.join(' · ');
  }

  Widget _buildConnectionIcon(BuildContext context) {
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
  }

  Widget _buildSignalBadge(BuildContext context) {
    return UspSignalStrengthIndicator(rssi: device.signalStrength!);
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
