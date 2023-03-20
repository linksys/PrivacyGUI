import 'package:flutter/material.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/page/layout/tab_layout.dart';

import 'consts.dart';

class StyledLinksysTabPageView extends StatelessWidget {
  static const double kDefaultToolbarHeight = 80;
  final String? title;
  final double toolbarHeight;
  final VoidCallback? onBackTap;
  final StyledBackState backState;
  final List<Widget>? actions;
  final List<LinksysTab> tabs;
  final Widget? headerContent;
  final List<Widget> tabContentViews;
  final bool? pinned;
  final bool? snap;
  final bool? floating;
  final bool isCloseStyle;
  final double? expandedHeight;

  const StyledLinksysTabPageView({
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
    this.pinned,
    this.snap,
    this.floating,
    this.expandedHeight,
  });

  @override
  Widget build(BuildContext context) => LinksysTabLayout(
        flexibleSpace: FlexibleSpaceBar(
          background: Column(
            children: [
              _buildAppBar(context),
              headerContent ?? Container(),
            ],
          ),
        ),
        expandedHeight: expandedHeight,
        tabs: tabs,
        tabContentViews: tabContentViews,
      );

  bool isBackEnabled() => backState == StyledBackState.enabled;

  LinksysAppBar _buildAppBar(BuildContext context) {
    final title = this.title;
    return isCloseStyle
        ? LinksysAppBar.withClose(
            context: context,
            title: title == null ? null : LinksysText.screenName(title),
            toolbarHeight: toolbarHeight,
            onBackTap: isBackEnabled()
                ? (onBackTap ??
                    () {
                      NavigationCubit.of(context).pop();
                    })
                : null,
            showBack: backState != StyledBackState.none,
          )
        : LinksysAppBar.withBack(
            context: context,
            title: title == null ? null : LinksysText.screenName(title),
            toolbarHeight: toolbarHeight,
            onBackTap: isBackEnabled()
                ? (onBackTap ??
                    () {
                      NavigationCubit.of(context).pop();
                    })
                : null,
            showBack: backState != StyledBackState.none,
            trailing: actions,
          );
  }
}
