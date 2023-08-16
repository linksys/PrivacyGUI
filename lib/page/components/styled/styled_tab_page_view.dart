import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/page/layout/tab_layout.dart';

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
  final bool isCloseStyle;
  final double? expandedHeight;
  final ScrollController? scrollController;

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      AppPageView.noNavigationBar(
        padding: const AppEdgeInsets.only(),
        child: AppTabLayout(
          flexibleSpace: FlexibleSpaceBar(
            background: Column(
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

  bool isBackEnabled() => backState == StyledBackState.enabled;

  LinksysAppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final title = this.title;
    return isCloseStyle
        ? LinksysAppBar.withClose(
            context: context,
            title: title == null ? null : AppText.screenName(title),
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
            title: title == null ? null : AppText.screenName(title),
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
