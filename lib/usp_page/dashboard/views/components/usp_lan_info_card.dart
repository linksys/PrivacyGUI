import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/lan_info_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspLanInfoCard extends StatelessWidget {
  final LanInfoUIModel info;

  const UspLanInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('LAN Information'),
          AppGap.xl(),
          UspInfoRow(label: 'LAN IP Address', value: info.ipAddress),
          UspInfoRow(label: 'Subnet Mask', value: info.subnetMask),
          UspInfoRow(
            label: 'DHCP Server',
            value: info.dhcpEnabled ? 'Enabled' : 'Disabled',
          ),
          if (info.dhcpEnabled)
            UspInfoRow(label: 'DHCP IP Range', value: info.dhcpRange),
          if (info.dnsServers.isNotEmpty)
            UspInfoRow(label: 'DNS Servers', value: info.dnsServers),
        ],
      ),
    );
  }
}
