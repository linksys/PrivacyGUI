import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/devices/views/components/device_icon_with_badge.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';

class UspConnectedDevicesCard extends ConsumerWidget {
  final List<DeviceUIModel>? devices;

  const UspConnectedDevicesCard({
    super.key,
    this.devices,
  });

  static const _maxDisplayCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final devices = this.devices ?? devicesData?.clientDevices;
    if (devices == null) return const CardSkeleton.list(rows: 3);
    final colorScheme = Theme.of(context).colorScheme;
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
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status summary - metric tiles style using LayoutBlock
          Row(
            children: [
              Expanded(
                child: LayoutBlock(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      UspStatusDot(isActive: true, size: 10),
                      AppGap.sm(),
                      AppText.titleSmall('${activeDevices.length}'),
                      AppGap.xs(),
                      AppText.bodySmall(
                        'Online',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: LayoutBlock(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      UspStatusDot(isActive: false, size: 10),
                      AppGap.sm(),
                      AppText.titleSmall('${inactiveDevices.length}'),
                      AppGap.xs(),
                      AppText.bodySmall(
                        'Offline',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppGap.md(),
          // Device list - only online devices, max 5
          if (activeDevices.isEmpty)
            const EmptyState(
              icon: Icons.devices,
              message: 'No devices online',
            )
          else
            for (var i = 0; i < displayDevices.length; i++) ...[
              _buildDeviceRow(context, displayDevices[i]),
              if (i < displayDevices.length - 1) AppGap.sm(),
            ],
        ],
      ),
    );
  }

  Widget _buildDeviceRow(BuildContext context, DeviceUIModel device) {
    final scheme = Theme.of(context).colorScheme;
    final deviceCategory = DeviceClassifier.classify(
      hostname: device.hostName,
      mac: device.mac,
    );

    return DeviceRow(
      icon: DeviceIconWithBadge.multiInterface(
        icon: deviceCategory.icon,
        size: 28,
        iconColor: scheme.onSurface,
        hasMultipleInterfaces: device.hasMultipleInterfaces,
      ),
      title: device.displayName,
      subtitle: device.ip,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (device.parentNodeName != null)
            _buildParentNodeBadge(context, device.parentNodeName!),
          if (device.hasSignalDisplay)
            UspSignalStrengthIndicator(rssi: device.signalStrength!)
          else
            AppText.bodySmall(
              device.isWifi ? 'WiFi' : 'Wired',
              color: scheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }

  Widget _buildParentNodeBadge(BuildContext context, String nodeName) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
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
