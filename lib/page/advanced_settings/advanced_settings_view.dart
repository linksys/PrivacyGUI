import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';

class AdvancedSettingsView extends ConsumerStatefulWidget {
  const AdvancedSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<AdvancedSettingsView> createState() =>
      _AdvancedSettingsViewState();
}

class _AdvancedSettingsViewState extends ConsumerState<AdvancedSettingsView> {
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
      child: ResponsiveLayout(
          desktop: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: Spacing.medium,
              crossAxisSpacing: ResponsiveLayout.columnPadding(context),
              childAspectRatio: (430 / 56),
              mainAxisExtent: 56,
            ),
            physics: const ScrollPhysics(),
            itemCount: advancedSettings.length,
            itemBuilder: (context, index) {
              return _advancedSettingCard(index);
            },
            shrinkWrap: true,
          ),
          mobile: ListView.separated(
            itemCount: advancedSettings.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return _advancedSettingCard(index);
            },
            separatorBuilder: (BuildContext context, int index) {
              return const AppGap.small2();
            },
          )),
    );
  }

  List<AppSectionItemData> _initAdvancedSettingsItems() {
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;
    return [
      AppSectionItemData(
        title: loc(context).internetSettings.capitalizeWords(),
        // iconData: getCharactersIcons(context).profileDefault,
        onTap: () => context.goNamed(RouteNamed.internetSettings),
      ),
      AppSectionItemData(
        title: loc(context).localNetwork,
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: isBridge ? null: () => context.goNamed(RouteNamed.settingsLocalNetwork),
      ),
      AppSectionItemData(
        title: loc(context).advancedRouting,
        // iconData: getCharactersIcons(context).infoRound,
        onTap: () => context.goNamed(RouteNamed.settingsStaticRouting),
      ),
      AppSectionItemData(
        title: loc(context).administration,
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: () => context.goNamed(RouteNamed.settingsAdministration),
      ),
      AppSectionItemData(
        title: loc(context).firewall,
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: () => context.goNamed(RouteNamed.settingsFirewall),
      ),
      AppSectionItemData(
        title: loc(context).dmz,
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: () => context.goNamed(RouteNamed.settingsDMZ),
      ),
      AppSectionItemData(
        title: loc(context).appsGaming,
        // iconData: getCharactersIcons(context).nodesDefault,
        onTap: isBridge ? null : () => context.goNamed(RouteNamed.settingsAppsGaming),
      ),
    ];
  }

  Widget _advancedSettingCard(int index) {
    return AppSettingCard(
      title: advancedSettings[index].title,
      trailing: const Icon(LinksysIcons.chevronRight),
      onTap: advancedSettings[index].onTap,
    );
  }
}
