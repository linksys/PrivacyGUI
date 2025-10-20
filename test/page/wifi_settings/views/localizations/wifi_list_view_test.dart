import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_main_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/_index.dart';
import '../../../../common/di.dart';
import '../../../../mocks/_index.dart';
import '../../../../mocks/wifi_view_notifier_mocks.dart';
import '../../../../test_data/_index.dart';

void main() {
  late WiFiViewNotifier mockWiFiViewNotifier;
  late MockWifiListNotifier mockWiFiListNotifier;
  late MockWifiAdvancedSettingsNotifier mockWiFiAdvancedSettingsNotifier;
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;

  mockDependencyRegister();

  setUp(() {
    mockWiFiViewNotifier = MockWiFiViewNotifier();
    mockWiFiListNotifier = MockWifiListNotifier();
    mockWiFiAdvancedSettingsNotifier = MockWifiAdvancedSettingsNotifier();
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();

    // Default state for most tests (Advanced Mode)
    when(mockWiFiListNotifier.build())
        .thenReturn(WiFiState.fromMap(wifiListAdvancedModeTestState));
    when(mockWiFiListNotifier.fetch(any)).thenAnswer((_) async {
      await Future.delayed(Durations.extralong1);
      return WiFiState.fromMap(wifiListAdvancedModeTestState);
    });

    when(mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(mockWiFiAdvancedSettingsNotifier.fetch(any)).thenAnswer((_) async {
      await Future.delayed(Durations.extralong1);
      return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState);
    });

    when(mockWiFiViewNotifier.build()).thenReturn(const WiFiViewState());

    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockInstantPrivacyNotifier.fetch(fetchRemote: anyNamed('fetchRemote')))
        .thenAnswer((_) async {
      await Future.delayed(Durations.extralong1);
      return InstantPrivacyState.fromMap(instantPrivacyTestState);
    });
  });

  group('Incredible-WiFi - Wifi list view - Simple Mode', () {
    testLocalizations('Incredible-WiFi - Wifi list view - simple mode',
        (tester, locale) async {
      when(mockWiFiListNotifier.build())
          .thenReturn(WiFiState.fromMap(wifiListTestState));
      final widget = testableSingleRoute(
        overrides: [
          wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
          wifiListProvider.overrideWith(() => mockWiFiListNotifier),
          wifiAdvancedProvider
              .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
        ],
        locale: locale,
        child: const WiFiMainView(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
    ]);

    testLocalizations(
        'Incredible-WiFi - Wifi list view - simple mode - enable guest wifi',
        (tester, locale) async {
      when(mockWiFiListNotifier.build())
          .thenReturn(WiFiState.fromMap(wifiListGuestEnabledTestState));
      final widget = testableSingleRoute(
        overrides: [
          wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
          wifiListProvider.overrideWith(() => mockWiFiListNotifier),
          wifiAdvancedProvider
              .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
        ],
        locale: locale,
        child: const WiFiMainView(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
    ]);
  });

  // group('Incredible-WiFi - Wifi list view - Advanced Mode', () {
  //   testLocalizations('Incredible-WiFi - Wifi list view - advanced mode',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - advanced mode - enable guest wifi',
  //       (tester, locale) async {
  //     final guestEnabledState =
  //         WiFiState.fromMap(wifiListAdvancedModeTestState);
  //     when(mockWiFiListNotifier.build()).thenReturn(guestEnabledState.copyWith(
  //         guestWiFi: guestEnabledState.guestWiFi.copyWith(isEnabled: true)));
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - discard editing modal',
  //       (tester, locale) async {
  //     when(mockWiFiViewNotifier.build()).thenReturn(
  //         WiFiViewState().copyWith(isWifiListViewStateChanged: true));
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();

  //     final backFinder = find.byIcon(LinksysIcons.arrowBack);
  //     await tester.tap(backFinder);
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations('Incredible-WiFi - Wifi list view - edit SSID',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.tap(editIconFinder.first);
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - edit SSID - empty error',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.tap(editIconFinder.first);
  //     await tester.pumpAndSettle();

  //     final inputFinder = find.bySemanticsLabel('wifi name');
  //     await tester.tap(inputFinder.first);
  //     await tester.enterText(inputFinder.first, '');
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - edit SSID - surround space error',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.tap(editIconFinder.first);
  //     await tester.pumpAndSettle();

  //     final inputFinder = find.bySemanticsLabel('wifi name');
  //     await tester.tap(inputFinder.first);
  //     await tester.enterText(inputFinder.first, ' surround space error ');
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - edit SSID - length error',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.tap(editIconFinder.first);
  //     await tester.pumpAndSettle();

  //     final inputFinder = find.bySemanticsLabel('wifi name');
  //     await tester.tap(inputFinder.first);
  //     await tester.enterText(inputFinder.first,
  //         'asdasldkjsldkja;lkj;lkjd;lakjdl;akjadjiwijo;ijojwtjiwlrijlkjfklwjlfj');
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations('Incredible-WiFi - Wifi list view - edit password',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.tap(editIconFinder.at(1));
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - edit password - error state',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.tap(editIconFinder.at(1));
  //     await tester.pumpAndSettle();

  //     final inputFinder = find.bySemanticsLabel('wifi password');
  //     // final inputFinder = find.byType(TextField);
  //     await tester.tap(inputFinder.last);
  //     await tester.enterText(inputFinder.last, ' 嗨');
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations('Incredible-WiFi - Wifi list view - edit security mode',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.tap(editIconFinder.at(2));
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations('Incredible-WiFi - Wifi list view - edit WiFi mode',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.scrollUntilVisible(editIconFinder.at(3), 100,
  //         scrollable: find.byType(Scrollable).last);
  //     await tester.tap(editIconFinder.at(3));
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - edit WiFi mode with invalid value',
  //       (tester, locale) async {
  //     when(mockWiFiListNotifier.build())
  //         .thenReturn(WiFiState.fromMap(wifiListInvalidWirelessModeTestState));

  //     when(mockWiFiListNotifier.fetch(any)).thenAnswer((realInvocation) async {
  //       await Future.delayed(Durations.extralong1);
  //       return WiFiState.fromMap(wifiListInvalidWirelessModeTestState);
  //     });
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.scrollUntilVisible(editIconFinder.at(3), 100,
  //         scrollable: find.byType(Scrollable).last);
  //     await tester.tap(editIconFinder.at(3));
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations('Incredible-WiFi - Wifi list view - edit channel width',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.scrollUntilVisible(editIconFinder.at(4), 100,
  //         scrollable: find.byType(Scrollable).last);
  //     await tester.tap(editIconFinder.at(4));
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - edit channel width with unavailable value',
  //       (tester, locale) async {
  //     when(mockWiFiListNotifier.build()).thenReturn(
  //         WiFiState.fromMap(wifiListUnavailableChannelWidthTestState));

  //     when(mockWiFiListNotifier.fetch(any)).thenAnswer((realInvocation) async {
  //       await Future.delayed(Durations.extralong1);
  //       return WiFiState.fromMap(wifiListUnavailableChannelWidthTestState);
  //     });
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     // find wifi card
  //     final wifiCardFinder = find.byKey(ValueKey('WiFiCard-5GHz'));
  //     expect(wifiCardFinder, findsOneWidget);
  //     final editIconFinder = find.descendant(
  //         of: wifiCardFinder, matching: find.byIcon(LinksysIcons.edit));
  //     await tester.scrollUntilVisible(editIconFinder.at(4), 100,
  //         scrollable: find.byType(Scrollable).last);
  //     await tester.tap(editIconFinder.at(4));
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations('Incredible-WiFi - Wifi list view - edit channel',
  //       (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();
  //     final editIconFinder = find.byIcon(LinksysIcons.edit);
  //     await tester.tap(editIconFinder.at(5));
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations('Incredible-WiFi - Wifi list view - save confirm modal',
  //       (tester, locale) async {
  //     when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
  //       await Future.delayed(Durations.extralong1);
  //       final wifiState = WiFiState.fromMap(wifiListTestState);
  //       return wifiState.copyWith(
  //           guestWiFi: wifiState.guestWiFi.copyWith(isEnabled: true));
  //     });

  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();

  //     final saveButtonFinder = find.byType(AppFilledButton);
  //     await tester.tap(saveButtonFinder);
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - save confirm modal - disable band warning',
  //       (tester, locale) async {
  //     when(mockWiFiListNotifier.build()).thenReturn(() {
  //       final wifiState = WiFiState.fromMap(wifiListGuestEnabledTestState);
  //       final changedMainWiFi =
  //           List<WiFiItem>.from(wifiState.mainWiFi).map((e) {
  //         if (e.radioID == WifiRadioBand.radio_24) {
  //           return e.copyWith(isEnabled: false);
  //         }
  //         return e;
  //       }).toList();
  //       return wifiState.copyWith(mainWiFi: changedMainWiFi);
  //     }.call());

  //     when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
  //       await Future.delayed(Durations.extralong1);
  //       final wifiState = WiFiState.fromMap(wifiListTestState);

  //       return wifiState.copyWith(
  //           guestWiFi: wifiState.guestWiFi.copyWith(isEnabled: true));
  //     });

  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();

  //     final saveButtonFinder = find.byType(AppFilledButton);
  //     await tester.tap(saveButtonFinder);
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);

  //   testLocalizations(
  //       'Incredible-WiFi - Wifi list view - save confirm modal - MLO warning',
  //       (tester, locale) async {
  //     final wifiState = WiFiState.fromMap(wifiListGuestEnabledTestState);
  //     when(mockWiFiListNotifier.build()).thenReturn(wifiState);

  //     when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
  //       await Future.delayed(Durations.extralong1);
  //       final wifiState = WiFiState.fromMap(wifiListTestState);

  //       return wifiState.copyWith(
  //           guestWiFi: wifiState.guestWiFi.copyWith(isEnabled: false));
  //     });
  //     final radios = Map.fromIterables(
  //         wifiState.mainWiFi.map((e) => e.radioID), wifiState.mainWiFi);
  //     when(mockWiFiListNotifier.checkingMLOSettingsConflicts(radios,
  //             isMloEnabled: true))
  //         .thenReturn(true);

  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();

  //     final saveButtonFinder = find.byType(AppFilledButton);
  //     await tester.tap(saveButtonFinder);
  //     await tester.pumpAndSettle();
  //   }, screens: [
  //     ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //     ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList(),
  //   ]);
  // });
}
