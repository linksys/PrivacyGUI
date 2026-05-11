import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/device_classifier.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';

/// Dashboard card showing connected devices summary.
///
/// Displays up to [maxVisibleDevices] online devices with device-type icons,
/// signal indicators, and IP addresses. Shows full online/offline counts in
/// the header. Use "View All" to see the complete device list.
class UspConnectedDevicesCard extends ConsumerWidget {
  final List<DeviceUIModel>? devices;
  final VoidCallback? onViewAll;

  /// Maximum number of online devices to display in the card.
  static const int maxVisibleDevices = 5;

  const UspConnectedDevicesCard({
    super.key,
    this.devices,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = this.devices ??
        ref.watch(devicesDataProvider).valueOrNull?.deviceModels;
    if (devices == null) return const CardSkeleton.list(rows: 3);

    final activeDevices = devices.where((d) => d.isActive).toList();
    final inactiveCount = devices.where((d) => !d.isActive).length;
    final visibleDevices = activeDevices.take(maxVisibleDevices).toList();
    final hasMore = activeDevices.length > maxVisibleDevices;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: AppText.titleMedium('Connected Devices')),
              if (onViewAll != null)
                AppButton.text(label: 'View All', onTap: onViewAll),
            ],
          ),
          AppGap.xs(),
          // Online/Offline counts
          Row(
            children: [
              UspStatusDot(isActive: true, size: 8),
              AppGap.xs(),
              AppText.labelLarge('${activeDevices.length} Online'),
              AppGap.md(),
              UspStatusDot(isActive: false, size: 8),
              AppGap.xs(),
              AppText.labelLarge('$inactiveCount Offline'),
            ],
          ),
          AppGap.lg(),
          // Device list (online only, max 5)
          if (activeDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: AppText.bodyMedium(
                  'No devices online',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  ...visibleDevices.map((d) => _buildDeviceRow(context, d)),
                  if (hasMore) ...[
                    AppGap.sm(),
                    Center(
                      child: AppText.labelSmall(
                        '+${activeDevices.length - maxVisibleDevices} more',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(BuildContext context, DeviceUIModel device) {
    final scheme = Theme.of(context).colorScheme;
    final category = DeviceClassifier.classify(
      hostname: device.hostName,
      mac: device.mac,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          // Device type icon (larger)
          Icon(category.icon, size: 28, color: scheme.onSurface),
          AppGap.md(),
          // Device name
          Expanded(
            child: AppText.bodyMedium(
              device.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppGap.sm(),
          // Signal indicator (WiFi) or "Wired" label (Ethernet)
          if (device.isWifi && device.signalStrength != null)
            UspSignalStrengthIndicator(rssi: device.signalStrength!)
          else
            AppText.labelSmall('Wired', color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
