import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/semantic.dart';
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
  FirewallState? _preservedState;
  final String _tag = 'firewall';

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
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).firewall,
      bottomBar: PageBottomBar(
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
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(loc(context).firewall),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title:
                    AppText.labelLarge(loc(context).ipv4SPIFirewallProtection),
                identifier: semanticIdentifier(
                    tag: _tag, description: 'ipv4SPIFirewallProtection'),
                semanticLabel: loc(context).ipv4SPIFirewallProtection,
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
                title: AppText.labelLarge(
                  loc(context).ipv6SPIFirewallProtection,
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'ipv6SPIFirewallProtection'),
                ),
                identifier: semanticIdentifier(
                    tag: _tag, description: 'ipv6SPIFirewallProtection'),
                semanticLabel: loc(context).ipv6SPIFirewallProtection,
                value: state.settings.isIPv6FirewallEnabled,
                onChanged: (value) {
                  ref.read(firewallProvider.notifier).setSettings(
                      state.settings.copyWith(isIPv6FirewallEnabled: value));
                },
              ),
            ),
            const AppGap.large4(),
            AppText.labelLarge(
              loc(context).vpnPassthrough,
              identifier:
                  semanticIdentifier(tag: _tag, description: 'vpnPassthrough'),
            ),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(
                  loc(context).ipsecPassthrough,
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'ipsecPassthrough'),
                ),
                identifier: semanticIdentifier(
                    tag: _tag, description: 'ipsecPassthrough'),
                semanticLabel: loc(context).ipsecPassthrough,
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
                title: AppText.labelLarge(
                  loc(context).pptpPassthrough,
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'pptpPassthrough'),
                ),
                identifier: semanticIdentifier(
                    tag: _tag, description: 'pptpPassthrough'),
                semanticLabel: loc(context).pptpPassthrough,
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
                title: AppText.labelLarge(
                  loc(context).l2tpPassthrough,
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'l2tpPassthrough'),
                ),
                identifier: semanticIdentifier(
                    tag: _tag, description: 'l2tpPassthrough'),
                semanticLabel: loc(context).l2tpPassthrough,
                value: !state.settings.blockL2TP,
                onChanged: (value) {
                  ref
                      .read(firewallProvider.notifier)
                      .setSettings(state.settings.copyWith(blockL2TP: !value));
                },
              ),
            ),
            const AppGap.large4(),
            AppText.labelLarge(
              loc(context).internetFilters,
              identifier:
                  semanticIdentifier(tag: _tag, description: 'internetFilters'),
            ),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(
                  loc(context).filterAnonymous,
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'filterAnonymous'),
                ),
                identifier: semanticIdentifier(
                    tag: _tag, description: 'filterAnonymous'),
                semanticLabel: loc(context).filterAnonymous,
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
                title: AppText.labelLarge(
                  loc(context).filterMulticast,
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'filterMulticast'),
                ),
                identifier: semanticIdentifier(
                    tag: _tag, description: 'filterMulticast'),
                semanticLabel: loc(context).filterMulticast,
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
                title: AppText.labelLarge(
                  loc(context).filterInternetNATRedirection,
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'filterInternetNATRedirection'),
                ),
                identifier: semanticIdentifier(
                    tag: _tag, description: 'filterInternetNATRedirection'),
                semanticLabel: loc(context).filterInternetNATRedirection,
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
                title: AppText.labelLarge(
                  loc(context).filterIdent,
                  identifier:
                      semanticIdentifier(tag: _tag, description: 'filterIdent'),
                ),
                identifier:
                    semanticIdentifier(tag: _tag, description: 'filterIdent'),
                semanticLabel: loc(context).filterIdent,
                value: state.settings.blockIDENT,
                onChanged: (value) {
                  ref
                      .read(firewallProvider.notifier)
                      .setSettings(state.settings.copyWith(blockIDENT: value));
                },
              ),
            ),
            const AppGap.large4(),
            AppListCard(
              title: AppText.labelLarge(
                loc(context).ipv6PortServices,
                identifier: semanticIdentifier(
                    tag: _tag, description: 'ipv6PortServices'),
              ),
              trailing: Semantics(
                  identifier: semanticIdentifier(
                      tag: _tag, description: 'ipv6PortServices-icon'),
                  label: 'ipv6 port services icon',
                  child: const Icon(LinksysIcons.chevronRight)),
              onTap: () {
                context.pushNamed(RouteNamed.ipv6PortServiceList);
              },
            ),
            const AppGap.small2(),
          ],
        ),
      ),
    );
  }
}
