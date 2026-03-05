import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';

class UspDeviceInfoCard extends StatelessWidget {
  final SystemInfoUIModel info;

  const UspDeviceInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Device Information'),
          AppGap.xl(),
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
