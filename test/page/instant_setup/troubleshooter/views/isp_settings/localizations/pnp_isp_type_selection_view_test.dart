import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../../common/config.dart';
import '../../../../../../common/test_helper.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../test_data/device_info_test_data.dart';

void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();

    when(testHelper.mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: true));
  });

  testLocalizations('Troubleshooter - PnP ISP type selection: default',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpIspTypeSelectionView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Troubleshooter - PnP ISP type selection: DHCP Alert',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpIspTypeSelectionView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    final dhcpFinder = find.byKey(const ValueKey('dhcp'));
    await tester.tap(dhcpFinder);
    await tester.pumpAndSettle();
  }, screens: screens);
}