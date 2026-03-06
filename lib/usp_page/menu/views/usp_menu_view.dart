import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_menu_view.dart';
import 'package:privacy_gui/page/models/app_section_item_data.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Menu page — grid layout matching the JNAP dashboard menu style.
///
/// Only features with USP support are shown. More items will be added
/// as USP protocol coverage expands.
class UspMenuView extends StatelessWidget {
  const UspMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      child: (childContext, constraints) {
        final items = _buildMenuItems(context);
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

  List<AppSectionItemData> _buildMenuItems(BuildContext context) {
    return [
      AppSectionItemData(
        title: 'Topology',
        description: 'View network topology and mesh nodes',
        iconData: Icons.account_tree,
        onTap: () => context.goNamed(RouteNamed.uspTopology),
      ),
      AppSectionItemData(
        title: 'Devices',
        description: 'View and manage connected devices',
        iconData: Icons.devices,
        onTap: () => context.goNamed(RouteNamed.uspDeviceList),
      ),
      AppSectionItemData(
        title: 'Instant Safety',
        description: 'Safe browsing with OpenDNS',
        iconData: Icons.shield_outlined,
        onTap: () => context.goNamed(RouteNamed.uspInstantSafety),
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
          );
        },
      ),
    );
  }
}
