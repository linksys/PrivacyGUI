import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

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
        ref.read(ipv6PortServiceListProvider.notifier).fetch(),
      ]),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firewallState = ref.watch(firewallProvider);
    final firewallNotifier = ref.watch(firewallProvider.notifier);
    final ipv6State = ref.watch(ipv6PortServiceListProvider);
    final ipv6Notifier = ref.watch(ipv6PortServiceListProvider.notifier);

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

    final isDirty = firewallNotifier.isDirty || ipv6Notifier.isDirty;

    return StyledAppPageView(
      padding: EdgeInsets.zero,
      useMainPadding: false,
      tabController: _tabController,
      title: loc(context).firewall,
      bottomBar: PageBottomBar(
        isPositiveEnabled: isDirty,
        onPositiveTap: () {
          List<Future> futures = [
            if (firewallNotifier.isDirty) firewallNotifier.save(),
            if (ipv6Notifier.isDirty) ipv6Notifier.save(),
          ];
          doSomethingWithSpinner(context, Future.wait(futures))
              .then((_) {
            showChangesSavedSnackBar();
          }).catchError((error) {
            showErrorMessageSnackBar(error);
          });
        },
      ),
      onBackTap: isDirty
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                if (firewallNotifier.isDirty) firewallNotifier.restore();
                if (ipv6Notifier.isDirty) ipv6Notifier.restore();
                context.pop();
              }
            }
          : null,
      tabs: tabs.map((e) => Tab(text: e)).toList(),
      tabContentViews: tabContents,
    );
  }

  Widget _firewallView(FirewallState state) {
    final notifier = ref.read(firewallProvider.notifier);
    return StyledAppPageView.innerPage(
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).ipv4SPIFirewallProtection),
              semanticLabel: 'ipv4 SPI firewall protection',
              value: state.settings.settings.isIPv4FirewallEnabled,
              onChanged: (value) {
                notifier.setSettings(state.settings.settings
                    .copyWith(isIPv4FirewallEnabled: value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).ipv6SPIFirewallProtection),
              semanticLabel: 'ipv6 SPI firewall protection',
              value: state.settings.settings.isIPv6FirewallEnabled,
              onChanged: (value) {
                notifier.setSettings(state.settings.settings
                    .copyWith(isIPv6FirewallEnabled: value));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vpnPassthroughView(FirewallState state) {
    final notifier = ref.read(firewallProvider.notifier);
    return StyledAppPageView.innerPage(
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).ipsecPassthrough),
              semanticLabel: 'ipsec passthrough',
              value: !state.settings.settings.blockIPSec,
              onChanged: (value) {
                notifier.setSettings(
                    state.settings.settings.copyWith(blockIPSec: !value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).pptpPassthrough),
              semanticLabel: 'pptp passthrough',
              value: !state.settings.settings.blockPPTP,
              onChanged: (value) {
                notifier.setSettings(
                    state.settings.settings.copyWith(blockPPTP: !value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).l2tpPassthrough),
              semanticLabel: 'l2tp passthrough',
              value: !state.settings.settings.blockL2TP,
              onChanged: (value) {
                notifier.setSettings(
                    state.settings.settings.copyWith(blockL2TP: !value));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _internetFiltersView(FirewallState state) {
    final notifier = ref.read(firewallProvider.notifier);
    return StyledAppPageView.innerPage(
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).filterAnonymous),
              semanticLabel: 'filter anonymous',
              value: state.settings.settings.blockAnonymousRequests,
              onChanged: (value) {
                notifier.setSettings(state.settings.settings
                    .copyWith(blockAnonymousRequests: value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).filterMulticast),
              semanticLabel: 'filter multicast',
              value: state.settings.settings.blockMulticast,
              onChanged: (value) {
                notifier.setSettings(
                    state.settings.settings.copyWith(blockMulticast: value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title:
                  AppText.labelLarge(loc(context).filterInternetNATRedirection),
              semanticLabel: 'filter internet NAT redirection',
              value: state.settings.settings.blockNATRedirection,
              onChanged: (value) {
                notifier.setSettings(state.settings.settings
                    .copyWith(blockNATRedirection: value));
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).filterIdent),
              semanticLabel: 'filter ident',
              value: state.settings.settings.blockIDENT,
              onChanged: (value) {
                notifier.setSettings(
                    state.settings.settings.copyWith(blockIDENT: value));
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
