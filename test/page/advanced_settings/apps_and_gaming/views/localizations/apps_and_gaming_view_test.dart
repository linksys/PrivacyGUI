import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/dyn_ddns_form.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/no_ip_ddns_form.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/tzo_ddns_form.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/tab_bar/linksys_tab_bar.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/ddns_test_state.dart';
import '../../../../../test_data/port_range_forwarding_test_state.dart';
import '../../../../../test_data/port_range_trigger_test_state.dart';
import '../../../../../test_data/single_port_forwarding_test_state.dart';

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
        final settings = DDNSSettingsUIModel(
            provider: DDNSProviderUIModel.create(dynDNSProviderName));
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
        final settings = DDNSSettingsUIModel(
          provider: DynDNSProviderUIModel(
            username: 'username',
            password: 'password',
            hostName: 'hostname',
            isWildcardEnabled: true,
            mode: 'Dynamic',
            isMailExchangeEnabled: true,
            mailExchangeSettings: const DynDNSMailExchangeUIModel(
              hostName: 'mail exchange',
              isBackup: true,
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
        final settings = DDNSSettingsUIModel(
          provider: DynDNSProviderUIModel(
            username: 'username',
            password: 'password',
            hostName: 'hostname',
            isWildcardEnabled: true,
            mode: 'Dynamic',
            isMailExchangeEnabled: true,
            mailExchangeSettings: const DynDNSMailExchangeUIModel(
              hostName: 'mail exchange',
              isBackup: true,
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

        final systemTypeFinder = find.byType(AppDropdownButton<DynDDNSSystem>);
        expect(systemTypeFinder, findsOneWidget);
        await tester.tap(systemTypeFinder.first);
        await tester.pumpAndSettle();

        expect(
            find.widgetWithText(DropdownMenuItem<DynDDNSSystem>,
                testHelper.loc(context).systemDynamic),
            findsOneWidget);
        expect(
            find.widgetWithText(DropdownMenuItem<DynDDNSSystem>,
                testHelper.loc(context).systemStatic),
            findsOneWidget);
        expect(
            find.widgetWithText(DropdownMenuItem<DynDDNSSystem>,
                testHelper.loc(context).systemCustom),
            findsOneWidget);
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
        final settings = DDNSSettingsUIModel(
            provider: DDNSProviderUIModel.create(noIPDNSProviderName));
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
        final settings = DDNSSettingsUIModel(
            provider: const NoIPDNSProviderUIModel(
          username: 'username',
          password: 'password',
          hostName: 'hostname',
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
        final settings = DDNSSettingsUIModel(
            provider: DDNSProviderUIModel.create(tzoDNSProviderName));
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
        final settings = DDNSSettingsUIModel(
            provider: const TzoDNSProviderUIModel(
          username: 'username',
          password: 'password',
          hostName: 'hostname',
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

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(1));
      await tester.pumpAndSettle();

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

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(1));
      await tester.pumpAndSettle();
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

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(1));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).applicationName), findsOneWidget);
        expect(find.text(testHelper.loc(context).internalPort), findsOneWidget);
        expect(find.text(testHelper.loc(context).externalPort), findsOneWidget);
        expect(find.text(testHelper.loc(context).protocol), findsOneWidget);
        expect(find.text(testHelper.loc(context).deviceIP), findsOneWidget);
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
                singlePortForwardingListTestState));
        // Mock isRuleValid to return false to disable save button
        when(testHelper.mockSinglePortForwardingRuleNotifier.isRuleValid())
            .thenReturn(false);
        // Mock isDeviceIpValidate to return false to trigger IP address error
        when(testHelper.mockSinglePortForwardingRuleNotifier
                .isDeviceIpValidate(any))
            .thenReturn(false);
        when(testHelper.mockSinglePortForwardingRuleNotifier.isNameValid(any))
            .thenReturn(false);

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(1));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        // Tap somewhere else to trigger validation, e.g., the application name field
        final applicationNameField =
            find.byKey(const Key('applicationNameTextField'));
        await tester.tap(applicationNameField);
        await tester.pumpAndSettle();

        final ipAddressForm = find.byKey(const Key('ipAddressTextField'));
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField);
        await tester.pumpAndSettle();

        // await tester.enterText(
        //     ipAddressTextFormField.at(0), '0'); // Invalid first octet
        // await tester.pumpAndSettle();

        await tester.tap(find.byType(SinglePortForwardingListView));
        await tester.pumpAndSettle();

        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).theNameMustNotBeEmpty),
        //     findsOneWidget);
        // expect(find.text(testHelper.loc(context).invalidIpAddress),
        //     findsOneWidget);
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

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(1));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('externalPortTextField')), '22');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(SinglePortForwardingListView));
        await tester.pumpAndSettle();

        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).rulesOverlapError),
        //     findsOneWidget);
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

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(1));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
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

        // Tap IP address form
        final ipAddressForm = find.byKey(const Key('ipAddressTextField'));
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '15');
        await tester.pumpAndSettle();

        expect(find.text('name'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('40'), findsOneWidget);
        expect(find.textContaining('15'), findsOneWidget);
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-SPF_FILL_DESK-01-form_filled',
    );

    // Test ID: APPGAM-SPF_EDIT_MOB
    testLocalizationsV2(
      'Single port forwarding - edit',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockSinglePortForwardingListNotifier.build())
            .thenReturn(SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const SinglePortForwardingRuleView(),
        );
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).applicationName), findsOneWidget);
        expect(find.text(testHelper.loc(context).internalPort), findsOneWidget);
        expect(find.text(testHelper.loc(context).externalPort), findsOneWidget);
        expect(find.text(testHelper.loc(context).protocol), findsOneWidget);
        expect(find.text(testHelper.loc(context).ipAddress), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).selectDevices), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-SPF_EDIT_MOB-01-edit_form_mobile',
    );

    // Test ID: APPGAM-SPF_EDIT_ERR_MOB
    testLocalizationsV2(
      'Single port forwarding - edit error',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockSinglePortForwardingListNotifier.build())
            .thenReturn(SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));
        when(testHelper.mockSinglePortForwardingRuleNotifier.isRuleValid())
            .thenAnswer((invocation) => false);

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const SinglePortForwardingRuleView(),
        );
        await tester.pumpAndSettle();

        final nameFieldFinder =
            find.byKey(const Key('applicationNameTextField'));
        await tester.tap(nameFieldFinder);
        await tester.pumpAndSettle();

        final ipFieldFinder = find.byKey(const Key('ipAddressTextField'));
        final ipAddressTextFormField = find.descendant(
            of: ipFieldFinder, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField.at(0));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(SinglePortForwardingRuleView));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).theNameMustNotBeEmpty),
            findsOneWidget);
        expect(find.text(testHelper.loc(context).invalidIpAddress),
            findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-SPF_EDIT_ERR_MOB-01-form_errors_mobile',
    );

    // Test ID: APPGAM-SPF_OVER_ERR_MOB
    testLocalizationsV2(
      'Single port forwarding - edit overlap error',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockSinglePortForwardingListNotifier.build())
            .thenReturn(SinglePortForwardingListState.fromMap(
                singlePortForwardingListTestState));
        when(testHelper.mockSinglePortForwardingRuleNotifier
                .isPortConflict(any, any))
            .thenAnswer((invocation) => true);
        when(testHelper.mockSinglePortForwardingRuleNotifier.isRuleValid())
            .thenAnswer((invocation) => false);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const SinglePortForwardingRuleView(),
        );
        await tester.pumpAndSettle();

        final textFieldFinder = find.byKey(const Key('externalPortTextField'));
        await tester.enterText(textFieldFinder, '999');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(SinglePortForwardingRuleView));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).rulesOverlapError),
            findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-SPF_OVER_ERR_MOB-01-overlap_error_mobile',
    );

    // Test ID: APPGAM-SPF_FILL_MOB
    testLocalizationsV2(
      'Single port forwarding - edit filled up',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockSinglePortForwardingListNotifier.build())
            .thenReturn(SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const SinglePortForwardingRuleView(),
        );
        await tester.pumpAndSettle();

        final textFieldFinder =
            find.byKey(const Key('applicationNameTextField'));
        await tester.tap(textFieldFinder);
        await tester.pumpAndSettle();
        await tester.enterText(textFieldFinder, 'name');
        await tester.pumpAndSettle();

        final internalPortField =
            find.byKey(const Key('internalPortTextField'));
        await tester.enterText(internalPortField, '20');
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('externalPortTextField')), '40');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byKey(const Key('ipAddressTextField'));
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '15');
        await tester.pumpAndSettle();

        // TODO: Why the name error keep showing on screenshot
        expect(find.text('name'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('40'), findsOneWidget);
        expect(find.textContaining('15'), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-SPF_FILL_MOB-01-form_filled_mobile',
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

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(2));
      await tester.pumpAndSettle();

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

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(2));
      await tester.pumpAndSettle();
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

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).applicationName), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).startEndPorts), findsOneWidget);
        expect(find.text(testHelper.loc(context).protocol), findsOneWidget);
        expect(find.text(testHelper.loc(context).deviceIP), findsOneWidget);
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
        // Mock isRuleValid to return false to disable save button
        when(testHelper.mockPortRangeForwardingRuleNotifier.isRuleValid())
            .thenReturn(false);

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2)); // Tap on Port Range Forwarding tab
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder =
            find.byKey(const Key('applicationNameTextField'));
        await tester.tap(textFieldFinder);
        await tester.pumpAndSettle();

        // Tap IP address form to trigger validation
        final ipAddressForm = find.byKey(const Key('ipAddressTextField'));
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField.at(0));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PortRangeForwardingListView));
        await tester.pumpAndSettle();

        // TODO: ToolTip cannot display on screenshot
        // expect(
        //     find.text(testHelper.loc(context).theNameMustNotBeEmpty), findsOneWidget);
        // expect(
        //     find.text(testHelper.loc(context).invalidIpAddress), findsOneWidget);
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

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

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

        // TODO: ToolTip cannot display on screenshot
        // expect(
        //     find.text(testHelper.loc(context).rulesOverlapError), findsOneWidget);
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

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
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

        // TODO: ToolTip cannot display on screenshot
        // expect(
        //     find.text(testHelper.loc(context).portRangeError), findsOneWidget);
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRF_PORT_ERR_DESK-01-port_error',
    );

    // Test ID: APPGAM-PRF_FILL_DESK
    testLocalizationsV2(
      'Port range forwarding - edit filled up',
      (tester, screen) async {
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
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
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '15');
        await tester.pumpAndSettle();

        // TODO: Why the portRangeError showing on the screenshot
        expect(find.text('name'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('40'), findsOneWidget);
        expect(find.textContaining('15'), findsOneWidget);
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

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final protocolTypeFinder = find.byType(AppDropdownButton<String>).first;
        await tester.tap(protocolTypeFinder);
        await tester.pumpAndSettle();

        expect(
            find.widgetWithText(
                DropdownMenuItem<String>, testHelper.loc(context).tcp),
            findsOneWidget);
        expect(
            find.widgetWithText(
                DropdownMenuItem<String>, testHelper.loc(context).udp),
            findsOneWidget);
        expect(
            find.widgetWithText(
                DropdownMenuItem<String>, testHelper.loc(context).udpAndTcp),
            findsOneWidget);
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
      goldenFilename: 'APPGAM-PRF_PROTO_DESK-01-protocol_dropdown',
    );

    // Test ID: APPGAM-PRF_EDIT_MOB
    testLocalizationsV2(
      'Port range forwarding - edit',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).applicationName), findsOneWidget);
        expect(find.text(testHelper.loc(context).startPort), findsOneWidget);
        expect(find.text(testHelper.loc(context).endPort), findsOneWidget);
        expect(find.text(testHelper.loc(context).protocol), findsOneWidget);
        expect(find.text(testHelper.loc(context).ipAddress), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-PRF_EDIT_MOB-01-edit_form_mobile',
    );

    // Test ID: APPGAM-PRF_EDIT_ERR_MOB
    testLocalizationsV2(
      'Port range forwarding - edit error',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpAndSettle();

        final textFieldFinder =
            find.byKey(const Key('applicationNameTextField'));
        await tester.tap(textFieldFinder);
        await tester.pumpAndSettle();

        // Tap IP address form to trigger validation
        final ipAddressForm = find.byKey(const Key('ipAddressTextField'));
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField.at(0));
        await tester.pumpAndSettle();

        final firstExternalPortField =
            find.byKey(const Key('firstExternalPortTextField'));
        await tester.enterText(firstExternalPortField, '20');
        await tester.pumpAndSettle();

        final lastExternalPortField =
            find.byKey(const Key('lastExternalPortTextField'));
        await tester.enterText(lastExternalPortField, '10');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PortRangeForwardingRuleView));
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).portRangeError), findsOneWidget);
        // TODO:
        // expect(
        //     find.text(testHelper.loc(context).theNameMustNotBeEmpty), findsOneWidget);
        expect(find.text(testHelper.loc(context).invalidIpAddress),
            findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-PRF_EDIT_ERR_MOB-01-form_errors_mobile',
    );

    // Test ID: APPGAM-PRF_OVER_ERR_MOB
    testLocalizationsV2(
      'Port range forwarding - edit overlap error',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingListTestState));
        when(testHelper.mockPortRangeForwardingRuleNotifier
                .isPortRangeValid(any, any))
            .thenReturn(true);
        when(testHelper.mockPortRangeForwardingRuleNotifier
                .isPortConflict(any, any, any))
            .thenReturn(true);

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpAndSettle();

        final firstExternalPortField =
            find.byKey(const Key('firstExternalPortTextField'));
        await tester.enterText(firstExternalPortField, '5000');
        await tester.pumpAndSettle();

        final lastExternalPortField =
            find.byKey(const Key('lastExternalPortTextField'));
        await tester.enterText(lastExternalPortField, '5005');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PortRangeForwardingRuleView));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).rulesOverlapError),
            findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-PRF_OVER_ERR_MOB-01-overlap_error_mobile',
    );

    // Test ID: APPGAM-PRF_FILL_MOB
    testLocalizationsV2(
      'Port range forwarding - edit filled up',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpAndSettle();

        final appNameField = find.byKey(const Key('applicationNameTextField'));
        await tester.enterText(appNameField, 'name');
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
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '15');
        await tester.pumpAndSettle();

        // TODO: Why the portRangeError showing on the screenshot
        expect(find.text('name'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('40'), findsOneWidget);
        expect(find.textContaining('15'), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-PRF_FILL_MOB-01-form_filled_mobile',
    );

    // Test ID: APPGAM-PRF_PROTO_MOB
    testLocalizationsV2(
      'Port range forwarding - protocol',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpAndSettle();

        final protocolTypeFinder = find.byType(AppDropdownButton<String>);
        await tester.tap(protocolTypeFinder.first);
        await tester.pumpAndSettle();

        expect(
            find.widgetWithText(
                DropdownMenuItem<String>, testHelper.loc(context).tcp),
            findsOneWidget);
        expect(
            find.widgetWithText(
                DropdownMenuItem<String>, testHelper.loc(context).udp),
            findsOneWidget);
        expect(
            find.widgetWithText(
                DropdownMenuItem<String>, testHelper.loc(context).udpAndTcp),
            findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-PRF_PROTO_MOB-01-protocol_dropdown_mobile',
    );
  });

  group('Apps & Gaming - Port range triggerring', () {
    // Test ID: APPGAM-PRT_DATA
    testLocalizationsV2('Port range triggerring - with data',
        (tester, screen) async {
      when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
          PortRangeTriggeringListState.fromMap(portRangeTriggerListTestState));

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();

      final tabFinder = find.byType(AppTabBar);
      final portRangeTriggeringFinder = find.byKey(Key('portRangeTriggering'));
      await tester.drag(tabFinder, Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(portRangeTriggeringFinder);
      await tester.pumpAndSettle();

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

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpAndSettle();

      final tabFinder = find.byType(AppTabBar);
      final portRangeTriggeringFinder = find.byKey(Key('portRangeTriggering'));
      await tester.drag(tabFinder, Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(portRangeTriggeringFinder);
      await tester.pumpAndSettle();

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

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(AppTabBar);
        final portRangeTriggeringFinder =
            find.byKey(Key('portRangeTriggering'));
        await tester.drag(tabFinder, Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.tap(portRangeTriggeringFinder);
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).applicationName), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).triggeredRange), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).forwardedRange), findsOneWidget);
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

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(AppTabBar);
        final portRangeTriggeringFinder =
            find.byKey(const Key('portRangeTriggering'));
        await tester.drag(tabFinder, const Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.tap(portRangeTriggeringFinder);
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder =
            find.byKey(const Key('applicationNameTextField'));
        // Tap the application name field to trigger validation on port range fields
        await tester.tap(textFieldFinder);
        await tester.pumpAndSettle();

        final firstForwardedPortField =
            find.byKey(const Key('firstForwardedPortTextField'));
        await tester.enterText(firstForwardedPortField, '7000');
        await tester.pumpAndSettle();

        final lastForwardedPortField =
            find.byKey(const Key('lastForwardedPortTextField'));
        await tester.enterText(
            lastForwardedPortField, '6001'); // Last Forwarded Port (invalid)
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PortRangeTriggeringListView));
        await tester.pumpAndSettle();

        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).theNameMustNotBeEmpty),
        //     findsOneWidget);
        // expect(find.text(testHelper.loc(context).portRangeError),
        //     findsOneWidget);
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

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(AppTabBar);
        final portRangeTriggeringFinder =
            find.byKey(Key('portRangeTriggering'));
        await tester.drag(tabFinder, Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.tap(portRangeTriggeringFinder);
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
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

        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).portRangeError),
        //     findsOneWidget);
        // expect(find.text(testHelper.loc(context).rulesOverlapError),
        //     findsOneWidget);
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

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpAndSettle();

        final tabFinder = find.byType(AppTabBar);
        final portRangeTriggeringFinder =
            find.byKey(Key('portRangeTriggering'));
        await tester.drag(tabFinder, Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.tap(portRangeTriggeringFinder);
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
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

    // Test ID: APPGAM-PRT_EDIT_MOB
    testLocalizationsV2(
      'Port range triggerring - edit',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const PortRangeTriggeringRuleView(),
        );
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).ruleName), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).triggeredRange), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).forwardedRange), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-PRT_EDIT_MOB-01-edit_form_mobile',
    );

    // Test ID: APPGAM-PRT_EDIT_ERR_MOB
    testLocalizationsV2(
      'Port range triggerring - edit error',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const PortRangeTriggeringRuleView(),
        );
        await tester.pumpAndSettle();

        final appNameField = find.byKey(const Key('ruleNameTextField'));
        await tester.tap(appNameField);
        await tester.pumpAndSettle();

        final firstTriggerPortField =
            find.byKey(const Key('firstTriggerPortTextField'));
        await tester.enterText(firstTriggerPortField, '6000');
        await tester.pumpAndSettle();

        final lastTriggerPortField =
            find.byKey(const Key('lastTriggerPortTextField'));
        await tester.enterText(lastTriggerPortField, '5000');
        await tester.pumpAndSettle();

        final firstForwardedPortField =
            find.byKey(const Key('firstForwardedPortTextField'));
        await tester.enterText(firstForwardedPortField, '20');
        await tester.pumpAndSettle();

        final lastForwardedPortField =
            find.byKey(const Key('lastForwardedPortTextField'));
        await tester.enterText(lastForwardedPortField, '10');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PortRangeTriggeringRuleView));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).theNameMustNotBeEmpty),
            findsOneWidget);
        expect(find.text(testHelper.loc(context).portRangeError),
            findsNWidgets(2));
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-PRT_EDIT_ERR_MOB-01-form_errors_mobile',
    );

    // Test ID: APPGAM-PRT_OVER_ERR_MOB
    testLocalizationsV2(
      'Port range triggerring - edit overlap error',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerListTestState));
        when(testHelper.mockPortRangeTriggeringRuleNotifier
                .isTriggeredPortConflict(any, any))
            .thenAnswer((invocation) => true);

        final context = await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const PortRangeTriggeringRuleView(),
        );
        await tester.pumpAndSettle();

        final firstForwardedPortField =
            find.byKey(const Key('firstForwardedPortTextField'));
        await tester.enterText(firstForwardedPortField, '7000');
        await tester.pumpAndSettle();

        final lastForwardedPortField =
            find.byKey(const Key('lastForwardedPortTextField'));
        await tester.enterText(lastForwardedPortField, '7001');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PortRangeTriggeringRuleView));
        await tester.pumpAndSettle();

        // TODO: The logic on desktop/mobile, trigger/forwarded is not the same
        // expect(find.text(testHelper.loc(context).rulesOverlapError),
        //     findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-PRT_OVER_ERR_MOB-01-overlap_error_mobile',
    );

    // Test ID: APPGAM-PRT_FILL_MOB
    testLocalizationsV2(
      'Port range triggerring - edit filled up',
      (tester, screen) async {
        // For mobile layout
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: screen.locale,
          child: const PortRangeTriggeringRuleView(),
        );
        await tester.pumpAndSettle();

        final appNameField = find.byKey(const Key('ruleNameTextField'));
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

        await tester.tap(find.byType(PortRangeTriggeringRuleView));
        await tester.pumpAndSettle();

        //TODO: Why the name error keep showing on screenshot
        expect(find.text('name'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(find.text('40'), findsOneWidget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
      goldenFilename: 'APPGAM-PRT_FILL_MOB-01-form_filled_mobile',
    );
  });
}
