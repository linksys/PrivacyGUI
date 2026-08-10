import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/models/app_section_item_data.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Advanced Settings — a list of network configuration sub-pages.
class UspAdvancedSettingsView extends StatelessWidget {
  const UspAdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).advancedSettings,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      onBackTap: () => context.navigateBack(fallback: RouteNamed.uspMenu),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return AppResponsiveLayout(
          mobile: (_) => _buildMobileList(items),
          desktop: (_) => _buildDesktopGrid(items),
        );
      },
    );
  }

  Widget _buildMobileList(List<AppSectionItemData> items) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildCard(item),
              ))
          .toList(),
    );
  }

  Widget _buildDesktopGrid(List<AppSectionItemData> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = Expanded(child: _buildCard(items[i]));
      final right = i + 1 < items.length
          ? Expanded(child: _buildCard(items[i + 1]))
          : const Expanded(child: SizedBox.shrink());
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [left, AppGap.gutter(), right],
        ),
      ));
    }
    return Column(children: rows);
  }

  List<AppSectionItemData> _buildItems(BuildContext context) {
    return [
      AppSectionItemData(
        identifier: 'advanced-settings-internet',
        title: loc(context).internetSettings,
        onTap: () => context.pushNamed(RouteNamed.uspInternetSettings),
      ),
      AppSectionItemData(
        identifier: 'advanced-settings-local-network',
        title: loc(context).localNetwork,
        onTap: () => context.pushNamed(RouteNamed.uspLocalNetwork),
      ),
      AppSectionItemData(
        identifier: 'advanced-settings-firewall',
        title: loc(context).firewall,
        onTap: () => context.pushNamed(RouteNamed.uspFirewall),
      ),
      AppSectionItemData(
        identifier: 'advanced-settings-dmz',
        title: loc(context).dmz,
        onTap: () => context.pushNamed(RouteNamed.uspDmz),
      ),
      AppSectionItemData(
        identifier: 'advanced-settings-port-forwarding',
        title: loc(context).portForwarding,
        onTap: () => context.pushNamed(RouteNamed.uspPortForwardingDetail),
      ),
      AppSectionItemData(
        identifier: 'advanced-settings-static-routing',
        title: loc(context).staticRouting,
        onTap: () => context.pushNamed(RouteNamed.uspStaticRouting),
      ),
    ];
  }

  Widget _buildCard(AppSectionItemData item) {
    return LayoutBlock(
      identifier: item.identifier,
      onTap: item.onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.bodyLarge(item.title),
          AppIcon.font(AppFontIcons.chevronRight, size: 20),
        ],
      ),
    );
  }
}
