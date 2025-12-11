import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/experimental/experimental_ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import '../../../common/test_helper.dart';

/// Golden tests for ExperimentalUiKitPageView component
///
/// These tests verify visual rendering of the experimental UI Kit page view
/// component to ensure it maintains visual consistency and API compatibility
/// with the original StyledAppPageView.
void main() {
  group('ExperimentalUiKitPageView Golden Tests', () {
    late TestHelper testHelper;

    setUpAll(() {
      testHelper = TestHelper();
      testHelper.setup();
    });

    group('Basic Page Configurations', () {
      testWidgets('should render basic page with title and content', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Basic Page Test',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Basic Page Content',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'This is a test of the ExperimentalUiKitPageView component with basic configuration.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_basic');
      });

      testWidgets('should render page with actions in app bar', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Page with Actions',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Page with AppBar actions',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_with_actions');
      });

      testWidgets('should render inner page without app bar', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView.innerPage(
            child: (context, constraints) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inner Page',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'This is an inner page created with the factory constructor. It should not have an app bar.',
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.info),
                      title: Text('Inner Page Content'),
                      subtitle: Text('No app bar should be visible'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_inner_page');
      });
    });

    group('Bottom Bar Configurations', () {
      testWidgets('should render page with standard bottom bar', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Page with Bottom Bar',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            bottomBar: PageBottomBar(
              isPositiveEnabled: true,
              isNegitiveEnabled: true,
              positiveLabel: 'Save Changes',
              negitiveLable: 'Cancel',
              onPositiveTap: () {},
              onNegitiveTap: () {},
            ),
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 48, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Settings Configuration',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Make your changes and use the bottom bar buttons to save or cancel.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_with_bottom_bar');
      });

      testWidgets('should render page with destructive bottom bar', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Destructive Action',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            bottomBar: InversePageBottomBar(
              isPositiveEnabled: true,
              positiveLabel: 'Delete Item',
              negitiveLable: 'Keep Item',
              onPositiveTap: () {},
              onNegitiveTap: () {},
            ),
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Delete Confirmation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This action cannot be undone. Are you sure you want to delete this item?',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_with_destructive_bottom_bar');
      });

      testWidgets('should render page with disabled positive button', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Disabled Button',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            bottomBar: PageBottomBar(
              isPositiveEnabled: false,
              isNegitiveEnabled: true,
              positiveLabel: 'Save (Disabled)',
              negitiveLable: 'Cancel',
              onPositiveTap: () {},
              onNegitiveTap: () {},
            ),
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Form Validation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The save button is disabled until all required fields are filled.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_with_disabled_button');
      });
    });

    group('Menu Configurations', () {
      testWidgets('should render page with menu', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Page with Menu',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
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
                PageMenuItem(
                  label: 'Network',
                  icon: Icons.network_wifi,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Security',
                  icon: Icons.security,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Help',
                  icon: Icons.help,
                  onTap: () {},
                ),
              ],
            ),
            largeMenu: false,
            menuOnRight: false,
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu, size: 48, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Page with Navigation Menu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The menu should appear in the app bar on mobile and as a side panel on desktop.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_with_menu');
      });

      testWidgets('should render page with large menu', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Large Menu Page',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            menu: PageMenu(
              title: 'Large Navigation',
              items: [
                PageMenuItem(
                  label: 'Home',
                  icon: Icons.home,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Dashboard',
                  icon: Icons.dashboard,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Network Settings',
                  icon: Icons.network_wifi,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Advanced Settings',
                  icon: Icons.settings_applications,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Security & Privacy',
                  icon: Icons.security,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Device Management',
                  icon: Icons.devices,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Support & Help',
                  icon: Icons.help_center,
                  onTap: () {},
                ),
              ],
            ),
            largeMenu: true,
            menuOnRight: false,
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.view_list, size: 48, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'Page with Large Menu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This page uses a large menu configuration that takes up more space.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_with_large_menu');
      });

      testWidgets('should render page with right-side menu', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Right Menu Page',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            menu: PageMenu(
              title: 'Right Side Navigation',
              items: [
                PageMenuItem(
                  label: 'Profile',
                  icon: Icons.person,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Preferences',
                  icon: Icons.tune,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Account',
                  icon: Icons.account_circle,
                  onTap: () {},
                ),
              ],
            ),
            largeMenu: false,
            menuOnRight: true,
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward, size: 48, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'Right-Side Menu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The menu should appear on the right side of the content.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_with_right_menu');
      });
    });

    group('Complex Configurations', () {
      testWidgets('should render page with menu and bottom bar', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Complete Page',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ],
            menu: PageMenu(
              title: 'Main Menu',
              items: [
                PageMenuItem(
                  label: 'Overview',
                  icon: Icons.visibility,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Configuration',
                  icon: Icons.build,
                  onTap: () {},
                ),
                PageMenuItem(
                  label: 'Monitoring',
                  icon: Icons.monitor,
                  onTap: () {},
                ),
              ],
            ),
            bottomBar: PageBottomBar(
              isPositiveEnabled: true,
              isNegitiveEnabled: true,
              positiveLabel: 'Apply',
              negitiveLable: 'Reset',
              onPositiveTap: () {},
              onNegitiveTap: () {},
            ),
            largeMenu: false,
            menuOnRight: false,
            child: (context, constraints) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Page Configuration',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('App Bar with Actions'),
                      subtitle: Text('Back button and search action'),
                    ),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.menu, color: Colors.blue),
                      title: Text('Navigation Menu'),
                      subtitle: Text('Side menu with multiple items'),
                    ),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.touch_app, color: Colors.orange),
                      title: Text('Bottom Action Bar'),
                      subtitle: Text('Apply and Reset buttons'),
                    ),
                  ),
                  Spacer(),
                  Text(
                    'This demonstrates all major features working together.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_complete_configuration');
      });

      testWidgets('should render scrollable page with custom padding', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Scrollable Content',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            scrollable: true,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list, size: 48, color: Colors.purple),
                    SizedBox(height: 16),
                    Text(
                      'Scrollable Content',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This page uses custom padding and scrollable configuration.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_scrollable_content');
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should render page with no content', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Empty Page',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            child: null, // Test null child handling
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_empty_content');
      });

      testWidgets('should render page with no app bar', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            appBarStyle: AppBarStyle.none,
            backState: StyledBackState.none,
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fullscreen, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No App Bar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This page has no app bar and uses the full screen.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_no_app_bar');
      });

      testWidgets('should render page with empty menu', (tester) async {
        await testHelper.pumpView(
          tester,
          child: ExperimentalUiKitPageView(
            title: 'Empty Menu',
            appBarStyle: AppBarStyle.back,
            backState: StyledBackState.enabled,
            menu: PageMenu(
              title: 'Empty Menu',
              items: [], // Empty menu items
            ),
            child: (context, constraints) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Page with empty menu (should handle gracefully)',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );

        await testHelper.takeScreenshot(tester, 'experimental_page_view_empty_menu');
      });
    });
  });
}