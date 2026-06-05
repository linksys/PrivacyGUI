import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';

class UspLanInfoCard extends ConsumerWidget {
  final LanInfoUIModel? info;

  const UspLanInfoCard({super.key, this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = this.info ?? ref.watch(lanDataProvider).valueOrNull?.model;
    if (info == null) return const CardSkeleton.info(rows: 4);
    return DashboardCardTemplate(
      title: 'LAN Information',
      detailRoute: RouteNamed.uspLocalNetwork,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (info.ipv6Addresses.isNotEmpty)
            for (final addr in info.ipv6Addresses)
              UspInfoRow(label: 'LAN IPv6', value: addr),
          if (info.ipv6Addresses.isEmpty && info.ipv6Enabled)
            UspInfoRow(label: 'IPv6', value: 'Enabled (no address)'),
        ],
      ),
    );
  }
}
