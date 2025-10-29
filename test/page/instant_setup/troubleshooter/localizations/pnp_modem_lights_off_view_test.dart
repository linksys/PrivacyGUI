import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_modem_lights_off_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/device_info_test_data.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';

void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
    when(testHelper.mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: true));
    when(testHelper.mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
  });

  testLocalizations('Troubleshooter - PnP modem lights off',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpModemLightsOffView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Troubleshooter - PnP modem lights off: show tips',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpModemLightsOffView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    final tipFinder = find.byType(TextButton);
    await tester.tap(tipFinder);
    await tester.pumpAndSettle();
  }, screens: screens);
}