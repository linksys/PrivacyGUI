import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';

import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/administration_settings_test_state.dart';

void main() {
  final testHelper = TestHelper();

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
  });

  testLocalizations('Administration settings view - no LAN ports',
      (tester, locale) async {
    when(testHelper.mockAdministrationSettingsNotifier.build()).thenReturn(
        AdministrationSettingsState.fromMap(administrationSettingsTestState)
            .copyWith(canDisAllowLocalMangementWirelessly: false));

    await testHelper.pumpView(
      tester,
      child: const AdministrationSettingsView(),
      locale: locale,
    );
  });
}