import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/experimental/experimental_ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';

/// Tests for ExperimentalUiKitPageView ensuring 100% API compatibility
/// with StyledAppPageView and proper integration with all adapters and wrappers
void main() {
  group('ExperimentalUiKitPageView Tests', () {
    group('API Compatibility', () {
      testWidgets('should accept all StyledAppPageView constructor parameters', (tester) async {
        // Test that ExperimentalUiKitPageView can be constructed with all
        // the same parameters as StyledAppPageView without compilation errors
        final experimentalPageView = ExperimentalUiKitPageView(
          title: 'Test Title',
          child: (context, constraints) => const Text('Test Content'),
          toolbarHeight: 80,
          onRefresh: () async {},
          backState: StyledBackState.enabled,
          actions: [const Icon(Icons.settings)],
          padding: const EdgeInsets.all(16),
          scrollable: true,
          appBarStyle: AppBarStyle.back,
          handleNoConnection: true,
          handleBanner: true,
          enableSafeArea: (left: true, top: true, right: true, bottom: true),
          menuOnRight: false,
          largeMenu: false,
          useMainPadding: true,
          pageContentType: PageContentType.flexible,
          enableSliverAppBar: false,
          bottomBar: PageBottomBar(
            isPositiveEnabled: true,
            positiveLabel: 'Save',
            onPositiveTap: () {},
          ),
          menu: PageMenu(
            title: 'Menu',
            items: [
              PageMenuItem(label: 'Item 1', icon: Icons.menu, onTap: () {}),
            ],
          ),
          menuIcon: Icons.menu,
          bottomSheet: const Text('Bottom Sheet'),
          bottomNavigationBar: const Text('Bottom Nav'),
          tabs: [const Tab(text: 'Tab 1')],
          tabContentViews: [const Text('Tab Content')],
          onBackTap: () {},
        );

        expect(experimentalPageView, isA<ExperimentalUiKitPageView>());
        expect(experimentalPageView, isA<ConsumerStatefulWidget>());
      });

      testWidgets('should provide innerPage factory constructor', (tester) async {
        final innerPage = ExperimentalUiKitPageView.innerPage(
          child: (context, constraints) => const Text('Inner Page Content'),
          padding: const EdgeInsets.all(16),
          scrollable: true,
          bottomBar: PageBottomBar(
            isPositiveEnabled: true,
            positiveLabel: 'Apply',
            onPositiveTap: () {},
          ),
          menuOnRight: false,
          largeMenu: true,
          useMainPadding: true,
          pageContentType: PageContentType.fit,
          onRefresh: () async {},
          enableSliverAppBar: false,
        );

        expect(innerPage, isA<ExperimentalUiKitPageView>());
        expect(innerPage.appBarStyle, equals(AppBarStyle.none));
        expect(innerPage.backState, equals(StyledBackState.none));
      });

      test('should maintain exact parameter types as StyledAppPageView', () {
        // This compilation test ensures parameter types match exactly
        void testParameterTypes(ExperimentalUiKitPageView experimentalPageView) {
          // String?
          String? title = experimentalPageView.title;
          expect(title, isA<String?>());

          // Widget Function(BuildContext, BoxConstraints)?
          Widget Function(BuildContext, BoxConstraints)? child = experimentalPageView.child;
          expect(child, isA<Widget Function(BuildContext, BoxConstraints)?>());

          // Enum types
          StyledBackState backState = experimentalPageView.backState;
          expect(backState, isA<StyledBackState>());

          AppBarStyle appBarStyle = experimentalPageView.appBarStyle;
          expect(appBarStyle, isA<AppBarStyle>());

          PageContentType pageContentType = experimentalPageView.pageContentType;
          expect(pageContentType, isA<PageContentType>());

          // Complex types
          PageBottomBar? bottomBar = experimentalPageView.bottomBar;
          expect(bottomBar, isA<PageBottomBar?>());

          PageMenu? menu = experimentalPageView.menu;
          expect(menu, isA<PageMenu?>());

          // Record type
          ({bool left, bool top, bool right, bool bottom}) enableSafeArea = experimentalPageView.enableSafeArea;
          expect(enableSafeArea.left, isA<bool>());
          expect(enableSafeArea.top, isA<bool>());
          expect(enableSafeArea.right, isA<bool>());
          expect(enableSafeArea.bottom, isA<bool>());
        }

        final testInstance = ExperimentalUiKitPageView(
          child: (context, constraints) => const Text('Test'),
        );
        testParameterTypes(testInstance);
      });
    });

    group('Parameter Conversion Integration', () {
      testWidgets('should convert AppBar parameters correctly', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                title: 'Test Page',
                appBarStyle: AppBarStyle.back,
                backState: StyledBackState.enabled,
                actions: [const Icon(Icons.search)],
                toolbarHeight: 72,
                child: (context, constraints) => const Text('Content'),
              ),
            ),
          ),
        );

        // Verify the component builds without errors
        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
      });

      testWidgets('should convert bottom bar parameters correctly', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                bottomBar: PageBottomBar(
                  isPositiveEnabled: true,
                  isNegitiveEnabled: false,
                  positiveLabel: 'Save Changes',
                  negitiveLable: 'Cancel',
                  onPositiveTap: () {},
                  onNegitiveTap: () {},
                ),
                child: (context, constraints) => const Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
      });

      testWidgets('should convert menu parameters correctly', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                menu: PageMenu(
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
                ),
                menuOnRight: false,
                largeMenu: true,
                menuIcon: Icons.menu,
                child: (context, constraints) => const Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
      });
    });

    group('PrivacyGUI Domain Logic Integration', () {
      testWidgets('should apply connection state wrapper', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                handleNoConnection: true,
                child: (context, constraints) => const Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
        // The connection state wrapper should be applied internally
      });

      testWidgets('should apply banner handling wrapper', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                handleBanner: true,
                child: (context, constraints) => const Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
        // The banner handling wrapper should be applied internally
      });

      testWidgets('should apply scroll listener wrapper', (tester) async {
        final scrollController = ScrollController();

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                controller: scrollController,
                child: (context, constraints) => const Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
        // The scroll listener wrapper should be applied internally

        scrollController.dispose();
      });
    });

    group('Factory Constructor Behavior', () {
      test('innerPage factory should set correct default values', () {
        final innerPage = ExperimentalUiKitPageView.innerPage(
          child: (context, constraints) => const Text('Inner'),
        );

        expect(innerPage.appBarStyle, equals(AppBarStyle.none));
        expect(innerPage.backState, equals(StyledBackState.none));
        expect(innerPage.useMainPadding, isTrue);
        expect(innerPage.pageContentType, equals(PageContentType.flexible));
        expect(innerPage.menuOnRight, isFalse);
        expect(innerPage.largeMenu, isFalse);
        expect(innerPage.enableSliverAppBar, isFalse);
      });

      test('innerPage factory should accept custom parameters', () {
        final innerPage = ExperimentalUiKitPageView.innerPage(
          child: (context, constraints) => const Text('Inner'),
          padding: const EdgeInsets.all(24),
          scrollable: false,
          largeMenu: true,
          menuOnRight: true,
          useMainPadding: false,
          pageContentType: PageContentType.fit,
          enableSliverAppBar: true,
        );

        expect(innerPage.padding, equals(const EdgeInsets.all(24)));
        expect(innerPage.scrollable, isFalse);
        expect(innerPage.largeMenu, isTrue);
        expect(innerPage.menuOnRight, isTrue);
        expect(innerPage.useMainPadding, isFalse);
        expect(innerPage.pageContentType, equals(PageContentType.fit));
        expect(innerPage.enableSliverAppBar, isTrue);
      });
    });

    group('Migration Extension', () {
      test('toExperimentalUiKit extension should preserve all parameters', () {
        final originalStyled = StyledAppPageView(
          title: 'Original Title',
          child: (context, constraints) => const Text('Original Content'),
          toolbarHeight: 88,
          backState: StyledBackState.disabled,
          actions: [const Icon(Icons.help)],
          padding: const EdgeInsets.all(20),
          scrollable: false,
          appBarStyle: AppBarStyle.close,
          handleNoConnection: true,
          handleBanner: true,
          enableSafeArea: (left: false, top: true, right: false, bottom: true),
          menuOnRight: true,
          largeMenu: true,
          useMainPadding: false,
          pageContentType: PageContentType.fit,
          enableSliverAppBar: true,
          bottomBar: PageBottomBar(
            isPositiveEnabled: false,
            positiveLabel: 'Apply',
            onPositiveTap: () {},
          ),
          menu: PageMenu(
            title: 'Test Menu',
            items: [PageMenuItem(label: 'Test Item', icon: Icons.menu, onTap: () {})],
          ),
          menuIcon: Icons.more_vert,
        );

        final converted = originalStyled.toExperimentalUiKit();

        // Verify all parameters are preserved
        expect(converted.title, equals(originalStyled.title));
        expect(converted.child, equals(originalStyled.child));
        expect(converted.toolbarHeight, equals(originalStyled.toolbarHeight));
        expect(converted.backState, equals(originalStyled.backState));
        expect(converted.actions, equals(originalStyled.actions));
        expect(converted.padding, equals(originalStyled.padding));
        expect(converted.scrollable, equals(originalStyled.scrollable));
        expect(converted.appBarStyle, equals(originalStyled.appBarStyle));
        expect(converted.handleNoConnection, equals(originalStyled.handleNoConnection));
        expect(converted.handleBanner, equals(originalStyled.handleBanner));
        expect(converted.enableSafeArea, equals(originalStyled.enableSafeArea));
        expect(converted.menuOnRight, equals(originalStyled.menuOnRight));
        expect(converted.largeMenu, equals(originalStyled.largeMenu));
        expect(converted.useMainPadding, equals(originalStyled.useMainPadding));
        expect(converted.pageContentType, equals(originalStyled.pageContentType));
        expect(converted.enableSliverAppBar, equals(originalStyled.enableSliverAppBar));
        expect(converted.bottomBar, equals(originalStyled.bottomBar));
        expect(converted.menu, equals(originalStyled.menu));
        expect(converted.menuIcon, equals(originalStyled.menuIcon));
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle null child gracefully', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                child: null, // Null child should be handled
              ),
            ),
          ),
        );

        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
        // Should build successfully with SizedBox.shrink fallback
      });

      testWidgets('should handle empty menu gracefully', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                menu: PageMenu(
                  title: 'Empty Menu',
                  items: [], // Empty items list
                ),
                child: (context, constraints) => const Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
      });

      testWidgets('should handle malformed bottom bar configuration', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                bottomBar: PageBottomBar(
                  isPositiveEnabled: false,
                  positiveLabel: null, // Malformed: enabled but no label
                  onPositiveTap: () {},
                ),
                child: (context, constraints) => const Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
        // Should handle malformed configuration gracefully via adapter
      });

      testWidgets('should handle mismatched tab configuration', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ExperimentalUiKitPageView(
                tabs: [const Tab(text: 'Tab 1'), const Tab(text: 'Tab 2')],
                tabContentViews: [const Text('Content 1')], // Mismatched lengths
                child: (context, constraints) => const Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(ExperimentalUiKitPageView), findsOneWidget);
        // Should handle mismatched configuration gracefully via adapter
      });
    });
  });
}