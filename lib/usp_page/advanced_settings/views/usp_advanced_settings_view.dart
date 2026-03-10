import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/models/app_section_item_data.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Advanced Settings — a list of network configuration sub-pages.
class UspAdvancedSettingsView extends StatelessWidget {
  const UspAdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);

    return UiKitPageView.withSliver(
      title: 'Advanced Settings',
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
          itemCount: items.length,
          itemBuilder: (context, index) => _buildCard(items[index]),
          shrinkWrap: true,
        ),
        mobile: (ctx) => ListView.separated(
          itemCount: items.length,
          shrinkWrap: true,
          itemBuilder: (context, index) => _buildCard(items[index]),
          separatorBuilder: (_, __) => AppGap.sm(),
        ),
      ),
    );
  }

  List<AppSectionItemData> _buildItems(BuildContext context) {
    return [
      AppSectionItemData(
        title: 'Local Network',
        onTap: () => context.goNamed(RouteNamed.uspLocalNetwork),
      ),
      AppSectionItemData(
        title: 'Firewall',
        onTap: () => context.goNamed(RouteNamed.uspFirewall),
      ),
      AppSectionItemData(
        title: 'DMZ',
        onTap: () => context.goNamed(RouteNamed.uspDmz),
      ),
      AppSectionItemData(
        title: 'Port Forwarding',
        onTap: () => context.goNamed(RouteNamed.uspPortForwardingDetail),
      ),
      AppSectionItemData(
        title: 'Static Routing',
        onTap: () => context.goNamed(RouteNamed.uspStaticRouting),
      ),
    ];
  }

  Widget _buildCard(AppSectionItemData item) {
    return AppListCard.setting(
      title: item.title,
      trailing: AppIcon.font(AppFontIcons.chevronRight),
      onTap: item.onTap,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xl,
      ),
    );
  }
}
