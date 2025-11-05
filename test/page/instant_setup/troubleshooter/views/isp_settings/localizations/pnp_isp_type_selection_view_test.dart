import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';
import 'package:privacy_gui/route/route_model.dart';

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
        InternetSettingsState.fromJson(internetSettingsStateData);
    when(testHelper.mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
    when(testHelper.mockInternetSettingsNotifier.fetch(forceRemote: true))
        .thenAnswer((_) async {
      return mockInternetSettingsState;
    });
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
    final mockInternetSettingsState =
        InternetSettingsState.fromMap(jsonDecode(internetSettingsStateData2));
    when(testHelper.mockInternetSettingsNotifier.build())
        .thenReturn(mockInternetSettingsState);
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
