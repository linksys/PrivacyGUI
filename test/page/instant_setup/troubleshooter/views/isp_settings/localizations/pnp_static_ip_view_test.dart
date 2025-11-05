import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_static_ip_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

import '../../../../../../common/config.dart';
import '../../../../../../common/test_helper.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../test_data/internet_settings_state_data.dart';

void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();

    when(testHelper.mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });

    final mockInternetSettingsState =
        InternetSettingsState.fromMap(jsonDecode(internetSettingsStateData));
    when(testHelper.mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    when(testHelper.mockInternetSettingsNotifier.fetch()).thenAnswer((_) async {
      return mockInternetSettingsState;
    });
  });

  testLocalizations('Troubleshooter - PnP static IP: default',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpStaticIpView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Troubleshooter - PnP static IP: with DNS 2',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpStaticIpView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    final dnsFinder = find.byType(AppTextButton);
    await tester.tap(dnsFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Troubleshooter - PnP static IP: wrong input formats',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpStaticIpView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    // Expand DNS 2 form
    final dnsFinder = find.byType(AppTextButton);
    await tester.tap(dnsFinder);
    await tester.pumpAndSettle();
    // Tap IP address form
    final ipAddressForm = find.byType(AppIPFormField).at(0);
    await tester.tap(ipAddressForm);
    // Input
    final ipAddressTextFormField = find.descendant(
        of: ipAddressForm, matching: find.byType(TextFormField));
    await tester.enterText(ipAddressTextFormField.at(0), '1');
    await tester.pumpAndSettle();
    // Tap subnet mask form
    final subnetMaskForm = find.byType(AppIPFormField).at(1);
    await tester.tap(subnetMaskForm);
    // Input
    final subnetMaskTextFormField = find.descendant(
        of: subnetMaskForm, matching: find.byType(TextFormField));
    await tester.enterText(subnetMaskTextFormField.at(0), '1');
    await tester.pumpAndSettle();
    // Tap gateway form
    final gatewayForm = find.byType(AppIPFormField).at(2);
    await tester.tap(gatewayForm);
    // Input
    final gatewayTextFormField =
        find.descendant(of: gatewayForm, matching: find.byType(TextFormField));
    await tester.enterText(gatewayTextFormField.at(0), '1');
    await tester.pumpAndSettle();
    // Tap DNS 1 form
    final dns1Form = find.byType(AppIPFormField).at(3);
    await tester.tap(dns1Form);
    // Input
    final dns1TextFormField =
        find.descendant(of: dns1Form, matching: find.byType(TextFormField));
    await tester.enterText(dns1TextFormField.at(0), '1');
    await tester.pumpAndSettle();
    // Tap DNS 2 form
    final dns2Form = find.byType(AppIPFormField).at(4);
    await tester.tap(dns2Form);
    await tester.pump(const Duration(seconds: 2));
  }, screens: screens);

  testLocalizations('Troubleshooter - PnP static IP: wrong gateway',
      (tester, locale) async {
    when(testHelper.mockInternetSettingsNotifier.savePnpIpv4(any)).thenAnswer((_) async {
      throw JNAPError(result: errorInvalidGateway, error: 'error');
    });
    await testHelper.pumpShellView(
      tester,
      child: const PnpStaticIpView(),
      locale: locale,
    );

    // Tap IP address form
    final ipAddressForm = find.byType(AppIPFormField, skipOffstage: true).at(0);
    await tester.tap(ipAddressForm);
    // Input
    final ipAddressTextFormField = find.descendant(
        of: ipAddressForm, matching: find.byType(TextFormField));
    await tester.enterText(ipAddressTextFormField.at(0), '192');
    await tester.enterText(ipAddressTextFormField.at(1), '168');
    await tester.enterText(ipAddressTextFormField.at(2), '1');
    await tester.enterText(ipAddressTextFormField.at(3), '1');
    await tester.pumpAndSettle();

    // Tap subnet mask form
    final subnetMaskForm =
        find.byType(AppIPFormField, skipOffstage: true).at(1);
    await tester.tap(subnetMaskForm);
    // Input
    final subnetMaskTextFormField = find.descendant(
        of: subnetMaskForm, matching: find.byType(TextFormField));
    await tester.enterText(subnetMaskTextFormField.at(0), '255');
    await tester.enterText(subnetMaskTextFormField.at(1), '255');
    await tester.enterText(subnetMaskTextFormField.at(2), '255');
    await tester.enterText(subnetMaskTextFormField.at(3), '0');
    await tester.pumpAndSettle();

    // Tap gateway form
    final gatewayForm = find.byType(AppIPFormField, skipOffstage: true).at(2);
    await tester.tap(gatewayForm);
    // Input
    final gatewayTextFormField =
        find.descendant(of: gatewayForm, matching: find.byType(TextFormField));
    await tester.enterText(gatewayTextFormField.at(0), '192');
    await tester.enterText(gatewayTextFormField.at(1), '168');
    await tester.enterText(gatewayTextFormField.at(2), '1');
    await tester.enterText(gatewayTextFormField.at(3), '1');
    await tester.pumpAndSettle();

    // Tap DNS 1 form
    final dns1Form = find.byType(AppIPFormField, skipOffstage: true).at(3);
    await tester.tap(dns1Form);
    // Input
    final dns1TextFormField =
        find.descendant(of: dns1Form, matching: find.byType(TextFormField));
    await tester.enterText(dns1TextFormField.at(0), '8');
    await tester.enterText(dns1TextFormField.at(1), '8');
    await tester.enterText(dns1TextFormField.at(2), '8');
    await tester.enterText(dns1TextFormField.at(3), '8');
    await tester.pumpAndSettle();
    //Tap next
    final nextFinder = find.byType(AppFilledButton);
    await tester.scrollUntilVisible(
      nextFinder,
      10,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();
  }, screens: screens);
}