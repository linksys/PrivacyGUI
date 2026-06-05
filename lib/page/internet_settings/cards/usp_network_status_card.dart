import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspNetworkStatusCard extends ConsumerWidget {
  final WanStatusUIModel? wan;

  const UspNetworkStatusCard({super.key, this.wan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wan = this.wan ?? ref.watch(wanDataProvider).valueOrNull?.model;
    if (wan == null) return const CardSkeleton.info(rows: 4);
    final isRenewing = ref.watch(uspMutationLoadingProvider) == 'wanRenew';
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Network Status',
            trailing: wan.addressingType.toLowerCase() == 'dhcp'
                ? AppButton.text(
                    label: isRenewing ? 'Renewing...' : 'Renew Lease',
                    onTap: isRenewing
                        ? null
                        : () => performUspMutation(
                              context,
                              ref,
                              loadingKey: 'wanRenew',
                              mutation: () => ref
                                  .read(uspInternetSettingsProvider.notifier)
                                  .renewDhcpLease(),
                              successMessage: 'DHCP lease renewed',
                            ),
                  )
                : null,
          ),
          AppGap.md(),
          // Status hero block - Online/Offline with WAN IP
          Block(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _StatusIndicator(isOnline: wan.isUp),
                AppGap.lg(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleLarge(wan.ipAddress),
                      AppGap.xxs(),
                      AppText.bodyMedium(
                        '${wan.isUp ? "Online" : "Offline"} - ${wan.addressingType}',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppGap.sm(),
          // Gateway & MTU - 2 columns
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.router,
                  label: 'Gateway',
                  value: wan.gateway.isNotEmpty ? wan.gateway : '-',
                  color: colorScheme.primary,
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: MetricTile(
                  icon: Icons.straighten,
                  label: 'MTU',
                  value: '${wan.mtu}',
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          AppGap.sm(),
          // Subnet & IPv6 info
          InfoGrid(
            items: [
              InfoGridItem(label: 'Subnet', value: wan.subnetMask),
              if (wan.ipv6Addresses.isNotEmpty)
                InfoGridItem(
                  label: 'IPv6',
                  value: wan.ipv6Addresses.first,
                  copyable: true,
                )
              else if (wan.ipv6Enabled)
                InfoGridItem(label: 'IPv6', value: 'Enabled'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isOnline;

  const _StatusIndicator({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();
    final color = isOnline
        ? (appColors?.semanticSuccess ?? Colors.green)
        : colorScheme.error;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: AppIcon.font(
        isOnline ? Icons.check : Icons.close,
        color: color,
        size: 28,
      ),
    );
  }
}
