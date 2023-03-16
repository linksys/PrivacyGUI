import 'package:flutter/material.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';

import 'consts.dart';

class StyledLinksysPageView extends StatelessWidget {
  static const double kDefaultToolbarHeight = 80;
  final String? title;
  final Widget? child;
  final double toolbarHeight;
  final VoidCallback? onBackTap;
  final StyledBackState backState;
  final List<Widget>? actions;
  final LinksysEdgeInsets? padding;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;
  final bool? scrollable;
  final bool isCloseStyle;

  const StyledLinksysPageView({
    super.key,
    this.title,
    this.padding,
    this.scrollable,
    this.toolbarHeight = kDefaultToolbarHeight,
    this.onBackTap,
    this.backState = StyledBackState.enabled,
    this.actions,
    this.child,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.isCloseStyle = false,
  });

  @override
  Widget build(BuildContext context) => LinksysPageView(
        appBar: _buildAppBar(context),
        padding: padding,
        scrollable: scrollable,
        bottomSheet: bottomSheet,
        bottomNavigationBar: bottomNavigationBar,
        child: child,
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
