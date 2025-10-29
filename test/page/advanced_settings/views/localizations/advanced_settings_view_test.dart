import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/advanced_settings_view.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/test_helper.dart';
import '../../../../test_data/dashboard_home_test_state.dart';

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('AdvancedSettings - init', (tester, locale) async {
    when(testHelper.mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeStateData));
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      locale: locale,
      child: const AdvancedSettingsView(),
    );
  }, screens: screens);

  testLocalizations('AdvancedSettings - birdge mode', (tester, locale) async {
    when(testHelper.mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeStateDataInBridge));
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      locale: locale,
      child: const AdvancedSettingsView(),
    );
  }, screens: screens);
}
