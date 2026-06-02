import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_renew_action_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Release & Renew DHCP lease section.
class UspRenewSection extends ConsumerWidget {
  final InternetSettingsFeatureState state;

  const UspRenewSection({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMutation = state.status.activeMutation;
    final isBridge = state.isBridgeMode;
    final l = loc(context);
    final wanIp = state.readOnlyInfo.staticIpAddress;
    final iconColor = Theme.of(context).colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.font(Icons.sync, size: 20, color: iconColor),
              AppGap.sm(),
              AppText.titleSmall(l.releaseAndRenew),
            ],
          ),
          AppGap.md(),
          // IPv4 DHCP Renew
          Block(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: UspRenewActionCard(
              protocolLabel: l.ipv4,
              ipAddress: wanIp,
              isLoading: activeMutation == 'renewIpv4',
              onRenew: isBridge
                  ? null
                  : () => _renewDhcp(context, ref, isIpv6: false),
            ),
          ),
          AppGap.sm(),
          // IPv6 DHCP Renew
          Block(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: UspRenewActionCard(
              protocolLabel: l.ipv6,
              isLoading: activeMutation == 'renewIpv6',
              onRenew: isBridge
                  ? null
                  : () => _renewDhcp(context, ref, isIpv6: true),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _renewDhcp(
    BuildContext context,
    WidgetRef ref, {
    required bool isIpv6,
  }) async {
    try {
      final notifier = ref.read(uspInternetSettingsProvider.notifier);
      if (isIpv6) {
        await notifier.renewDhcpv6Lease();
      } else {
        await notifier.renewDhcpLease();
      }
      if (context.mounted) {
        final protocol = isIpv6 ? loc(context).ipv6 : loc(context).ipv4;
        showSuccessSnackBar(context, loc(context).leaseRenewed(protocol));
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, loc(context).failedToRenew('$e'));
      }
    }
  }
}
