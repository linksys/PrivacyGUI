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
        semanticLabel: 'menu-wifi-settings',
        title: 'WiFi Settings',
        description: 'Networks, security, MAC filtering',
        iconData: Icons.wifi,
        onTap: () => context.goNamed(RouteNamed.uspWifiSettings),
      ),
      AppSectionItemData(
        semanticLabel: 'menu-topology',
        title: 'Topology',
        description: 'View network topology and mesh nodes',
        iconData: Icons.account_tree,
        onTap: () => context.goNamed(RouteNamed.uspTopology),
      ),
      AppSectionItemData(
        semanticLabel: 'menu-devices',
        title: 'Devices',
        description: 'View and manage connected devices',
        iconData: Icons.devices,
        onTap: () => context.goNamed(RouteNamed.uspDeviceList),
      ),
      AppSectionItemData(
        semanticLabel: 'menu-instant-safety',
        title: 'Instant Safety',
        description: 'Safe browsing with OpenDNS',
        iconData: Icons.shield_outlined,
        badges: lanData != null
            ? [isSafetyEnabled ? MenuBadge.on : MenuBadge.off]
            : [],
        onTap: () => context.goNamed(RouteNamed.uspInstantSafety),
      ),
      AppSectionItemData(
        semanticLabel: 'menu-instant-privacy',
        title: 'Instant Privacy',
        description: 'Lock network to currently connected devices',
        iconData: Icons.lock_outlined,
        badges: privacyState != null
            ? [privacyState.isEnabled ? MenuBadge.on : MenuBadge.off]
            : [],
        onTap: () => context.goNamed(RouteNamed.uspInstantPrivacy),
      ),
      AppSectionItemData(
        semanticLabel: 'menu-administration',
        title: 'Administration',
        description: 'Password, timezone, reboot',
        iconData: Icons.admin_panel_settings,
        onTap: () => context.goNamed(RouteNamed.uspAdmin),
      ),
      AppSectionItemData(
        semanticLabel: 'menu-advanced-settings',
        title: 'Advanced Settings',
        description: 'Firewall, local network, DMZ, port forwarding, routing',
        iconData: Icons.tune,
        onTap: () => context.goNamed(RouteNamed.uspAdvancedSettings),
      ),
      // AppSectionItemData(
      //   semanticLabel: 'menu-system-logs',
      //   title: 'System Logs',
      //   description: 'View router log files',
      //   iconData: Icons.article_outlined,
      //   onTap: () => context.goNamed(RouteNamed.uspSystemLog),
      // ),
      AppSectionItemData(
        semanticLabel: 'menu-statistics',
        title: 'Statistics',
        description: 'Network, device, and system analytics',
        iconData: Icons.bar_chart,
        onTap: () => context.goNamed(RouteNamed.uspStatistics),
      ),
      if (kDebugMode)
        AppSectionItemData(
          title: 'USP Console',
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
          );
        },
      ),
    );
  }
}
