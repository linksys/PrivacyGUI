import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_rule_view.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_view.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/static_routing_state.dart';

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('Static routing view test - empty state',
      (tester, locale) async {
    final state = StaticRoutingState.fromMap(staticRoutingTestStateEmpty);
    when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
    when(testHelper.mockStaticRoutingNotifier.fetch(forceRemote: any)).thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
      child: const StaticRoutingView(),
    );
  }, screens: screens);
  testLocalizations('Static routing view test - NAT enabled',
      (tester, locale) async {
    final state = StaticRoutingState.fromMap(staticRoutingTestState);
    when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
    when(testHelper.mockStaticRoutingNotifier.fetch(forceRemote: any)).thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
      child: const StaticRoutingView(),
    );
  }, screens: screens);

  testLocalizations('Static routing view test - NAT enabled add rule',
      (tester, locale) async {
    final state = StaticRoutingState.fromMap(staticRoutingTestState);
    when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
    when(testHelper.mockStaticRoutingNotifier.fetch(forceRemote: any)).thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(testHelper.mockStaticRoutingRuleNotifier.build()).thenReturn(
        const StaticRoutingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
      child: const StaticRoutingView(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LinksysIcons.add));
    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);

  testLocalizations(
      'Static routing view test - NAT enabled add rule - interface dropdown',
      (tester, locale) async {
    final state = StaticRoutingState.fromMap(staticRoutingTestState);
    when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
    when(testHelper.mockStaticRoutingNotifier.fetch()).thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(testHelper.mockStaticRoutingRuleNotifier.build()).thenReturn(
        const StaticRoutingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    await testHelper.pumpShellView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
      child: const StaticRoutingView(),
    );

    await tester.tap(find.byIcon(LinksysIcons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppDropdownButton<RoutingSettingInterface>));
    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);

  testLocalizations(
      'Static routing view test - NAT enabled add rule - invalid gateway IP',
      (tester, locale) async {
    final state = StaticRoutingState.fromMap(staticRoutingTestState);
    when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
    when(testHelper.mockStaticRoutingNotifier.fetch()).thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(testHelper.mockStaticRoutingRuleNotifier.build()).thenReturn(
        const StaticRoutingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    await testHelper.pumpShellView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
      child: const StaticRoutingView(),
    );

    await tester.tap(find.byIcon(LinksysIcons.add));
    await tester.pumpAndSettle();

    final ipFormFieldFinder = find.byType(AppIPFormField).last;
    final ipInput = find.descendant(
        of: ipFormFieldFinder, matching: find.byType(TextFormField));

    await tester.enterText(ipInput.at(0), '10');
    await tester.enterText(ipInput.at(1), '10');
    await tester.enterText(ipInput.at(2), '10');
    await tester.enterText(ipInput.at(3), '10');
    await tester.tap(find.byType(AppText).first);

    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);

  testLocalizations('Static routing view test - NAT enabled add rule',
      (tester, locale) async {
    final state = StaticRoutingState.fromMap(staticRoutingTestState);
    when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
    when(testHelper.mockStaticRoutingNotifier.fetch()).thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(testHelper.mockStaticRoutingRuleNotifier.build()).thenReturn(
        const StaticRoutingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    when(testHelper.mockStaticRoutingRuleNotifier.init(any, any, any, any, any))
        .thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
    });
    await testHelper.pumpShellView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
      child: StaticRoutingRuleView(
        args: {'items': state.settings.current.entries.entries},
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations(
      'Static routing view test - NAT enabled add rule - interface dropdown',
      (tester, locale) async {
    final state = StaticRoutingState.fromMap(staticRoutingTestState);
    when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
    when(testHelper.mockStaticRoutingNotifier.fetch()).thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(testHelper.mockStaticRoutingRuleNotifier.build()).thenReturn(
        const StaticRoutingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    when(testHelper.mockStaticRoutingRuleNotifier.init(any, any, any, any, any))
        .thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
    });
    await testHelper.pumpShellView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
      child: StaticRoutingRuleView(
        args: {'items': state.settings.current.entries.entries},
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppDropdownButton<RoutingSettingInterface>));
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations(
      'Static routing view test - NAT enabled add rule - invalid gateway IP',
      (tester, locale) async {
    final state = StaticRoutingState.fromMap(staticRoutingTestState);
    when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
    when(testHelper.mockStaticRoutingNotifier.fetch()).thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(testHelper.mockStaticRoutingRuleNotifier.build()).thenReturn(
        const StaticRoutingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    when(testHelper.mockStaticRoutingRuleNotifier.init(any, any, any, any, any))
        .thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
    });
    await testHelper.pumpShellView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
      child: StaticRoutingRuleView(
        args: {'items': state.settings.current.entries.entries},
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final ipFormFieldFinder = find.byType(AppIPFormField).last;
    final ipInput = find.descendant(
        of: ipFormFieldFinder, matching: find.byType(TextFormField));
    await tester.enterText(ipInput.at(0), '10');
    await tester.enterText(ipInput.at(1), '10');
    await tester.enterText(ipInput.at(2), '10');
    await tester.enterText(ipInput.at(3), '10');
    await tester.tap(find.byType(AppCard).first);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Static routing view test - Dynamic Routing (RIP) enabled',
      (tester, locale) async {
    final state = StaticRoutingState.fromMap(staticRoutingTestState).copyWith(
        settings: Preservable(
            original: const StaticRoutingSettings(
                isNATEnabled: false,
                isDynamicRoutingEnabled: true,
                entries: NamedStaticRouteEntryList(entries: [])),
            current: const StaticRoutingSettings(
                isNATEnabled: false,
                isDynamicRoutingEnabled: true,
                entries: NamedStaticRouteEntryList(entries: []))));
    when(testHelper.mockStaticRoutingNotifier.build()).thenReturn(state);
    when(testHelper.mockStaticRoutingNotifier.fetch()).thenAnswer((_) async {
      Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
      locale: locale,
      child: const StaticRoutingView(),
    );
  }, screens: screens);
}
