import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/select_device_view.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/_index.dart';
import '../../../../common/test_helper.dart';
import '../../../../mocks/_index.dart';
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
  group('Incredible-WiFi - Wifi list view', () {
    testLocalizations('Incredible-WiFi - Wifi list view',
        (tester, locale) async {
      when(testHelper.mockWiFiListNotifier.build())
          .thenReturn(WiFiState.fromMap(wifiListGuestEnabledTestState));
      when(testHelper.mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        return WiFiState.fromMap(wifiListGuestEnabledTestState);
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ]);

    testLocalizations(
        'Incredible-WiFi - Wifi list view - discard editing modal',
        (tester, locale) async {
      when(testHelper.mockWiFiViewNotifier.build()).thenReturn(
          const WiFiViewState().copyWith(isWifiListViewStateChanged: true));
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final backFinder = find.byIcon(LinksysIcons.arrowBack);
      await tester.tap(backFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit SSID',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.first);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Incredible-WiFi - Wifi list view - edit SSID - empty error',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.first);
      await tester.pumpAndSettle();

      final inputFinder = find.bySemanticsLabel('wifi name');
      await tester.tap(inputFinder.first);
      await tester.enterText(inputFinder.first, '');
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Incredible-WiFi - Wifi list view - edit SSID - surround space error',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.first);
      await tester.pumpAndSettle();

      final inputFinder = find.bySemanticsLabel('wifi name');
      await tester.tap(inputFinder.first);
      await tester.enterText(inputFinder.first, ' asd ');
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Incredible-WiFi - Wifi list view - edit SSID - length error',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.first);
      await tester.pumpAndSettle();

      final inputFinder = find.bySemanticsLabel('wifi name');
      await tester.tap(inputFinder.first);
      await tester.enterText(inputFinder.first,
          'asdasldkjsldkja;lkj;lkjd;lakjdl;akjadjiwijo;ijojwtjiwlrijlkjfklwjlfj');
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit password',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.at(1));
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Incredible-WiFi - Wifi list view - edit password - error state',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.at(1));
      await tester.pumpAndSettle();

      final inputFinder = find.bySemanticsLabel('wifi password');
      // final inputFinder = find.byType(TextField);
      await tester.tap(inputFinder.last);
      await tester.enterText(inputFinder.last, ' 嗨');
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit security mode',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.scrollUntilVisible(editIconFinder.at(2), 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(editIconFinder.at(2));
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit WiFi mode',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.scrollUntilVisible(editIconFinder.at(3), 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(editIconFinder.at(3));
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Incredible-WiFi - Wifi list view - edit WiFi mode with invalid value',
        (tester, locale) async {
      when(testHelper.mockWiFiListNotifier.build())
          .thenReturn(WiFiState.fromMap(wifiListInvalidWirelessModeTestState));

      when(testHelper.mockWiFiListNotifier.fetch(any)).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        return WiFiState.fromMap(wifiListInvalidWirelessModeTestState);
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.scrollUntilVisible(editIconFinder.at(3), 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(editIconFinder.at(3));
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit channel width',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.scrollUntilVisible(editIconFinder.at(4), 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(editIconFinder.at(4));
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Incredible-WiFi - Wifi list view - edit channel width with unavailable value',
        (tester, locale) async {
      when(testHelper.mockWiFiListNotifier.build()).thenReturn(
          WiFiState.fromMap(wifiListUnavailableChannelWidthTestState));

      when(testHelper.mockWiFiListNotifier.fetch(any)).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        return WiFiState.fromMap(wifiListUnavailableChannelWidthTestState);
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      // find wifi card
      final wifiCardFinder = find.byKey(const ValueKey('WiFiCard-5GHz'));
      expect(wifiCardFinder, findsOneWidget);
      final editIconFinder = find.descendant(
          of: wifiCardFinder, matching: find.byIcon(LinksysIcons.edit));
      await tester.scrollUntilVisible(editIconFinder.at(4), 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(editIconFinder.at(4));
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit channel',
        (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.scrollUntilVisible(editIconFinder.at(5), 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(editIconFinder.at(5));
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - save confirm modal',
        (tester, locale) async {
      when(testHelper.mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        final wifiState = WiFiState.fromMap(wifiListTestState);
        return wifiState.copyWith(
            guestWiFi: wifiState.guestWiFi.copyWith(isEnabled: true));
      });

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final saveButtonFinder = find.byType(AppFilledButton);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Incredible-WiFi - Wifi list view - save confirm modal - disable band warning',
        (tester, locale) async {
      when(testHelper.mockWiFiListNotifier.build()).thenReturn(() {
        final wifiState = WiFiState.fromMap(wifiListGuestEnabledTestState);
        final changedMainWiFi =
            List<WiFiItem>.from(wifiState.mainWiFi).map((e) {
          if (e.radioID == WifiRadioBand.radio_24) {
            return e.copyWith(isEnabled: false);
          }
          return e;
        }).toList();
        return wifiState.copyWith(mainWiFi: changedMainWiFi);
      }.call());

      when(testHelper.mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        final wifiState = WiFiState.fromMap(wifiListTestState);

        return wifiState.copyWith(
            guestWiFi: wifiState.guestWiFi.copyWith(isEnabled: true));
      });

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final saveButtonFinder = find.byType(AppFilledButton);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Incredible-WiFi - Wifi list view - save confirm modal - MLO warning',
        (tester, locale) async {
      final wifiState = WiFiState.fromMap(wifiListGuestEnabledTestState);
      when(testHelper.mockWiFiListNotifier.build()).thenReturn(wifiState);

      when(testHelper.mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        final wifiState = WiFiState.fromMap(wifiListTestState);

        return wifiState.copyWith(
            guestWiFi: wifiState.guestWiFi.copyWith(isEnabled: false));
      });
      final radios = Map.fromIterables(
          wifiState.mainWiFi.map((e) => e.radioID), wifiState.mainWiFi);
      when(testHelper.mockWiFiListNotifier.checkingMLOSettingsConflicts(radios,
              isMloEnabled: true))
          .thenReturn(true);

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const WiFiMainView(),
      );

      final saveButtonFinder = find.byType(AppFilledButton);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();
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

  testLocalizations('Incredible-WiFi - Wifi list view - No Guest WiFi',
      (tester, locale) async {
    when(testHelper.mockServiceHelper.isSupportGuestNetwork()).thenReturn(false);
    when(testHelper.mockServiceHelper.isSupportLedMode()).thenReturn(false);
    when(testHelper.mockWiFiListNotifier.build()).thenReturn(
        WiFiState.fromMap(wifiListGuestEnabledTestState).copyWith());
    when(testHelper.mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(Durations.extralong1);
      return WiFiState.fromMap(wifiListGuestEnabledTestState);
    });
    await testHelper.pumpView(
      tester,
      locale: locale,
      child: const WiFiMainView(),
    );
  }, screens: [...responsiveMobileScreens, ...responsiveDesktopScreens]);
}