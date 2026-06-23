import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
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
          CardHeader(title: loc(context).dhcpServer),
          AppGap.md(),
          InfoList(
            items: [
              InfoListItem(
                label: loc(context).status,
                value: info.dhcpEnabled
                    ? loc(context).enabled
                    : loc(context).disabled,
                leading: UspStatusDot(isActive: info.dhcpEnabled, size: 10),
              ),
              InfoListItem(
                  label: loc(context).routerIp,
                  value: info.ipAddress,
                  copyable: true),
              InfoListItem(
                  label: loc(context).subnetMask, value: info.subnetMask),
              if (info.dhcpRange.isNotEmpty)
                InfoListItem(
                    label: loc(context).dhcpRange, value: info.dhcpRange),
              if (info.dnsServers.isNotEmpty)
                InfoListItem(
                    label: loc(context).dnsServers, value: info.dnsServers),
            ],
          ),
        ],
      ),
    );
  }
}
