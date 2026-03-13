import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_state.dart';
import 'package:privacy_gui/usp_page/internet_settings/views/components/usp_renew_action_card.dart';
import 'package:privacy_gui/usp_page/internet_settings/views/components/usp_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Release & Renew DHCP lease section.
class UspRenewSection extends ConsumerWidget {
  final UspInternetSettingsState state;

  const UspRenewSection({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingKey = ref.watch(uspInternetMutationLoadingProvider);
    final isBridge = state.isBridgeMode;
    final l = loc(context);
    final wanIp = state.wanSettings.staticIpAddress;

    return UspSectionCard(
      title: l.releaseAndRenew,
      leadingIcon: Icons.sync,
      child: Column(
        children: [
          // IPv4 DHCP Renew
          UspRenewActionCard(
            protocolLabel: l.ipv4,
            ipAddress: wanIp,
            isLoading: loadingKey == 'renewIpv4',
            onRenew:
                isBridge ? null : () => _renewDhcp(context, ref, isIpv6: false),
          ),
          AppGap.lg(),
          AppDivider(),
          AppGap.lg(),
          // IPv6 DHCP Renew
          UspRenewActionCard(
            protocolLabel: l.ipv6,
            isLoading: loadingKey == 'renewIpv6',
            onRenew:
                isBridge ? null : () => _renewDhcp(context, ref, isIpv6: true),
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
    final key = isIpv6 ? 'renewIpv6' : 'renewIpv4';
    ref.read(uspInternetMutationLoadingProvider.notifier).state = key;
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
    } finally {
      ref.read(uspInternetMutationLoadingProvider.notifier).state = null;
    }
  }
}
