import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/devices/views/components/device_icon_with_badge.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';

class UspConnectedDevicesCard extends ConsumerWidget {
  final List<DeviceUIModel>? devices;
  final VoidCallback? onViewAll;

  const UspConnectedDevicesCard({
    super.key,
    this.devices,
    this.onViewAll,
  });

  static const _maxDisplayCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final devices = this.devices ?? devicesData?.clientDevices;
    if (devices == null) return const CardSkeleton.list(rows: 3);
    final activeDevices = devices.where((d) => d.isActive).toList();
    final inactiveDevices = devices.where((d) => !d.isActive).toList();
    final displayDevices = activeDevices.take(_maxDisplayCount).toList();

    return DashboardCardTemplate(
      title: 'Connected Devices',
      titleBadge: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UspStatusDot(isActive: true, size: 8),
          AppGap.xs(),
          AppText.labelSmall('${activeDevices.length}'),
          AppGap.sm(),
          UspStatusDot(isActive: false, size: 8),
          AppGap.xs(),
          AppText.labelSmall('${inactiveDevices.length}'),
        ],
      ),
      detailRoute: RouteNamed.uspDeviceList,
      itemCount: devices.length,
      detailLabel: 'View all',
      content: activeDevices.isEmpty
          ? Center(child: AppText.bodyMedium('No devices online'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayDevices
                  .map((d) => _buildDeviceRow(context, d))
                  .toList(),
            ),
    );
  }

  Widget _buildDeviceRow(BuildContext context, DeviceUIModel device) {
    final scheme = Theme.of(context).colorScheme;
    final deviceCategory = DeviceClassifier.classify(
      hostname: device.hostName,
      mac: device.mac,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device icon (larger) with multi-interface badge
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: DeviceIconWithBadge.multiInterface(
              icon: deviceCategory.icon,
              size: 32,
              iconColor: scheme.onSurface,
              hasMultipleInterfaces: device.hasMultipleInterfaces,
            ),
          ),
          AppGap.md(),
          // Name + IP (subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  device.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppGap.xxs(),
                AppText.bodySmall(
                  device.ip,
                  color: scheme.onSurfaceVariant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppGap.sm(),
          // Parent node badge + Signal/Wired (stacked)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (device.parentNodeName != null)
                _buildParentNodeBadge(context, device.parentNodeName!),
              AppGap.xxs(),
              if (device.hasSignalDisplay)
                UspSignalStrengthIndicator(rssi: device.signalStrength!)
              else
                AppText.bodySmall(
                  device.isWifi ? 'WiFi' : 'Wired',
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentNodeBadge(BuildContext context, String nodeName) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: AppText.labelSmall(
        nodeName,
        color: scheme.onSurfaceVariant,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
