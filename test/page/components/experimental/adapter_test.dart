import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/experimental/ui_kit_adapters.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';

/// Tests for parameter conversion between PrivacyGUI and UI Kit APIs
void main() {
  group('UiKitPageViewAdapter Tests', () {
    late UiKitPageViewAdapter adapter;

    setUp(() {
      adapter = const UiKitPageViewAdapter();
    });

    group('AppBar parameter conversion', () {
      test('should convert basic AppBar parameters', () {
        final result = adapter.convertAppBarConfig(
          title: 'Test Title',
          appBarStyle: AppBarStyle.back,
          backState: StyledBackState.enabled,
          actions: [const Icon(Icons.settings)],
          toolbarHeight: 80,
        );

        expect(result.title, equals('Test Title'));
        expect(result.showBackButton, isTrue);
        expect(result.actions, hasLength(1));
        expect(result.toolbarHeight, equals(80));
      });

      test('should handle different AppBar styles', () {
        // Test back style
        var result = adapter.convertAppBarConfig(
          title: 'Back Style',
          appBarStyle: AppBarStyle.back,
          backState: StyledBackState.enabled,
        );
        expect(result.showBackButton, isTrue);

        // Test close style
        result = adapter.convertAppBarConfig(
          title: 'Close Style',
          appBarStyle: AppBarStyle.close,
          backState: StyledBackState.enabled,
        );
        expect(result.showBackButton, isTrue); // Should still show back button

        // Test none style
        result = adapter.convertAppBarConfig(
          title: 'None Style',
          appBarStyle: AppBarStyle.none,
          backState: StyledBackState.enabled,
        );
        expect(result.showBackButton, isFalse);
      });

      test('should handle different back states', () {
        // Test enabled state
        var result = adapter.convertAppBarConfig(
          title: 'Enabled',
          appBarStyle: AppBarStyle.back,
          backState: StyledBackState.enabled,
        );
        expect(result.showBackButton, isTrue);

        // Test disabled state
        result = adapter.convertAppBarConfig(
          title: 'Disabled',
          appBarStyle: AppBarStyle.back,
          backState: StyledBackState.disabled,
        );
        expect(result.showBackButton, isFalse);

        // Test none state
        result = adapter.convertAppBarConfig(
          title: 'None',
          appBarStyle: AppBarStyle.back,
          backState: StyledBackState.none,
        );
        expect(result.showBackButton, isFalse);
      });
    });

    group('Bottom bar parameter conversion', () {
      test('should convert standard PageBottomBar', () {
        final privacyBottomBar = PageBottomBar(
          isPositiveEnabled: true,
          isNegitiveEnabled: false,
          positiveLabel: 'Save Changes',
          negitiveLable: 'Cancel',
          onPositiveTap: () {},
          onNegitiveTap: () {},
        );

        final result = adapter.convertBottomBarConfig(privacyBottomBar);

        expect(result.positiveLabel, equals('Save Changes'));
        expect(result.negativeLabel, equals('Cancel'));
        expect(result.isPositiveEnabled, isTrue);
        expect(result.isNegativeEnabled, isFalse);
        expect(result.isDestructive, isFalse);
      });

      test('should convert InversePageBottomBar as destructive', () {
        final inverseBottomBar = InversePageBottomBar(
          isPositiveEnabled: true,
          positiveLabel: 'Delete Item',
          negitiveLable: 'Keep',
          onPositiveTap: () {},
          onNegitiveTap: () {},
        );

        final result = adapter.convertBottomBarConfig(inverseBottomBar);

        expect(result.positiveLabel, equals('Delete Item'));
        expect(result.negativeLabel, equals('Keep'));
        expect(result.isDestructive, isTrue); // Should be marked as destructive
      });

      test('should handle nullable negative button', () {
        final bottomBar = PageBottomBar(
          isPositiveEnabled: true,
          positiveLabel: 'Continue',
          onPositiveTap: () {},
          // No negative button
        );

        final result = adapter.convertBottomBarConfig(bottomBar);

        expect(result.positiveLabel, equals('Continue'));
        expect(result.negativeLabel, isNull);
        expect(result.onNegativeTap, isNull);
      });
    });

    group('Menu parameter conversion', () {
      test('should convert PageMenu to PageMenuConfig', () {
        final privacyMenu = PageMenu(
          title: 'Navigation Menu',
          items: [
            PageMenuItem(
              label: 'Dashboard',
              icon: Icons.dashboard,
              onTap: () {},
            ),
            PageMenuItem(
              label: 'Settings',
              icon: Icons.settings,
              onTap: () {},
            ),
          ],
        );

        final result = adapter.convertMenuConfig(
          menu: privacyMenu,
          menuOnRight: false,
          largeMenu: true,
        );

        expect(result, isNotNull);
        expect(result!.title, equals('Navigation Menu'));
        expect(result!.items, hasLength(2));
        expect(result!.items.first.label, equals('Dashboard'));
        expect(result!.items.first.icon, equals(Icons.dashboard));
        expect(result!.largeMenu, isTrue);
        expect(result!.showOnDesktop, isTrue); // Should be enabled by default
        expect(result!.showOnMobile, isTrue);
      });

      test('should handle menu positioning', () {
        final menu = PageMenu(
          title: 'Side Menu',
          items: [
            PageMenuItem(label: 'Item 1', icon: Icons.menu, onTap: () {}),
          ],
        );

        // Test right-side menu
        var result = adapter.convertMenuConfig(
          menu: menu,
          menuOnRight: true,
          largeMenu: false,
        );
        expect(result, isNotNull);
        expect(result!.largeMenu, isFalse);

        // Test large menu
        result = adapter.convertMenuConfig(
          menu: menu,
          menuOnRight: false,
          largeMenu: true,
        );
        expect(result, isNotNull);
        expect(result!.largeMenu, isTrue);
      });

      test('should handle empty menu', () {
        final emptyMenu = PageMenu(
          title: 'Empty',
          items: [],
        );

        final result = adapter.convertMenuConfig(
          menu: emptyMenu,
          menuOnRight: false,
          largeMenu: false,
        );

        expect(result, isNotNull);
        expect(result!.items, isEmpty);
        expect(result!.hasItems, isFalse);
      });
    });

    group('Complex parameter combinations', () {
      test('should handle full parameter conversion', () {
        final privacyBottomBar = PageBottomBar(
          isPositiveEnabled: true,
          positiveLabel: 'Apply',
          negitiveLable: 'Reset',
          onPositiveTap: () {},
          onNegitiveTap: () {},
        );

        final privacyMenu = PageMenu(
          title: 'Options',
          items: [
            PageMenuItem(label: 'Option 1', icon: Icons.check, onTap: () {}),
          ],
        );

        final appBarResult = adapter.convertAppBarConfig(
          title: 'Complex Page',
          appBarStyle: AppBarStyle.back,
          backState: StyledBackState.enabled,
          actions: [const Icon(Icons.help)],
          toolbarHeight: 72,
        );

        final bottomBarResult = adapter.convertBottomBarConfig(privacyBottomBar);

        final menuResult = adapter.convertMenuConfig(
          menu: privacyMenu,
          menuOnRight: false,
          largeMenu: true,
        );

        // Verify all conversions work together
        expect(appBarResult.title, equals('Complex Page'));
        expect(bottomBarResult.positiveLabel, equals('Apply'));
        expect(menuResult, isNotNull);
        expect(menuResult!.title, equals('Options'));
      });
    });

    group('Edge cases and error handling', () {
      test('should handle null values gracefully', () {
        // Test null title
        final result1 = adapter.convertAppBarConfig(
          title: null,
          appBarStyle: AppBarStyle.back,
          backState: StyledBackState.enabled,
        );
        expect(result1.title, isNull);

        // Test null menu
        final result2 = adapter.convertMenuConfig(
          menu: null,
          menuOnRight: false,
          largeMenu: false,
        );
        expect(result2, isNull);
      });

      test('should handle malformed parameters', () {
        // Test bottom bar with mismatched enable states
        final malformedBottomBar = PageBottomBar(
          isPositiveEnabled: false, // Disabled but has onTap
          positiveLabel: 'Save',
          onPositiveTap: () {}, // This should be handled gracefully
        );

        final result = adapter.convertBottomBarConfig(malformedBottomBar);
        expect(result.isPositiveEnabled, isFalse);
        expect(result.onPositiveTap, isNotNull); // Should preserve the callback
      });
    });
  });
}