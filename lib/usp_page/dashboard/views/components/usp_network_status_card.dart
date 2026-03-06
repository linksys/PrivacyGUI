import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/wan_status_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspNetworkStatusCard extends StatelessWidget {
  final WanStatusUIModel wan;

  const UspNetworkStatusCard({super.key, required this.wan});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UspStatusDot(isActive: wan.isUp, size: 12),
              AppGap.sm(),
              AppText.titleMedium('Network Status'),
              const Spacer(),
              AppText.bodyMedium(
                wan.isUp ? 'Online' : 'Offline',
                color: wan.isUp
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          AppGap.xl(),
          UspInfoRow(label: 'WAN IP', value: wan.ipAddress),
          UspInfoRow(label: 'Subnet Mask', value: wan.subnetMask),
          UspInfoRow(label: 'Connection Type', value: wan.addressingType),
          if (wan.gateway.isNotEmpty)
            UspInfoRow(label: 'Default Gateway', value: wan.gateway),
          UspInfoRow(label: 'MTU', value: '${wan.mtu}'),
        ],
      ),
    );
  }
}
