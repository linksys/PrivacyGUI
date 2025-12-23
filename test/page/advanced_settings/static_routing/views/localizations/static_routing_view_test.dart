import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_route_entry_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_routing_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_rule_view.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_view.dart';
import 'package:privacy_gui/page/components/settings_view/editable_card_list_settings_view.dart';
import 'package:privacy_gui/page/components/settings_view/editable_table_settings_view.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

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
  final screens = responsiveAllScreens;
  final desktopScreens = responsiveDesktopScreens;
  final mobileScreens = responsiveMobileScreens;

  setUp(() {
    testHelper.setup();
  });

  group('StaticRoutingView', () {
    testLocalizationsV2(
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

        expect(find.byType(AppEditableTableSettingsView<StaticRouteEntryUIModel>),
            findsOneWidget);
        expect(
            find.text(testHelper.loc(context).noStaticRoutes), findsOneWidget);
        expect(
            find.byKey(const Key('pageBottomPositiveButton')), findsOneWidget);
      },
      goldenFilename: 'SROUTE-EMPTY-01-initial-desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verify the view in its empty state with no static routes.',
      (tester, screen) async {
        // Test ID: SROUTE-EMPTY
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

        expect(find.byType(EditableCardListsettingsView<StaticRoutingRuleUIModel>),
            findsOneWidget);
        expect(find.text(testHelper.loc(context).noAdvancedRouting),
            findsOneWidget);
        expect(
            find.byKey(const Key('pageBottomPositiveButton')), findsOneWidget);
      },
      goldenFilename: 'SROUTE-EMPTY-01-initial-mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
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

    testLocalizationsV2(
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

    testLocalizationsV2(
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
        expect(find.text(testHelper.loc(context).noAdvancedRouting),
            findsOneWidget);
      },
      goldenFilename: 'SROUTE-RIP-01-initial_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the add static route rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-ADD-RULE
        final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LinksysIcons.add));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ruleName')), findsOneWidget);
        expect(find.byKey(const Key('destinationIP')), findsOneWidget);
        expect(find.byKey(const Key('subnetMask')), findsOneWidget);
        expect(find.byKey(const Key('gateway')), findsOneWidget);
        expect(find.byKey(const Key('interface')), findsOneWidget);

        final saveButton = tester.widget<AppFilledButton>(
            find.byKey(const Key('pageBottomPositiveButton')));
        expect(saveButton.onTap, isNull);
      },
      goldenFilename: 'SROUTE-ADD-RULE-01-initial_desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the add static route rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-ADD-RULE
        final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);

        // Convert entries to StaticRoutingRuleUIModel for editor
        final ruleItems = state.settings.current.entries
            .map((e) => StaticRoutingRuleUIModel(
                  name: e.name,
                  destinationIP: e.destinationIP,
                  networkPrefixLength:
                      NetworkUtils.subnetMaskToPrefixLength(e.subnetMask),
                  gateway: e.gateway.isEmpty ? null : e.gateway,
                  interface: e.interface,
                ))
            .toList();

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: StaticRoutingRuleView(
              args: {'items': ruleItems}),
        );
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).addStaticRoute), findsOneWidget);
        expect(find.byKey(const Key('ruleName')), findsOneWidget);
        expect(find.byKey(const Key('destinationIP')), findsOneWidget);
        expect(find.byKey(const Key('subnetMask')), findsOneWidget);
        expect(find.byKey(const Key('gateway')), findsOneWidget);
        expect(find.byKey(const Key('interface')), findsOneWidget);

        final saveButton = tester.widget<AppFilledButton>(
            find.byKey(const Key('pageBottomPositiveButton')));
        expect(saveButton.onTap, isNull);
      },
      goldenFilename: 'SROUTE-ADD-RULE-01-initial_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the edit static route rule view with pre-filled data.',
      (tester, screen) async {
        // Test ID: SROUTE-EDIT-RULE
        final state = StaticRoutingState.fromMap(staticRoutingTestState);
        final rule = state.current.entries.first;
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
        when(testHelper.mockStaticRoutingRuleNotifier.isRuleValid())
            .thenReturn(true);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: StaticRoutingView(),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LinksysIcons.edit).first);
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppTextField, rule.name), findsOneWidget);
        final destinationIp = tester
            .widget<AppIPFormField>(find.byKey(Key('destinationIP')))
            .controller
            ?.text;
        expect(destinationIp, rule.destinationIP);
        final subnetMask = tester
            .widget<AppIPFormField>(find.byKey(Key('subnetMask')))
            .controller
            ?.text;
        expect(subnetMask, rule.subnetMask);
        final gatewayIp = tester
            .widget<AppIPFormField>(find.byKey(Key('gateway')))
            .controller
            ?.text;
        expect(gatewayIp, rule.gateway);

        final saveButton = tester.widget<AppFilledButton>(
            find.byKey(const Key('pageBottomPositiveButton')));
        expect(saveButton.onTap, isNull);
      },
      goldenFilename: 'SROUTE-EDIT-RULE-01-initial_desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the edit static route rule view with pre-filled data.',
      (tester, screen) async {
        // Test ID: SROUTE-EDIT-RULE
        final state = StaticRoutingState.fromMap(staticRoutingTestState);
        final rule = state.current.entries.first;
        when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
        when(testHelper.mockStaticRoutingRuleNotifier.isRuleValid())
            .thenReturn(true);

        // Convert entries to StaticRoutingRuleUIModel for editor
        final ruleItems = state.settings.current.entries
            .map((e) => StaticRoutingRuleUIModel(
                  name: e.name,
                  destinationIP: e.destinationIP,
                  networkPrefixLength:
                      NetworkUtils.subnetMaskToPrefixLength(e.subnetMask),
                  gateway: e.gateway.isEmpty ? null : e.gateway,
                  interface: e.interface,
                ))
            .toList();

        // Convert edit rule to StaticRoutingRuleUIModel
        final editRule = StaticRoutingRuleUIModel(
          name: rule.name,
          destinationIP: rule.destinationIP,
          networkPrefixLength:
              NetworkUtils.subnetMaskToPrefixLength(rule.subnetMask),
          gateway: rule.gateway.isEmpty ? null : rule.gateway,
          interface: rule.interface,
        );

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: StaticRoutingRuleView(
            args: {
              'items': ruleItems,
              'edit': editRule,
            },
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppTextField, rule.name), findsOneWidget);
        final destinationIp = tester
            .widget<AppIPFormField>(find.byKey(Key('destinationIP')))
            .controller
            ?.text;
        expect(destinationIp, rule.destinationIP);
        final subnetMask = tester
            .widget<AppIPFormField>(find.byKey(Key('subnetMask')))
            .controller
            ?.text;
        expect(subnetMask, rule.subnetMask);
        final gatewayIp = tester
            .widget<AppIPFormField>(find.byKey(Key('gateway')))
            .controller
            ?.text;
        expect(gatewayIp, rule.gateway);

        final saveButton = tester.widget<AppFilledButton>(
            find.byKey(const Key('pageBottomPositiveButton')));
        expect(saveButton.onTap, isNotNull);
      },
      goldenFilename: 'SROUTE-EDIT-RULE-01-initial_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the validation for an empty route name in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-NAME

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LinksysIcons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('ruleName')), '');
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

    testLocalizationsV2(
      'Verifies the validation for an empty route name in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-NAME
        final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);

        // Convert entries to StaticRoutingRuleUIModel for editor
        final ruleItems = state.settings.current.entries
            .map((e) => StaticRoutingRuleUIModel(
                  name: e.name,
                  destinationIP: e.destinationIP,
                  networkPrefixLength:
                      NetworkUtils.subnetMaskToPrefixLength(e.subnetMask),
                  gateway: e.gateway.isEmpty ? null : e.gateway,
                  interface: e.interface,
                ))
            .toList();

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: StaticRoutingRuleView(
              args: {'items': ruleItems}),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('ruleName')), '');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(StaticRoutingRuleView));
        await tester.pumpAndSettle();

        expect(
            find.text(testHelper.loc(context).theNameMustNotBeEmpty), findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-NAME-01-error_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the validation for an invalid destination IP in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-DEST
        when(testHelper.mockStaticRoutingRuleNotifier.isValidIpAddress(any, any))
            .thenReturn(false);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LinksysIcons.add));
        await tester.pumpAndSettle();

        final ipAddressForm = find.byKey(const Key('destinationIP'));
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField.first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingView));
        await tester.pumpAndSettle();

        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).invalidIpAddress),
        //     findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-DEST-01-error_desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the validation for an invalid destination IP in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-DEST
        when(testHelper.mockStaticRoutingRuleNotifier.isValidIpAddress(any, any))
            .thenReturn(false);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingRuleView(),
        );
        await tester.pumpAndSettle();

        final ipAddressForm = find.byKey(const Key('destinationIP'));
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField.first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingRuleView));
        await tester.pumpAndSettle();
        expect(find.text(testHelper.loc(context).invalidIpAddress),
            findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-DEST-01-error_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the validation for an invalid subnet mask in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-SUBNET
        when(testHelper.mockStaticRoutingRuleNotifier.isValidSubnetMask(any))
            .thenReturn(false);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LinksysIcons.add));
        await tester.pumpAndSettle();
        
        final ipAddressForm = find.byKey(const Key('subnetMask'));
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField.first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingView));
        await tester.pumpAndSettle();

        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).invalidSubnetMask),
        //     findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-SUBNET-01-error_desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the validation for an invalid subnet mask in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-SUBNET
        when(testHelper.mockStaticRoutingRuleNotifier.isValidSubnetMask(any))
            .thenReturn(false);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingRuleView(),
        );
        await tester.pumpAndSettle();
        
        final ipAddressForm = find.byKey(const Key('subnetMask'));
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField.first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingRuleView));
        await tester.pumpAndSettle();
        expect(find.text(testHelper.loc(context).invalidSubnetMask),
            findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-SUBNET-01-error_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the validation for an invalid gateway IP in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-GATEWAY
        when(testHelper.mockStaticRoutingRuleNotifier.isValidIpAddress(any, any))
            .thenReturn(false);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LinksysIcons.add));
        await tester.pumpAndSettle();

        final ipAddressForm = find.byKey(const Key('gateway'));
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField.first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingView));
        await tester.pumpAndSettle();
        // TODO: ToolTip cannot display on screenshot
        // expect(find.text(testHelper.loc(context).invalidGatewayIpAddress),
        //     findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-GATEWAY-01-error_desktop',
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      'Verifies the validation for an invalid gateway IP in the rule view.',
      (tester, screen) async {
        // Test ID: SROUTE-VAL-GATEWAY
        when(testHelper.mockStaticRoutingRuleNotifier.isValidIpAddress(any, any))
            .thenReturn(false);

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingRuleView(),
        );
        await tester.pumpAndSettle();

        final ipAddressForm = find.byKey(const Key('gateway'));
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.tap(ipAddressTextFormField.first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(StaticRoutingRuleView));
        await tester.pumpAndSettle();
        expect(find.text(testHelper.loc(context).invalidGatewayIpAddress),
            findsOneWidget);
      },
      goldenFilename: 'SROUTE-VAL-GATEWAY-01-error_mobile',
      screens: mobileScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      "Verifies the 'Interface' dropdown menu in the rule view.",
      (tester, screen) async {
        // Test ID: SROUTE-DROPDOWN

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingView(),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(LinksysIcons.add));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('interface')));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).lanWireless), findsAtLeast(1));
        expect(find.text('Internet'), findsAtLeast(1));
        await testHelper.takeScreenshot(tester, 'SROUTE-DROPDOWN-02-opened_desktop');
      },
      screens: desktopScreens,
      helper: testHelper,
    );

    testLocalizationsV2(
      "Verifies the 'Interface' dropdown menu in the rule view.",
      (tester, screen) async {
        // Test ID: SROUTE-DROPDOWN

        final context = await testHelper.pumpShellView(
          tester,
          locale: screen.locale,
          child: const StaticRoutingRuleView(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('interface')));
        await tester.pumpAndSettle();

        expect(find.text(testHelper.loc(context).lanWireless), findsAtLeast(1));
        expect(find.text('Internet'), findsAtLeast(1));
        await testHelper.takeScreenshot(tester, 'SROUTE-DROPDOWN-02-opened_mobile');
      },
      screens: mobileScreens,
      helper: testHelper,
    );
  });
}
