import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/components/composed/app_switch_trigger_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';

class FirewallView extends ArgumentsConsumerStatefulView {
  const FirewallView({super.key, super.args});

  @override
  ConsumerState<FirewallView> createState() => _FirewallViewState();
}

class _FirewallViewState extends ConsumerState<FirewallView>
    with PageSnackbarMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    doSomethingWithSpinner(
        context,
        Future.wait([
          ref.read(firewallProvider.notifier).fetch(),
          ref.read(ipv6PortServiceListProvider.notifier).fetch()
        ]));
  }

  @override
  void dispose() {
    super.dispose();

    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firewallState = ref.watch(firewallProvider);
    final ipv6State = ref.watch(ipv6PortServiceListProvider);
    final tabs = [
      loc(context).firewall,
      loc(context).vpnPassthrough,
      loc(context).internetFilters,
      loc(context).ipv6PortServices,
    ];
    final tabContents = [
      _firewallView(firewallState),
      _vpnPassthroughView(firewallState),
      _internetFiltersView(firewallState),
      _ipv6PortServicesView(firewallState),
    ];

    final isDirty = firewallState.isDirty || ipv6State.isDirty;

    return UiKitPageView.withSliver(
      padding: EdgeInsets.zero,
      tabController: _tabController,
      title: loc(context).firewall,
      bottomBar: UiKitBottomBarConfig(
          isPositiveEnabled: isDirty,
          onPositiveTap: () {
            List<Future> futures = [];
            if (firewallState.isDirty) {
              futures.add(ref.read(firewallProvider.notifier).save());
            }
            if (ipv6State.isDirty) {
              futures
                  .add(ref.read(ipv6PortServiceListProvider.notifier).save());
            }

            doSomethingWithSpinner(context, Future.wait(futures))
                .then((values) {
              if (!mounted) return;
              showChangesSavedSnackBar();
            }).onError((error, stackTrace) {
              if (!mounted) return;
              showErrorMessageSnackBar(error);
            });
          }),
      onBackTap: isDirty
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                if (!mounted) return;
                ref.read(firewallProvider.notifier).revert();
                ref.read(ipv6PortServiceListProvider.notifier).revert();
                context.pop();
              }
            }
          : null,
      tabs: tabs
          .map((e) => Tab(
                text: e,
              ))
          .toList(),
      tabContentViews: tabContents,
    );
  }

  Widget _firewallView(FirewallState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSwitchTriggerTile(
                key: const Key('ipv4SPIFirewallProtection'),
                title:
                    AppText.labelLarge(loc(context).ipv4SPIFirewallProtection),
                semanticLabel: 'ipv4 SPI firewall protection',
                value: state.settings.current.isIPv4FirewallEnabled,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(state
                      .settings.current
                      .copyWith(isIPv4FirewallEnabled: value));
                },
              ),
            ),
          ),
          AppGap.sm(),
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSwitchTriggerTile(
                key: const Key('ipv6SPIFirewallProtection'),
                title:
                    AppText.labelLarge(loc(context).ipv6SPIFirewallProtection),
                semanticLabel: 'ipv6 SPI firewall protection',
                value: state.settings.current.isIPv6FirewallEnabled,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(state
                      .settings.current
                      .copyWith(isIPv6FirewallEnabled: value));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vpnPassthroughView(FirewallState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSwitchTriggerTile(
                key: const Key('ipsecPassthrough'),
                title: AppText.labelLarge(loc(context).ipsecPassthrough),
                semanticLabel: 'ipsec passthrough',
                value: !state.settings.current.blockIPSec,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.current.copyWith(blockIPSec: !value));
                },
              ),
            ),
          ),
          AppGap.sm(),
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSwitchTriggerTile(
                key: const Key('pptpPassthrough'),
                title: AppText.labelLarge(loc(context).pptpPassthrough),
                semanticLabel: 'pptp passthrough',
                value: !state.settings.current.blockPPTP,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.current.copyWith(blockPPTP: !value));
                },
              ),
            ),
          ),
          AppGap.sm(),
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSwitchTriggerTile(
                key: const Key('l2tpPassthrough'),
                title: AppText.labelLarge(loc(context).l2tpPassthrough),
                semanticLabel: 'l2tp passthrough',
                value: !state.settings.current.blockL2TP,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.current.copyWith(blockL2TP: !value));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _internetFiltersView(FirewallState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSwitchTriggerTile(
                key: const Key('filterAnonymous'),
                title: AppText.labelLarge(loc(context).filterAnonymous),
                semanticLabel: 'filter anonymous',
                value: state.settings.current.blockAnonymousRequests,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(state
                      .settings.current
                      .copyWith(blockAnonymousRequests: value));
                },
              ),
            ),
          ),
          AppGap.sm(),
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSwitchTriggerTile(
                key: const Key('filterMulticast'),
                title: AppText.labelLarge(loc(context).filterMulticast),
                semanticLabel: 'filter multicast',
                value: state.settings.current.blockMulticast,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.current.copyWith(blockMulticast: value));
                },
              ),
            ),
          ),
          AppGap.sm(),
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSwitchTriggerTile(
                key: const Key('filterNATRedirection'),
                title: AppText.labelLarge(
                    loc(context).filterInternetNATRedirection),
                semanticLabel: 'filter internet NAT redirection',
                value: state.settings.current.blockNATRedirection,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(state
                      .settings.current
                      .copyWith(blockNATRedirection: value));
                },
              ),
            ),
          ),
          AppGap.sm(),
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSwitchTriggerTile(
                key: const Key('filterIdent'),
                title: AppText.labelLarge(loc(context).filterIdent),
                semanticLabel: 'filter ident',
                value: state.settings.current.blockIDENT,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.current.copyWith(blockIDENT: value));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ipv6PortServicesView(FirewallState state) {
    return Ipv6PortServiceListView();
  }
}
