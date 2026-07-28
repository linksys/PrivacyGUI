import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/styled/menus/widgets/app_menu_card.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/models/app_section_item_data.dart';
import 'package:privacy_gui/page/models/menu_badge.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Menu page — grid layout matching the JNAP dashboard menu style.
///
/// Only features with USP support are shown. More items will be added
/// as USP protocol coverage expands.
class UspMenuView extends ConsumerWidget {
  const UspMenuView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      child: (childContext, constraints) {
        final items = _buildMenuItems(context, ref);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.headlineSmall(loc(context).menu),
              AppGap.xl(),
              _buildMenuGrid(context, items),
            ],
          ),
        );
      },
    );
  }

  List<AppSectionItemData> _buildMenuItems(
      BuildContext context, WidgetRef ref) {
    // Read from L1 providers for applied state (not page-level pending state)
    final lanData = ref.watch(lanDataProvider).valueOrNull;
    final privacyState = ref.watch(uspInstantPrivacyProvider).valueOrNull;

    // Instant Safety is enabled when DNS is set to OpenDNS
    final isSafetyEnabled = lanData != null &&
        UspInstantSafetyService.isOpenDns(lanData.model.dnsServers);

    return [
      AppSectionItemData(
        identifier: 'menu-wifi-settings',
        title: loc(context).menuWifiSettings,
        description: loc(context).menuWifiSettingsDesc,
        iconData: Icons.wifi,
        onTap: () => context.goNamed(RouteNamed.uspWifiSettings),
      ),
      AppSectionItemData(
        identifier: 'menu-topology',
        title: loc(context).topology,
        description: loc(context).menuTopologyDesc,
        iconData: Icons.account_tree,
        onTap: () => context.goNamed(RouteNamed.uspTopology),
      ),
      AppSectionItemData(
        identifier: 'menu-devices',
        title: loc(context).devices,
        description: loc(context).instantDevicesDesc,
        iconData: Icons.devices,
        onTap: () => context.goNamed(RouteNamed.uspDeviceList),
      ),
      AppSectionItemData(
        identifier: 'menu-instant-safety',
        title: loc(context).instantSafety,
        description: loc(context).menuInstantSafetyDesc,
        iconData: Icons.shield_outlined,
        badges: lanData != null
            ? [isSafetyEnabled ? MenuBadge.on : MenuBadge.off]
            : [],
        onTap: () => context.goNamed(RouteNamed.uspInstantSafety),
      ),
      AppSectionItemData(
        identifier: 'menu-instant-privacy',
        title: loc(context).instantPrivacy,
        description: loc(context).instantPrivacyDesc,
        iconData: Icons.lock_outlined,
        badges: privacyState != null
            ? [privacyState.isEnabled ? MenuBadge.on : MenuBadge.off]
            : [],
        onTap: () => context.goNamed(RouteNamed.uspInstantPrivacy),
      ),
      AppSectionItemData(
        identifier: 'menu-administration',
        title: loc(context).administration,
        description: loc(context).menuAdministrationDesc,
        iconData: Icons.admin_panel_settings,
        onTap: () => context.goNamed(RouteNamed.uspAdmin),
      ),
      AppSectionItemData(
        identifier: 'menu-advanced-settings',
        title: loc(context).advancedSettings,
        description: loc(context).menuAdvancedSettingsDesc,
        iconData: Icons.tune,
        onTap: () => context.goNamed(RouteNamed.uspAdvancedSettings),
      ),
      // AppSectionItemData(
      //   identifier: 'menu-system-logs',
      //   title: 'System Logs',
      //   description: 'View router log files',
      //   iconData: Icons.article_outlined,
      //   onTap: () => context.goNamed(RouteNamed.uspSystemLog),
      // ),
      AppSectionItemData(
        identifier: 'menu-statistics',
        title: loc(context).statistics,
        description: loc(context).menuStatisticsDesc,
        iconData: Icons.bar_chart,
        onTap: () => context.goNamed(RouteNamed.uspStatistics),
      ),
      AppSectionItemData(
        identifier: 'menu-speed-test',
        title: loc(context).speedTest,
        description: loc(context).menuSpeedTestDesc,
        iconData: Icons.speed,
        onTap: () => context.goNamed(RouteNamed.uspSpeedTest),
      ),
      AppSectionItemData(
        identifier: 'menu-network-diagnostics',
        title: loc(context).networkDiagnostics,
        description: loc(context).menuNetworkDiagnosticsDesc,
        iconData: Icons.network_check,
        onTap: () => context.goNamed(RouteNamed.uspUnifiedDiagnostics),
      ),
      if (kDebugMode)
        AppSectionItemData(
          title: loc(context).uspConsole,
          description: 'Raw USP CRUD, SSE, subscription & turbo debug tool',
          iconData: Icons.terminal,
          onTap: () => context.goNamed(RouteNamed.uspTestConsole),
        ),
    ];
  }

  Widget _buildMenuGrid(BuildContext context, List<AppSectionItemData> items) {
    final isDesktop = !context.isMobileLayout;
    return SizedBox(
      height: (items.length / (isDesktop ? 3 : 1)).ceil() *
              (isDesktop ? 152 : 112) +
          kDefaultToolbarHeight,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 3 : 1,
          mainAxisSpacing: isDesktop ? AppSpacing.md : AppSpacing.sm,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: (205 / 152),
          mainAxisExtent: isDesktop ? 152 : 112,
        ),
        clipBehavior: Clip.none,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return AppMenuCard(
            iconData: item.iconData,
            title: item.title,
            description: item.description,
            onTap: item.onTap,
            badges: item.badges,
            semanticLabel: item.semanticLabel,
            identifier: item.identifier,
          );
        },
      ),
    );
  }
}
