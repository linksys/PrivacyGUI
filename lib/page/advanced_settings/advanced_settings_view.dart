import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/models/app_section_item_data.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    advancedSettings = _initAdvancedSettingsItems();
    return UiKitPageView.withSliver(
      title: loc(context).advancedSettings,
      scrollable: true,
      child: (context, constraints) => AppResponsiveLayout(
        desktop: (ctx) => GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            childAspectRatio: (430 / 60),
            mainAxisExtent: 60,
          ),
          physics: const ScrollPhysics(),
          itemCount: advancedSettings.length,
          itemBuilder: (context, index) {
            return _advancedSettingCard(index);
          },
          shrinkWrap: true,
        ),
        mobile: (ctx) => ListView.separated(
          itemCount: advancedSettings.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return _advancedSettingCard(index);
          },
          separatorBuilder: (BuildContext context, int index) {
            return AppGap.sm();
          },
        ),
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
      child: AppListCard.setting(
        title: item.title,
        trailing: AppIcon.font(AppFontIcons.chevronRight),
        onTap: disabled ? null : item.onTap,
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xl,
        ),
      ),
    );
  }
}
