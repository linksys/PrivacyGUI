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
  final List<Widget> tabs;
  final Widget? headerContent;
  final List<Widget> tabContentViews;
  final bool pinned;
  final bool snap;
  final bool floating;
  final bool isCloseStyle;
  final double? expandedHeight;
  final ScrollController? scrollController;
  final bool useMainPadding;

  const StyledAppTabPageView({
    super.key,
    this.title,
    this.toolbarHeight = kDefaultToolbarHeight,
    this.onBackTap,
    this.backState = StyledBackState.enabled,
    this.actions,
    this.isCloseStyle = false,
    required this.tabs,
    this.headerContent,
    this.tabContentViews = const [],
    this.pinned = true,
    this.snap = false,
    this.floating = false,
    this.expandedHeight,
    this.scrollController,
    this.useMainPadding = true,
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
      background: Theme.of(context).colorScheme.background,

      child: AppTabLayout(
        flexibleSpace: FlexibleSpaceBar(
          background: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context, ref),
              headerContent ?? Container(),
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

  LinksysAppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final title = this.title;
    return isCloseStyle
        ? LinksysAppBar.withClose(
            context: context,
            title: title == null ? null : AppText.titleLarge(title),
            toolbarHeight: toolbarHeight,
            onBackTap: isBackEnabled()
                ? (onBackTap ??
                    () {
                      context.pop();
                    })
                : null,
            showBack: backState != StyledBackState.none,
          )
        : LinksysAppBar.withBack(
            context: context,
            title: title == null
                ? null
                : AppText.titleLarge(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            toolbarHeight: toolbarHeight,
            onBackTap: isBackEnabled()
                ? (onBackTap ??
                    () {
                      context.pop();
                    })
                : null,
            showBack: backState != StyledBackState.none,
            trailing: actions,
          );
  }
}
