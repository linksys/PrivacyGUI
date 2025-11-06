import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/providers/preservable.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/administration_settings_test_state.dart';

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  tearDown(() {
  });

  testLocalizations('Administration settings view', (tester, locale) async {
    when(testHelper.mockAdministrationSettingsNotifier.build()).thenReturn(
        AdministrationSettingsState.fromMap(administrationSettingsTestState));

    await testHelper.pumpView(
      tester,
      child: const AdministrationSettingsView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Administration settings view - no LAN ports',
      (tester, locale) async {
    final state =
        AdministrationSettingsState.fromMap(administrationSettingsTestState);
    final settings =
        state.current.copyWith(canDisAllowLocalMangementWirelessly: false);
    when(testHelper.mockAdministrationSettingsNotifier.build()).thenReturn(
        state.copyWith(
            settings: Preservable(original: settings, current: settings)));

    await testHelper.pumpView(
      tester,
      child: const AdministrationSettingsView(),
      locale: locale,
    );
  }, screens: screens);
}
