import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/info_card.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

class StaticRoutingView extends ArgumentsConsumerStatefulView {
  const StaticRoutingView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<StaticRoutingView> createState() => _StaticRoutingViewState();
}

class _StaticRoutingViewState extends ConsumerState<StaticRoutingView> {
  LocalNetworkSettingsState? originalSettings;

  @override
  void initState() {
    super.initState();
    doSomethingWithSpinner(
      context,
      ref.read(staticRoutingProvider.notifier).fetchSettings(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staticRoutingProvider);
    return StyledAppPageView(
      title: loc(context).advancedRouting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRadioList(
            initial: state.setting.isNATEnabled
                ? RoutingSettingNetwork.nat
                : RoutingSettingNetwork.dynamicRouting,
            itemHeight: 56,
            items: [
              AppRadioListItem(
                title: loc(context).nat,
                value: RoutingSettingNetwork.nat,
              ),
              AppRadioListItem(
                title: loc(context).dynamicRouting,
                value: RoutingSettingNetwork.dynamicRouting,
              ),
            ],
            onChanged: (index, value) {
              if (value != null) {
                doSomethingWithSpinner(
                  context,
                  ref
                      .read(staticRoutingProvider.notifier)
                      .saveRoutingSettingNetork(value),
                );
              }
            },
          ),
          const AppGap.large2(),
          AppInfoCard(
            title: loc(context).staticRouting,
            trailing: const Icon(LinksysIcons.chevronRight),
            onTap: () {
              context.pushNamed(RouteNamed.settingsStaticRoutingList);
            },
          ),
        ],
      ),
    );
  }
}
