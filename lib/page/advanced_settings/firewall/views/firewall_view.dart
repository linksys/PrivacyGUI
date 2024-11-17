import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

class FirewallView extends ArgumentsConsumerStatefulView {
  const FirewallView({super.key, super.args});

  @override
  ConsumerState<FirewallView> createState() => _FirewallViewState();
}

class _FirewallViewState extends ConsumerState<FirewallView> {
  FirewallState? _preservedState;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    doSomethingWithSpinner(
        context,
        ref.read(firewallProvider.notifier).fetch().then((value) {
          _preservedState = value;
        }));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(firewallProvider);
    final tabs = [
      loc(context).firewall,
      loc(context).vpnPassthrough,
      loc(context).internetFilters,
      loc(context).ipv6PortServices,
    ];
    final tabContents = [
      _firewallView(state),
      _vpnPassthroughView(state),
      _internetFiltersView(state),
      _ipv6PortServicesView(state),
    ];
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      bottomBar: _tabIndex == 3
          ? null
          : PageBottomBar(
              isPositiveEnabled: _preservedState != state,
              onPositiveTap: () {
                doSomethingWithSpinner(
                    context,
                    ref.read(firewallProvider.notifier).save().then((value) {
                      _preservedState = value;
                      showSuccessSnackBar(context, loc(context).saved);
                    }).onError((error, stackTrace) {
                      showFailedSnackBar(
                          context, loc(context).unknownErrorCode(error ?? ''));
                    }));
              }),
      child: AppBasicLayout(
        content: StyledAppTabPageView(
          padding: EdgeInsets.zero,
          useMainPadding: false,
          title: loc(context).firewall,
          onBackTap: _preservedState != state
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                ref.read(firewallProvider.notifier).fetch();
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
          expandedHeight: 120,
          onTap: (index) {
            setState(() {
              _tabIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _firewallView(FirewallState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).ipv4SPIFirewallProtection),
              semanticLabel: 'ipv4 SPI firewall protection',
              value: state.settings.isIPv4FirewallEnabled,
              onChanged: (value) {
                ref.read(firewallProvider.notifier).setSettings(
                    state.settings.copyWith(isIPv4FirewallEnabled: value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).ipv6SPIFirewallProtection),
              semanticLabel: 'ipv6 SPI firewall protection',
              value: state.settings.isIPv6FirewallEnabled,
              onChanged: (value) {
                ref.read(firewallProvider.notifier).setSettings(
                    state.settings.copyWith(isIPv6FirewallEnabled: value));
              },
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
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).ipsecPassthrough),
              semanticLabel: 'ipsec passthrough',
              value: !state.settings.blockIPSec,
              onChanged: (value) {
                ref
                    .read(firewallProvider.notifier)
                    .setSettings(state.settings.copyWith(blockIPSec: !value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).pptpPassthrough),
              semanticLabel: 'pptp passthrough',
              value: !state.settings.blockPPTP,
              onChanged: (value) {
                ref
                    .read(firewallProvider.notifier)
                    .setSettings(state.settings.copyWith(blockPPTP: !value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).l2tpPassthrough),
              semanticLabel: 'l2tp passthrough',
              value: !state.settings.blockL2TP,
              onChanged: (value) {
                ref
                    .read(firewallProvider.notifier)
                    .setSettings(state.settings.copyWith(blockL2TP: !value));
              },
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
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).filterAnonymous),
              semanticLabel: 'filter anonymous',
              value: state.settings.blockAnonymousRequests,
              onChanged: (value) {
                ref.read(firewallProvider.notifier).setSettings(
                    state.settings.copyWith(blockAnonymousRequests: value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).filterMulticast),
              semanticLabel: 'filter multicast',
              value: state.settings.blockMulticast,
              onChanged: (value) {
                ref.read(firewallProvider.notifier).setSettings(
                    state.settings.copyWith(blockMulticast: value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title:
                  AppText.labelLarge(loc(context).filterInternetNATRedirection),
              semanticLabel: 'filter internet NAT redirection',
              value: state.settings.blockNATRedirection,
              onChanged: (value) {
                ref.read(firewallProvider.notifier).setSettings(
                    state.settings.copyWith(blockNATRedirection: value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).filterIdent),
              semanticLabel: 'filter ident',
              value: state.settings.blockIDENT,
              onChanged: (value) {
                ref
                    .read(firewallProvider.notifier)
                    .setSettings(state.settings.copyWith(blockIDENT: value));
              },
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
