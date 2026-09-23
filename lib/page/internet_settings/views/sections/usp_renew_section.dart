import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_renew_action_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Release & Renew DHCP lease section.
///
/// The address shown here is READ-ONLY, so it comes from L1 (#1587 Phase 2). It used to
/// read `state.readOnlyInfo.staticIpAddress`, which is the page's L2 snapshot and
/// therefore froze at page-entry — stale for the same reason, and from the same cause,
/// as the status banner above it. Same TR-181 parameter either way; `wanDataProvider`
/// is the copy that a `wanStatus` push refreshes.
///
/// Reading L1 here also picks up something L2 did not: `usp_internet_settings_notifier`
/// already calls `ref.invalidate(wanDataProvider)` after a save and after a DHCP renew,
/// so those two paths now refresh this address as well.
///
/// That external `ref.invalidate` does NOT blink the address to '--' while the refetch
/// runs, which is worth stating because `invalidate` and `invalidateSelf` are not
/// interchangeable and only one of them was obviously safe. Measured on riverpod 2.6.1
/// with a listener on this provider: the frame during the refetch is
/// `isLoading: true, hasValue: true` still carrying the previous address, and only the
/// completion swaps in the new one. So the user does not see a flash of "unknown" in the
/// middle of the renew they just triggered.
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
    // `null`, not `''`, when L1 has no value: `UspRenewActionCard` renders both as '--',
    // but keeping them distinct here means this widget never claims to have read an
    // address it could not read. `AsyncError` is reachable on an ordinary path —
    // `uspWanDataServiceProvider` throws when `uspClientProvider` is null (session not
    // yet established, re-auth, dropped socket) — and this provider has no retry, so
    // collapsing it into "empty address" would have been indefinitely wrong rather than
    // briefly wrong. Same reasoning as the status banner above; see its `isKnown`.
    final wanIp = ref.watch(wanDataProvider).valueOrNull?.model.ipAddress;
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
          LayoutBlock(
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
          LayoutBlock(
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
