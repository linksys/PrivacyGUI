import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/_ddns.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class AppsGamingSettingsView extends ArgumentsConsumerStatefulView {
  const AppsGamingSettingsView({super.key, super.args});

  @override
  ConsumerState<AppsGamingSettingsView> createState() =>
      _AppsGamingSettingsViewState();
}

class _AppsGamingSettingsViewState
    extends ConsumerState<AppsGamingSettingsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      Tab(
        text: loc(context).ddns,
      ),
      Tab(
        text: loc(context).singlePortForwarding,
      ),
      Tab(
        text: loc(context).portRangeForwarding,
      ),
      Tab(
        text: loc(context).portRangeTriggering,
      ),
    ];
    final tabContents = [
      DDNSSettingsView(),
      SinglePortForwardingListView(),
      PortRangeForwardingListView(),
      PortRangeTriggeringListView(),
    ];
    return StyledAppTabPageView(
      title: loc(context).appsGaming,
      tabs: tabs,
      tabContentViews: tabContents,
      expandedHeight: 120,
    );
    // return StyledAppPageView(
    //   title: loc(context).portSettings,
    //   child: AppBasicLayout(
    //     content: Column(
    //       children: [
    //         AppListCard(
    //           padding: const EdgeInsets.all(Spacing.large2),
    //           title: AppText.labelLarge(loc(context).singlePortForwarding),
    //           trailing: const Icon(LinksysIcons.chevronRight),
    //           onTap: () {
    //             context.pushNamed(RouteNamed.singlePortForwardingList);
    //           },
    //         ),
    //         const AppGap.small2(),
    //         AppListCard(
    //           padding: const EdgeInsets.all(Spacing.large2),
    //           title: AppText.labelLarge(loc(context).portRangeForwarding),
    //           trailing: const Icon(LinksysIcons.chevronRight),
    //           onTap: () {
    //             context.pushNamed(RouteNamed.portRangeForwardingList);
    //           },
    //         ),
    //         const AppGap.small2(),
    //         AppListCard(
    //           padding: const EdgeInsets.all(Spacing.large2),
    //           title: AppText.labelLarge(loc(context).portRangeTriggering),
    //           trailing: const Icon(LinksysIcons.chevronRight),
    //           onTap: () {
    //             context.pushNamed(RouteNamed.portRangeTriggeringList);
    //           },
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
