import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';

class DashboardAdvancedSettingsView extends ConsumerStatefulWidget {
  const DashboardAdvancedSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardAdvancedSettingsView> createState() =>
      _DashboardAdvancedSettingsViewState();
}

class _DashboardAdvancedSettingsViewState
    extends ConsumerState<DashboardAdvancedSettingsView> {
  List<AppSectionItemData> advancedSettings = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (advancedSettings.isEmpty) {
      advancedSettings = _initAdvancedSettingsItems();
    }
    return StyledAppPageView(
      title: loc(context).advancedSettings,
      child: ListView.builder(
        itemCount: advancedSettings.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return AppSettingCard(
            title: advancedSettings[index].title,
            trailing: const Icon(LinksysIcons.chevronRight),
            onTap: advancedSettings[index].onTap,
          );
        },
      ),
    );
  }

  List<AppSectionItemData> _initAdvancedSettingsItems() {
    return [
      AppSectionItemData(
        title: loc(context).internetSettings.capitalizeWords(),
        // iconData: getCharactersIcons(context).profileDefault,
        onTap: () => context.goNamed(RouteNamed.settingsInternet),
      ),
      AppSectionItemData(
        title: loc(context).localNetwork,
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: () => context.goNamed(RouteNamed.settingsLocalNetwork),
      ),
      // AppSectionItemData(
      //   title: loc(context).advancedRouting,
      //   // iconData: getCharactersIcons(context).infoRound,
      //   onTap: () => context.goNamed(RouteNamed.settingsIpDetails),
      // ),
      AppSectionItemData(
        title: loc(context).firewall,
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: () => context.goNamed(RouteNamed.settingsFirewall),
      ),
      // AppSectionItemData(
      //   title: loc(context).dmz,
      //   // iconData: getCharactersIcons(context).nodesDefault,
      //   onTap: () => context.goNamed(RouteNamed.settingsPort),
      // ),
      AppSectionItemData(
        title: loc(context).portForwarding,
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: () => context.goNamed(RouteNamed.settingsPort),
      ),
    ];
  }
}
