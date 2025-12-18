import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_main_view.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/_index.dart';
import '../../../common/test_helper.dart';
import '../../../test_data/wifi_bundle_test_state.dart';

void main() {
  final testHelper = TestHelper();
  late WifiBundleState initialState;

  setUp(() {
    testHelper.setup();
    final settings = WifiBundleSettings.fromMap(
        wifiBundleTestState['settings'] as Map<String, dynamic>);
    final status = WifiBundleStatus.fromMap(
        wifiBundleTestState['status'] as Map<String, dynamic>);
    initialState = WifiBundleState(
      settings: Preservable(original: settings, current: settings),
      status: status,
    );
    when(testHelper.mockWiFiBundleNotifier.build()).thenReturn(initialState);
    when(testHelper.mockWiFiBundleNotifier.state).thenReturn(initialState);
    when(testHelper.mockWiFiBundleNotifier.isDirty()).thenReturn(false);
  });

  testLocalizations('Dialog - Router Not Found', (tester, locale) async {
    when(testHelper.mockWiFiBundleNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      throw JNAPSideEffectError();
    });

    await testHelper.pumpView(
      tester,
      child: const WiFiMainView(),
      locale: locale,
    );

    // Simulate a change to enable the save button
    final dirtyState = initialState.copyWith(
        settings: initialState.settings.update(initialState.settings.current
            .copyWith(
                advanced: initialState.settings.current.advanced
                    .copyWith(isIptvEnabled: true))));
    when(testHelper.mockWiFiBundleNotifier.isDirty()).thenReturn(true);
    when(testHelper.mockWiFiBundleNotifier.state).thenReturn(dirtyState);
    await tester.pump();

    // Tap save button
    final saveButtonFinder = find.byType(AppButton);
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Dialog - You have unsaved changes',
      (tester, locale) async {
    final settings = WifiBundleSettings.fromMap(
        wifiBundleTestState['settings'] as Map<String, dynamic>);
    final status = WifiBundleStatus.fromMap(
        wifiBundleTestState['status'] as Map<String, dynamic>);
    final dirtySettings = settings.copyWith(
        advanced: settings.advanced.copyWith(isIptvEnabled: true));
    final dirtyState = WifiBundleState(
      settings: Preservable(original: settings, current: dirtySettings),
      status: status,
    );

    when(testHelper.mockWiFiBundleNotifier.isDirty()).thenReturn(true);
    when(testHelper.mockWiFiBundleNotifier.state).thenReturn(dirtyState);

    await testHelper.pumpView(
      tester,
      child: const WiFiMainView(),
      locale: locale,
    );
    await tester.pumpAndSettle();

    // Tap back button
    final backButtonFinder = find.byType(AppIconButton);
    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();
  });
}
