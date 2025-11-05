import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart';
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

  testLocalizations('Troubleshooter - PnP no internet connection: no SSID',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpNoInternetConnectionView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Troubleshooter - PnP no internet connection: has SSID',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpNoInternetConnectionView(
        args: {'ssid': 'AwesomeSSID'},
      ),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations(
      'Troubleshooter - PnP no internet connection: has SSID and need help',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpNoInternetConnectionView(
        args: {'ssid': 'AwesomeSSID'},
      ),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
  }, screens: screens);
}