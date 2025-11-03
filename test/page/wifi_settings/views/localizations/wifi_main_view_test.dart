import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/views/select_device_view.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/_index.dart';
import '../../../../common/test_helper.dart';
import '../../../../test_data/_index.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockWiFiListNotifier.fetch(any)).thenAnswer((realInvocation) async {
      await Future.delayed(Durations.extralong1);
      return WiFiState.fromMap(wifiListTestState);
    });
    when(testHelper.mockWiFiAdvancedSettingsNotifier.fetch(any))
        .thenAnswer((realInvocation) async {
      await Future.delayed(Durations.extralong1);
      return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState);
    });
    when(testHelper.mockInstantPrivacyNotifier.fetch(fetchRemote: anyNamed('fetchRemote')))
        .thenAnswer((_) async {
      await Future.delayed(Durations.extralong1);
      return InstantPrivacyState.fromMap(instantPrivacyTestState);
    });
  });

  group('Incredible-WiFi - WiFi Advanced settings view', () {
    testLocalizations('Incredible-WiFi - Advanced settings view',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(1));
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ]);

    testLocalizations('Incredible-WiFi - Advanced settings view - MLO warning',
        (tester, locale) async {
      final wifiState = WiFiState.fromMap(wifiListGuestEnabledTestState);
      when(testHelper.mockWiFiListNotifier.build()).thenReturn(wifiState);

      final radios = Map.fromIterables(
          wifiState.mainWiFi.map((e) => e.radioID), wifiState.mainWiFi);
      when(testHelper.mockWiFiListNotifier.checkingMLOSettingsConflicts(radios))
          .thenReturn(true);

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(1));
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ]);

    testLocalizations(
        'Incredible-WiFi - Advanced settings view - DFS warning modal',
        (tester, locale) async {
      when(testHelper.mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
          WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));

      when(testHelper.mockWiFiAdvancedSettingsNotifier.fetch())
          .thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState)
            .copyWith(isDFSEnabled: false);
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.last);
      await tester.pumpAndSettle();

      final saveButtonFinder = find.byType(AppFilledButton);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();
    });
  });

  group('Incredible-WiFi - MAC Filtering view', () {
    testLocalizations('Incredible-WiFi - MAC Filtering view',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.last);
      await tester.pumpAndSettle();
    }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

    testLocalizations('Incredible-WiFi - MAC Filtering view - enabled',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.last);
      await tester.pumpAndSettle();
    }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

    testLocalizations('Incredible-WiFi - MAC Filtering view - turn on alert',
        (tester, locale) async {
      when(testHelper.mockInstantPrivacyNotifier.build())
          .thenReturn(InstantPrivacyState.fromMap(instantPrivacyDenyTestState));
      when(testHelper.mockInstantPrivacyNotifier.fetch(
              fetchRemote: anyNamed('fetchRemote')))
          .thenAnswer((_) {
        return Future.delayed(Durations.extralong1, () {
          return InstantPrivacyState.fromMap(instantPrivacyTestState);
        });
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppFilledButton));
      await tester.pumpAndSettle();
    }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

    testLocalizations('Incredible-WiFi - MAC Filtering view - turn off alert',
        (tester, locale) async {
      when(testHelper.mockInstantPrivacyNotifier.fetch(
              fetchRemote: anyNamed('fetchRemote')))
          .thenAnswer((_) {
        return Future.delayed(Durations.extralong1, () {
          return InstantPrivacyState.fromMap(instantPrivacyDenyTestState);
        });
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppFilledButton));
      await tester.pumpAndSettle();
    }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

    testLocalizations(
        'Incredible-WiFi - MAC Filtering view - Instant Privacy disable warning',
        (tester, locale) async {
      when(testHelper.mockInstantPrivacyNotifier.build()).thenReturn(
          InstantPrivacyState.fromMap(instantPrivacyEnabledTestState));
      when(testHelper.mockInstantPrivacyNotifier.fetch(
              fetchRemote: anyNamed('fetchRemote')))
          .thenAnswer((_) async {
        await Future.delayed(Durations.extralong1);
        return InstantPrivacyState.fromMap(instantPrivacyEnabledTestState);
      });

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.last);
      await tester.pumpAndSettle();
    }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);
  });

  testLocalizations('Incredible-WiFi - MAC Filtering Devices view',
      (tester, locale) async {
    when(testHelper.mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyDenyTestState));

    await testHelper.pumpView(
      tester,
      locale: locale,
      child: const FilteredDevicesView(),
    );
  }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

  testLocalizations(
      'Incredible-WiFi - MAC Filtering Devices view - Manual add MAC address',
      (tester, locale) async {
    when(testHelper.mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyDenyTestState));

    await testHelper.pumpView(
      tester,
      locale: locale,
      child: const FilteredDevicesView(),
    );

    await tester.tap(find.byIcon(LinksysIcons.add).last);
    await tester.pumpAndSettle();
  }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

  testLocalizations(
      'Incredible-WiFi - MAC Filtering Devices view - Select devices',
      (tester, locale) async {
    when(testHelper.mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyDenyTestState));

    await testHelper.pumpView(
      tester,
      locale: locale,
      child: SelectDeviceView(
        args: {
          'type': 'mac',
          'selected': InstantPrivacyState.fromMap(instantPrivacyDenyTestState)
              .settings
              .denyMacAddresses,
        },
      ),
    );
  }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);

}