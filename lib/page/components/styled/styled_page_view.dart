// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/status_label.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_column_layout.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/base_page_view.dart';
import 'package:collection/collection.dart';
import 'package:privacy_gui/core/utils/extension.dart';

import 'package:privacy_gui/localization/localization_hook.dart';

import 'consts.dart';

///
/// To display negitive item, isNegitiveEnabled should not be null
///
class PageBottomBar extends Equatable {
  final bool isPositiveEnabled;
  final bool? isNegitiveEnabled;
  final String? positiveLabel;
  final String? negitiveLable;
  final void Function() onPositiveTap;
  final void Function()? onNegitiveTap;

  const PageBottomBar({
    required this.isPositiveEnabled,
    this.isNegitiveEnabled,
    this.positiveLabel,
    this.negitiveLable,
    required this.onPositiveTap,
    this.onNegitiveTap,
  });

  PageBottomBar copyWith({
    bool? isPositiveEnabled,
    bool? isNegitiveEnabled,
    String? positiveLabel,
    String? negitiveLable,
    void Function()? onPositiveTap,
    void Function()? onNegitiveTap,
  }) {
    return PageBottomBar(
      isPositiveEnabled: isPositiveEnabled ?? this.isPositiveEnabled,
      isNegitiveEnabled: isNegitiveEnabled ?? this.isNegitiveEnabled,
      positiveLabel: positiveLabel ?? this.positiveLabel,
      negitiveLable: negitiveLable ?? this.negitiveLable,
      onPositiveTap: onPositiveTap ?? this.onPositiveTap,
      onNegitiveTap: onNegitiveTap ?? this.onNegitiveTap,
    );
  }

  @override
  List<Object?> get props {
    return [
      isPositiveEnabled,
      isNegitiveEnabled,
      positiveLabel,
      negitiveLable,
      onPositiveTap,
      onNegitiveTap,
    ];
  }
}

class InversePageBottomBar extends PageBottomBar {
  const InversePageBottomBar({
    required super.isPositiveEnabled,
    super.isNegitiveEnabled,
    super.positiveLabel,
    super.negitiveLable,
    required super.onPositiveTap,
    super.onNegitiveTap,
  });
}

class PageMenu {
  final String? title;
  List<PageMenuItem> items;
  PageMenu({
    this.title,
    required this.items,
  });
}

class PageMenuItem {
  final String label;
  final IconData? icon;
  final void Function()? onTap;
  PageMenuItem({
    required this.label,
    required this.icon,
    this.onTap,
  });
}

const double kDefaultToolbarHeight = 80;
const double kDefaultBottomHeight = 80;

class StyledAppPageView extends ConsumerWidget {
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
  final IconData? menuIcon;
  final PageMenu? menu;
  final Widget? menuWidget;
  final ScrollController? controller;
  final ({bool left, bool top, bool right, bool bottom}) enableSafeArea;
  final PageBottomBar? bottomBar;
  final bool menuOnRight;
  final bool largeMenu;
  final Widget? topbar;
  final bool useMainPadding;
  final String? markLabel;

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
    this.menuIcon,
    this.menu,
    this.menuWidget,
    this.controller,
    this.enableSafeArea = (left: true, top: true, right: true, bottom: true),
    this.bottomBar,
    this.menuOnRight = false,
    this.largeMenu = false,
    this.topbar,
    this.useMainPadding = true,
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
                  topbar ??
                      const PreferredSize(
                          preferredSize: Size(0, 80), child: TopBar()),
                  Expanded(
                    child: AppResponsiveColumnLayout(
                      column: config?.column?.column,
                      centered: config?.column?.centered ?? false,
                      isShowNaviRail:
                          LinksysRoute.isShowNaviRail(context, config),
                      builder: () => buildMainContent(context, ref),
                      showColumnOverlay: !kReleaseMode && showColumnOverlay,
                    ),
                  ),
                ],
              );
            })
        : buildMainContent(context, ref);
    // return buildMainContent(context, ref);
  }

  Widget buildPageView(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
          controller: controller,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: buildMainContent(context, ref),
            ),
          ),
        );
      },
    );
  }

  Widget buildMainContent(BuildContext context, WidgetRef ref) {
    final views = [
      if (!ResponsiveLayout.isMobileLayout(context) && hasMenu()) ...[
        SizedBox(
          width: largeMenu ? 4.col : 3.col,
          child: AppCard(
            child: _createMenuWidget(context),
          ),
        ),
        const AppGap.gutter(),
      ],
      Expanded(child: child),
    ];
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: bottomBar != null ? 80.0 : 0.0),
          child: AppPageView(
            appBar: _buildAppBar(context, ref),
            padding: padding,
            scrollable: scrollable,
            scrollController: controller,
            bottomSheet: bottomSheet,
            bottomNavigationBar: bottomNavigationBar,
            background: Theme.of(context).colorScheme.background,
            enableSafeArea: (
              left: enableSafeArea.left,
              top: enableSafeArea.top,
              right: enableSafeArea.right,
              bottom: enableSafeArea.bottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: menuOnRight ? views.reversed.toList() : views,
            ),
          ),
        ),
        _bottomWidget(context),
      ],
    );
  }

  bool isBackEnabled() => backState == StyledBackState.enabled;

  bool hasMenu() => menu != null || menuWidget != null;

  LinksysAppBar? _buildAppBar(BuildContext context, WidgetRef ref) {
    final title = this.title;
    switch (appBarStyle) {
      case AppBarStyle.back:
        return LinksysAppBar.withBack(
          context: context,
          title: title == null
              ? null
              : Semantics(
                  label: 'page title',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: AppText.titleLarge(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (markLabel != null) ...[
                        const AppGap.small2(),
                        StatusLabel(label: markLabel!),
                      ],
                    ],
                  ),
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
          trailing: _buildActions(context),
        );
      case AppBarStyle.close:
        return LinksysAppBar.withClose(
          context: context,
          title: title == null
              ? null
              : Semantics(
                  label: 'page title', child: Row(
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
                  ),),
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
      case AppBarStyle.none:
        return null;
    }
  }

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

  Widget _bottomWidget(BuildContext context) {
    return bottomBar != null
        ? Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Theme.of(context).colorScheme.background,
              height: kDefaultBottomHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Semantics(
                      identifier: 'now-page-bottom-container',
                      child: Row(
                        children: [
                          if (ResponsiveLayout.isMobileLayout(context)) ...[
                            if (bottomBar?.isNegitiveEnabled != null) ...[
                              Expanded(
                                child: AppOutlinedButton.fillWidth(
                                  bottomBar?.negitiveLable ??
                                      loc(context).cancel,
                                  onTap: bottomBar?.isNegitiveEnabled == true
                                      ? () {
                                          bottomBar?.onNegitiveTap?.call();
                                        }
                                      : null,
                                  color: Theme.of(context).colorScheme.outline,
                                  identifier: 'now-page-bottom-button-negitive',
                                ),
                              ),
                              const AppGap.medium(),
                            ],
                            Expanded(
                              child: AppFilledButton.fillWidth(
                                bottomBar?.positiveLabel ?? loc(context).save,
                                onTap: bottomBar?.isPositiveEnabled == true
                                    ? () {
                                        bottomBar?.onPositiveTap.call();
                                      }
                                    : null,
                                color: bottomBar is InversePageBottomBar
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                                identifier: 'now-page-bottom-button-positive',
                              ),
                            ),
                          ],
                          if (!ResponsiveLayout.isMobileLayout(context)) ...[
                            if (bottomBar?.isNegitiveEnabled != null) ...[
                              AppOutlinedButton(
                                bottomBar?.negitiveLable ?? loc(context).cancel,
                                color: Theme.of(context).colorScheme.outline,
                                identifier: 'now-page-bottom-button-negitice',
                                onTap: bottomBar?.isNegitiveEnabled == true
                                    ? () {
                                        bottomBar?.onNegitiveTap?.call();
                                      }
                                    : null,
                              ),
                              const AppGap.medium(),
                            ],
                            AppFilledButton(
                              bottomBar?.positiveLabel ?? loc(context).save,
                              identifier: 'now-page-bottom-button-positive',
                              onTap: bottomBar?.isPositiveEnabled == true
                                  ? () {
                                      bottomBar?.onPositiveTap.call();
                                    }
                                  : null,
                              color: bottomBar is InversePageBottomBar
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        : const Center();
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
