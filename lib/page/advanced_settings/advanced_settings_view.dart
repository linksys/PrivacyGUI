import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
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
      scrollable: true,
      child: (context, constraints, scrollController) => Column(
        children: [
          Expanded(
            child: ResponsiveLayout(
                desktop: SizedBox(
                  height: (advancedSettings.length / 2) * 56,
                  child: GridView.builder(
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
                ),
                mobile: SizedBox(
                  height: advancedSettings.length * 56,
                  child: ListView.separated(
                    itemCount: advancedSettings.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return _advancedSettingCard(index);
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const AppGap.small2();
                    },
                  ),
                )),
          ),
        ],
      ),
    );
  }

  List<AppSectionItemData> _initAdvancedSettingsItems() {
    return [
      AppSectionItemData(
        title: loc(context).internetSettings.capitalizeWords(),
        onTap: () => context.goNamed(RouteNamed.internetSettings),
      ),
      AppSectionItemData(
          title: loc(context).localNetwork,
          onTap: () => context.goNamed(RouteNamed.settingsLocalNetwork),
          disabledOnBridge: true),
      AppSectionItemData(
        title: loc(context).advancedRouting,
        onTap: () => context.goNamed(RouteNamed.settingsStaticRouting),
        disabledOnBridge: true,
      ),
      AppSectionItemData(
        title: loc(context).administration,
        onTap: () => context.goNamed(RouteNamed.settingsAdministration),
        disabledOnBridge: true,
      ),
      AppSectionItemData(
        title: loc(context).firewall,
        onTap: () => context.goNamed(RouteNamed.settingsFirewall),
        disabledOnBridge: true,
      ),
      AppSectionItemData(
        title: loc(context).dmz,
        onTap: () => context.goNamed(RouteNamed.settingsDMZ),
        disabledOnBridge: true,
      ),
      AppSectionItemData(
          title: loc(context).appsGaming,
          onTap: () => context.goNamed(RouteNamed.settingsAppsGaming),
          disabledOnBridge: true),
    ];
  }

  Widget _advancedSettingCard(int index) {
    final item = advancedSettings[index];
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;
    final disabled = item.disabledOnBridge && isBridge;
    return Opacity(
      opacity: disabled ? .3 : 1,
      child: AppSettingCard(
        title: item.title,
        trailing: const Icon(LinksysIcons.chevronRight),
        onTap: disabled ? null : item.onTap,
      ),
    );
  }
}
