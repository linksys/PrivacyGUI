import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/wan_status_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspNetworkStatusCard extends ConsumerWidget {
  final WanStatusUIModel? wan;

  const UspNetworkStatusCard({super.key, this.wan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wan =
        this.wan ?? ref.watch(uspDashboardProvider).valueOrNull?.wanStatusModel;
    if (wan == null) return const SizedBox.shrink();
    final isRenewing = ref.watch(uspMutationLoadingProvider) == 'wanRenew';

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
          if (wan.ipv6Addresses.isNotEmpty)
            for (final addr in wan.ipv6Addresses)
              UspInfoRow(label: 'WAN IPv6', value: addr),
          if (wan.ipv6Addresses.isEmpty && wan.ipv6Enabled)
            UspInfoRow(label: 'IPv6', value: 'Enabled (no address)'),
          if (wan.addressingType.toLowerCase() == 'dhcp') ...[
            AppGap.lg(),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton.text(
                label: isRenewing ? 'Renewing...' : 'Renew Lease',
                icon: isRenewing ? null : AppIcon.font(Icons.refresh, size: 16),
                onTap: isRenewing
                    ? null
                    : () => performUspMutation(
                          context,
                          ref,
                          loadingKey: 'wanRenew',
                          mutation: () => ref
                              .read(uspDashboardProvider.notifier)
                              .renewWanLease(),
                          successMessage: 'DHCP lease renewed',
                        ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
