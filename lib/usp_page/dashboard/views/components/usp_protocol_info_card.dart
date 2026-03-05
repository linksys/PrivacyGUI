import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';

class UspProtocolInfoCard extends StatelessWidget {
  const UspProtocolInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Protocol'),
          AppGap.xl(),
          UspInfoRow(label: 'Transport', value: 'USP (TR-369 over WebSocket)'),
          UspInfoRow(label: 'Data Model', value: 'TR-181 Device:2'),
          UspInfoRow(label: 'JNAP', value: 'Unavailable'),
        ],
      ),
    );
  }
}
