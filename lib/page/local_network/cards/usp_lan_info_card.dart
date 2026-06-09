import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspLanInfoCard extends ConsumerWidget {
  final LanInfoUIModel? info;

  const UspLanInfoCard({super.key, this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = this.info ?? ref.watch(lanDataProvider).valueOrNull?.model;
    if (info == null) return const CardSkeleton.info(rows: 4);
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCardTemplate(
      title: 'LAN Information',
      detailRoute: RouteNamed.uspLocalNetwork,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero block - Router IP with DHCP status
          LayoutBlock(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon.font(
                    Icons.router,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                AppGap.lg(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleLarge(info.ipAddress),
                      AppGap.xxs(),
                      Row(
                        children: [
                          UspStatusDot(isActive: info.dhcpEnabled, size: 8),
                          AppGap.xs(),
                          AppText.bodyMedium(
                            'DHCP ${info.dhcpEnabled ? "Enabled" : "Disabled"}',
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppGap.sm(),
          // Subnet & DNS - 2 columns
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.lan,
                  label: 'Subnet Mask',
                  value: info.subnetMask,
                  color: colorScheme.primary,
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: MetricTile(
                  icon: Icons.dns,
                  label: 'DNS',
                  value: info.dnsServers.isNotEmpty ? info.dnsServers : '-',
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          // DHCP Range & IPv6
          if (info.dhcpEnabled && info.dhcpRange.isNotEmpty ||
              info.ipv6Addresses.isNotEmpty ||
              info.ipv6Enabled) ...[
            AppGap.sm(),
            InfoGrid(
              items: [
                if (info.dhcpEnabled && info.dhcpRange.isNotEmpty)
                  InfoGridItem(label: 'DHCP Range', value: info.dhcpRange),
                if (info.ipv6Addresses.isNotEmpty)
                  InfoGridItem(
                    label: 'IPv6',
                    value: info.ipv6Addresses.first,
                    copyable: true,
                  )
                else if (info.ipv6Enabled)
                  InfoGridItem(label: 'IPv6', value: 'Enabled'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
