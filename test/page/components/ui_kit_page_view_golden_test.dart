import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';

/// T093: Comprehensive golden tests for production UiKitPageView
///
/// Tests all PrivacyGUI features including TopBar, connection state,
/// banner integration, factory constructors, and API compatibility.
void main() {
  group('UiKitPageView Golden Tests', () {
    testGoldens(
      'UiKitPageView - Basic Configuration',
      (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Basic Page',
                child: (context, constraints) => const Center(
                  child: Text('Basic page content'),
                ),
                appBarStyle: UiKitAppBarStyle.back,
                backState: UiKitBackState.enabled,
              ),
            ),
            name: 'Basic Configuration',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Page with Actions',
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
                child: (context, constraints) => const Center(
                  child: Text('Page with actions'),
                ),
                appBarStyle: UiKitAppBarStyle.back,
                backState: UiKitBackState.enabled,
              ),
            ),
            name: 'With Actions',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ui_kit_page_view_basic');
      },
      tags: ['golden'],
    );

    testGoldens(
      'UiKitPageView - Factory Constructors',
      (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView.login(
                title: 'Login',
                child: (context, constraints) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(decoration: InputDecoration(labelText: 'Username')),
                      SizedBox(height: 16),
                      TextField(decoration: InputDecoration(labelText: 'Password')),
                    ],
                  ),
                ),
              ),
            ),
            name: 'Login Factory',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView.dashboard(
                title: 'Dashboard',
                menu: UiKitMenuConfig(
                  title: 'Menu',
                  items: [
                    UiKitMenuItem(label: 'Home', icon: Icons.home),
                    UiKitMenuItem(label: 'Settings', icon: Icons.settings),
                  ],
                ),
                child: (context, constraints) => const Center(
                  child: Text('Dashboard content'),
                ),
              ),
            ),
            name: 'Dashboard Factory',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView.settings(
                title: 'Settings',
                menu: UiKitMenuConfig(
                  title: 'Settings',
                  items: [
                    UiKitMenuItem(label: 'General', icon: Icons.settings),
                    UiKitMenuItem(label: 'Privacy', icon: Icons.security),
                    UiKitMenuItem(label: 'Network', icon: Icons.wifi),
                  ],
                ),
                bottomBar: UiKitBottomBarConfig(
                  positiveLabel: 'Save',
                  onPositiveTap: () {},
                  negativeLabel: 'Cancel',
                  onNegativeTap: () {},
                ),
                child: (context, constraints) => const Center(
                  child: Text('Settings content'),
                ),
              ),
            ),
            name: 'Settings Factory',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ui_kit_page_view_factories');
      },
      tags: ['golden'],
    );

    testGoldens(
      'UiKitPageView - Bottom Bar Variations',
      (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Standard Bottom Bar',
                bottomBar: UiKitBottomBarConfig(
                  positiveLabel: 'Save',
                  onPositiveTap: () {},
                  negativeLabel: 'Cancel',
                  onNegativeTap: () {},
                ),
                child: (context, constraints) => const Center(
                  child: Text('Standard bottom bar'),
                ),
              ),
            ),
            name: 'Standard Bottom Bar',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Destructive Bottom Bar',
                bottomBar: UiKitBottomBarConfig(
                  positiveLabel: 'Delete',
                  onPositiveTap: () {},
                  negativeLabel: 'Cancel',
                  onNegativeTap: () {},
                  isDestructive: true,
                ),
                child: (context, constraints) => const Center(
                  child: Text('Destructive bottom bar'),
                ),
              ),
            ),
            name: 'Destructive Bottom Bar',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Disabled Actions',
                bottomBar: UiKitBottomBarConfig(
                  positiveLabel: 'Save',
                  onPositiveTap: () {},
                  isPositiveEnabled: false,
                  negativeLabel: 'Cancel',
                  onNegativeTap: () {},
                  isNegativeEnabled: false,
                ),
                child: (context, constraints) => const Center(
                  child: Text('Disabled actions'),
                ),
              ),
            ),
            name: 'Disabled Actions',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ui_kit_page_view_bottom_bar');
      },
      tags: ['golden'],
    );

    testGoldens(
      'UiKitPageView - Menu Configurations',
      (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Small Menu Left',
                menu: UiKitMenuConfig(
                  title: 'Menu',
                  items: [
                    UiKitMenuItem(label: 'Item 1', icon: Icons.home),
                    UiKitMenuItem(label: 'Item 2', icon: Icons.settings),
                    UiKitMenuItem(label: 'Item 3', icon: Icons.info),
                  ],
                ),
                menuOnRight: false,
                largeMenu: false,
                child: (context, constraints) => const Center(
                  child: Text('Small menu on left'),
                ),
              ),
            ),
            name: 'Small Menu Left',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Large Menu Right',
                menu: UiKitMenuConfig(
                  title: 'Navigation',
                  items: [
                    UiKitMenuItem(label: 'Dashboard', icon: Icons.dashboard),
                    UiKitMenuItem(label: 'Network', icon: Icons.wifi),
                    UiKitMenuItem(label: 'Security', icon: Icons.security),
                    UiKitMenuItem(label: 'Parental Controls', icon: Icons.family_restroom),
                    UiKitMenuItem(label: 'Guest Access', icon: Icons.person_add),
                    UiKitMenuItem(label: 'Advanced', icon: Icons.build),
                  ],
                ),
                menuOnRight: true,
                largeMenu: true,
                child: (context, constraints) => const Center(
                  child: Text('Large menu on right'),
                ),
              ),
            ),
            name: 'Large Menu Right',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ui_kit_page_view_menu');
      },
      tags: ['golden'],
    );

    testGoldens(
      'UiKitPageView - TopBar Integration',
      (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'With TopBar',
                hideTopbar: false, // Show TopBar
                child: (context, constraints) => const Center(
                  child: Text('Page with TopBar'),
                ),
              ),
            ),
            name: 'With TopBar',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Without TopBar',
                hideTopbar: true, // Hide TopBar
                child: (context, constraints) => const Center(
                  child: Text('Page without TopBar'),
                ),
              ),
            ),
            name: 'Without TopBar',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Custom TopBar',
                topbar: Container(
                  height: 80,
                  color: Colors.blue.withOpacity(0.2),
                  child: const Center(
                    child: Text('Custom TopBar', style: TextStyle(fontSize: 18)),
                  ),
                ),
                child: (context, constraints) => const Center(
                  child: Text('Page with custom TopBar'),
                ),
              ),
            ),
            name: 'Custom TopBar',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ui_kit_page_view_topbar');
      },
      tags: ['golden'],
    );

    testGoldens(
      'UiKitPageView - Sliver Mode',
      (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView.withSliver(
                title: 'Sliver Mode',
                child: (context, constraints) => ListView.builder(
                  itemCount: 20,
                  itemBuilder: (context, index) => ListTile(
                    title: Text('Item $index'),
                    subtitle: Text('Subtitle $index'),
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                  ),
                ),
              ),
            ),
            name: 'Sliver Mode',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView(
                title: 'Box Mode',
                enableSliverAppBar: false,
                child: (context, constraints) => ListView.builder(
                  itemCount: 20,
                  itemBuilder: (context, index) => ListTile(
                    title: Text('Item $index'),
                    subtitle: Text('Subtitle $index'),
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                  ),
                ),
              ),
            ),
            name: 'Box Mode',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ui_kit_page_view_sliver');
      },
      tags: ['golden'],
    );

    testGoldens(
      'UiKitPageView - Tab Navigation',
      (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
          ..addScenario(
            widget: _wrapWithProviders(
              DefaultTabController(
                length: 3,
                child: UiKitPageView(
                  title: 'Tabbed Page',
                  tabs: const [
                    Tab(text: 'Tab 1'),
                    Tab(text: 'Tab 2'),
                    Tab(text: 'Tab 3'),
                  ],
                  tabContentViews: [
                    const Center(child: Text('Tab 1 Content')),
                    const Center(child: Text('Tab 2 Content')),
                    const Center(child: Text('Tab 3 Content')),
                  ],
                  child: (context, constraints) => const Center(
                    child: Text('This should not be visible with tabs'),
                  ),
                ),
              ),
            ),
            name: 'Tab Navigation',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ui_kit_page_view_tabs');
      },
      tags: ['golden'],
    );

    testGoldens(
      'UiKitPageView - Inner Page',
      (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView.innerPage(
                child: (context, constraints) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Inner Page Content'),
                      SizedBox(height: 16),
                      Text('No AppBar or TopBar'),
                    ],
                  ),
                ),
              ),
            ),
            name: 'Inner Page',
          )
          ..addScenario(
            widget: _wrapWithProviders(
              UiKitPageView.innerPage(
                bottomBar: UiKitBottomBarConfig(
                  positiveLabel: 'Next',
                  onPositiveTap: () {},
                  negativeLabel: 'Back',
                  onNegativeTap: () {},
                ),
                child: (context, constraints) => const Center(
                  child: Text('Inner page with bottom bar'),
                ),
              ),
            ),
            name: 'Inner Page with Bottom Bar',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ui_kit_page_view_inner');
      },
      tags: ['golden'],
    );

    testGoldens(
      'UiKitPageView - Complex Configurations',
      (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletLandscape])
          ..addScenario(
            widget: _wrapWithProviders(
              DefaultTabController(
                length: 2,
                child: UiKitPageView(
                  title: 'Full Featured Page',
                  actions: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
                  ],
                  menu: UiKitMenuConfig(
                    title: 'Navigation',
                    items: [
                      UiKitMenuItem(label: 'Home', icon: Icons.home),
                      UiKitMenuItem(label: 'Settings', icon: Icons.settings),
                      UiKitMenuItem(label: 'Help', icon: Icons.help),
                    ],
                  ),
                  bottomBar: UiKitBottomBarConfig(
                    positiveLabel: 'Save',
                    onPositiveTap: () {},
                    negativeLabel: 'Cancel',
                    onNegativeTap: () {},
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Details'),
                  ],
                  tabContentViews: [
                    const Center(child: Text('Overview Content')),
                    const Center(child: Text('Details Content')),
                  ],
                  handleNoConnection: true,
                  handleBanner: true,
                  child: (context, constraints) => const Center(
                    child: Text('This should not be visible with tabs'),
                  ),
                ),
              ),
            ),
            name: 'Full Featured',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ui_kit_page_view_complex');
      },
      tags: ['golden'],
    );
  });

  group('UiKitPageView API Compatibility Tests', () {
    testWidgets('should match StyledAppPageView API signatures', (tester) async {
      // Test that all StyledAppPageView parameters are accepted
      const pageView = UiKitPageView(
        title: 'Test',
        toolbarHeight: 56.0,
        backState: UiKitBackState.enabled,
        appBarStyle: UiKitAppBarStyle.back,
        handleNoConnection: true,
        handleBanner: true,
        enableSafeArea: (left: true, top: true, right: true, bottom: true),
        menuOnRight: false,
        largeMenu: false,
        useMainPadding: true,
        markLabel: 'test-label',
        pageContentType: UiKitPageContentType.flexible,
        hideTopbar: false,
        enableSliverAppBar: false,
      );

      expect(pageView.title, equals('Test'));
      expect(pageView.toolbarHeight, equals(56.0));
      expect(pageView.backState, equals(UiKitBackState.enabled));
      expect(pageView.appBarStyle, equals(UiKitAppBarStyle.back));
      expect(pageView.handleNoConnection, isTrue);
      expect(pageView.handleBanner, isTrue);
      expect(pageView.menuOnRight, isFalse);
      expect(pageView.largeMenu, isFalse);
      expect(pageView.useMainPadding, isTrue);
      expect(pageView.hideTopbar, isFalse);
      expect(pageView.enableSliverAppBar, isFalse);
    });

    testWidgets('factory constructors should work correctly', (tester) async {
      final loginPage = UiKitPageView.login(
        title: 'Login',
        child: (context, constraints) => const Text('Login'),
      );

      final dashboardPage = UiKitPageView.dashboard(
        title: 'Dashboard',
        child: (context, constraints) => const Text('Dashboard'),
      );

      final settingsPage = UiKitPageView.settings(
        title: 'Settings',
        child: (context, constraints) => const Text('Settings'),
      );

      final innerPage = UiKitPageView.innerPage(
        child: (context, constraints) => const Text('Inner'),
      );

      final sliverPage = UiKitPageView.withSliver(
        title: 'Sliver',
        child: (context, constraints) => const Text('Sliver'),
      );

      // Verify factory constructor behavior
      expect(loginPage.title, equals('Login'));
      expect(loginPage.handleNoConnection, isTrue);
      expect(loginPage.hideTopbar, isFalse);

      expect(dashboardPage.title, equals('Dashboard'));
      expect(dashboardPage.handleNoConnection, isTrue);
      expect(dashboardPage.handleBanner, isTrue);

      expect(settingsPage.title, equals('Settings'));
      expect(settingsPage.menuOnRight, isTrue);
      expect(settingsPage.largeMenu, isTrue);

      expect(innerPage.hideTopbar, isTrue);
      expect(innerPage.appBarStyle, equals(UiKitAppBarStyle.none));

      expect(sliverPage.enableSliverAppBar, isTrue);
    });
  });
}

/// Helper to wrap widgets with necessary providers
Widget _wrapWithProviders(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: child,
    ),
  );
}