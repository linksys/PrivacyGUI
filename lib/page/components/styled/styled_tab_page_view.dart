import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/components/styled/status_label.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_column_layout.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:collection/collection.dart';

import 'package:privacygui_widgets/widgets/page/base_page_view.dart';
import 'package:privacygui_widgets/widgets/page/layout/tab_layout.dart';

import 'consts.dart';

class StyledAppTabPageView extends ConsumerWidget {
  static const double kDefaultToolbarHeight = 80;
  final String? title;
  final double toolbarHeight;
  final VoidCallback? onBackTap;
  final StyledBackState backState;
  final List<Widget>? actions;
  final List<Widget> tabs;
  final Widget? headerContent;
  final List<Widget> tabContentViews;
  final bool pinned;
  final bool snap;
  final bool floating;
  final AppBarStyle appBarStyle;
  final double? expandedHeight;
  final ScrollController? scrollController;
  final bool useMainPadding;
  final EdgeInsets? padding;
  final void Function(int index)? onTap;
  final IconData? menuIcon;
  final PageMenu? menu;
  final Widget? menuWidget;
  final String? markLabel;

  const StyledAppTabPageView({
    super.key,
    this.title,
    this.toolbarHeight = kDefaultToolbarHeight,
    this.onBackTap,
    this.backState = StyledBackState.enabled,
    this.actions,
    this.appBarStyle = AppBarStyle.back,
    required this.tabs,
    this.headerContent,
    this.tabContentViews = const [],
    this.pinned = true,
    this.snap = false,
    this.floating = false,
    this.expandedHeight,
    this.scrollController,
    this.useMainPadding = true,
    this.padding,
    this.onTap,
    this.menu,
    this.menuIcon,
    this.menuWidget,
    this.markLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageRoute = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .routes
        .last as LinksysRoute?;
    final config = pageRoute?.config;
    return useMainPadding
        ? ValueListenableBuilder<bool>(
            valueListenable: showColumnOverlayNotifier,
            builder: (context, showColumnOverlay, _) {
              return Column(
                children: [
                  const PreferredSize(
                      preferredSize: Size(0, 80), child: TopBar()),
                  Expanded(
                    child: AppResponsiveColumnLayout(
                      column: config?.column?.column,
                      centered: config?.column?.centered ?? false,
                      isShowNaviRail:
                          LinksysRoute.isShowNaviRail(context, config),
                      // topWidget: const TopBar(),
                      builder: () => buildMainContent(context, ref),
                      showColumnOverlay: showColumnOverlay,
                    ),
                  ),
                ],
              );
            })
        : buildMainContent(context, ref);
  }

  Widget buildMainContent(BuildContext context, WidgetRef ref) {
    return AppPageView(
      // appBar: _buildAppBar(context, ref),
      padding: padding,
      background: Theme.of(context).colorScheme.background,
      child: AppTabLayout(
        flexibleSpace: FlexibleSpaceBar(
          background: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appBarStyle != AppBarStyle.none)
                _buildAppBar(context, ref) ?? SizedBox(height: 0),
              headerContent ?? SizedBox(height: 0),
            ],
          ),
        ),
        expandedHeight: expandedHeight,
        scrollController: scrollController,
        pinned: pinned,
        floating: floating,
        snap: snap,
        tabs: tabs,
        tabContentViews: tabContentViews,
        onTap: onTap,
      ),
    );
  }

  bool isBackEnabled() => backState == StyledBackState.enabled;

  LinksysAppBar? _buildAppBar(BuildContext context, WidgetRef ref) {
    final title = this.title;
    switch (appBarStyle) {
      case AppBarStyle.back:
        return LinksysAppBar.withBack(
          context: context,
          title: title == null
              ? null
              : MergeSemantics(
                  child: Semantics(
                    label: 'page title',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.titleLarge(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (markLabel != null) ...[
                          const AppGap.small2(),
                          StatusLabel(label: markLabel!),
                        ],
                      ],
                    ),
                  ),
                ),
          toolbarHeight: toolbarHeight,
          onBackTap: isBackEnabled()
              ? (onBackTap ??
                  () {
                    context.pop();
                  })
              : null,
          showBack: backState != StyledBackState.none,
          trailing: _buildActions(context),
        );
      case AppBarStyle.close:
        return LinksysAppBar.withClose(
          context: context,
          title: title == null
              ? null
              : MergeSemantics(
                  child: Semantics(
                    label: 'page title',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.titleLarge(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (markLabel != null) ...[
                          const AppGap.small2(),
                          StatusLabel(label: markLabel!),
                        ],
                      ],
                    ),
                  ),
                ),
          toolbarHeight: toolbarHeight,
          onBackTap: isBackEnabled()
              ? (onBackTap ??
                  () {
                    context.pop();
                  })
              : null,
          showBack: backState != StyledBackState.none,
          trailing: _buildActions(context),
        );
      case AppBarStyle.none:
        return null;
    }
  }

  bool hasMenu() => menu != null || menuWidget != null;

  List<Widget>? _buildActions(BuildContext context) {
    final actionWidgets =
        !hasMenu() || !ResponsiveLayout.isMobileLayout(context)
            ? actions
            : [_createMenuAction(context), ...(actions ?? [])];
    return actionWidgets?.expandIndexed<Widget>((index, element) sync* {
      if (index != actionWidgets.length - 1) {
        yield element;
        yield const AppGap.small2();
      } else {
        yield element;
      }
    }).toList();
  }

  Widget _createMenuAction(BuildContext context) {
    return AppIconButton.noPadding(
      icon: menuIcon ?? LinksysIcons.moreHoriz,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          builder: (context) => Container(
              padding: const EdgeInsets.all(Spacing.large2),
              width: double.infinity,
              child: _createMenuWidget(context)),
        );
      },
    );
  }

  Widget _createMenuWidget(BuildContext context, [double? maxWidth]) {
    return Semantics(
      explicitChildNodes: true,
      identifier: 'now-page-menu-container',
      child: Container(
        constraints:
            maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
        child: menuWidget ??
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 24.0, right: 24.0, top: 24.0, bottom: 0.0),
                  child: Semantics(
                      identifier: 'now-page-menu-title',
                      child: AppText.titleSmall(menu?.title ?? '')),
                ),
                const AppGap.medium(),
                ...(menu?.items ?? []).map((e) => ListTile(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(100))),
                      leading: e.icon != null ? Icon(e.icon) : null,
                      title: Semantics(
                        // excludeSemantics: true,
                        identifier: 'now-page-menu-${e.label.kebab()}',
                        child: AppText.bodySmall(e.label),
                      ),
                      onTap: e.onTap,
                    ))
              ],
            ),
      ),
    );
  }
}
