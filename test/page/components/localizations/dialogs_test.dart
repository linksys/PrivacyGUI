import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/wifi_advanced_settings_test_state.dart';
import '../../../test_data/wifi_list_test_state.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('Dialog - Router Not Found', (tester, locale) async {
    // Wifi main view notifier
    when(testHelper.mockWiFiViewNotifier.build()).thenReturn(WiFiViewState());
    // Wifi list view notifier
    when(testHelper.mockWiFiListNotifier.build()).thenReturn(
      WiFiState.fromMap(wifiListTestState),
    );
    when(testHelper.mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(Durations.extralong1);
      return WiFiState.fromMap(wifiListTestState);
    });
    // Wifi advanced settings view notifier
    when(testHelper.mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
      WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState).copyWith(
        isMLOEnabled: false,
        isDFSEnabled: false,
      ),
    );
    when(testHelper.mockWiFiAdvancedSettingsNotifier.fetch()).thenAnswer(
      (realInvocation) async {
        return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState);
      },
    );
    when(testHelper.mockWiFiAdvancedSettingsNotifier.save()).thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 1));
      throw JNAPSideEffectError();
    });

    await testHelper.pumpView(
      tester,
      child: const WiFiMainView(),
      locale: locale,
    );
    // switch to advanced settings
    final tabFinder = find.byType(Tab);
    await tester.tap(tabFinder.at(1));
    await tester.pumpAndSettle();
    // Tap save button
    final saveButtonFinder = find.byType(AppFilledButton);
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Dialog - You have unsaved changes',
      (tester, locale) async {
    // Wifi main view notifier
    when(testHelper.mockWiFiViewNotifier.build()).thenReturn(
      WiFiViewState(isWifiAdvancedSettingsViewStateChanged: true),
    );
    // Wifi list view notifier
    when(testHelper.mockWiFiListNotifier.build())
        .thenReturn(WiFiState.fromMap(wifiListTestState));
    when(testHelper.mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(Durations.extralong1);
      return WiFiState.fromMap(wifiListTestState);
    });
    // Wifi advanced settings view notifier
    when(testHelper.mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(testHelper.mockWiFiAdvancedSettingsNotifier.fetch())
        .thenAnswer((realInvocation) async {
      return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState);
    });

    await testHelper.pumpView(
      tester,
      child: const WiFiMainView(),
      locale: locale,
    );
    // Switch to advanced settings
    final tabFinder = find.byType(Tab);
    await tester.tap(tabFinder.at(1));
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 1));
    // Tap back button
    final backButtonFinder = find.byType(AppIconButton);
    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();
  });
}