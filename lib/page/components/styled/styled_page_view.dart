import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/status_label.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/base_page_view.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';

import 'package:privacy_gui/localization/localization_hook.dart';

import 'consts.dart';

/// Defines how the main content of the page should be laid out.
enum PageContentType {
  /// The content can be flexible in size.
  flexible,

  /// The content should fill the available space.
  fit,
  ;
}

/// A model for the page's bottom action bar.
///
/// Defines the state and behavior of buttons like "Save" and "Cancel".
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

/// A variant of [PageBottomBar] typically used for destructive actions like "Delete",
/// where the main positive action button is styled with an error color (red).
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

/// A model for the page menu, used for the side menu on desktop
/// or the modal bottom sheet menu on mobile.
class PageMenu {
  final String? title;
  List<PageMenuItem> items;
  PageMenu({
    this.title,
    required this.items,
  });
}

/// A single item within a [PageMenu].
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

/// A powerful and highly configurable page layout widget.
///
/// This widget serves as the base frame for most pages in the application.
/// It integrates multiple layout modes:
/// - **Non-Sliver Mode**: A traditional layout with a fixed AppBar.
/// - **Sliver Mode**: A collapsible AppBar effect when `enableSliverAppBar: true`.
/// - **Tab Support**: Supports TabBar and TabBarView in both sliver and non-sliver modes.
/// - **Responsive Design**: Automatically handles menu display for desktop and mobile.
/// - **Bottom Action Bar**: An optional area for action buttons.
/// - **Bottom Navigation Bar Integration**: Automatically hides/shows the global
///   BottomNavigationBar based on scroll direction in Sliver mode.
class StyledAppPageView extends ConsumerStatefulWidget {
  final String? title;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      child;
  final double toolbarHeight;
  final Future<void> Function()? onRefresh;
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
  // Tabs
  final List<Widget>? tabs;
  final List<Widget>? tabContentViews;
  final TabController? tabController;
  final void Function(int index)? onTabTap;
  // Top bar
  final bool hideTopbar;
  //
  final PageContentType pageContentType;

  /// Whether to enable the Sliver AppBar effect.
  final bool enableSliverAppBar;

  const StyledAppPageView({
    super.key,
    this.title,
    this.padding,
    this.scrollable,
    this.toolbarHeight = kDefaultToolbarHeight,
    this.onBackTap,
    this.onRefresh,
    this.backState = StyledBackState.enabled,
    this.actions,
    this.child,
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
    this.tabContentViews,
    this.tabs,
    this.tabController,
    this.onTabTap,
    this.hideTopbar = false,
    this.pageContentType = PageContentType.flexible,
    this.enableSliverAppBar = false,
  }) : assert(child != null ||
            (tabs != null &&
                tabContentViews != null &&
                tabs.length == tabContentViews.length));

  /// A factory constructor for creating an "inner page", which is a page
  /// without its own top bar or AppBar. This is typically used for pages
  /// that are children of a TabBarView.
  factory StyledAppPageView.innerPage({
    Widget Function(BuildContext context, BoxConstraints constraints)? child,
    EdgeInsets? padding,
    bool? scrollable = true,
    ScrollController? controller,
    PageBottomBar? bottomBar,
    bool menuOnRight = false,
    bool largeMenu = false,
    bool useMainPadding = true,
    PageContentType pageContentType = PageContentType.flexible,
    Future<void> Function()? onRefresh,
    bool enableSliverAppBar = false,
  }) {
    return StyledAppPageView(
      child: child,
      padding: padding,
      scrollable: scrollable,
      controller: controller,
      bottomBar: bottomBar,
      menuOnRight: menuOnRight,
      largeMenu: largeMenu,
      useMainPadding: useMainPadding,
      pageContentType: pageContentType,
      hideTopbar: true,
      appBarStyle: AppBarStyle.none,
      onRefresh: onRefresh,
      enableSliverAppBar: enableSliverAppBar,
    );
  }

  @override
  ConsumerState<StyledAppPageView> createState() => _StyledAppPageViewState();
}

/// The main state class for [StyledAppPageView].
///
/// This class is responsible for:
/// 1. Managing the lifecycle of the `ScrollController`.
/// 2. Listening to scroll events to coordinate with the global BottomNavigationBar.
/// 3. Acting as a dispatcher to render the correct layout based on input parameters.
class _StyledAppPageViewState extends ConsumerState<StyledAppPageView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    // Only dispose the controller if it was created by this widget.
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  /// Listens to scroll events to automatically hide/show the global BottomNavigationBar.
  void _scrollListener() {
    final menu = ref.read(menuController);
    // Only act if the menu is a bottom bar (i.e., on mobile layout).
    if (menu.displayType != MenuDisplay.bottom) {
      // If we scrolled and the menu is no longer a bottom bar (e.g., due to screen resize),
      // ensure its visibility is reset to true.
      if (!menu.isVisible) {
        menu.setMenuVisible(true);
      }
      return;
    }

    final direction = _scrollController.position.userScrollDirection;

    // Always show the menu when scrolled near the top.
    if (_scrollController.position.pixels < 100) {
      if (!menu.isVisible) {
        menu.setMenuVisible(true);
      }
      return;
    }

    // Hide when scrolling down.
    if (direction == ScrollDirection.reverse) {
      if (menu.isVisible) {
        menu.setMenuVisible(false);
      }
    } else if (direction == ScrollDirection.forward) {
      // Show when scrolling up.
      if (!menu.isVisible) {
        menu.setMenuVisible(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This ValueListenableBuilder is likely a technique to force redraws when a global state changes.
    return ValueListenableBuilder<bool>(
      valueListenable: showColumnOverlayNotifier,
      builder: (context, showColumnOverlay, _) {
        // Dispatch to the appropriate private layout widget based on conditions.
        if (widget.enableSliverAppBar) {
          Widget body;
          if (widget.tabs != null) {
            body = _SliverWithTabsLayout(state: this);
          } else {
            body = _SliverWithoutTabsLayout(state: this);
          }

          // Wrap with RefreshIndicator if needed.
          if (widget.onRefresh != null) {
            body = RefreshIndicator(
              onRefresh: widget.onRefresh!,
              child: body,
            );
          }

          // Combine the main body and the bottom action bar in a Stack.
          return Stack(
            children: [
              SafeArea(
                left: widget.enableSafeArea.left,
                top: widget.enableSafeArea.top,
                right: widget.enableSafeArea.right,
                bottom: widget.enableSafeArea.bottom,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        widget.bottomBar != null ? kDefaultBottomHeight : 0.0,
                  ),
                  child: body,
                ),
              ),
              _bottomWidget(context),
            ],
          );
        } else {
          // If not using Sliver mode, render the traditional layout.
          return _NonSliverLayout(state: this);
        }
      },
    );
  }

  //region Helper Methods
  //----------------------------------------------------------------------------

  /// Checks if the back button should be enabled.
  bool isBackEnabled() => widget.backState == StyledBackState.enabled;

  /// Checks if a side menu is provided.
  bool hasMenu() => widget.menu != null || widget.menuWidget != null;

  /// Builds the [SliverAppBar].
  SliverAppBar? _buildSliverAppBar(
    BuildContext context,
    WidgetRef ref,
  ) {
    final title = widget.title;
    final leading = widget.appBarStyle == AppBarStyle.back
        ? BackButton(
            onPressed: isBackEnabled()
                ? (widget.onBackTap ?? () => context.pop())
                : null,
          )
        : widget.appBarStyle == AppBarStyle.close
            ? CloseButton(
                onPressed: isBackEnabled()
                    ? (widget.onBackTap ?? () => context.pop())
                    : null,
              )
            : null;

    if (widget.appBarStyle == AppBarStyle.none) {
      return null;
    }

    return SliverAppBar(
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.background,
      leading: widget.backState != StyledBackState.none ? leading : null,
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
                  if (widget.markLabel != null) ...[
                    const AppGap.small2(),
                    StatusLabel(label: widget.markLabel!),
                  ],
                ],
              ),
            ),
      actions: _buildActions(context),
      pinned: true,
      floating: true,
      snap: true,
      toolbarHeight: widget.toolbarHeight,
    );
  }

  /// Builds the traditional [LinksysAppBar].
  LinksysAppBar? _buildAppBar(BuildContext context, WidgetRef ref) {
    final title = widget.title;
    switch (widget.appBarStyle) {
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
                      if (widget.markLabel != null) ...[
                        const AppGap.small2(),
                        StatusLabel(label: widget.markLabel!),
                      ],
                    ],
                  ),
                ),
          toolbarHeight: widget.toolbarHeight,
          onBackTap: isBackEnabled()
              ? (widget.onBackTap ??
                  () {
                    // ref.read(navigationsProvider.notifier).pop();
                    context.pop();
                  })
              : null,
          showBack: widget.backState != StyledBackState.none,
          trailing: _buildActions(context),
        );
      case AppBarStyle.close:
        return LinksysAppBar.withClose(
          context: context,
          title: title == null
              ? null
              : Semantics(
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
                      if (widget.markLabel != null) ...[
                        const AppGap.small2(),
                        StatusLabel(label: widget.markLabel!),
                      ],
                    ],
                  ),
                ),
          toolbarHeight: widget.toolbarHeight,
          onBackTap: isBackEnabled()
              ? (widget.onBackTap ??
                  () {
                    // ref.read(navigationsProvider.notifier).pop();
                    context.pop();
                  })
              : null,
          showBack: widget.backState != StyledBackState.none,
          trailing: _buildActions(context),
        );
      case AppBarStyle.none:
        return null;
    }
  }

  /// Builds the list of actions for the AppBar.
  List<Widget>? _buildActions(BuildContext context) {
    final actionWidgets =
        !hasMenu() || !ResponsiveLayout.isMobileLayout(context)
            ? widget.actions
            : [_createMenuAction(context), ...(widget.actions ?? [])];
    return actionWidgets?.expandIndexed<Widget>((index, element) sync* {
      if (index != actionWidgets.length - 1) {
        yield element;
        yield const AppGap.small2();
      } else {
        yield element;
      }
    }).toList();
  }

  /// Builds the bottom action bar.
  Widget _bottomWidget(BuildContext context) {
    return widget.bottomBar != null
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveLayout.pageHorizontalPadding(
                                context)),
                        child: Row(
                          children: [
                            if (ResponsiveLayout.isMobileLayout(context)) ...[
                              if (widget.bottomBar?.isNegitiveEnabled !=
                                  null) ...[
                                Expanded(
                                  child: AppOutlinedButton.fillWidth(
                                    widget.bottomBar?.negitiveLable ??
                                        loc(context).cancel,
                                    onTap:
                                        widget.bottomBar?.isNegitiveEnabled ==
                                                true
                                            ? () {
                                                widget.bottomBar?.onNegitiveTap
                                                    ?.call();
                                              }
                                            : null,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                    identifier:
                                        'now-page-bottom-button-negitive',
                                  ),
                                ),
                                const AppGap.medium(),
                              ],
                              Expanded(
                                child: AppFilledButton.fillWidth(
                                  widget.bottomBar?.positiveLabel ??
                                      loc(context).save,
                                  onTap: widget.bottomBar?.isPositiveEnabled ==
                                          true
                                      ? () {
                                          widget.bottomBar?.onPositiveTap
                                              .call();
                                        }
                                      : null,
                                  color:
                                      widget.bottomBar is InversePageBottomBar
                                          ? Theme.of(context).colorScheme.error
                                          : null,
                                  identifier: 'now-page-bottom-button-positive',
                                ),
                              ),
                            ],
                            if (!ResponsiveLayout.isMobileLayout(context)) ...[
                              if (widget.bottomBar?.isNegitiveEnabled !=
                                  null) ...[
                                AppOutlinedButton(
                                  widget.bottomBar?.negitiveLable ??
                                      loc(context).cancel,
                                  color: Theme.of(context).colorScheme.outline,
                                  identifier: 'now-page-bottom-button-negitice',
                                  onTap: widget.bottomBar?.isNegitiveEnabled ==
                                          true
                                      ? () {
                                          widget.bottomBar?.onNegitiveTap
                                              ?.call();
                                        }
                                      : null,
                                ),
                                const AppGap.medium(),
                              ],
                              AppFilledButton(
                                widget.bottomBar?.positiveLabel ??
                                    loc(context).save,
                                identifier: 'now-page-bottom-button-positive',
                                onTap: widget.bottomBar?.isPositiveEnabled ==
                                        true
                                    ? () {
                                        widget.bottomBar?.onPositiveTap.call();
                                      }
                                    : null,
                                color: widget.bottomBar is InversePageBottomBar
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        : const Center();
  }

  /// Builds the "More" icon button on mobile to open the menu.
  Widget _createMenuAction(BuildContext context) {
    return AppIconButton.noPadding(
      icon: widget.menuIcon ?? LinksysIcons.moreHoriz,
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

  /// Builds the content widget for the menu.
  Widget _createMenuWidget(BuildContext context, [double? maxWidth]) {
    return Semantics(
      explicitChildNodes: true,
      identifier: 'now-page-menu-container',
      child: Container(
        constraints:
            maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
        child: widget.menuWidget ??
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
                      child: AppText.titleSmall(widget.menu?.title ?? '')),
                ),
                const AppGap.medium(),
                ...(widget.menu?.items ?? []).map((e) => ListTile(
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
  //endregion
}

//region Layout Widgets
//----------------------------------------------------------------------------

/// A private layout widget for the case where Slivers are enabled and tabs are present.
///
/// It uses a [NestedScrollView] to coordinate the outer Sliver components (AppBar, etc.)
/// with the inner [TabBarView].
class _SliverWithTabsLayout extends StatelessWidget {
  const _SliverWithTabsLayout({required this.state});
  final _StyledAppPageViewState state;

  @override
  Widget build(BuildContext context) {
    final mainContentPadding = ResponsiveLayout.pageHorizontalPadding(context);
    final tabBar = AppTabBar(
      tabController: state.widget.tabController,
      tabs: state.widget.tabs!,
      onTap: state.widget.onTabTap,
    );

    return NestedScrollView(
      physics:
          state.widget.scrollable == false ? const NeverScrollableScrollPhysics() : null,
      controller: state._scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          if (!state.widget.hideTopbar)
            SliverToBoxAdapter(
              child: state.widget.topbar ??
                  const PreferredSize(
                      preferredSize: Size(0, 80), child: TopBar()),
            ),
          if (state.widget.appBarStyle != AppBarStyle.none)
            state._buildSliverAppBar(context, state.ref)!,
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(tabBar),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: state.widget.tabController,
        children: state.widget.tabContentViews!
            .map((e) => Padding(
                  padding: state.widget.useMainPadding
                      ? EdgeInsets.symmetric(horizontal: mainContentPadding)
                      : EdgeInsets.zero,
                  child: e,
                ))
            .toList(),
      ),
    );
  }
}

/// A private layout widget for the case where Slivers are enabled but no tabs are present.
///
/// It uses a standard [CustomScrollView] to build the page.
class _SliverWithoutTabsLayout extends StatelessWidget {
  const _SliverWithoutTabsLayout({required this.state});
  final _StyledAppPageViewState state;

  @override
  Widget build(BuildContext context) {
    final mainContentPadding = ResponsiveLayout.pageHorizontalPadding(context);
    return CustomScrollView(
      physics:
          state.widget.scrollable == false ? const NeverScrollableScrollPhysics() : null,
      controller: state._scrollController,
      slivers: [
        if (!state.widget.hideTopbar)
          SliverToBoxAdapter(
            child: state.widget.topbar ??
                const PreferredSize(
                    preferredSize: Size(0, 80), child: TopBar()),
          ),
        if (state.widget.appBarStyle != AppBarStyle.none)
          state._buildSliverAppBar(context, state.ref)!,
        SliverPadding(
          padding: state.widget.useMainPadding
              ? EdgeInsets.symmetric(horizontal: mainContentPadding)
              : EdgeInsets.zero,
          sliver: SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // On desktop with a menu, show a side-by-side layout.
                if (!ResponsiveLayout.isMobileLayout(context) &&
                    state.hasMenu()) {
                  final views = [
                    SizedBox(
                      width: state.widget.largeMenu ? 4.col : 3.col,
                      child: AppCard(
                        child: state._createMenuWidget(context),
                      ),
                    ),
                    const AppGap.gutter(),
                    Expanded(
                      child: state.widget.child?.call(context, constraints) ??
                          const SizedBox.shrink(),
                    ),
                  ];
                  return Padding(
                    padding: state.widget.padding ?? EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: state.widget.menuOnRight
                          ? views.reversed.toList()
                          : views,
                    ),
                  );
                } else {
                  // On mobile or without a menu, show the main child directly.
                  return Padding(
                    padding: state.widget.padding ?? EdgeInsets.zero,
                    child: state.widget.child?.call(context, constraints) ??
                        const SizedBox.shrink(),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A private layout widget for the traditional, non-Sliver layout.
class _NonSliverLayout extends StatelessWidget {
  const _NonSliverLayout({required this.state});
  final _StyledAppPageViewState state;

  @override
  Widget build(BuildContext context) {
    final mainContentPadding = ResponsiveLayout.pageHorizontalPadding(context);
    final showColumnOverlay = showColumnOverlayNotifier.value;
    final useMainPadding = state.widget.useMainPadding;

    final content = Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
              bottom: state.widget.bottomBar != null
                  ? kDefaultBottomHeight
                  : 0.0),
          child: state.widget.tabs != null
              ? Container(
                  color: Theme.of(context).colorScheme.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.widget.appBarStyle != AppBarStyle.none)
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: mainContentPadding),
                          child: state._buildAppBar(context, state.ref) ??
                              const SizedBox(height: 0),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: mainContentPadding),
                        child: AppTabBar(
                          tabController: state.widget.tabController,
                          tabs: state.widget.tabs!,
                          onTap: state.widget.onTabTap,
                        ),
                      ),
                      AppGap.medium(),
                      Expanded(
                        child: TabBarView(
                          controller: state.widget.tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: state.widget.tabContentViews!,
                        ),
                      ),
                    ],
                  ),
                )
              : AppPageView(
                  padding: state.widget.padding,
                  onRefresh: state.widget.onRefresh,
                  scrollable: state.widget.scrollable,
                  scrollController: state._scrollController,
                  bottomSheet: state.widget.bottomSheet,
                  bottomNavigationBar: state.widget.bottomNavigationBar,
                  background: Theme.of(context).colorScheme.background,
                  enableSafeArea: (
                    left: state.widget.enableSafeArea.left,
                    top: state.widget.enableSafeArea.top,
                    right: state.widget.enableSafeArea.right,
                    bottom: state.widget.enableSafeArea.bottom,
                  ),
                  useContentMainPadding: useMainPadding,
                  isOverlayVisible: showColumnOverlay,
                  child: (context, constraints) {
                    final views = [
                      if (!ResponsiveLayout.isMobileLayout(context) &&
                          state.hasMenu()) ...[
                        SizedBox(
                          width: state.widget.largeMenu ? 4.col : 3.col,
                          child: AppCard(
                            child: state._createMenuWidget(context),
                          ),
                        ),
                        const AppGap.gutter(),
                      ],
                      Expanded(
                          child: state.widget.child
                                  ?.call(context, constraints) ??
                              const SizedBox.shrink()),
                    ];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.widget.appBarStyle != AppBarStyle.none)
                          state._buildAppBar(context, state.ref) ??
                              const SizedBox(height: 0),
                        Expanded(
                          child: SizedBox(
                            height: state.widget.pageContentType ==
                                    PageContentType.fit
                                ? constraints.maxHeight
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: state.widget.menuOnRight
                                  ? views.reversed.toList()
                                  : views,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        state._bottomWidget(context),
      ],
    );
    return Column(
      children: [
        if (!state.widget.hideTopbar)
          state.widget.topbar ??
              const PreferredSize(
                  preferredSize: Size(0, 80), child: TopBar()),
        Expanded(child: content),
      ],
    );
  }
}

//endregion

/// A helper delegate to wrap the [AppTabBar] in a [SliverPersistentHeader]
/// so it can be pinned below the [SliverAppBar].
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final AppTabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
