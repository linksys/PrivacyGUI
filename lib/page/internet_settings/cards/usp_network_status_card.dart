import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
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

    return DashboardCardTemplate(
      title: loc(context).networkStatus,
      trailing: wan.addressingType.toLowerCase() == 'dhcp'
          ? AppButton.text(
              label:
                  isRenewing ? loc(context).renewing : loc(context).renewLease,
              onTap: isRenewing
                  ? null
                  : () => performUspMutation(
                        context,
                        ref,
                        loadingKey: 'wanRenew',
                        mutation: () => ref
                            .read(uspInternetSettingsProvider.notifier)
                            .renewDhcpLease(),
                        successMessage: loc(context).leaseRenewed('DHCP'),
                      ),
            )
          : null,
      // The WAN address, which is this card's own hero line — and the word for
      // the state when there is no address to show, because an IP on a link
      // that is down reads as working. `offline` is the same string the hero's
      // subtitle uses one screen up.
      popupValue: wan.isUp ? wan.ipAddress : loc(context).offline,
      detailRoute: RouteNamed.uspInternetSettings,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status hero block - Online/Offline with WAN IP
          LayoutBlock(
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
                        '${wan.isUp ? loc(context).online : loc(context).offline} - ${wan.addressingType}',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppGap.sm(),
          // Gateway & MTU - 2 columns using MetricTile
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.router,
                  label: loc(context).gateway,
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
          // Subnet & IPv6 info using InfoGrid
          InfoGrid(
            items: [
              InfoGridItem(label: loc(context).subnet, value: wan.subnetMask),
              if (wan.ipv6Addresses.isNotEmpty)
                InfoGridItem(
                  label: 'IPv6',
                  value: wan.ipv6Addresses.first,
                  copyable: true,
                  // The representative address prefers global unicast; when only
                  // a link-local (fe80::/10) address exists it is still shown,
                  // tagged with a scope badge rather than hidden. See #1128.
                  labelTrailing: isLinkLocalIpv6(wan.ipv6Addresses.first)
                      ? const Ipv6ScopeBadge()
                      : null,
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
