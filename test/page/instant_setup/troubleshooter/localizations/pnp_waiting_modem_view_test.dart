import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

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

  testLocalizations('Troubleshooter - PnP waiting modem: counting',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpWaitingModemView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 3));
  }, screens: screens);

  testLocalizations(
      'Troubleshooter - PnP waiting modem: plug your modem back in',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpWaitingModemView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
  }, screens: screens);
  testLocalizations('Troubleshooter - PnP waiting modem: wait to start up',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpWaitingModemView(),
      locale: locale,
    );
    await tester.pumpAndSettle();
    final btnFinder = find.byType(AppFilledButton);
    await tester.tap(btnFinder);
    await tester.pump(const Duration(seconds: 3));
  }, screens: screens);

  testLocalizations('Troubleshooter - PnP waiting modem: checking for internet',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpWaitingModemView(),
      locale: locale,
    );
    await tester.pumpAndSettle();
    final btnFinder = find.byType(AppFilledButton);
    await tester.tap(btnFinder);
    await tester.pump(const Duration(seconds: 5));
  }, screens: screens);
}