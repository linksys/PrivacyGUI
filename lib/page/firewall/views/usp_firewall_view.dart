import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Firewall settings page — SPI firewall, VPN passthrough, internet filters.
class UspFirewallView extends ConsumerWidget {
  const UspFirewallView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspFirewallProvider);
    final status = state.status;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).firewall,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdvancedSettings,
      onRefresh: () =>
          ref.read(uspFirewallProvider.notifier).fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, ref, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (status.error != null) {
          return ServiceErrorView(
            error: status.error,
            title: loc(context).failedToLoadSettings,
            onRetry: () =>
                ref.read(uspFirewallProvider.notifier).fetch(forceRemote: true),
          );
        }
        return _buildContent(context, ref, state);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    FirewallFeatureState state,
  ) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: !state.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () => ref.read(uspFirewallProvider.notifier).revert(),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    FirewallFeatureState state,
  ) {
    final notifier = ref.read(uspFirewallProvider.notifier);
    final fw = state.current.model;
    final rules = state.current.ruleContext;
    // A switch is locked while saving, and when its rule is not on the router:
    // it would show a value the router never reported, and a save would write
    // nothing for it (#1611).
    bool locked(FirewallSwitch s) =>
        state.status.isSaving || !rules.controls(s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          loc(context).configureFirewallDesc,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),
        _buildFirewallSection(context, fw, notifier, locked),
        AppGap.md(),
        _buildVpnSection(context, fw, notifier, locked),
        AppGap.md(),
        _buildFiltersSection(context, fw, notifier, locked),
        AppGap.md(),
        _buildIpv6PortServiceLink(context),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Firewall Protection Section
  // ---------------------------------------------------------------------------

  Widget _buildFirewallSection(
    BuildContext context,
    FirewallUIModel fw,
    UspFirewallNotifier notifier,
    bool Function(FirewallSwitch) locked,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(loc(context).firewallProtection),
          AppGap.md(),
          SwitchBlock(
            identifier: 'firewall-spi-ipv4',
            label: loc(context).ipv4SpiFirewall,
            value: fw.isIPv4FirewallEnabled,
            onChanged: locked(FirewallSwitch.ipv4Firewall)
                ? null
                : (v) => notifier.updateSetting(
                      (m) => m.copyWith(isIPv4FirewallEnabled: v),
                    ),
          ),
          AppGap.sm(),
          SwitchBlock(
            identifier: 'firewall-spi-ipv6',
            label: loc(context).ipv6SpiFirewall,
            value: fw.isIPv6FirewallEnabled,
            onChanged: locked(FirewallSwitch.ipv6Firewall)
                ? null
                : (v) => notifier.updateSetting(
                      (m) => m.copyWith(isIPv6FirewallEnabled: v),
                    ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VPN Passthrough Section
  // ---------------------------------------------------------------------------

  Widget _buildVpnSection(
    BuildContext context,
    FirewallUIModel fw,
    UspFirewallNotifier notifier,
    bool Function(FirewallSwitch) locked,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(loc(context).vpnPassthrough),
          AppGap.md(),
          SwitchBlock(
            label: loc(context).ipsecPassthrough,
            value: !fw.blockIPSec,
            onChanged: locked(FirewallSwitch.ipsec)
                ? null
                : (v) => notifier.updateSetting(
                      (m) => m.copyWith(blockIPSec: !v),
                    ),
          ),
          AppGap.sm(),
          SwitchBlock(
            label: loc(context).pptpPassthrough,
            value: !fw.blockPPTP,
            onChanged: locked(FirewallSwitch.pptp)
                ? null
                : (v) => notifier.updateSetting(
                      (m) => m.copyWith(blockPPTP: !v),
                    ),
          ),
          AppGap.sm(),
          SwitchBlock(
            label: loc(context).l2tpPassthrough,
            value: !fw.blockL2TP,
            onChanged: locked(FirewallSwitch.l2tp)
                ? null
                : (v) => notifier.updateSetting(
                      (m) => m.copyWith(blockL2TP: !v),
                    ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Internet Filters Section
  // ---------------------------------------------------------------------------

  Widget _buildFiltersSection(
    BuildContext context,
    FirewallUIModel fw,
    UspFirewallNotifier notifier,
    bool Function(FirewallSwitch) locked,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(loc(context).internetFilters),
          AppGap.md(),
          SwitchBlock(
            identifier: 'firewall-filter-anonymous',
            label: loc(context).filterAnonymous,
            value: fw.blockAnonymousRequests,
            onChanged: locked(FirewallSwitch.anonymousRequests)
                ? null
                : (v) => notifier.updateSetting(
                      (m) => m.copyWith(blockAnonymousRequests: v),
                    ),
          ),
          AppGap.sm(),
          SwitchBlock(
            identifier: 'firewall-filter-multicast',
            label: loc(context).filterMulticast,
            value: fw.blockMulticast,
            onChanged: locked(FirewallSwitch.multicast)
                ? null
                : (v) => notifier.updateSetting(
                      (m) => m.copyWith(blockMulticast: v),
                    ),
          ),
          AppGap.sm(),
          // 1.x's order: multicast, NAT redirection, IDENT.
          SwitchBlock(
            identifier: 'firewall-filter-nat-redirection',
            label: loc(context).filterInternetNATRedirection,
            value: fw.blockNATRedirection,
            onChanged: locked(FirewallSwitch.natRedirection)
                ? null
                : (v) => notifier.updateSetting(
                      (m) => m.copyWith(blockNATRedirection: v),
                    ),
          ),
          AppGap.sm(),
          SwitchBlock(
            identifier: 'firewall-filter-ident',
            label: loc(context).filterIdent,
            value: fw.blockIDENT,
            onChanged: locked(FirewallSwitch.ident)
                ? null
                : (v) => notifier.updateSetting(
                      (m) => m.copyWith(blockIDENT: v),
                    ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IPv6 Port Service Link
  // ---------------------------------------------------------------------------

  Widget _buildIpv6PortServiceLink(BuildContext context) {
    return NavLinkBlock(
      identifier: 'firewall-ipv6-port-service',
      title: loc(context).ipv6PortService,
      description: loc(context).manageIpv6PortRules,
      // Detail pages are entered with pushNamed: `go` replaces the location, so
      // the entry point (e.g. the Dashboard) is dropped from the back stack and
      // Firewall's own back falls through to backFallback instead (#1420).
      onTap: () => context.pushNamed(RouteNamed.uspIpv6PortService),
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspFirewallProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, loc(context).firewallSettingsSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}
