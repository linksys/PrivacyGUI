import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/firewall_settings_test_state.dart';
import '../../../../../test_data/ipv6_port_service_list_test_state.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockFirewallNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return FirewallState.fromMap(firewallSettingsTestState);
    });
    when(testHelper.mockIpv6PortServiceListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      return Ipv6PortServiceListState.fromMap(ipv6PortServiceListTestState);
    });
  });
  testLocalizations('Firewall settings view - firewall',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Firewall settings view - VPN passthrough',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: locale,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
  });

  testLocalizations('Firewall settings view - Internet filters',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: locale,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
  });

  testLocalizations('Firewall settings view - IPv6 port service',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: locale,
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBar), const Offset(-200.0, 0.0), 10000.0);
    await tester.tap(find.byType(Tab, skipOffstage: false).at(3));
    await tester.pumpAndSettle();
  });

  testLocalizations('Firewall settings view - IPv6 port service - empty state',
      (tester, locale) async {
    final state = Ipv6PortServiceListState.fromMap(ipv6PortServiceEmptyListTestState);
    when(testHelper.mockIpv6PortServiceListNotifier.build()).thenReturn(state);
    when(testHelper.mockIpv6PortServiceListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      return state;
    });

    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: locale,
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBar), const Offset(-200.0, 0.0), 10000.0);
    await tester.tap(find.byType(Tab, skipOffstage: false).at(3));
    await tester.pumpAndSettle();
  });

  testLocalizations('Firewall settings view - IPv6 port service - add rule',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: locale,
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBar), const Offset(-200.0, 0.0), 10000.0);
    await tester.tap(find.byType(Tab, skipOffstage: false).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LinksysIcons.add));
    await tester.pumpAndSettle();
  }, screens: [...responsiveDesktopScreens]);
  testLocalizations('Firewall settings view - IPv6 port service - add rule',
      (tester, locale) async {
    final state =
        Ipv6PortServiceListState.fromMap(ipv6PortServiceListTestState);
    when(testHelper.mockIpv6PortServiceRuleNotifier.isRuleValid()).thenReturn(true);
    await testHelper.pumpView(
      tester,
      child: Ipv6PortServiceRuleView(
        args: {'items': state.settings.current.rules},
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
  }, screens: [...responsiveMobileScreens]);

  testLocalizations(
      'Firewall settings view - IPv6 port service - add rule - protocol dropdown',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: locale,
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBar), const Offset(-200.0, 0.0), 10000.0);
    await tester.tap(find.byType(Tab, skipOffstage: false).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LinksysIcons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppDropdownButton<String>));
    await tester.pumpAndSettle();
  }, screens: [...responsiveDesktopScreens]);
  testLocalizations(
      'Firewall settings view - IPv6 port service - add rule - protocol dropdown',
      (tester, locale) async {
    final state =
        Ipv6PortServiceListState.fromMap(ipv6PortServiceListTestState);
    when(testHelper.mockIpv6PortServiceRuleNotifier.isRuleValid()).thenReturn(true);
    await testHelper.pumpView(
      tester,
      child: Ipv6PortServiceRuleView(
        args: {'items': state.current.rules},
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppDropdownButton<String>));
    await tester.pumpAndSettle();
  }, screens: [...responsiveMobileScreens]);

  testLocalizations(
      'Firewall settings view - IPv6 port service - add rule - invalid ports',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const FirewallView(),
      locale: locale,
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TabBar), const Offset(-200.0, 0.0), 10000.0);
    await tester.tap(find.byType(Tab, skipOffstage: false).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LinksysIcons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppDropdownButton<String>));
    await tester.pumpAndSettle();
  }, screens: [...responsiveDesktopScreens]);
  testLocalizations(
      'Firewall settings view - IPv6 port service - add rule - invalid ports',
      (tester, locale) async {
    final state =
        Ipv6PortServiceListState.fromMap(ipv6PortServiceListTestState);
    when(testHelper.mockIpv6PortServiceRuleNotifier.isRuleValid()).thenReturn(true);
    await testHelper.pumpView(
      tester,
      child: Ipv6PortServiceRuleView(
        args: {'items': state.current.rules},
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();

    final textInputFind = find.byType(AppTextField);
    await tester.enterText(textInputFind.at(1), '99');
    await tester.enterText(textInputFind.at(2), '55');
    await tester.tap(textInputFind.first);
    await tester.pumpAndSettle();
  }, screens: [...responsiveMobileScreens]);
}
