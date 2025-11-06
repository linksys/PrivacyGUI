import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/views/select_device_view.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/_index.dart';
import '../../../../test_data/wifi_bundle_test_state.dart';
import '../../../../common/test_helper.dart';
import '../../../../test_data/_index.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
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
      when(testHelper.mockInstantPrivacyNotifier
              .fetch(forceRemote: anyNamed('forceRemote')))
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
      when(testHelper.mockInstantPrivacyNotifier
              .fetch(forceRemote: anyNamed('forceRemote')))
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
      when(testHelper.mockInstantPrivacyNotifier
              .fetch(forceRemote: anyNamed('forceRemote')))
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
          // 'selected': InstantPrivacyState.fromMap(instantPrivacyDenyTestState)
          //     .settings
          //     .denyMacAddresses,
        },
      ),
    );
  }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);
  });

  group('Incredible-WiFi Views', () {
    testLocalizations('Incredible-WiFi - Main View Renders Correctly',
        (tester, locale) async {
      await testHelper.pumpView(
      tester,
      locale: locale,
      child: const WiFiMainView(),
    );
      await tester.pumpAndSettle();

      // Verify that the main view and tabs are rendered
      expect(find.byType(WiFiMainView), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ]);

    testLocalizations(
        'Incredible-WiFi - Editing a setting marks state as dirty',
        (tester, locale) async {
      final settings = WifiBundleSettings.fromMap(
          wifiBundleTestState['settings'] as Map<String, dynamic>);
      final status = WifiBundleStatus.fromMap(
          wifiBundleTestState['status'] as Map<String, dynamic>);

      final dirtySettings = settings.copyWith(
          wifiList: settings.wifiList.copyWith(isSimpleMode: false));
      final dirtyState = WifiBundleState(
        settings: Preservable(original: settings, current: dirtySettings),
        status: status,
      );

      when(testHelper.mockWiFiBundleNotifier.build()).thenReturn(dirtyState);
      when(testHelper.mockWiFiBundleNotifier.state).thenReturn(dirtyState);
      when(testHelper.mockWiFiBundleNotifier.isDirty()).thenReturn(true);

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      await tester.pumpAndSettle();

      // Verify that the save button is enabled
      final saveButtonFinder = find.byType(AppFilledButton);
      expect(saveButtonFinder, findsOneWidget);
      final AppFilledButton button = tester.widget(saveButtonFinder);
      expect(button.onTap, isNotNull);
    });
  });

}
