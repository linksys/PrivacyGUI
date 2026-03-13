import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';

class UspDeviceInfoCard extends ConsumerWidget {
  final SystemInfoUIModel? info;

  const UspDeviceInfoCard({super.key, this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = this.info ??
        ref.watch(uspDashboardProvider).valueOrNull?.systemInfoModel;
    if (info == null) return const SizedBox.shrink();
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
        ],
      ),
    );
  }
}
