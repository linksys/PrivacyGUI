import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/administration/firewall/providers/firewall_provider.dart';
import 'package:privacy_gui/page/administration/firewall/providers/firewall_state.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/shortcuts/spinners.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

class FirewallView extends ArgumentsConsumerStatefulView {
  const FirewallView({super.key, super.args});

  @override
  ConsumerState<FirewallView> createState() => _FirewallViewState();
}

class _FirewallViewState extends ConsumerState<FirewallView> {
  OverlayEntry? _loadingEntry;
  FirewallState? _preservedState;

  @override
  void initState() {
    super.initState();
    // _loadingEntry = showFullScreenSpinner(context);
    ref.read(firewallProvider.notifier).fetch().then((value) {
      _preservedState = value;
      _loadingEntry?.remove();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(firewallProvider);
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).firewall,
      bottomBar: PageBottomBar(
          isPositiveEnabled: _preservedState != state,
          onPositiveTap: () {
            _loadingEntry = showFullScreenSpinner(context);
            ref.read(firewallProvider.notifier).save().then((value) {
              _preservedState = value;
              showSuccessSnackBar(context, loc(context).saved);
            }).onError((error, stackTrace) {
              showFailedSnackBar(
                  context, loc(context).unknownErrorCode(error ?? ''));
            }).whenComplete(() => _loadingEntry?.remove());
          }),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).firewall),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title:
                    AppText.labelLarge(loc(context).ipv4SPIFirewallProtection),
                value: state.settings.isIPv4FirewallEnabled,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.copyWith(isIPv4FirewallEnabled: value));
                },
              ),
            ),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title:
                    AppText.labelLarge(loc(context).ipv6SPIFirewallProtection),
                value: state.settings.isIPv6FirewallEnabled,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.copyWith(isIPv6FirewallEnabled: value));
                },
              ),
            ),
            const AppGap.large3(),
            AppText.labelLarge(loc(context).vpnPassthrough),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).ipsecPassthrough),
                value: !state.settings.blockIPSec,
                onChanged: (value) {
                  ref
                      .read(firewallProvider.notifier)
                      .setSettings(state.settings.copyWith(blockIPSec: !value));
                },
              ),
            ),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).pptpPassthrough),
                value: !state.settings.blockPPTP,
                onChanged: (value) {
                  ref
                      .read(firewallProvider.notifier)
                      .setSettings(state.settings.copyWith(blockPPTP: !value));
                },
              ),
            ),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).l2tpPassthrough),
                value: !state.settings.blockL2TP,
                onChanged: (value) {
                  ref
                      .read(firewallProvider.notifier)
                      .setSettings(state.settings.copyWith(blockL2TP: !value));
                },
              ),
            ),
            const AppGap.large3(),
            AppText.labelLarge(loc(context).internetFilters),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).filterAnonymous),
                value: state.settings.blockAnonymousRequests,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.copyWith(blockAnonymousRequests: value));
                },
              ),
            ),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).filterMulticast),
                value: state.settings.blockMulticast,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.copyWith(blockMulticast: value));
                },
              ),
            ),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(
                    loc(context).filterInternetNATRedirection),
                value: state.settings.blockNATRedirection,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.copyWith(blockNATRedirection: value));
                },
              ),
            ),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).filterIdent),
                value: state.settings.blockIDENT,
                onChanged: (value) {
                  ref
                      .read(firewallProvider.notifier)
                      .setSettings(state.settings.copyWith(blockIDENT: value));
                },
              ),
            ),
            const AppGap.large3(),
            AppListCard(
              title: AppText.labelLarge(loc(context).ipv6PortServices),
              trailing: const Icon(LinksysIcons.chevronRight),
              onTap: () {
                context.pushNamed(RouteNamed.ipv6PortServiceList);
              },
            ),
            const AppGap.medium(),
          ],
        ),
      ),
    );
  }
}
