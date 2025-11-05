import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_pppoe_view.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

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
    when(testHelper.mockInternetSettingsNotifier.fetch()).thenAnswer((_) async {
      return mockInternetSettingsState;
    });
  });

  testLocalizations('Troubleshooter - PnP PPPoE: default',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpPPPOEView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Troubleshooter - PnP PPPoE: with Remove VLAN ID',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpPPPOEView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    final addVLANFinder = find.byType(AppTextButton);
    await tester.tap(addVLANFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations(
      'Troubleshooter - PnP PPPoE: wrong account name or password',
      (tester, locale) async {
    final mockInternetSettingsState =
        InternetSettingsState.fromJson(internetSettingsStateData);
    final mockInternetSettings = mockInternetSettingsState.settings.current;
    final pppoeSetting = mockInternetSettings.ipv4Setting.copyWith(
      ipv4ConnectionType: WanType.pppoe.name,
    );
    when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
        mockInternetSettingsState.copyWith(
            settings: Preservable(
                original: mockInternetSettings,
                current:
                    mockInternetSettings.copyWith(ipv4Setting: pppoeSetting))));
    when(testHelper.mockInternetSettingsNotifier.savePnpIpv4(any)).thenAnswer((_) async {
      throw JNAPError(result: '', error: 'error');
    });
    await testHelper.pumpShellView(
      tester,
      child: const PnpPPPOEView(),
      locale: locale,
    );
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