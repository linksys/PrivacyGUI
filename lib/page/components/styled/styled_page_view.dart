// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/material/color_schemes_ext.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/buttons/popup_button.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';

import 'consts.dart';

class PageMenuItem {
  final String title;
  final IconData? icon;
  final void Function()? onTap;
  PageMenuItem({
    required this.title,
    required this.icon,
    this.onTap,
  });
}

class StyledAppPageView extends ConsumerWidget {
  static const double kDefaultToolbarHeight = 80;
  final String? title;
  final Widget child;
  final double toolbarHeight;
  final VoidCallback? onBackTap;
  final StyledBackState backState;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;
  final bool? scrollable;
  final AppBarStyle appBarStyle;
  final bool handleNoConnection;
  final bool handleBanner;
  final List<PageMenuItem> menuItems;

  const StyledAppPageView({
    super.key,
    this.title,
    this.padding,
    this.scrollable,
    this.toolbarHeight = kDefaultToolbarHeight,
    this.onBackTap,
    this.backState = StyledBackState.enabled,
    this.actions,
    required this.child,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.appBarStyle = AppBarStyle.back,
    this.handleNoConnection = false,
    this.handleBanner = false,
    this.menuItems = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPageView(
      appBar: _buildAppBar(context, ref),
      padding: padding,
      scrollable: scrollable,
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
      background: Theme.of(context).extension<ColorSchemeExt>()?.surfaceBright,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!ResponsiveLayout.isMobile(context))
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(
                  Radius.circular(8),
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              elevation: 0,
              child: _createMenuWidget(context),
            ),
          Expanded(child: child),
        ],
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
          trailing: _buildActions(context),
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
        );
      case AppBarStyle.none:
        return null;
    }
  }

  List<Widget>? _buildActions(BuildContext context) {
    return menuItems.isEmpty || !ResponsiveLayout.isMobile(context)
        ? actions
        : ((actions ?? [])..add(_createMenuAction(context)));
  }

  Widget _createMenuAction(BuildContext context) {
    return AppPopupButton(
        button: Icon(getCharactersIcons(context).moreVertical),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        builder: (controller) {
          return _createMenuWidget(context);
        });
  }

  Widget _createMenuWidget(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...menuItems.map((e) => ListTile(
                leading: e.icon != null ? Icon(e.icon) : null,
                title: AppText.bodySmall(e.title),
                onTap: e.onTap,
              ))
        ],
      ),
    );
  }
}
