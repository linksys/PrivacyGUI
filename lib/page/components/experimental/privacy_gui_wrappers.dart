import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/theme/material/color_schemes_ext.dart';
import 'package:privacygui_widgets/theme/material/text_scheme_ext.dart';
import 'package:privacygui_widgets/theme/material/color_schemes.dart';

/// Domain-specific wrapper functions that handle PrivacyGUI-specific logic
/// while integrating with the UI Kit ExperimentalUiKitPageView.
///
/// These wrappers bridge the gap between generic UI Kit components and
/// PrivacyGUI's specific business logic requirements.
class PrivacyGuiWrappers {
  const PrivacyGuiWrappers._();

  /// T059: PrivacyGUI connection state wrapper
  ///
  /// Handles connection state detection and UI adaptation based on
  /// network connectivity status in PrivacyGUI context.
  static Widget wrapWithConnectionState({
    required Widget child,
    required bool handleNoConnection,
    Widget Function(BuildContext context)? noConnectionBuilder,
  }) {
    if (!handleNoConnection) {
      return child;
    }

    return Consumer(
      builder: (context, ref, _) {
        // TODO: Replace with actual PrivacyGUI connection state provider
        // final connectionState = ref.watch(connectionStateProvider);
        //
        // For now, assume connected. This will be replaced with actual
        // PrivacyGUI connection state logic.
        final isConnected = true; // connectionState.isConnected;

        if (!isConnected) {
          return noConnectionBuilder?.call(context) ??
              _buildDefaultNoConnectionWidget(context);
        }

        return child;
      },
    );
  }

  /// T060: PrivacyGUI banner handling wrapper
  ///
  /// Handles banner notifications and status messages that should appear
  /// at the top of pages in PrivacyGUI context.
  static Widget wrapWithBannerHandling({
    required Widget child,
    required bool handleBanner,
    EdgeInsets? bannerPadding,
  }) {
    if (!handleBanner) {
      return child;
    }

    return Consumer(
      builder: (context, ref, _) {
        // TODO: Replace with actual PrivacyGUI banner provider
        // final bannerState = ref.watch(bannerStateProvider);
        // final activeBanners = bannerState.activeBanners;

        // For now, assume no banners. This will be replaced with actual
        // PrivacyGUI banner state logic.
        final activeBanners = <Widget>[]; // bannerState.activeBanners;

        if (activeBanners.isEmpty) {
          return child;
        }

        return Column(
          children: [
            ...activeBanners.map((banner) => Padding(
                  padding: bannerPadding ?? const EdgeInsets.all(8.0),
                  child: banner,
                )),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  /// T061: PrivacyGUI scroll listener wrapper with menu controller integration
  ///
  /// Handles scroll-based UI changes like hiding/showing bottom navigation
  /// and menu state management in PrivacyGUI context.
  static Widget wrapWithScrollListener({
    required Widget child,
    ScrollController? scrollController,
    bool hideBottomNavigationOnScroll = false,
    VoidCallback? onScrollUp,
    VoidCallback? onScrollDown,
  }) {
    if (scrollController == null && !hideBottomNavigationOnScroll) {
      return child;
    }

    return Consumer(
      builder: (context, ref, _) {
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo is ScrollUpdateNotification) {
              final ScrollMetrics metrics = scrollInfo.metrics;

              // Handle bottom navigation visibility
              if (hideBottomNavigationOnScroll) {
                // TODO: Integrate with PrivacyGUI bottom navigation controller
                // final bottomNavController = ref.read(bottomNavigationControllerProvider.notifier);
                //
                // if (scrollInfo.scrollDelta != null) {
                //   if (scrollInfo.scrollDelta! > 0) {
                //     // Scrolling down - hide bottom nav
                //     bottomNavController.hide();
                //     onScrollDown?.call();
                //   } else if (scrollInfo.scrollDelta! < 0) {
                //     // Scrolling up - show bottom nav
                //     bottomNavController.show();
                //     onScrollUp?.call();
                //   }
                // }
              }

              // Handle menu state changes based on scroll position
              if (metrics.pixels > 100) {
                // Scrolled past threshold - could trigger menu state changes
                // TODO: Integrate with PrivacyGUI menu state if needed
              }
            }

            return false; // Don't consume the notification
          },
          child: child,
        );
      },
    );
  }

  /// T062: PrivacyGUI localization wrapper for button labels
  ///
  /// Provides localized button labels and text content for UI Kit components
  /// using PrivacyGUI's localization system.
  static Map<String, String> localizeButtonLabels({
    required BuildContext context,
    String? positiveLabel,
    String? negativeLabel,
    bool isDestructive = false,
  }) {
    final localization = loc(context); // PrivacyGUI localization hook

    // Provide localized defaults if no custom labels specified
    final localizedPositiveLabel = positiveLabel ??
        (isDestructive
            ? 'Delete'
            : 'Save'); // TODO: Use actual localization keys from localization

    final localizedNegativeLabel =
        negativeLabel ?? 'Cancel'; // TODO: Use actual localization keys

    return {
      'positiveLabel': localizedPositiveLabel,
      'negativeLabel': localizedNegativeLabel,
    };
  }

  /// Extended localization for menu and navigation items
  static String localizeMenuTitle(BuildContext context, String? title) {
    if (title == null || title.isEmpty) {
      return 'Menu'; // TODO: Use actual localization from loc(context)
    }

    // TODO: Add menu title localization mapping if needed
    // This could map English menu titles to localized versions
    // final titleMap = {
    //   'Navigation': context.loc.navigation,
    //   'Settings': context.loc.settings,
    //   'Options': context.loc.options,
    // };
    //
    // return titleMap[title] ?? title;

    return title; // For now, return as-is
  }

  /// Extended localization for page titles
  static String localizePageTitle(BuildContext context, String? title) {
    if (title == null || title.isEmpty) {
      return ''; // Return empty for null titles
    }

    // TODO: Add page title localization mapping if needed
    return title; // For now, return as-is
  }

  /// T063: PrivacyGUI route navigation wrapper with context.pop integration
  ///
  /// Handles navigation actions that integrate with PrivacyGUI's routing system
  /// and GoRouter navigation patterns.
  static VoidCallback wrapBackButtonAction({
    required BuildContext context,
    VoidCallback? customOnBackTap,
    bool canPop = true,
  }) {
    return () {
      // Execute custom back action if provided
      if (customOnBackTap != null) {
        customOnBackTap();
        return;
      }

      // Use PrivacyGUI's standard back navigation
      if (canPop && context.canPop()) {
        context.pop();
      } else {
        // TODO: Handle cases where we can't pop
        // This might involve navigating to a default route or
        // showing a confirmation dialog

        // For now, attempt to pop anyway
        if (context.mounted) {
          Navigator.of(context).maybePop();
        }
      }
    };
  }

  /// Extended navigation wrapper for menu item actions
  static VoidCallback wrapMenuItemAction({
    required BuildContext context,
    required VoidCallback originalAction,
    String? routeName,
    Map<String, String>? routeParameters,
  }) {
    return () {
      // Execute the original action
      originalAction();

      // If navigation is specified, handle it
      if (routeName != null) {
        try {
          if (routeParameters != null && routeParameters.isNotEmpty) {
            context.pushNamed(routeName, pathParameters: routeParameters);
          } else {
            context.pushNamed(routeName);
          }
        } catch (e) {
          // TODO: Handle navigation errors
          // Could log error or show fallback navigation
          debugPrint('Navigation error: $e');
        }
      }
    };
  }

  /// T070: PrivacyGUI theme wrapper
  ///
  /// Ensures that PrivacyGUI theme extensions (ColorSchemeExt, TextSchemeExt)
  /// are available in the theme context when using UI Kit components.
  static Widget wrapWithPrivacyGuiTheme({
    required Widget child,
    BuildContext? context,
    ThemeData? baseTheme,
  }) {
    // Get the current theme or use provided base theme
    final theme =
        baseTheme ?? (context != null ? Theme.of(context) : ThemeData.light());

    // Check if PrivacyGUI theme extensions are already present
    final hasColorSchemeExt = theme.extension<ColorSchemeExt>() != null;
    final hasTextSchemeExt = theme.extension<TextSchemeExt>() != null;

    // If extensions are already present, no need to wrap
    if (hasColorSchemeExt && hasTextSchemeExt) {
      return child;
    }

    // Create default PrivacyGUI theme extensions if missing
    final colorSchemeExt = theme.extension<ColorSchemeExt>() ??
        (theme.brightness == Brightness.light
            ? lightColorSchemeExt
            : darkColorSchemeExt);

    // TODO: Get TextSchemeExt - we'll need to create a default one
    // For now, create a minimal TextSchemeExt to prevent null errors
    final textSchemeExt =
        theme.extension<TextSchemeExt>() ?? const TextSchemeExt();

    // Create enhanced theme with PrivacyGUI extensions
    final enhancedTheme = theme.copyWith(
      extensions: [
        colorSchemeExt,
        textSchemeExt,
        // Preserve any existing extensions
        ...theme.extensions.values
            .where((ext) => ext is! ColorSchemeExt && ext is! TextSchemeExt),
      ],
    );

    return Theme(
      data: enhancedTheme,
      child: child,
    );
  }

  /// Helper method for building default no-connection widget
  static Widget _buildDefaultNoConnectionWidget(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Connection', // TODO: Use actual localization from loc(context)
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again', // TODO: Use actual localization
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension methods for easier integration with existing PrivacyGUI components
extension PrivacyGuiWrappersExtension on Widget {
  /// Wrap this widget with connection state handling
  Widget wrapWithConnectionState({
    required bool handleNoConnection,
    Widget Function(BuildContext context)? noConnectionBuilder,
  }) {
    return PrivacyGuiWrappers.wrapWithConnectionState(
      child: this,
      handleNoConnection: handleNoConnection,
      noConnectionBuilder: noConnectionBuilder,
    );
  }

  /// Wrap this widget with banner handling
  Widget wrapWithBannerHandling({
    required bool handleBanner,
    EdgeInsets? bannerPadding,
  }) {
    return PrivacyGuiWrappers.wrapWithBannerHandling(
      child: this,
      handleBanner: handleBanner,
      bannerPadding: bannerPadding,
    );
  }

  /// Wrap this widget with scroll listener
  Widget wrapWithScrollListener({
    ScrollController? scrollController,
    bool hideBottomNavigationOnScroll = false,
    VoidCallback? onScrollUp,
    VoidCallback? onScrollDown,
  }) {
    return PrivacyGuiWrappers.wrapWithScrollListener(
      child: this,
      scrollController: scrollController,
      hideBottomNavigationOnScroll: hideBottomNavigationOnScroll,
      onScrollUp: onScrollUp,
      onScrollDown: onScrollDown,
    );
  }

  /// Wrap this widget with PrivacyGUI theme compatibility
  Widget wrapWithPrivacyGuiTheme({
    BuildContext? context,
    ThemeData? baseTheme,
  }) {
    return PrivacyGuiWrappers.wrapWithPrivacyGuiTheme(
      child: this,
      context: context,
      baseTheme: baseTheme,
    );
  }
}
