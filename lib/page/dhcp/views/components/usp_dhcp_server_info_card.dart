import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Read-only card showing DHCP server configuration from LanNetworkInfo.
class UspDhcpServerInfoCard extends StatelessWidget {
  final LanInfoUIModel info;

  const UspDhcpServerInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('DHCP Server'),
          AppGap.xl(),
          UspInfoRow(
            label: 'DHCP Server',
            value: info.dhcpEnabled ? 'Enabled' : 'Disabled',
          ),
          UspInfoRow(label: 'LAN IP', value: info.ipAddress),
          UspInfoRow(label: 'Subnet Mask', value: info.subnetMask),
          UspInfoRow(label: 'DHCP Range', value: info.dhcpRange),
          if (info.dnsServers.isNotEmpty)
            UspInfoRow(label: 'DNS Servers', value: info.dnsServers),
        ],
      ),
    );
  }
}
