import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/extension.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/card/list_card.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';
import 'package:linksys_widgets/widgets/text/app_text.dart';

class DashboardAdvancedSettingsView extends ConsumerStatefulWidget {
  const DashboardAdvancedSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardAdvancedSettingsView> createState() =>
      _DashboardAdvancedSettingsViewState();
}

class _DashboardAdvancedSettingsViewState
    extends ConsumerState<DashboardAdvancedSettingsView> {
  late List<AppSectionItemData> advancedSettings;
  @override
  void initState() {
    super.initState();

    advancedSettings = _initAdvancedSettingsItems();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).advancedSettings,
      child: ListView.builder(
        itemCount: advancedSettings.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return AppListCard(
            title: AppText.labelLarge(advancedSettings[index].title),
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
        title: loc(context).internet_settings.capitalized(),
        // iconData: getCharactersIcons(context).profileDefault,
        onTap: () => context.goNamed(RouteNamed.settingsInternet),
      ),
      AppSectionItemData(
        title: 'IP Details',
        // iconData: getCharactersIcons(context).infoRound,
        onTap: () => context.goNamed(RouteNamed.settingsIpDetails),
      ),
      AppSectionItemData(
        title: 'Local Network Settings',
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: () => context.goNamed(RouteNamed.settingsLocalNetwork),
      ),
      AppSectionItemData(
        title: 'Port',
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: () => context.goNamed(RouteNamed.settingsPort),
      ),
    ];
  }

}
