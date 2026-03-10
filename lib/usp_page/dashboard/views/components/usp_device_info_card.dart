import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';

class UspDeviceInfoCard extends StatelessWidget {
  final SystemInfoUIModel info;

  const UspDeviceInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final iconName = routerIconTestByModel(
      modelNumber: info.modelName,
      hardwareVersion: info.hardwareVersion,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Device Information'),
          AppGap.lg(),
          Center(
            child: Image(
              image: DeviceImageHelper.getRouterImage(iconName),
              width: 100,
              height: 100,
            ),
          ),
          AppGap.lg(),
          UspInfoRow(label: 'Manufacturer', value: info.manufacturer),
          UspInfoRow(label: 'Model', value: info.modelName),
          UspInfoRow(label: 'Serial Number', value: info.serialNumber),
          UspInfoRow(label: 'Hardware Version', value: info.hardwareVersion),
          UspInfoRow(label: 'Firmware Version', value: info.softwareVersion),
          if (info.firmwareImages.isNotEmpty) ...[
            AppGap.lg(),
            const Divider(),
            AppGap.md(),
            AppText.titleSmall('Firmware Images'),
            AppGap.md(),
            ...info.firmwareImages
                .map((img) => _buildFirmwareRow(context, img)),
          ],
        ],
      ),
    );
  }

  /// Extract a short label from the instance path (e.g. "Image 1").
  static String _imageLabel(FirmwareImageUIModel img) {
    if (img.name.isNotEmpty) return img.name;
    final match = RegExp(r'\.(\d+)\.$').firstMatch(img.instancePath);
    return match != null ? 'Image ${match.group(1)}' : img.instancePath;
  }

  Widget _buildFirmwareRow(BuildContext context, FirmwareImageUIModel img) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: AppText.labelLarge(_imageLabel(img)),
          ),
          Expanded(
            child:
                AppText.bodyMedium(img.version.isNotEmpty ? img.version : '—'),
          ),
          if (img.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AppText.labelSmall(
                'Active',
                color: colorScheme.primary,
              ),
            ),
          if (img.isBootTarget && !img.isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AppText.labelSmall(
                'Boot',
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
