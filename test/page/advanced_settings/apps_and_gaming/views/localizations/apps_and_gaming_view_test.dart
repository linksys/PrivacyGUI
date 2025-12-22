import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/dyn_ddns_form.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/no_ip_ddns_form.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/tzo_ddns_form.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/ddns_test_state.dart';
import '../../../../../test_data/port_range_forwarding_test_state.dart';
import '../../../../../test_data/port_range_trigger_test_state.dart';
import '../../../../../test_data/single_port_forwarding_test_state.dart';

/// Helper to switch tabs by index using TabController
Future<void> switchToTab(WidgetTester tester, int index) async {
  final tabBarFinder = find.byType(TabBar);
  expect(tabBarFinder, findsOneWidget);

  final tabBar = tester.widget<TabBar>(tabBarFinder);
  final controller = tabBar.controller;
  if (controller != null) {
    controller.animateTo(index);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }
}

// View ID: APPGAM
// Implementation file under test: lib/page/advanced_settings/apps_and_gaming/views/apps_and_gaming_view.dart
///
/// | Test ID                     | Description                                                                 |
/// | :-------------------------- | :-------------------------------------------------------------------------- |
/// | `APPGAM-DDNS_DIS`           | Verifies the DDNS tab in its disabled state.                                |
/// | `APPGAM-DDNS_DYN`           | Verifies the DDNS tab with 'dyn.com' provider selected.                     |
/// | `APPGAM-DDNS_DYN_FILL`      | Verifies the DDNS tab with 'dyn.com' provider and filled-in data.           |
/// | `APPGAM-DDNS_DYN_SYS`       | Verifies the DDNS 'dyn.com' provider's system type dropdown.                |
/// | `APPGAM-DDNS_NOIP`          | Verifies the DDNS tab with 'No-IP.com' provider selected.                   |
/// | `APPGAM-DDNS_NOIP_FILL`     | Verifies the DDNS tab with 'No-IP.com' provider and filled-in data.         |
/// | `APPGAM-DDNS_TZO`           | Verifies the DDNS tab with 'TZO' provider selected.                         |
/// | `APPGAM-DDNS_TZO_FILL`      | Verifies the DDNS tab with 'TZO' provider and filled-in data.               |
/// | `APPGAM-SPF_DATA`           | Verifies the Single Port Forwarding tab with existing rules.                |
/// | `APPGAM-SPF_EMPTY`          | Verifies the Single Port Forwarding tab with no rules.                      |
/// | `APPGAM-SPF_EDIT_DESK`      | Verifies the edit/add rule form for Single Port Forwarding on desktop.      |
/// | `APPGAM-SPF_EDIT_ERR_DESK`  | Verifies error states in the Single Port Forwarding form on desktop.        |
/// | `APPGAM-SPF_OVER_ERR_DESK`  | Verifies port overlap error in the Single Port Forwarding form on desktop.  |
/// | `APPGAM-SPF_FILL_DESK`      | Verifies the filled Single Port Forwarding form on desktop.                 |
/// | `APPGAM-SPF_EDIT_MOB`       | Verifies the edit/add rule form for Single Port Forwarding on mobile.       |
/// | `APPGAM-SPF_EDIT_ERR_MOB`   | Verifies error states in the Single Port Forwarding form on mobile.         |
/// | `APPGAM-SPF_OVER_ERR_MOB`   | Verifies port overlap error in the Single Port Forwarding form on mobile.   |
/// | `APPGAM-SPF_FILL_MOB`       | Verifies the filled Single Port Forwarding form on mobile.                  |
/// | `APPGAM-PRF_DATA`           | Verifies the Port Range Forwarding tab with existing rules.                 |
/// | `APPGAM-PRF_EMPTY`          | Verifies the Port Range Forwarding tab with no rules.                       |
/// | `APPGAM-PRF_EDIT_DESK`      | Verifies the edit/add rule form for Port Range Forwarding on desktop.       |
/// | `APPGAM-PRF_EDIT_ERR_DESK`  | Verifies error states in the Port Range Forwarding form on desktop.         |
/// | `APPGAM-PRF_OVER_ERR_DESK`  | Verifies port overlap error in the Port Range Forwarding form on desktop.   |
/// | `APPGAM-PRF_FILL_DESK`      | Verifies the filled Port Range Forwarding form on desktop.                  |
/// | `APPGAM-PRF_PROTO_DESK`     | Verifies the protocol dropdown in the Port Range Forwarding form on desktop.|
/// | `APPGAM-PRF_EDIT_MOB`       | Verifies the edit/add rule form for Port Range Forwarding on mobile.        |
/// | `APPGAM-PRF_EDIT_ERR_MOB`   | Verifies error states in the Port Range Forwarding form on mobile.          |
/// | `APPGAM-PRF_OVER_ERR_MOB`   | Verifies port overlap error in the Port Range Forwarding form on mobile.    |
/// | `APPGAM-PRF_FILL_MOB`       | Verifies the filled Port Range Forwarding form on mobile.                   |
/// | `APPGAM-PRF_PROTO_MOB`      | Verifies the protocol dropdown in the Port Range Forwarding form on mobile.  |
/// | `APPGAM-PRT_DATA`           | Verifies the Port Range Triggering tab with existing rules.                 |
/// | `APPGAM-PRT_EMPTY`          | Verifies the Port Range Triggering tab with no rules.                       |
/// | `APPGAM-PRT_EDIT_DESK`      | Verifies the edit/add rule form for Port Range Triggering on desktop.       |
/// | `APPGAM-PRT_EDIT_ERR_DESK`  | Verifies error states in the Port Range Triggering form on desktop.         |
/// | `APPGAM-PRT_OVER_ERR_DESK`  | Verifies port overlap error in the Port Range Triggering form on desktop.   |
/// | `APPGAM-PRT_FILL_DESK`      | Verifies the filled Port Range Triggering form on desktop.                  |
/// | `APPGAM-PRT_EDIT_MOB`       | Verifies the edit/add rule form for Port Range Triggering on mobile.        |
/// | `APPGAM-PRT_EDIT_ERR_MOB`   | Verifies error states in the Port Range Triggering form on mobile.          |
/// | `APPGAM-PRT_OVER_ERR_MOB`   | Verifies port overlap error in the Port Range Triggering form on mobile.    |
/// | `APPGAM-PRT_FILL_MOB`       | Verifies the filled Port Range Triggering form on mobile.                   |
///
void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  group('Apps & Gaming - DDNS', () {
    // Test ID: APPGAM-DDNS_DIS
    testLocalizationsV2(
      'DDNS - disable',
      (tester, screen) async {
        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).appsGaming), findsOneWidget);
        expect(find.text(testHelper.loc(context).ddns), findsOneWidget);
        expect(find.text(testHelper.loc(context).singlePortForwarding),
            findsOneWidget);
        expect(find.text(testHelper.loc(context).portRangeForwarding),
            findsOneWidget);
        expect(find.text(testHelper.loc(context).portRangeTriggering),
            findsOneWidget);

        expect(
            find.text(testHelper.loc(context).selectAProvider), findsOneWidget);
        expect(find.text(testHelper.loc(context).disabled), findsOneWidget);
      },
      screens: screens,
      goldenFilename: 'APPGAM-DDNS_DIS-01-disabled_state',
    );

    // Test ID: APPGAM-DDNS_DYN
    testLocalizationsV2(
      'DDNS - dyn.com',
      (tester, screen) async {
        final state = DDNSState.fromMap(ddnsTestState);
        final settings =
            DDNSSettings(provider: DDNSProvider.create(dynDNSProviderName));
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).appsGaming), findsOneWidget);
        expect(find.text('dyn.com'), findsOneWidget);
        expect(find.byType(DynDNSForm), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-DDNS_DYN-01-dyn_selected',
    );

    // Test ID: APPGAM-DDNS_DYN_FILL
    testLocalizationsV2(
      'DDNS - dyn.com filled up',
      (tester, screen) async {
        final state = DDNSState.fromMap(ddnsTestState);
        final settings = DDNSSettings(
          provider: DynDNSProvider(
            settings: const DynDNSSettings(
              username: 'username',
              password: 'password',
              hostName: 'hostname',
              isWildcardEnabled: true,
              mode: 'Dynamic',
              isMailExchangeEnabled: true,
              mailExchangeSettings: DynDNSMailExchangeSettings(
                hostName: 'mail exchange',
                isBackup: true,
              ),
            ),
          ),
        );
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).appsGaming), findsOneWidget);
        expect(find.text('dyn.com'), findsOneWidget);
        expect(find.byType(DynDNSForm), findsOneWidget);
        expect(find.text('username'), findsOneWidget);
        expect(find.text('password'), findsOneWidget);
        expect(find.text('hostname'), findsOneWidget);
        expect(find.text('mail exchange'), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-DDNS_DYN_FILL-01-dyn_filled',
    );

    // Test ID: APPGAM-DDNS_DYN_SYS
    testLocalizationsV2(
      'DDNS - dyn.com system type',
      (tester, screen) async {
        final state = DDNSState.fromMap(ddnsTestState);
        final settings = DDNSSettings(
          provider: DynDNSProvider(
            settings: const DynDNSSettings(
              username: 'username',
              password: 'password',
              hostName: 'hostname',
              isWildcardEnabled: true,
              mode: 'Dynamic',
              isMailExchangeEnabled: true,
              mailExchangeSettings: DynDNSMailExchangeSettings(
                hostName: 'mail exchange',
                isBackup: true,
              ),
            ),
          ),
        );

        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final systemTypeFinder = find.byType(AppDropdown<DynDDNSSystem>);
        expect(systemTypeFinder, findsOneWidget);
        await tester.tap(systemTypeFinder.first);
        await tester.pumpAndSettle();

        // Verify dropdown items are visible using text finders
        // AppDropdown doesn't use DropdownMenuItem internally
        expect(find.text(testHelper.loc(context).systemDynamic), findsWidgets);
        expect(find.text(testHelper.loc(context).systemStatic), findsWidgets);
        expect(find.text(testHelper.loc(context).systemCustom), findsWidgets);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-DDNS_DYN_SYS-01-dyn_system_type_dropdown',
    );

    // Test ID: APPGAM-DDNS_NOIP
    testLocalizationsV2(
      'DDNS - No-IP.com',
      (tester, screen) async {
        final state = DDNSState.fromMap(ddnsTestState);
        final settings =
            DDNSSettings(provider: DDNSProvider.create(noIPDNSProviderName));
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        expect(find.text(testHelper.loc(context).appsGaming), findsOneWidget);
        expect(find.text('No-IP.com'), findsOneWidget);
        expect(find.byType(NoIPDNSForm), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-DDNS_NOIP-01-noip_selected',
    );

    // Test ID: APPGAM-DDNS_NOIP_FILL
    testLocalizationsV2(
      'DDNS - No-IP.com filled up',
      (tester, screen) async {
        final state = DDNSState.fromMap(ddnsTestState);
        final settings = DDNSSettings(
            provider: NoIPDNSProvider(
          settings: const NoIPSettings(
            username: 'username',
            password: 'password',
            hostName: 'hostname',
          ),
        ));

        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        expect(find.text('username'), findsOneWidget);
        expect(find.text('password'), findsOneWidget);
        expect(find.text('hostname'), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-DDNS_NOIP_FILL-01-noip_filled',
    );

    // Test ID: APPGAM-DDNS_TZO
    testLocalizationsV2(
      'DDNS - TZO',
      (tester, screen) async {
        final state = DDNSState.fromMap(ddnsTestState);
        final settings =
            DDNSSettings(provider: DDNSProvider.create(tzoDNSProviderName));
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        expect(find.text(testHelper.loc(context).appsGaming), findsOneWidget);
        expect(find.text('tzo.com'), findsOneWidget);
        expect(find.byType(TzoDNSForm), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-DDNS_TZO-01-tzo_selected',
    );

    // Test ID: APPGAM-DDNS_TZO_FILL
    testLocalizationsV2(
      'DDNS - TZO filled up',
      (tester, screen) async {
        final state = DDNSState.fromMap(ddnsTestState);
        final settings = DDNSSettings(
            provider: TzoDNSProvider(
          settings: const TZOSettings(
            username: 'username',
            password: 'password',
            hostName: 'hostname',
          ),
        ));
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        expect(find.text('username'), findsOneWidget);
        expect(find.text('password'), findsOneWidget);
        expect(find.text('hostname'), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-DDNS_TZO_FILL-01-tzo_filled',
    );
  });

  group('Apps & Gaming - Single port forwarding', () {
    // Test ID: APPGAM-SPF_DATA
    testLocalizationsV2('Single port forwarding - with data',
        (tester, screen) async {
      when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
          SinglePortForwardingListState.fromMap(
              singlePortForwardingListTestState));

      // Enable animations for tab switching - MUST be set before pumpView
      testHelper.disableAnimations = false;

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();

      await switchToTab(tester, 1);

      expect(find.text(testHelper.loc(context).singlePortForwarding),
          findsWidgets);
      expect(find.text('XBOX'), findsOneWidget);
      expect(find.text('tt123'), findsOneWidget);
    }, screens: screens, goldenFilename: 'APPGAM-SPF_DATA-01-with_data');

    // Test ID: APPGAM-SPF_EMPTY
    testLocalizationsV2('Single port forwarding - empty',
        (tester, screen) async {
      when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
          SinglePortForwardingListState.fromMap(
              singlePortForwardingEmptyListTestState));

      // Enable animations for tab switching - MUST be set before pumpView
      testHelper.disableAnimations = false;

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();
      await switchToTab(tester, 1);
      expect(find.text(testHelper.loc(context).noSinglePortForwarding),
          findsOneWidget);
    }, screens: screens, goldenFilename: 'APPGAM-SPF_EMPTY-01-empty_state');

    // Test ID: APPGAM-SPF_EDIT_DESK
    testLocalizationsV2(
      'Single port forwarding - edit',
      (tester, screen) async {
        when(testHelper.mockSinglePortForwardingListNotifier.build())
            .thenReturn(SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        await switchToTab(tester, 1);

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).applicationName), findsWidgets);
        expect(find.text(testHelper.loc(context).internalPort), findsWidgets);
        expect(find.text(testHelper.loc(context).externalPort), findsWidgets);
        expect(find.text(testHelper.loc(context).protocol), findsWidgets);
        expect(find.text(testHelper.loc(context).deviceIP), findsWidgets);
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-SPF_EDIT_DESK-01-edit_form',
    );

    // Test ID: APPGAM-SPF_EDIT_ERR_DESK
    testLocalizationsV2(
      'Single port forwarding - edit error',
      (tester, screen) async {
        when(testHelper.mockSinglePortForwardingListNotifier.build())
            .thenReturn(SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        await switchToTab(tester, 1);

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        // Just tap outside to trigger validation - the empty fields should show error icons
        await tester.tap(find.byType(SinglePortForwardingListView));
        await tester.pumpAndSettle();

        // Error icons should be visible (tooltip shown on hover, but icon always visible)
        // The screenshot will capture the error icons
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-SPF_EDIT_ERR_DESK-01-form_errors',
    );

    // Test ID: APPGAM-SPF_OVER_ERR_DESK
    testLocalizationsV2(
      'Single port forwarding - edit overlap error',
      (tester, screen) async {
        when(testHelper.mockSinglePortForwardingListNotifier.build())
            .thenReturn(SinglePortForwardingListState.fromMap(
                singlePortForwardingListTestState));
        when(testHelper.mockSinglePortForwardingRuleNotifier
                .isPortConflict(any, any))
            .thenAnswer((invocation) => true);
        when(testHelper.mockSinglePortForwardingRuleNotifier.isRuleValid())
            .thenAnswer((invocation) => false);

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        await switchToTab(tester, 1);

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('externalPortTextField')), '22');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(SinglePortForwardingListView));
        await tester.pumpAndSettle();

        // Hover on error icon to trigger tooltip display for overlap error
        final errorIconFinder = find.byIcon(Icons.error_outline);
        if (tester.any(errorIconFinder)) {
          final gesture =
              await tester.createGesture(kind: PointerDeviceKind.mouse);
          addTearDown(gesture.removePointer);
          await gesture.addPointer(location: Offset.zero);
          await gesture.moveTo(tester.getCenter(errorIconFinder.first));
          await tester.pumpAndSettle();
        }
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-SPF_OVER_ERR_DESK-01-overlap_error',
    );

    // Test ID: APPGAM-SPF_FILL_DESK
    testLocalizationsV2(
      'Single port forwarding - edit filled up',
      (tester, screen) async {
        when(testHelper.mockSinglePortForwardingListNotifier.build())
            .thenReturn(SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        await switchToTab(tester, 1);

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('applicationNameTextField')), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('internalPortTextField')), '20');
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('externalPortTextField')), '40');
        await tester.pumpAndSettle();

        // Tap and enter IP address - use TextField instead of TextFormField
        final ipAddressForm = find.byKey(const Key('ipAddressTextField'));
        final ipAddressTextField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextField));
        await tester.enterText(ipAddressTextField.first, '192.168.1.100');
        await tester.pumpAndSettle();

        expect(find.text('name'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('40'), findsOneWidget);
        expect(find.textContaining('192.168.1.100'), findsOneWidget);
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-SPF_FILL_DESK-01-form_filled',
    );
  });

  group('Apps & Gaming - Port range forwarding', () {
    setUp(() {
      when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
          SinglePortForwardingListState.fromMap(
              singlePortForwardingEmptyListTestState));
    });
    // Test ID: APPGAM-PRF_DATA
    testLocalizationsV2('Port range forwarding - with data',
        (tester, screen) async {
      when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
          PortRangeForwardingListState.fromMap(
              portRangeForwardingListTestState));

      // Enable animations for tab switching - MUST be set before pumpView
      testHelper.disableAnimations = false;

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();
      await switchToTab(tester, 2);

      expect(
          find.text(testHelper.loc(context).portRangeForwarding), findsWidgets);
      expect(find.text('Rule 2222'), findsOneWidget);
    }, screens: screens, goldenFilename: 'APPGAM-PRF_DATA-01-with_data');

    // Test ID: APPGAM-PRF_EMPTY
    testLocalizationsV2('Port range forwarding - empty',
        (tester, screen) async {
      when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
          PortRangeForwardingListState.fromMap(
              portRangeForwardingEmptyListTestState));

      // Enable animations for tab switching - MUST be set before pumpView
      testHelper.disableAnimations = false;

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();
      await switchToTab(tester, 2);
      expect(find.text(testHelper.loc(context).noPortRangeForwarding),
          findsOneWidget);
    }, screens: screens, goldenFilename: 'APPGAM-PRF_EMPTY-01-empty_state');

    // Test ID: APPGAM-PRF_EDIT_DESK
    testLocalizationsV2(
      'Port range forwarding - edit',
      (tester, screen) async {
        final portRangeForwardingEmptyListState =
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState);
        when(testHelper.mockPortRangeForwardingListNotifier.build())
            .thenReturn(portRangeForwardingEmptyListState);

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        await switchToTab(tester, 2);

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).applicationName), findsWidgets);
        expect(find.text(testHelper.loc(context).startEndPorts), findsWidgets);
        expect(find.text(testHelper.loc(context).protocol), findsWidgets);
        expect(find.text(testHelper.loc(context).deviceIP), findsWidgets);
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRF_EDIT_DESK-01-edit_form',
    );

    // Test ID: APPGAM-PRF_EDIT_ERR_DESK
    testLocalizationsV2(
      'Port range forwarding - edit error',
      (tester, screen) async {
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        await switchToTab(tester, 2); // Port Range Forwarding tab

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        // Tap outside the form to trigger validation - empty fields should show error icons
        await tester.tap(find.byType(PortRangeForwardingListView));
        await tester.pumpAndSettle();

        // Hover on error icon to trigger tooltip display
        final errorIconFinder = find.byIcon(Icons.error_outline);
        if (tester.any(errorIconFinder)) {
          final gesture =
              await tester.createGesture(kind: PointerDeviceKind.mouse);
          addTearDown(gesture.removePointer);
          await gesture.addPointer(location: Offset.zero);
          await gesture.moveTo(tester.getCenter(errorIconFinder.first));
          await tester.pumpAndSettle();
        }

        // Screenshot will capture the error icons and tooltip if visible
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRF_EDIT_ERR_DESK-01-form_errors',
    );

    // Test ID: APPGAM-PRF_OVER_ERR_DESK
    testLocalizationsV2(
      'Port range forwarding - edit overlap error',
      (tester, screen) async {
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingListTestState));
        when(testHelper.mockPortRangeForwardingRuleNotifier
                .isPortRangeValid(any, any))
            .thenAnswer((invocation) => true);
        when(testHelper.mockPortRangeForwardingRuleNotifier
                .isPortConflict(any, any, any))
            .thenAnswer((invocation) => true);

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        await switchToTab(tester, 2);

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        // Use keys directly (now supported by AppRangeInput)
        final firstExternalPortField =
            find.byKey(const Key('firstExternalPortTextField'));
        await tester.enterText(firstExternalPortField, '5000');
        await tester.pumpAndSettle();

        final lastExternalPortField =
            find.byKey(const Key('lastExternalPortTextField'));
        await tester.enterText(lastExternalPortField, '5005');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PortRangeForwardingListView));
        await tester.pumpAndSettle();

        // Hover on error icon to trigger tooltip display
        final errorIconFinder = find.byIcon(Icons.error_outline);
        if (tester.any(errorIconFinder)) {
          final gesture =
              await tester.createGesture(kind: PointerDeviceKind.mouse);
          addTearDown(gesture.removePointer);
          await gesture.addPointer(location: Offset.zero);
          await gesture.moveTo(tester.getCenter(errorIconFinder.first));
          await tester.pumpAndSettle();
        }
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRF_OVER_ERR_DESK-01-overlap_error',
    );

    // Test ID: APPGAM-PRF_PORT_ERR_DESK
    testLocalizationsV2(
      'Port range forwarding - edit port error',
      (tester, screen) async {
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingListTestState));
        when(testHelper.mockPortRangeForwardingRuleNotifier
                .isPortRangeValid(any, any))
            .thenAnswer((invocation) => true);
        when(testHelper.mockPortRangeForwardingRuleNotifier
                .isPortConflict(any, any, any))
            .thenAnswer((invocation) => true);

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        await switchToTab(tester, 2);

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final firstExternalPortField =
            find.byKey(const Key('firstExternalPortTextField'));
        await tester.enterText(firstExternalPortField, '5000');
        await tester.pumpAndSettle();

        final lastExternalPortField =
            find.byKey(const Key('lastExternalPortTextField'));
        await tester.enterText(lastExternalPortField, '0');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PortRangeForwardingListView));
        await tester.pumpAndSettle();

        // Hover on error icon to trigger tooltip display
        final errorIconFinder = find.byIcon(Icons.error_outline);
        if (tester.any(errorIconFinder)) {
          final gesture =
              await tester.createGesture(kind: PointerDeviceKind.mouse);
          addTearDown(gesture.removePointer);
          await gesture.addPointer(location: Offset.zero);
          await gesture.moveTo(tester.getCenter(errorIconFinder.first));
          await tester.pumpAndSettle();
        }
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRF_PORT_ERR_DESK-01-range_error',
    );

    // Test ID: APPGAM-PRF_FILL_DESK
    testLocalizationsV2(
      'Port range forwarding - edit filled up',
      (tester, screen) async {
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        await switchToTab(tester, 2);

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder =
            find.byKey(const Key('applicationNameTextField'));
        await tester.enterText(textFieldFinder, 'name');
        await tester.pumpAndSettle();

        final lastExternalPortField =
            find.byKey(const Key('lastExternalPortTextField'));
        await tester.enterText(lastExternalPortField, '40');
        await tester.pumpAndSettle();

        final firstExternalPortField =
            find.byKey(const Key('firstExternalPortTextField'));
        await tester.enterText(firstExternalPortField, '20');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byKey(const Key('ipAddressTextField'));
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextField));
        await tester.enterText(ipAddressTextFormField.first, '15');
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRF_FILL_DESK-01-form_filled',
    );

    // Test ID: APPGAM-PRF_PROTO_DESK
    testLocalizationsV2(
      'Port range forwarding - protocol',
      (tester, screen) async {
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        await switchToTab(tester, 2);

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final protocolTypeFinder = find.byType(AppDropdown<String>).first;
        await tester.tap(protocolTypeFinder);
        await tester.pumpAndSettle();

        // AppDropdown doesn't use Flutter's DropdownMenuItem, use text finder
        expect(find.text(testHelper.loc(context).tcp), findsWidgets);
        expect(find.text(testHelper.loc(context).udp), findsWidgets);
        expect(find.text(testHelper.loc(context).udpAndTcp), findsWidgets);
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRF_PROTO_DESK-01-protocol_dropdown',
    );
  });

  group('Apps & Gaming - Port range triggerring', () {
    // Test ID: APPGAM-PRT_DATA
    testLocalizationsV2('Port range triggerring - with data',
        (tester, screen) async {
      when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
          PortRangeTriggeringListState.fromMap(portRangeTriggerListTestState));

      // Enable animations for tab switching - MUST be set before pumpView
      testHelper.disableAnimations = false;

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();
      await switchToTab(tester, 3); // Port Range Triggering tab

      expect(
          find.text(testHelper.loc(context).portRangeTriggering), findsWidgets);
      expect(find.text('Triggering 1'), findsOneWidget);
    }, screens: screens, goldenFilename: 'APPGAM-PRT_DATA-01-with_data');

    // Test ID: APPGAM-PRT_EMPTY
    testLocalizationsV2('Port range triggerring - empty',
        (tester, screen) async {
      when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
          PortRangeTriggeringListState.fromMap(
              portRangeTriggerEmptyListTestState));

      // Enable animations for tab switching - MUST be set before pumpView
      testHelper.disableAnimations = false;

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();
      await switchToTab(tester, 3); // Port Range Triggering tab

      expect(find.text(testHelper.loc(context).noPortRangeTriggering),
          findsOneWidget);
    }, screens: screens, goldenFilename: 'APPGAM-PRT_EMPTY-01-empty_state');

    // Test ID: APPGAM-PRT_EDIT_DESK
    testLocalizationsV2(
      'Port range triggerring - edit',
      (tester, screen) async {
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        await switchToTab(tester, 3); // Port Range Triggering tab

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).applicationName), findsWidgets);
        expect(find.text(testHelper.loc(context).triggeredRange), findsWidgets);
        expect(find.text(testHelper.loc(context).forwardedRange), findsWidgets);
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRT_EDIT_DESK-01-edit_form',
    );

    // Test ID: APPGAM-PRT_EDIT_ERR_DESK
    testLocalizationsV2(
      'Port range triggerring - edit error',
      (tester, screen) async {
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerListTestState));
        // Mock isRuleValid to return false to disable save button
        when(testHelper.mockPortRangeTriggeringRuleNotifier.isRuleValid())
            .thenReturn(false);

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        await switchToTab(tester, 3); // Port Range Triggering tab

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        // Tap outside the form to trigger validation
        await tester.tap(find.byType(PortRangeTriggeringListView));
        await tester.pumpAndSettle();

        // Hover on error icon to trigger tooltip display
        final errorIconFinder = find.byIcon(Icons.error_outline);
        if (tester.any(errorIconFinder)) {
          final gesture =
              await tester.createGesture(kind: PointerDeviceKind.mouse);
          addTearDown(gesture.removePointer);
          await gesture.addPointer(location: Offset.zero);
          await gesture.moveTo(tester.getCenter(errorIconFinder.first));
          await tester.pumpAndSettle();
        }
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRT_EDIT_ERR_DESK-01-form_errors',
    );

    // Test ID: APPGAM-PRT_OVER_ERR_DESK
    testLocalizationsV2(
      'Port range triggerring - edit overlap error',
      (tester, screen) async {
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerListTestState));
        when(testHelper.mockPortRangeTriggeringRuleNotifier
                .isTriggeredPortConflict(any, any))
            .thenAnswer((invocation) => false);

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();
        await switchToTab(tester, 3); // Port Range Triggering tab

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final appNameField = find.byKey(const Key('applicationNameTextField'));
        await tester.enterText(appNameField, 'name');
        await tester.pumpAndSettle();

        final startPortField =
            find.byKey(const Key('firstTriggerPortTextField'));
        await tester.enterText(startPortField, '6000');
        await tester.pumpAndSettle();

        final endPortField = find.byKey(const Key('lastTriggerPortTextField'));
        await tester.enterText(endPortField, '5000');
        await tester.pumpAndSettle();

        final firstForwardedPortField =
            find.byKey(const Key('firstForwardedPortTextField'));
        await tester.enterText(firstForwardedPortField, '7000');
        await tester.pumpAndSettle();

        final lastForwardedPortField =
            find.byKey(const Key('lastForwardedPortTextField'));
        await tester.enterText(lastForwardedPortField, '7001');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PortRangeTriggeringListView));
        await tester.pumpAndSettle();

        // Hover on error icon to trigger tooltip display
        final errorIconFinder = find.byIcon(Icons.error_outline);
        if (tester.any(errorIconFinder)) {
          final gesture =
              await tester.createGesture(kind: PointerDeviceKind.mouse);
          addTearDown(gesture.removePointer);
          await gesture.addPointer(location: Offset.zero);
          await gesture.moveTo(tester.getCenter(errorIconFinder.first));
          await tester.pumpAndSettle();
        }
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRT_OVER_ERR_DESK-01-overlap_error',
    );

    // Test ID: APPGAM-PRT_FILL_DESK
    testLocalizationsV2(
      'Port range triggerring - edit filled up',
      (tester, screen) async {
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        // Enable animations for tab switching - MUST be set before pumpView
        testHelper.disableAnimations = false;

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        await switchToTab(tester, 3); // Port Range Triggering tab

        final addBtnFinder = find.byKey(const Key('appDataTable_addButton'));
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final appNameField = find.byKey(const Key('applicationNameTextField'));
        await tester.enterText(appNameField, 'name');
        await tester.pumpAndSettle();

        final firstTriggerPortField =
            find.byKey(const Key('firstTriggerPortTextField'));
        await tester.enterText(firstTriggerPortField, '10');
        await tester.pumpAndSettle();

        final lastTriggerPortField =
            find.byKey(const Key('lastTriggerPortTextField'));
        await tester.enterText(lastTriggerPortField, '20');
        await tester.pumpAndSettle();

        final firstForwardedPortField =
            find.byKey(const Key('firstForwardedPortTextField'));
        await tester.enterText(firstForwardedPortField, '30');
        await tester.pumpAndSettle();

        final lastForwardedPortField =
            find.byKey(const Key('lastForwardedPortTextField'));
        await tester.enterText(lastForwardedPortField, '40');
        await tester.pumpAndSettle();

        await tester.tap(appNameField);
        await tester.pumpAndSettle();

        expect(find.text('name'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(find.text('40'), findsOneWidget);
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRT_FILL_DESK-01-form_filled',
    );
  });
}
