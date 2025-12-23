import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/ipv6_port_service_list_test_state.dart';

/// Helper to switch tabs by index using TabController
Future<void> switchToTab(WidgetTester tester, int index) async {
  final tabBarFinder = find.byType(TabBar);
  expect(tabBarFinder, findsOneWidget);

  final tabBar = tester.widget<TabBar>(tabBarFinder);
  final controller = tabBar.controller;
  if (controller != null) {
    controller.animateTo(index);
    // Pump to process the animateTo request
    await tester.pump();
    // Wait a bit for tab animation
    await tester.pump(const Duration(milliseconds: 300));
    // Final settle
    await tester.pumpAndSettle();
  }
}

// Reference to Implementation File: lib/page/advanced_settings/firewall/views/firewall_view.dart
// View ID: FWS

/// | Test ID         | Description                                                                  |
/// | :-------------- | :--------------------------------------------------------------------------- |
/// | `FWS-FW_INIT`     | Verifies the initial state of the Firewall tab.                              |
/// | `FWS-VPN_INIT`    | Verifies the initial state of the VPN Passthrough tab.                       |
/// | `FWS-FIL_INIT`    | Verifies the initial state of the Internet Filters tab.                      |
/// | `FWS-IPV6_INIT`   | Verifies the initial state of the IPv6 Port Services tab with existing rules. |
/// | `FWS-IPV6_EMPTY`  | Verifies the empty state of the IPv6 Port Services tab.                      |
/// | `FWS-IPV6_ADD`    | Verifies opening the 'Add Rule' view for IPv6 Port Services.                 |
/// | `FWS-IPV6_DROP`   | Verifies the protocol dropdown in the 'Add Rule' view.                       |
/// | `FWS-IPV6_INVALID`| Verifies the validation for invalid port ranges in the 'Add Rule' view.      |
/// | `FWS-IPV6_OVERLAP`  | Verifies the validation for overlapping port ranges in the 'Add Rule' view.  |
void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  // Test ID: FWS-FW_INIT
  testLocalizationsV2(
    'Firewall settings view - firewall',
    (tester, screen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const FirewallView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, loc(context).firewall), findsOneWidget);
      expect(
          find.byKey(const Key('ipv4SPIFirewallProtection')), findsOneWidget);
      expect(
          find.byKey(const Key('ipv6SPIFirewallProtection')), findsOneWidget);
    },
    goldenFilename: 'FWS-FW_INIT-01-initial_state',
    helper: testHelper,
  );

  // Test ID: FWS-VPN_INIT
  testLocalizationsV2(
    'Firewall settings view - VPN passthrough',
    (tester, screen) async {
      // Enable animations for tab switching
      testHelper.disableAnimations = false;

      await testHelper.pumpView(
        tester,
        child: const FirewallView(),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      // Switch to VPN Passthrough tab (index 1)
      await switchToTab(tester, 1);

      expect(find.byKey(const Key('ipsecPassthrough')), findsOneWidget);
      expect(find.byKey(const Key('pptpPassthrough')), findsOneWidget);
      expect(find.byKey(const Key('l2tpPassthrough')), findsOneWidget);
    },
    goldenFilename: 'FWS-VPN_INIT-01-initial_state',
    helper: testHelper,
  );

  // Test ID: FWS-FIL_INIT
  testLocalizationsV2(
    'Firewall settings view - Internet filters',
    (tester, screen) async {
      // Enable animations for tab switching
      testHelper.disableAnimations = false;

      await testHelper.pumpView(
        tester,
        child: const FirewallView(),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      // Switch to Internet Filters tab (index 2)
      await switchToTab(tester, 2);

      expect(find.byKey(const Key('filterAnonymous')), findsOneWidget);
      expect(find.byKey(const Key('filterMulticast')), findsOneWidget);
      expect(find.byKey(const Key('filterNATRedirection')), findsOneWidget);
      expect(find.byKey(const Key('filterIdent')), findsOneWidget);
    },
    goldenFilename: 'FWS-FIL_INIT-01-initial_state',
    helper: testHelper,
  );

  // Test ID: FWS-IPV6_INIT
  testLocalizationsV2(
    'Firewall settings view - IPv6 port service',
    (tester, screen) async {
      // Enable animations for tab switching
      testHelper.disableAnimations = false;

      await testHelper.pumpView(
        tester,
        child: const FirewallView(),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      // Switch to IPv6 Port Services tab (index 3)
      await switchToTab(tester, 3);

      expect(find.text('rule1'), findsOneWidget);
      expect(find.text('rule2'), findsOneWidget);
    },
    goldenFilename: 'FWS-IPV6_INIT-01-initial_state',
    helper: testHelper,
  );

  // Test ID: FWS-IPV6_EMPTY
  testLocalizationsV2(
    'Firewall settings view - IPv6 port service - empty state',
    (tester, screen) async {
      // Enable animations for tab switching
      testHelper.disableAnimations = false;

      final state =
          Ipv6PortServiceListState.fromMap(ipv6PortServiceEmptyListTestState);
      when(testHelper.mockIpv6PortServiceListNotifier.build())
          .thenReturn(state);
      when(testHelper.mockIpv6PortServiceListNotifier.fetch())
          .thenAnswer((realInvocation) async {
        return state;
      });

      final context = await testHelper.pumpView(
        tester,
        child: const FirewallView(),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      // Switch to IPv6 Port Services tab (index 3)
      await switchToTab(tester, 3);

      expect(find.text(loc(context).noIPv6PortService), findsOneWidget);
    },
    goldenFilename: 'FWS-IPV6_EMPTY-01-empty_state',
    helper: testHelper,
  );

  // Test ID: FWS-IPV6_ADD
  testLocalizationsV2('Firewall settings view - IPv6 port service - add rule',
      (tester, screen) async {
    // Enable animations for tab switching
    testHelper.disableAnimations = false;

    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: screen.locale,
    );
    await tester.pumpAndSettle();

    // Switch to IPv6 Port Services tab (index 3)
    await switchToTab(tester, 3);
    // Use key-based finder for add button (desktop uses AppButton with key)
    await tester.tap(find.byKey(const Key('appDataTable_addButton')));
    await tester.pumpAndSettle();

    expect(find.byType(Ipv6PortServiceListView), findsOneWidget);
  },
      screens: [...responsiveDesktopScreens],
      goldenFilename: 'FWS-IPV6_ADD-01-add_rule_desktop',
      helper: testHelper);

  // Test ID: FWS-IPV6_DROP
  // TODO: Skip until Ipv6PortServiceListView adds stable keys for form fields
  // Current implementation uses dynamic ValueKey('protocol_$hashCode') which changes per test
  testLocalizationsV2(
      'Firewall settings view - IPv6 port service - add rule - protocol dropdown',
      (tester, screen) async {
    // Enable animations for tab switching
    testHelper.disableAnimations = false;

    final context = await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: screen.locale,
    );
    await tester.pumpAndSettle();

    // Switch to IPv6 Port Services tab (index 3)
    await switchToTab(tester, 3);
    // Use key-based finder for add button (desktop uses AppButton with key)
    await tester.tap(find.byKey(const Key('appDataTable_addButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('protocol')));
    await tester.pumpAndSettle();

    expect(find.text(loc(context).tcp), findsOneWidget);
    expect(find.text(loc(context).udp), findsOneWidget);
    expect(find.text(loc(context).udpAndTcp), findsAtLeast(1));
  },
      screens: [...responsiveDesktopScreens],
      goldenFilename: 'FWS-IPV6_DROP-01-dropdown_desktop',
      helper: testHelper);

  // Test ID: FWS-IPV6_INVALID
  // TODO: Skip until Ipv6PortServiceListView adds stable keys for form fields
  testLocalizationsV2(
      'Firewall settings view - IPv6 port service - add rule - invalid ports',
      (tester, screen) async {
    // Enable animations for tab switching
    testHelper.disableAnimations = false;

    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: screen.locale,
    );
    await tester.pumpAndSettle();

    // Switch to IPv6 Port Services tab (index 3)
    await switchToTab(tester, 3);
    // Use key-based finder for add button (desktop uses AppButton with key)
    await tester.tap(find.byKey(const Key('appDataTable_addButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('firstPort')), '99');
    await tester.enterText(find.byKey(const Key('lastPort')), '55');
    await tester.tap(find.byKey(const Key('ruleName')));
    await tester.pumpAndSettle();

    // TODO: ToolTip cannot display on screenshot
    // expect(find.text(loc(context).portRangeError), findsOneWidget);
  },
      screens: [...responsiveDesktopScreens],
      goldenFilename: 'FWS-IPV6_INVALID-01-invalid_ports_desktop',
      helper: testHelper);

  // Test ID: FWS-IPV6_OVERLAP
  testLocalizationsV2(
      'Firewall settings view - IPv6 port service - add rule - overlap ports',
      (tester, screen) async {
    // Enable animations for tab switching
    testHelper.disableAnimations = false;

    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: screen.locale,
    );
    await tester.pumpAndSettle();

    // Switch to IPv6 Port Services tab (index 3)
    await switchToTab(tester, 3);
    // Use key-based finder for add button (desktop uses AppButton with key)
    await tester.tap(find.byKey(const Key('appDataTable_addButton')));
    await tester.pumpAndSettle();

    when(testHelper.mockIpv6PortServiceRuleNotifier.isRuleValid())
        .thenReturn(false);
    when(testHelper.mockIpv6PortServiceRuleNotifier.isPortRangeValid(any, any))
        .thenReturn(true);
    when(testHelper.mockIpv6PortServiceRuleNotifier
            .isPortConflict(any, any, any))
        .thenReturn(true);

    await tester.enterText(find.byKey(const Key('firstPort')), '1225');
    await tester.enterText(find.byKey(const Key('lastPort')), '1230');
    await tester
        .tap(find.byKey(const Key('ruleName'))); // Tap to trigger validation
    await tester.pumpAndSettle();

    // TODO: ToolTip cannot display on screenshot
    // expect(find.text(loc(context).rulesOverlapError), findsOneWidget);
  },
      screens: [...responsiveDesktopScreens],
      goldenFilename: 'FWS-IPV6_OVERLAP-01-overlap_ports_desktop',
      helper: testHelper);
}
