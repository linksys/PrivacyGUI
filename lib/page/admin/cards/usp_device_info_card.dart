import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspDeviceInfoCard extends ConsumerWidget {
  final SystemInfoUIModel? info;

  const UspDeviceInfoCard({super.key, this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info =
        this.info ?? ref.watch(systemInfoDataProvider).valueOrNull?.model;
    if (info == null) return const CardSkeleton.info(rows: 5);

    // Get MAC and hostname from master node
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final masterNode =
        devicesData?.nodeModels.where((n) => n.isMaster).firstOrNull;
    final macAddress = masterNode?.deviceId;
    final hostName = masterNode?.displayName;

    final iconName = routerIconTestByModel(
      modelNumber: info.modelName,
      hardwareVersion: info.hardwareVersion,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(title: 'Device Information'),
          AppGap.md(),
          // Device hero block - model name with icon
          Block(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Image(
                    image: DeviceImageHelper.getRouterImage(iconName),
                    width: 72,
                    height: 72,
                  ),
                ),
                AppGap.lg(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hostName != null &&
                          hostName.isNotEmpty &&
                          hostName != info.modelName) ...[
                        AppText.titleLarge(hostName),
                        AppGap.xxs(),
                        AppText.bodyMedium(info.modelName),
                      ] else
                        AppText.titleLarge(info.modelName),
                      AppGap.xs(),
                      AppText.bodySmall(
                        info.manufacturer,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppGap.sm(),
          // Firmware & Hardware - 2 columns
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.system_update,
                  label: 'Firmware',
                  value: info.softwareVersion,
                  color: colorScheme.primary,
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: MetricTile(
                  icon: Icons.memory,
                  label: 'Hardware',
                  value: info.hardwareVersion,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          AppGap.sm(),
          // Serial & MAC - side by side with copy
          InfoGrid(
            items: [
              InfoGridItem(
                label: 'Serial',
                value: info.serialNumber,
                copyable: true,
              ),
              if (macAddress != null && macAddress.isNotEmpty)
                InfoGridItem(
                  label: 'MAC',
                  value: macAddress.toUpperCase(),
                  copyable: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
