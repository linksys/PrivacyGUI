import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';

void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
    when(testHelper.mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
  });

  testLocalizations('Troubleshooter - PnP unplug modem',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpUnplugModemView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Troubleshooter - PnP unplug modem: show tips',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpUnplugModemView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    final tipFinder = find.byType(TextButton);
    await tester.tap(tipFinder);
    await tester.pumpAndSettle();
  }, screens: screens);
}