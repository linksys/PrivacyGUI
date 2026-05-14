import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/device_classifier.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText.titleMedium('Connected Devices'),
              ),
              if (onViewAll != null)
                AppButton.text(
                  label: 'View All',
                  onTap: onViewAll,
                ),
            ],
          ),
          AppGap.xs(),
          Row(
            children: [
              UspStatusDot(isActive: true, size: 8),
              AppGap.xs(),
              AppText.labelLarge('${activeDevices.length} Online'),
              AppGap.md(),
              UspStatusDot(isActive: false, size: 8),
              AppGap.xs(),
              AppText.labelLarge('${inactiveDevices.length} Offline'),
            ],
          ),
          AppGap.xl(),
          // Device list — only online devices, max 5
          if (activeDevices.isEmpty)
            AppText.bodyMedium('No devices online')
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: displayDevices
                      .map((d) => _buildDeviceRow(context, d))
                      .toList(),
                ),
              ),
            ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device icon (larger)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(
              deviceCategory.icon,
              size: 32,
              color: scheme.onSurface,
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
