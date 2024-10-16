import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_column_layout.dart';

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
  final List<AppTab> tabs;
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
              : AppText.titleLarge(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                ),
          toolbarHeight: toolbarHeight,
          onBackTap: isBackEnabled()
              ? (onBackTap ??
                  () {
                    // ref.read(navigationsProvider.notifier).pop();
                    context.pop();
                  })
              : null,
          showBack: backState != StyledBackState.none,
          // trailing: _buildActions(context),
        );
      case AppBarStyle.close:
        return LinksysAppBar.withClose(
          context: context,
          title: title == null ? null : AppText.titleLarge(title),
          toolbarHeight: toolbarHeight,
          onBackTap: isBackEnabled()
              ? (onBackTap ??
                  () {
                    // ref.read(navigationsProvider.notifier).pop();
                    context.pop();
                  })
              : null,
          showBack: backState != StyledBackState.none,
          // trailing: _buildActions(context),
        );
      case AppBarStyle.none:
        return null;
    }
  }
}
