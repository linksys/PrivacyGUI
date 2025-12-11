import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart'
    hide PageMenuItem;
import 'package:privacy_gui/page/components/styled/consts.dart'
    as privacy_gui_consts;
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/page/components/experimental/ui_kit_adapters.dart';
import 'package:privacy_gui/page/components/experimental/privacy_gui_wrappers.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// T064: ExperimentalUiKitPageView - Drop-in replacement for StyledAppPageView
///
/// This component provides 100% API compatibility with StyledAppPageView while
/// internally using the UI Kit AppPageView with parameter conversion adapters
/// and PrivacyGUI domain logic wrappers.
///
/// Features:
/// - Complete API compatibility with StyledAppPageView constructor and factory methods
/// - Automatic parameter conversion from PrivacyGUI to UI Kit format
/// - Integration with PrivacyGUI domain logic (connection state, banners, navigation, TopBar)
/// - Seamless drop-in replacement requiring no code changes in existing usage
class ExperimentalUiKitPageView extends ConsumerStatefulWidget {
  // All StyledAppPageView parameters - maintaining 100% API compatibility
  final String? title;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      child;
  final double? toolbarHeight;
  final Future<void> Function()? onRefresh;
  final privacy_gui_consts.StyledBackState backState;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final bool? scrollable;
  final privacy_gui_consts.AppBarStyle appBarStyle;
  final bool handleNoConnection;
  final bool handleBanner;
  final ({bool left, bool top, bool right, bool bottom}) enableSafeArea;
  final bool menuOnRight;
  final bool largeMenu;
  final Widget? topbar; // PrivacyGUI TopBar support
  final bool useMainPadding;
  final String? markLabel;
  final PageContentType pageContentType;
  final ScrollController? controller;
  final PageBottomBar? bottomBar;
  final PageMenu? menu;
  final IconData? menuIcon;
  final bool hideTopbar; // PrivacyGUI TopBar control
  final bool enableSliverAppBar;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;
  final List<Widget>? tabs;
  final List<Widget>? tabContentViews;
  final TabController? tabController;
  final void Function(int index)? onTabTap;
  final VoidCallback? onBackTap;

  // T064: Main constructor with complete API compatibility
  const ExperimentalUiKitPageView({
    super.key,
    this.title,
    this.child,
    this.toolbarHeight,
    this.onRefresh,
    this.backState = privacy_gui_consts.StyledBackState.enabled,
    this.actions,
    this.padding,
    this.scrollable,
    this.appBarStyle = privacy_gui_consts.AppBarStyle.back,
    this.handleNoConnection = false,
    this.handleBanner = false,
    this.enableSafeArea = (left: true, top: true, right: true, bottom: true),
    this.menuOnRight = false,
    this.largeMenu = false,
    this.topbar,
    this.useMainPadding = true,
    this.markLabel,
    this.pageContentType = PageContentType.flexible,
    this.controller,
    this.bottomBar,
    this.menu,
    this.menuIcon,
    this.hideTopbar = false,
    this.enableSliverAppBar = false,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.tabs,
    this.tabContentViews,
    this.tabController,
    this.onTabTap,
    this.onBackTap,
  });

  // T065: Factory constructor for inner pages (matching StyledAppPageView.innerPage)
  factory ExperimentalUiKitPageView.innerPage({
    Key? key,
    required Widget Function(BuildContext context, BoxConstraints constraints)
        child,
    EdgeInsets? padding,
    bool? scrollable,
    PageBottomBar? bottomBar,
    bool menuOnRight = false,
    bool largeMenu = false,
    bool useMainPadding = true,
    PageContentType pageContentType = PageContentType.flexible,
    Future<void> Function()? onRefresh,
    bool enableSliverAppBar = false,
  }) {
    return ExperimentalUiKitPageView(
      key: key,
      child: child,
      padding: padding,
      scrollable: scrollable,
      bottomBar: bottomBar,
      menuOnRight: menuOnRight,
      largeMenu: largeMenu,
      useMainPadding: useMainPadding,
      pageContentType: pageContentType,
      onRefresh: onRefresh,
      enableSliverAppBar: enableSliverAppBar,
      appBarStyle:
          privacy_gui_consts.AppBarStyle.none, // Inner pages don't have app bar
      backState: privacy_gui_consts.StyledBackState.none,
      hideTopbar: true, // Inner pages don't show TopBar like StyledAppPageView
    );
  }

  // T066: Factory constructor with Sliver mode enabled by default
  factory ExperimentalUiKitPageView.withSliver({
    Key? key,
    String? title,
    Widget Function(BuildContext context, BoxConstraints constraints)? child,
    double? toolbarHeight,
    Future<void> Function()? onRefresh,
    privacy_gui_consts.StyledBackState backState = privacy_gui_consts.StyledBackState.enabled,
    List<Widget>? actions,
    EdgeInsets? padding,
    bool? scrollable,
    privacy_gui_consts.AppBarStyle appBarStyle = privacy_gui_consts.AppBarStyle.back,
    bool handleNoConnection = false,
    bool handleBanner = false,
    ({bool left, bool top, bool right, bool bottom}) enableSafeArea = (left: true, top: true, right: true, bottom: true),
    bool menuOnRight = false,
    bool largeMenu = false,
    Widget? topbar,
    bool useMainPadding = true,
    String? markLabel,
    PageContentType pageContentType = PageContentType.flexible,
    ScrollController? controller,
    PageBottomBar? bottomBar,
    PageMenu? menu,
    IconData? menuIcon,
    bool hideTopbar = false,
    Widget? bottomSheet,
    Widget? bottomNavigationBar,
    List<Widget>? tabs,
    List<Widget>? tabContentViews,
    TabController? tabController,
    void Function(int index)? onTabTap,
    VoidCallback? onBackTap,
  }) {
    return ExperimentalUiKitPageView(
      key: key,
      title: title,
      child: child,
      toolbarHeight: toolbarHeight,
      onRefresh: onRefresh,
      backState: backState,
      actions: actions,
      padding: padding,
      scrollable: scrollable,
      appBarStyle: appBarStyle,
      handleNoConnection: handleNoConnection,
      handleBanner: handleBanner,
      enableSafeArea: enableSafeArea,
      menuOnRight: menuOnRight,
      largeMenu: largeMenu,
      topbar: topbar,
      useMainPadding: useMainPadding,
      markLabel: markLabel,
      pageContentType: pageContentType,
      controller: controller,
      bottomBar: bottomBar,
      menu: menu,
      menuIcon: menuIcon,
      hideTopbar: hideTopbar,
      enableSliverAppBar: true, // Default to Sliver mode
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
      tabs: tabs,
      tabContentViews: tabContentViews,
      tabController: tabController,
      onTabTap: onTabTap,
      onBackTap: onBackTap,
    );
  }

  @override
  ConsumerState<ExperimentalUiKitPageView> createState() =>
      _ExperimentalUiKitPageViewState();
}

class _ExperimentalUiKitPageViewState
    extends ConsumerState<ExperimentalUiKitPageView> {
  late final UiKitPageViewAdapter _adapter;

  @override
  void initState() {
    super.initState();
    _adapter = const UiKitPageViewAdapter();
  }

  @override
  Widget build(BuildContext context) {
    // T066: Convert all PrivacyGUI parameters to UI Kit format
    final Map<String, dynamic> uiKitParameters = _convertToUiKitParameters();

    // T067: Apply PrivacyGUI domain logic wrappers
    Widget pageContent = _buildUiKitPageView(uiKitParameters);

    // Apply connection state wrapper if needed
    if (widget.handleNoConnection) {
      pageContent = PrivacyGuiWrappers.wrapWithConnectionState(
        child: pageContent,
        handleNoConnection: widget.handleNoConnection,
      );
    }

    // Apply banner handling wrapper if needed
    if (widget.handleBanner) {
      pageContent = PrivacyGuiWrappers.wrapWithBannerHandling(
        child: pageContent,
        handleBanner: widget.handleBanner,
      );
    }

    // Apply scroll listener wrapper if scroll controller or hide navigation is configured
    if (widget.controller != null) {
      pageContent = PrivacyGuiWrappers.wrapWithScrollListener(
        child: pageContent,
        scrollController: widget.controller,
        hideBottomNavigationOnScroll: false, // Could be made configurable
      );
    }

    // T070: Apply PrivacyGUI theme compatibility wrapper
    // This ensures that PrivacyGUI theme extensions (ColorSchemeExt, TextSchemeExt)
    // are available throughout the component tree, preventing null value errors
    pageContent = PrivacyGuiWrappers.wrapWithPrivacyGuiTheme(
      child: pageContent,
      context: context,
    );

    return pageContent;
  }

  /// T066: Parameter conversion from PrivacyGUI to UI Kit format
  Map<String, dynamic> _convertToUiKitParameters() {
    final Map<String, dynamic> parameters = {};

    // Convert AppBar configuration
    if (widget.title != null ||
        widget.actions != null ||
        widget.appBarStyle != privacy_gui_consts.AppBarStyle.none) {
      final appBarConfig = _adapter.convertAppBarConfig(
        title: widget.title,
        appBarStyle: widget.appBarStyle,
        backState: widget.backState,
        actions: widget.actions,
        toolbarHeight: widget.toolbarHeight,
        onBackTap: widget.onBackTap != null
            ? PrivacyGuiWrappers.wrapBackButtonAction(
                context: context,
                customOnBackTap: widget.onBackTap,
              )
            : null,
      );
      parameters['appBarConfig'] = appBarConfig;
    }

    // Convert bottom bar configuration
    if (widget.bottomBar != null) {
      var bottomBarConfig = _adapter.convertBottomBarConfig(widget.bottomBar!);

      // Apply localized labels if needed
      if (bottomBarConfig.positiveLabel != null ||
          bottomBarConfig.negativeLabel != null) {
        final localizedLabels = PrivacyGuiWrappers.localizeButtonLabels(
          context: context,
          positiveLabel: bottomBarConfig.positiveLabel,
          negativeLabel: bottomBarConfig.negativeLabel,
          isDestructive: bottomBarConfig.isDestructive,
        );

        bottomBarConfig = PageBottomBarConfig(
          positiveLabel: localizedLabels['positiveLabel'],
          negativeLabel: localizedLabels['negativeLabel'],
          onPositiveTap: bottomBarConfig.onPositiveTap,
          onNegativeTap: bottomBarConfig.onNegativeTap,
          isPositiveEnabled: bottomBarConfig.isPositiveEnabled,
          isNegativeEnabled: bottomBarConfig.isNegativeEnabled,
          isDestructive: bottomBarConfig.isDestructive,
        );
      }

      parameters['bottomBarConfig'] = bottomBarConfig;
    }

    // Convert menu configuration
    if (widget.menu != null) {
      var menuConfig = _adapter.convertMenuConfig(
        menu: widget.menu,
        menuOnRight: widget.menuOnRight,
        largeMenu: widget.largeMenu,
        menuIcon: widget.menuIcon,
      );

      if (menuConfig != null) {
        // Apply localized menu title
        final localizedTitle = PrivacyGuiWrappers.localizeMenuTitle(
          context,
          menuConfig.title,
        );

        menuConfig = PageMenuConfig(
          title: localizedTitle,
          items: menuConfig.items.map((item) {
            // Wrap menu item actions with navigation handling
            if (item.isDivider) {
              return const PageMenuItem.divider();
            } else {
              return PageMenuItem.navigation(
                label: item.label,
                icon: item.icon ?? Icons.circle,
                onTap: item.onTap != null
                    ? PrivacyGuiWrappers.wrapMenuItemAction(
                        context: context,
                        originalAction: item.onTap!,
                      )
                    : () {},
                isSelected: item.isSelected,
              );
            }
          }).toList(),
          largeMenu: menuConfig.largeMenu,
          showOnDesktop: menuConfig.showOnDesktop,
          showOnMobile: menuConfig.showOnMobile,
          mobileMenuIcon: menuConfig.mobileMenuIcon,
        );

        parameters['menuConfig'] = menuConfig;
      }
    }

    // Convert layout parameters with smart padding logic
    // If explicit padding is EdgeInsets.zero, respect user's intent to have no padding
    final bool shouldUseContentPadding =
        widget.useMainPadding && (widget.padding != EdgeInsets.zero);

    final layoutConfig = _adapter.convertLayoutConfig(
      padding: widget.padding,
      useMainPadding: shouldUseContentPadding,
      pageContentType: widget.pageContentType,
      scrollable: widget.scrollable ?? true,
      controller: widget.controller,
      onRefresh: widget.onRefresh,
    );
    parameters.addAll(layoutConfig);

    // Convert SafeArea parameters
    final safeAreaConfig = _adapter.convertSafeAreaConfig(
      enableSafeArea: widget.enableSafeArea,
    );
    parameters.addAll(safeAreaConfig);

    // Convert tab parameters if present
    if (widget.tabs != null && widget.tabContentViews != null) {
      final tabConfig = _adapter.convertTabConfig(
        tabs: widget.tabs,
        tabContentViews: widget.tabContentViews,
        tabController: widget.tabController,
        onTabTap: widget.onTabTap,
      );
      parameters.addAll(tabConfig);
    }

    // Handle child parameter - UI Kit AppPageView now properly handles function children in all modes
    if (widget.child != null) {
      parameters['child'] = widget.child;
    } else {
      parameters['child'] = const SizedBox.shrink();
    }

    parameters['backgroundColor'] = null; // StyledAppPageView doesn't have this

    // Smart Sliver mode selection:
    // - If explicitly enabled via enableSliverAppBar, always use Sliver mode
    // - This preserves PrivacyGUI's expectation that enableSliverAppBar controls layout strategy
    parameters['useSlivers'] = widget.enableSliverAppBar;

    parameters['bottomSheet'] = widget.bottomSheet;
    parameters['bottomNavigationBar'] = widget.bottomNavigationBar;

    // Apply edge case handling for safety
    return _adapter.handleEdgeCases(parameters: parameters);
  }

  /// T068: Build UI Kit AppPageView with converted parameters
  Widget _buildUiKitPageView(Map<String, dynamic> parameters) {
    final bool useSlivers = parameters['useSlivers'] as bool? ?? false;

    // Build TopBar widget if needed
    // TopBar is a separate banner component, independent of AppBar
    // Only hideTopbar parameter controls TopBar visibility
    final bool shouldHideTopBar = widget.hideTopbar;

    Widget? topBarWidget;
    if (!shouldHideTopBar) {
      topBarWidget = widget.topbar ??
          const PreferredSize(preferredSize: Size(0, 80), child: TopBar());
    }

    // If we have a TopBar and we're using Sliver mode, we need to handle it specially
    if (topBarWidget != null && useSlivers) {
      // In Sliver mode, we need to extract the content from SafeArea to prevent conflicts
      Widget topBarContent = topBarWidget;

      // If it's a PreferredSize wrapper around TopBar, extract the TopBar
      if (topBarContent is PreferredSize && topBarContent.child is TopBar) {
        topBarContent = topBarContent.child;
      }

      // Wrap in SliverToBoxAdapter for Sliver compatibility
      final sliverTopBar = SliverToBoxAdapter(
        child: SizedBox(
          height: 80, // Fixed height to match PreferredSize
          child: topBarContent,
        ),
      );

      return AppPageView(
        // Extract parameters with proper null handling
        appBarConfig: parameters['appBarConfig'] as PageAppBarConfig?,
        bottomBarConfig: parameters['bottomBarConfig'] as PageBottomBarConfig?,
        menuConfig: parameters['menuConfig'] as PageMenuConfig?,
        padding: parameters['padding'] as EdgeInsets?,
        useContentPadding: parameters['useContentPadding'] as bool? ?? true,
        scrollable: parameters['scrollable'] as bool? ?? true,
        scrollController: parameters['scrollController'] as ScrollController?,
        onRefresh: parameters['onRefresh'] as Future<void> Function()?,
        backgroundColor: parameters['backgroundColor'] as Color?,
        useSlivers: true,
        bottomSheet: parameters['bottomSheet'] as Widget?,
        bottomNavigationBar: parameters['bottomNavigationBar'] as Widget?,
        tabs: parameters['tabs'] as List<Tab>?,
        tabViews: parameters['tabContentViews'] as List<Widget>?,
        tabController: parameters['tabController'] as TabController?,
        // Disable top SafeArea when TopBar is present since TopBar handles its own SafeArea
        enableSafeArea: (left: true, top: false, right: true, bottom: true),
        header: sliverTopBar, // Pass TopBar wrapped in SliverToBoxAdapter
        child: parameters['child'] ?? const SizedBox.shrink(),
      );
    } else if (topBarWidget != null && !useSlivers) {
      // Box mode with TopBar - use AppPageView but with special function child handling
      return AppPageView(
        // Extract parameters with proper null handling
        appBarConfig: parameters['appBarConfig'] as PageAppBarConfig?,
        bottomBarConfig: parameters['bottomBarConfig'] as PageBottomBarConfig?,
        menuConfig: parameters['menuConfig'] as PageMenuConfig?,
        padding: parameters['padding'] as EdgeInsets?,
        useContentPadding: parameters['useContentPadding'] as bool? ?? true,
        scrollable: parameters['scrollable'] as bool? ?? true,
        scrollController: parameters['scrollController'] as ScrollController?,
        onRefresh: parameters['onRefresh'] as Future<void> Function()?,
        backgroundColor: parameters['backgroundColor'] as Color?,
        useSlivers: false,
        bottomSheet: parameters['bottomSheet'] as Widget?,
        bottomNavigationBar: parameters['bottomNavigationBar'] as Widget?,
        tabs: parameters['tabs'] as List<Tab>?,
        tabViews: parameters['tabContentViews'] as List<Widget>?,
        tabController: parameters['tabController'] as TabController?,
        // Disable top SafeArea when TopBar is present since TopBar handles its own SafeArea
        enableSafeArea: (left: true, top: false, right: true, bottom: true),
        header: topBarWidget,
        child: parameters['child'] ?? const SizedBox.shrink(),
      );
    } else {
      // No TopBar, use standard AppPageView
      return AppPageView(
        // Extract parameters with proper null handling
        appBarConfig: parameters['appBarConfig'] as PageAppBarConfig?,
        bottomBarConfig: parameters['bottomBarConfig'] as PageBottomBarConfig?,
        menuConfig: parameters['menuConfig'] as PageMenuConfig?,
        padding: parameters['padding'] as EdgeInsets?,
        useContentPadding: parameters['useContentPadding'] as bool? ?? true,
        scrollable: parameters['scrollable'] as bool? ?? true,
        scrollController: parameters['scrollController'] as ScrollController?,
        onRefresh: parameters['onRefresh'] as Future<void> Function()?,
        backgroundColor: parameters['backgroundColor'] as Color?,
        useSlivers: useSlivers,
        bottomSheet: parameters['bottomSheet'] as Widget?,
        bottomNavigationBar: parameters['bottomNavigationBar'] as Widget?,
        tabs: parameters['tabs'] as List<Tab>?,
        tabViews: parameters['tabContentViews'] as List<Widget>?,
        tabController: parameters['tabController'] as TabController?,
        // Use consistent SafeArea handling - preserve original SafeArea settings when no TopBar
        enableSafeArea: parameters['enableSafeArea'] as ({
              bool left,
              bool top,
              bool right,
              bool bottom
            })? ??
            (left: true, top: true, right: true, bottom: true),
        child: parameters['child'] ?? const SizedBox.shrink(),
      );
    }
  }
}

/// Extension for easier migration from StyledAppPageView to ExperimentalUiKitPageView
extension StyledAppPageViewMigration on StyledAppPageView {
  /// Convert this StyledAppPageView to ExperimentalUiKitPageView
  ///
  /// This method provides a simple way to migrate existing StyledAppPageView
  /// usage to the experimental UI Kit version without changing any parameters.
  ExperimentalUiKitPageView toExperimentalUiKit() {
    return ExperimentalUiKitPageView(
      title: title,
      child: child,
      toolbarHeight: toolbarHeight,
      onRefresh: onRefresh,
      backState: backState,
      actions: actions,
      padding: padding,
      scrollable: scrollable,
      appBarStyle: appBarStyle,
      handleNoConnection: handleNoConnection,
      handleBanner: handleBanner,
      enableSafeArea: enableSafeArea,
      menuOnRight: menuOnRight,
      largeMenu: largeMenu,
      topbar: topbar,
      useMainPadding: useMainPadding,
      markLabel: markLabel,
      pageContentType: pageContentType,
      controller: controller,
      bottomBar: bottomBar,
      menu: menu,
      menuIcon: menuIcon,
      hideTopbar: hideTopbar,
      enableSliverAppBar: enableSliverAppBar,
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
      tabs: tabs,
      tabContentViews: tabContentViews,
      tabController: tabController,
      onTabTap: onTabTap,
      onBackTap: onBackTap,
    );
  }

  /// Convert this StyledAppPageView to ExperimentalUiKitPageView with Sliver mode enabled
  ///
  /// This method migrates to the experimental UI Kit version with Sliver mode
  /// enabled by default, providing the benefit of header appearing above AppBar.
  ExperimentalUiKitPageView toExperimentalUiKitSliver() {
    return ExperimentalUiKitPageView.withSliver(
      title: title,
      child: child,
      toolbarHeight: toolbarHeight,
      onRefresh: onRefresh,
      backState: backState,
      actions: actions,
      padding: padding,
      scrollable: scrollable,
      appBarStyle: appBarStyle,
      handleNoConnection: handleNoConnection,
      handleBanner: handleBanner,
      enableSafeArea: enableSafeArea,
      menuOnRight: menuOnRight,
      largeMenu: largeMenu,
      topbar: topbar,
      useMainPadding: useMainPadding,
      markLabel: markLabel,
      pageContentType: pageContentType,
      controller: controller,
      bottomBar: bottomBar,
      menu: menu,
      menuIcon: menuIcon,
      hideTopbar: hideTopbar,
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
      tabs: tabs,
      tabContentViews: tabContentViews,
      tabController: tabController,
      onTabTap: onTabTap,
      onBackTap: onBackTap,
    );
  }
}
