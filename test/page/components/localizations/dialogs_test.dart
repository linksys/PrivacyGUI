import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/_index.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/wifi_view_notifier_mocks.dart';
import '../../../test_data/_index.dart';

void main() {
  setUp(() {});

  testLocalizations('Dialog - Router Not Found', (tester, locale) async {
    // Wifi main view notifier
    final mockWiFiViewNotifier = MockWiFiViewNotifier();
    when(mockWiFiViewNotifier.build()).thenReturn(WiFiViewState());
    // Wifi list view notifier
    final mockWiFiListNotifier = MockWifiListNotifier();
    when(mockWiFiListNotifier.build()).thenReturn(
      WiFiState.fromMap(wifiListTestState),
    );
    when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(Durations.extralong1);
      return WiFiState.fromMap(wifiListTestState);
    });
    // Wifi advanced settings view notifier
    final mockWiFiAdvancedSettingsNotifier = MockWifiAdvancedSettingsNotifier();
    when(mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
      WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState).copyWith(
        isMLOEnabled: false,
        isDFSEnabled: false,
      ),
    );
    when(mockWiFiAdvancedSettingsNotifier.fetch()).thenAnswer(
      (realInvocation) async {
        return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState);
      },
    );
    when(mockWiFiAdvancedSettingsNotifier.save()).thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 1));
      throw JNAPSideEffectError();
    });

    final widget = testableSingleRoute(
      overrides: [
        wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
        wifiListProvider.overrideWith(() => mockWiFiListNotifier),
        wifiAdvancedProvider
            .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
      ],
      locale: locale,
      child: const WiFiMainView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    // switch to advanced settings
    final tabFinder = find.byType(Tab);
    await tester.tap(tabFinder.last);
    await tester.pumpAndSettle();
    // Tap save button
    final saveButtonFinder = find.byType(AppFilledButton);
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Dialog - You have unsaved changes',
      (tester, locale) async {
    // Wifi main view notifier
    final mockWiFiViewNotifier = MockWiFiViewNotifier();
    when(mockWiFiViewNotifier.build()).thenReturn(
      WiFiViewState(isWifiAdvancedSettingsViewStateChanged: true),
    );
    // Wifi list view notifier
    final mockWiFiListNotifier = MockWifiListNotifier();
    when(mockWiFiListNotifier.build())
        .thenReturn(WiFiState.fromMap(wifiListTestState));
    when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(Durations.extralong1);
      return WiFiState.fromMap(wifiListTestState);
    });
    // Wifi advanced settings view notifier
    final mockWiFiAdvancedSettingsNotifier = MockWifiAdvancedSettingsNotifier();
    when(mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(mockWiFiAdvancedSettingsNotifier.fetch())
        .thenAnswer((realInvocation) async {
      return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState);
    });

    final widget = testableSingleRoute(
      overrides: [
        wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
        wifiListProvider.overrideWith(() => mockWiFiListNotifier),
        wifiAdvancedProvider
            .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
      ],
      locale: locale,
      child: const WiFiMainView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    // Switch to advanced settings
    final tabFinder = find.byType(Tab);
    await tester.tap(tabFinder.last);
    await tester.pumpAndSettle();
    // Tap back button
    final backButtonFinder = find.byType(AppIconButton);
    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();
  });
}
