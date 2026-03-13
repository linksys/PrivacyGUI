import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/models/app_section_item_data.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Advanced Settings — a list of network configuration sub-pages.
class UspAdvancedSettingsView extends StatelessWidget {
  const UspAdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Advanced Settings',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      onBackTap: () => context.canPop()
          ? context.pop()
          : context.goNamed(RouteNamed.uspMenu),
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
        title: loc(context).internetSettings,
        onTap: () => context.pushNamed(RouteNamed.uspInternetSettings),
      ),
      AppSectionItemData(
        title: loc(context).localNetwork,
        onTap: () => context.goNamed(RouteNamed.uspLocalNetwork),
      ),
      AppSectionItemData(
        title: loc(context).firewall,
        onTap: () => context.goNamed(RouteNamed.uspFirewall),
      ),
      AppSectionItemData(
        title: loc(context).dmz,
        onTap: () => context.goNamed(RouteNamed.uspDmz),
      ),
      AppSectionItemData(
        title: 'Port Forwarding',
        onTap: () => context.goNamed(RouteNamed.uspPortForwardingDetail),
      ),
      AppSectionItemData(
        title: loc(context).staticRouting,
        onTap: () => context.goNamed(RouteNamed.uspStaticRouting),
      ),
      AppSectionItemData(
        title: 'Network Diagnostics',
        onTap: () => context.goNamed(RouteNamed.uspNetworkDiagnostics),
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
