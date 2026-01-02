import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_route_entry_ui_model.dart';

import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';

import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_view.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/static_routing_state.dart';

// View ID: SROUTE

/// | Test ID             | Description                                                                 |
/// | :------------------ | :-------------------------------------------------------------------------- |
/// | `SROUTE-EMPTY`      | Verifies the view in its empty state with no static routes.                 |
/// | `SROUTE-NAT`        | Verifies the view with NAT enabled and a list of static routes.             |
/// | `SROUTE-RIP`        | Verifies the view with Dynamic Routing (RIP) enabled.                       |
/// | `SROUTE-DEL-MOB`    | Verifies deleting a static route on mobile view.                            |
/// | `SROUTE-ADD-RULE`   | Verifies the add static route rule view.                                    |
/// | `SROUTE-EDIT-RULE`  | Verifies the edit static route rule view with pre-filled data.              |
/// | `SROUTE-VAL-NAME`   | Verifies the validation for an empty route name in the rule view.           |
/// | `SROUTE-VAL-DEST`   | Verifies the validation for an invalid destination IP in the rule view.     |
/// | `SROUTE-VAL-SUBNET` | Verifies the validation for an invalid subnet mask in the rule view.        |
/// | `SROUTE-VAL-GATEWAY`| Verifies the validation for an invalid gateway IP in the rule view.         |
/// | `SROUTE-DROPDOWN`   | Verifies the 'Interface' dropdown menu in the rule view.

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens.where((s) => s.width != 744).toList();
  final desktopScreens = responsiveDesktopScreens;
  final mobileScreens = responsiveMobileScreens;

  setUp(() {
    testHelper.setup();
  });

  group('StaticRoutingView', () {
    testLocalizations(
      'Verify the view in its empty state with no static routes.',
      (tester, screen) async {
        // Test ID: SROUTE-EMPTY
        final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
        final context = await testHelper.pumpShellView(
          tester,
          config:
              LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).advancedRouting), findsOneWidget);
        expect(find.byKey(const Key('settingNetwork')), findsOneWidget);
        expect(find.text(testHelper.loc(context).nat), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).dynamicRouting), findsOneWidget);

        expect(
            find.byType(AppDataTable<StaticRouteEntryUIModel>), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).noStaticRoutes), findsOneWidget);
        expect(
            find.byKey(const Key('pageBottomPositiveButton')), findsOneWidget);
      },
      goldenFilename: 'SROUTE-EMPTY-01-initial-desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizations(
      'Verify the view in its empty state with no static routes.',
      (tester, screen) async {
        // Test ID: SROUTE-EMPTY
        final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);

        await testHelper.pumpShellView(
          tester,
          config:
              LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        // Screenshot test - visual verification only
        expect(find.byKey(const Key('settingNetwork')), findsOneWidget);
        expect(
            find.byType(AppDataTable<StaticRouteEntryUIModel>), findsOneWidget);
      },
      goldenFilename: 'SROUTE-EMPTY-01-initial-mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizations(
      'Verifies the view with NAT enabled and a list of static routes.',
      (tester, screen) async {
        // Test ID: SROUTE-NAT
        final state = StaticRoutingState.fromMap(staticRoutingTestState);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);

        final context = await testHelper.pumpShellView(
          tester,
          config:
              LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).advancedRouting), findsOneWidget);
        final firstRule = state.current.entries.first;
        expect(find.text(firstRule.name), findsOneWidget);
        expect(find.text(firstRule.destinationIP), findsOneWidget);
      },
      goldenFilename: 'SROUTE-NAT-01-initial',
      screens: screens,
      helper: testHelper,
    );

    testLocalizations(
      'Verifies the view with Dynamic Routing (RIP) enabled.',
      (tester, screen) async {
        // Test ID: SROUTE-RIP
        final state =
            StaticRoutingState.fromMap(staticRoutingTestState).copyWith(
          settings: const Preservable(
            original: StaticRoutingSettings(
                isNATEnabled: false,
                isDynamicRoutingEnabled: true,
                entries: []),
            current: StaticRoutingSettings(
                isNATEnabled: false,
                isDynamicRoutingEnabled: true,
                entries: []),
          ),
        );
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);

        final context = await testHelper.pumpShellView(
          tester,
          config:
              LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        final radioList = tester
            .widget<AppRadioList>(find.byKey(const Key('settingNetwork')));
        expect(radioList.selected, RoutingSettingNetwork.dynamicRouting);
        expect(
            find.text(testHelper.loc(context).noStaticRoutes), findsOneWidget);
      },
      goldenFilename: 'SROUTE-RIP-01-initial_desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizations(
      'Verifies the view with Dynamic Routing (RIP) enabled.',
      (tester, screen) async {
        // Test ID: SROUTE-RIP
        final state =
            StaticRoutingState.fromMap(staticRoutingTestState).copyWith(
          settings: const Preservable(
            original: StaticRoutingSettings(
                isNATEnabled: false,
                isDynamicRoutingEnabled: true,
                entries: []),
            current: StaticRoutingSettings(
                isNATEnabled: false,
                isDynamicRoutingEnabled: true,
                entries: []),
          ),
        );
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);

        await testHelper.pumpShellView(
          tester,
          config:
              LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        // Screenshot test - visual verification only
        final radioList = tester
            .widget<AppRadioList>(find.byKey(const Key('settingNetwork')));
        expect(radioList.selected, RoutingSettingNetwork.dynamicRouting);
      },
      goldenFilename: 'SROUTE-RIP-01-initial_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    // SKIPPED: SROUTE-ADD-RULE - requires inline editing interaction that differs between desktop and mobile
    testLocalizations(
      'Verifies the add static route rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-ADD-RULE
        testHelper.disableAnimations = false;
        final state = StaticRoutingState.fromMap(staticRoutingTestState);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
        when(testHelper.mockStaticRoutingRuleNotifier.isRuleValid())
            .thenReturn(false);

        await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('appDataTable_addButton')));
        await tester.pumpAndSettle();

        final nameController = tester
            .widget<AppTextField>(find.byKey(const Key('routeName')))
            .controller;
        expect(nameController?.text, isEmpty);

        final destinationIp = tester
            .widget<AppIpv4TextField>(find.byKey(const Key('destinationIP')))
            .controller
            ?.text;
        expect(destinationIp, isEmpty);

        final subnetMask = tester
            .widget<AppIpv4TextField>(find.byKey(const Key('subnetMask')))
            .controller
            ?.text;
        expect(subnetMask, '255.255.255.0');

        final gatewayIp = tester
            .widget<AppIpv4TextField>(find.byKey(const Key('gateway')))
            .controller
            ?.text;
        expect(gatewayIp, isEmpty);
      },
      goldenFilename: 'SROUTE-ADD-RULE-01-initial_desktop',
      screens: desktopScreens.where((s) => s.width != 744).toList(),
      helper: testHelper,
    );

    testLocalizations(
      'Verifies the add static route rule view (Tablet).',
      (tester, screen) async {
        // Test ID: SROUTE-ADD-RULE-TABLET
        testHelper.disableAnimations = false;
        final state = StaticRoutingState.fromMap(staticRoutingTestState);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
        when(testHelper.mockStaticRoutingRuleNotifier.isRuleValid())
            .thenReturn(false);

        await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('appDataTable_addButton')));
        await tester.pump();
        await tester.pumpAndSettle();

        final nameController = tester
            .widget<AppTextField>(find.byKey(const Key('routeName')))
            .controller;
        expect(nameController?.text, isEmpty);

        final destinationIp = tester
            .widget<AppIpv4TextField>(find.byKey(const Key('destinationIP')))
            .controller
            ?.text;
        expect(destinationIp, isEmpty);

        final subnetMask = tester
            .widget<AppIpv4TextField>(find.byKey(const Key('subnetMask')))
            .controller
            ?.text;
        expect(subnetMask, '255.255.255.0');

        final gatewayIp = tester
            .widget<AppIpv4TextField>(find.byKey(const Key('gateway')))
            .controller
            ?.text;
        expect(gatewayIp, isEmpty);
      },
      goldenFilename: 'SROUTE-ADD-RULE-01-initial_tablet',
      screens: [device744w],
      helper: testHelper,
    );

    testLocalizations(
      'Verifies the edit static route rule view with pre-filled data.',
      (tester, screen) async {
        // Test ID: SROUTE-EDIT-RULE
        testHelper.disableAnimations = false;
        final state = StaticRoutingState.fromMap(staticRoutingTestState);
        final rule = state.current.entries.first;
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
        when(testHelper.mockStaticRoutingRuleNotifier.isRuleValid())
            .thenReturn(true);

        await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Use key-based finder for edit button (first row = index 0)
        await tester.tap(find.byKey(const Key('appDataTable_editButton_0')));
        await tester.pumpAndSettle();

        // Verify pre-filled data in input fields
        final nameController = tester
            .widget<AppTextField>(find.byKey(const Key('routeName')))
            .controller;
        expect(nameController?.text, rule.name);

        final destinationIp = tester
            .widget<AppIpv4TextField>(find.byKey(const Key('destinationIP')))
            .controller
            ?.text;
        expect(destinationIp, rule.destinationIP);
        final subnetMask = tester
            .widget<AppIpv4TextField>(find.byKey(const Key('subnetMask')))
            .controller
            ?.text;
        expect(subnetMask, rule.subnetMask);
        final gatewayIp = tester
            .widget<AppIpv4TextField>(find.byKey(const Key('gateway')))
            .controller
            ?.text;
        expect(gatewayIp, rule.gateway);
      },
      goldenFilename: 'SROUTE-EDIT-RULE-01-initial_desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizations(
      'Verifies the validation for an empty route name in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-NAME
        testHelper.disableAnimations = false; // Enable animations for this test

        await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('appDataTable_addButton')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('routeName')), '');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingView));
        await tester.pumpAndSettle();

        // TODO: ToolTip cannot display on screenshot
        // expect(
        //     find.text(testHelper.loc(context).theNameMustNotBeEmpty), findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-NAME-01-error_desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizations(
      'Verifies the validation for an invalid destination IP in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-DEST
        testHelper.disableAnimations = false; // Enable animations for this test
        final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
        when(testHelper.mockStaticRoutingRuleNotifier
                .isValidIpAddress(any, any))
            .thenReturn(false);

        await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('appDataTable_addButton')));
        await tester.pumpAndSettle();

        final ipAddressForm = find.byKey(const Key('destinationIP'));
        final ipAddressTextField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextField));
        await tester.tap(ipAddressTextField.first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingView));
        await tester.pumpAndSettle();

        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).invalidIpAddress),
        //     findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-DEST-01-error_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizations(
      'Verifies the validation for an invalid subnet mask in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-SUBNET
        testHelper.disableAnimations = false; // Enable animations for this test
        final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
        when(testHelper.mockStaticRoutingRuleNotifier.isValidSubnetMask(any))
            .thenReturn(false);

        await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('appDataTable_addButton')));
        await tester.pumpAndSettle();

        final ipAddressForm = find.byKey(const Key('subnetMask'));
        final ipAddressTextField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextField));
        await tester.tap(ipAddressTextField.first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingView));
        await tester.pumpAndSettle();

        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).invalidSubnetMask),
        //     findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-SUBNET-01-error_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizations(
      'Verifies the validation for an invalid gateway IP in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-GATEWAY
        testHelper.disableAnimations = false; // Enable animations for this test
        final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
        when(testHelper.mockStaticRoutingRuleNotifier
                .isValidIpAddress(any, any))
            .thenReturn(false);

        await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('appDataTable_addButton')));
        await tester.pumpAndSettle();

        final ipAddressForm = find.byKey(const Key('gateway'));
        final ipAddressTextField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextField));
        await tester.tap(ipAddressTextField.first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingView));
        await tester.pumpAndSettle();
        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).invalidGatewayIpAddress),
        //     findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-GATEWAY-01-error_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizations(
      "Verifies the 'Interface' dropdown menu in the rule view.",
      (tester, screen) async {
        // Test ID: SROUTE-DROPDOWN
        testHelper.disableAnimations = false; // Enable animations for this test
        final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('appDataTable_addButton')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('interface')));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).lanWireless), findsAtLeast(1));
        expect(find.text('Internet'), findsAtLeast(1));
        await testHelper.takeScreenshot(
            tester, 'SROUTE-DROPDOWN-02-opened_desktop');
      },
      screens: mobileScreens,
      helper: testHelper,
    );
  });
}
