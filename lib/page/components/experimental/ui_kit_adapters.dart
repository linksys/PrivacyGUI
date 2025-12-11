import 'package:flutter/material.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/consts.dart' as privacy_gui_consts;
import 'package:ui_kit_library/ui_kit.dart';
import 'package:ui_kit_library/ui_kit.dart' as ui_kit;

/// Adapter for converting PrivacyGUI parameters to UI Kit format
///
/// This class provides the conversion layer between StyledAppPageView parameters
/// and the equivalent UI Kit AppPageView parameters, ensuring 100% API compatibility.
class UiKitPageViewAdapter {
  const UiKitPageViewAdapter();

  /// Converts PrivacyGUI AppBar parameters to UI Kit PageAppBarConfig
  PageAppBarConfig convertAppBarConfig({
    String? title,
    required privacy_gui_consts.AppBarStyle appBarStyle,
    required privacy_gui_consts.StyledBackState backState,
    List<Widget>? actions,
    double? toolbarHeight,
    VoidCallback? onBackTap,
  }) {
    // Determine if back button should be shown
    final bool showBackButton = _shouldShowBackButton(appBarStyle, backState);

    return PageAppBarConfig(
      title: title,
      showBackButton: showBackButton,
      actions: actions,
      toolbarHeight: toolbarHeight,
    );
  }

  /// Converts PrivacyGUI PageBottomBar to UI Kit PageBottomBarConfig
  PageBottomBarConfig convertBottomBarConfig(PageBottomBar bottomBar) {
    // Check if this is an InversePageBottomBar (destructive action)
    final bool isDestructive = bottomBar is InversePageBottomBar;

    return PageBottomBarConfig(
      positiveLabel: bottomBar.positiveLabel,
      negativeLabel: bottomBar.negitiveLable, // Note: PrivacyGUI has typo "negitive"
      onPositiveTap: bottomBar.onPositiveTap,
      onNegativeTap: bottomBar.onNegitiveTap,
      isPositiveEnabled: bottomBar.isPositiveEnabled,
      isNegativeEnabled: bottomBar.isNegitiveEnabled,
      isDestructive: isDestructive,
    );
  }

  /// Converts PrivacyGUI PageMenu to UI Kit PageMenuConfig
  PageMenuConfig? convertMenuConfig({
    PageMenu? menu,
    required bool menuOnRight,
    required bool largeMenu,
    IconData? menuIcon,
  }) {
    if (menu == null) {
      return null;
    }

    // Convert PageMenuItem list
    final List<ui_kit.PageMenuItem> convertedItems = menu.items
        .map((item) => ui_kit.PageMenuItem.navigation(
              label: item.label,
              icon: item.icon ?? Icons.circle,
              onTap: item.onTap ?? () {}, // Provide empty callback if null
              isSelected: false, // PrivacyGUI doesn't have selected state concept
            ))
        .toList();

    return PageMenuConfig(
      title: menu.title,
      items: convertedItems,
      largeMenu: largeMenu,
      showOnDesktop: true, // Always show on desktop for PrivacyGUI compatibility
      showOnMobile: true, // Always show on mobile for PrivacyGUI compatibility
      mobileMenuIcon: menuIcon,
    );
  }

  /// Converts tab-related parameters (T057)
  Map<String, dynamic> convertTabConfig({
    List<Widget>? tabs,
    List<Widget>? tabContentViews,
    TabController? tabController,
    void Function(int index)? onTabTap,
  }) {
    // If no tabs provided, return empty config
    if (tabs == null || tabContentViews == null) {
      return {};
    }

    // Validate that tabs and content views match
    if (tabs.length != tabContentViews.length) {
      throw ArgumentError(
        'Tabs and tabContentViews must have the same length. '
        'Got ${tabs.length} tabs and ${tabContentViews.length} content views.',
      );
    }

    // Convert Widget tabs to Tab objects for UI Kit compatibility
    final List<Tab> convertedTabs = tabs.map((widget) {
      // Try to extract text from the widget if it's a text-based tab
      if (widget is Tab) {
        return widget; // Already a Tab, use as-is
      } else if (widget is Text) {
        return Tab(text: widget.data);
      } else {
        // For other widgets, wrap them in a Tab
        return Tab(child: widget);
      }
    }).toList();

    return {
      'tabs': convertedTabs,
      'tabContentViews': tabContentViews,
      'tabController': tabController,
      'onTabTap': onTabTap,
      'hasTabNavigation': true,
    };
  }

  /// Converts padding and layout parameters
  Map<String, dynamic> convertLayoutConfig({
    EdgeInsets? padding,
    bool useMainPadding = true,
    PageContentType pageContentType = PageContentType.flexible,
    bool scrollable = true,
    ScrollController? controller,
    Future<void> Function()? onRefresh,
  }) {
    return {
      'padding': padding,
      'useContentPadding': useMainPadding,
      'scrollable': scrollable,
      'scrollController': controller,
      'onRefresh': onRefresh,
    };
  }

  /// Converts SafeArea parameters
  Map<String, dynamic> convertSafeAreaConfig({
    ({bool left, bool top, bool right, bool bottom}) enableSafeArea =
        (left: true, top: true, right: true, bottom: true),
  }) {
    return {
      'enableSafeArea': enableSafeArea,
    };
  }

  /// Helper method to determine if back button should be shown
  bool _shouldShowBackButton(privacy_gui_consts.AppBarStyle appBarStyle, privacy_gui_consts.StyledBackState backState) {
    // If AppBar style is none, never show back button
    if (appBarStyle == privacy_gui_consts.AppBarStyle.none) {
      return false;
    }

    // If back state is explicitly disabled or none, don't show
    if (backState == privacy_gui_consts.StyledBackState.disabled || backState == privacy_gui_consts.StyledBackState.none) {
      return false;
    }

    // For back and close styles with enabled state, show back button
    if ((appBarStyle == privacy_gui_consts.AppBarStyle.back || appBarStyle == privacy_gui_consts.AppBarStyle.close) &&
        backState == privacy_gui_consts.StyledBackState.enabled) {
      return true;
    }

    return false;
  }

  /// Handles edge cases and malformed parameters (T058)
  ///
  /// This method provides fallbacks and validation for potentially problematic
  /// parameter combinations to ensure the adapter doesn't crash on malformed input.
  Map<String, dynamic> handleEdgeCases({
    required Map<String, dynamic> parameters,
  }) {
    final Map<String, dynamic> safeParameters = Map.from(parameters);

    // Handle malformed bottom bar configuration
    if (safeParameters.containsKey('bottomBarConfig')) {
      final bottomBarConfig = safeParameters['bottomBarConfig'] as PageBottomBarConfig?;
      if (bottomBarConfig != null) {
        // If positive button is disabled but has no label, provide default
        if (!bottomBarConfig.isPositiveEnabled && bottomBarConfig.positiveLabel == null) {
          // Don't modify - let UI Kit handle empty label case
        }

        // If negative button is enabled but has no callback, disable it
        if ((bottomBarConfig.isNegativeEnabled ?? false) && bottomBarConfig.onNegativeTap == null) {
          safeParameters['bottomBarConfig'] = PageBottomBarConfig(
            positiveLabel: bottomBarConfig.positiveLabel,
            negativeLabel: bottomBarConfig.negativeLabel,
            onPositiveTap: bottomBarConfig.onPositiveTap,
            onNegativeTap: bottomBarConfig.onNegativeTap,
            isPositiveEnabled: bottomBarConfig.isPositiveEnabled,
            isNegativeEnabled: false, // Disable if no callback
            isDestructive: bottomBarConfig.isDestructive,
          );
        }
      }
    }

    // Handle malformed menu configuration
    if (safeParameters.containsKey('menuConfig')) {
      final menuConfig = safeParameters['menuConfig'] as PageMenuConfig?;
      if (menuConfig != null) {
        // Filter out menu items with empty labels
        final validItems = menuConfig.items
            .where((item) => item.label.trim().isNotEmpty || item.isDivider)
            .toList();

        if (validItems.length != menuConfig.items.length) {
          safeParameters['menuConfig'] = PageMenuConfig(
            title: menuConfig.title,
            items: validItems,
            largeMenu: menuConfig.largeMenu,
            showOnDesktop: menuConfig.showOnDesktop,
            showOnMobile: menuConfig.showOnMobile,
            mobileMenuIcon: menuConfig.mobileMenuIcon,
          );
        }
      }
    }

    // Handle tab configuration edge cases
    if (safeParameters.containsKey('hasTabNavigation') &&
        safeParameters['hasTabNavigation'] == true) {
      final tabs = safeParameters['tabs'] as List<Tab>?; // Updated to expect Tab objects
      final tabContentViews = safeParameters['tabContentViews'] as List<Widget>?;

      // Ensure tab counts match, truncate longer list if needed
      if (tabs != null && tabContentViews != null && tabs.length != tabContentViews.length) {
        final minLength = [tabs.length, tabContentViews.length].reduce((a, b) => a < b ? a : b);
        safeParameters['tabs'] = tabs.take(minLength).toList();
        safeParameters['tabContentViews'] = tabContentViews.take(minLength).toList();
      }
    }

    // Handle AppBar configuration edge cases
    if (safeParameters.containsKey('appBarConfig')) {
      final appBarConfig = safeParameters['appBarConfig'] as PageAppBarConfig?;
      if (appBarConfig != null) {
        // Ensure toolbar height is within reasonable bounds
        if (appBarConfig.toolbarHeight != null) {
          final height = appBarConfig.toolbarHeight!;
          if (height < 40 || height > 200) {
            // Replace with default height if outside reasonable range
            safeParameters['appBarConfig'] = PageAppBarConfig(
              title: appBarConfig.title,
              showBackButton: appBarConfig.showBackButton,
              actions: appBarConfig.actions,
              toolbarHeight: 80, // Default height
            );
          }
        }
      }
    }

    return safeParameters;
  }
}

/// Extension methods for easier parameter conversion
extension StyledAppPageViewConversion on StyledAppPageView {
  /// Converts this StyledAppPageView to UI Kit equivalent parameters
  Map<String, dynamic> toUiKitParameters() {
    const adapter = UiKitPageViewAdapter();

    final Map<String, dynamic> parameters = {};

    // Convert AppBar config
    if (title != null || actions != null || appBarStyle != privacy_gui_consts.AppBarStyle.none) {
      parameters['appBarConfig'] = adapter.convertAppBarConfig(
        title: title,
        appBarStyle: appBarStyle,
        backState: backState,
        actions: actions,
        toolbarHeight: toolbarHeight,
        onBackTap: onBackTap,
      );
    }

    // Convert bottom bar config
    if (bottomBar != null) {
      parameters['bottomBarConfig'] = adapter.convertBottomBarConfig(bottomBar!);
    }

    // Convert menu config
    if (menu != null) {
      final menuConfig = adapter.convertMenuConfig(
        menu: menu,
        menuOnRight: menuOnRight,
        largeMenu: largeMenu,
        menuIcon: menuIcon,
      );
      if (menuConfig != null) {
        parameters['menuConfig'] = menuConfig;
      }
    }

    // Convert layout parameters
    final layoutConfig = adapter.convertLayoutConfig(
      padding: padding,
      useMainPadding: useMainPadding,
      pageContentType: pageContentType,
      scrollable: scrollable ?? true,
      controller: controller,
      onRefresh: onRefresh,
    );
    parameters.addAll(layoutConfig);

    // Convert SafeArea parameters
    final safeAreaConfig = adapter.convertSafeAreaConfig(
      enableSafeArea: enableSafeArea,
    );
    parameters.addAll(safeAreaConfig);

    // Convert tab parameters if present
    if (tabs != null && tabContentViews != null) {
      final tabConfig = adapter.convertTabConfig(
        tabs: tabs,
        tabContentViews: tabContentViews,
        tabController: tabController,
        onTabTap: onTabTap,
      );
      parameters.addAll(tabConfig);
    }

    // Add other direct parameters
    parameters['child'] = child;
    parameters['backgroundColor'] = null; // StyledAppPageView doesn't have this
    parameters['useSlivers'] = enableSliverAppBar;
    parameters['bottomSheet'] = bottomSheet;
    parameters['bottomNavigationBar'] = bottomNavigationBar;

    // Apply edge case handling for safety
    return adapter.handleEdgeCases(parameters: parameters);
  }
}