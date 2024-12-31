import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/_index.dart';
import '../../../../mocks/_index.dart';
import '../../../../mocks/wifi_view_notifier_mocks.dart';
import '../../../../test_data/_index.dart';

void main() {
  late WiFiViewNotifier mockWiFiViewNotifier;
  late WifiListNotifier mockWiFiListNotifier;
  late WifiAdvancedSettingsNotifier mockWiFiAdvancedSettingsNotifier;

  setUp(() {
    mockWiFiViewNotifier = MockWiFiViewNotifier();
    mockWiFiListNotifier = MockWifiListNotifier();
    mockWiFiAdvancedSettingsNotifier = MockWifiAdvancedSettingsNotifier();

    when(mockWiFiListNotifier.build())
        .thenReturn(WiFiState.fromMap(wifiListTestState));

    when(mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(mockWiFiViewNotifier.build()).thenReturn(WiFiViewState());

    when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(Durations.extralong1);
      return WiFiState.fromMap(wifiListTestState);
    });

    when(mockWiFiAdvancedSettingsNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(Durations.extralong1);
      return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState);
    });
  });
  group('Incredible-WiFi - Wifi list view', () {
    testLocalizations('Incredible-WiFi - Wifi list view',
        (tester, locale) async {
      when(mockWiFiListNotifier.build())
          .thenReturn(WiFiState.fromMap(wifiListGuestEnabledTestState));
      when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        return WiFiState.fromMap(wifiListGuestEnabledTestState);
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
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ]);

    testLocalizations('Incredible-WiFi - Wifi list view - discard editing modal',
        (tester, locale) async {
      when(mockWiFiViewNotifier.build()).thenReturn(
          WiFiViewState().copyWith(isWifiListViewStateChanged: true));
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

      final backFinder = find.byIcon(LinksysIcons.arrowBack);
      await tester.tap(backFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit SSID', (tester, locale) async {
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.first);
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit SSID - empty error',
        (tester, locale) async {
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.first);
      await tester.pumpAndSettle();

      final inputFinder = find.bySemanticsLabel('wifi name');
      await tester.tap(inputFinder.first);
      await tester.enterText(inputFinder.first, '');
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit SSID - surround space error',
        (tester, locale) async {
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.first);
      await tester.pumpAndSettle();

      final inputFinder = find.bySemanticsLabel('wifi name');
      await tester.tap(inputFinder.first);
      await tester.enterText(inputFinder.first, ' asd ');
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit SSID - length error',
        (tester, locale) async {
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.first);
      await tester.pumpAndSettle();

      final inputFinder = find.bySemanticsLabel('wifi name');
      await tester.tap(inputFinder.first);
      await tester.enterText(inputFinder.first, 'asdasldkjsldkja;lkj;lkjd;lakjdl;akjadjiwijo;ijojwtjiwlrijlkjfklwjlfj');
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit password',
        (tester, locale) async {
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.at(1));
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit password - error state',
        (tester, locale) async {
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.at(2));
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit WiFi mode',
        (tester, locale) async {
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.at(3));
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit channel width',
        (tester, locale) async {
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.at(4));
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - edit channel', (tester, locale) async {
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.at(5));
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - save confirm modal',
        (tester, locale) async {
      when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        final wifiState = WiFiState.fromMap(wifiListTestState);
        return wifiState.copyWith(
            guestWiFi: wifiState.guestWiFi.copyWith(isEnabled: true));
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

      final saveButtonFinder = find.byType(AppFilledButton);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Incredible-WiFi - Wifi list view - save confirm modal - disable band warning',
        (tester, locale) async {
      when(mockWiFiListNotifier.build()).thenReturn(() {
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

      when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        final wifiState = WiFiState.fromMap(wifiListTestState);

        return wifiState.copyWith(
            guestWiFi: wifiState.guestWiFi.copyWith(isEnabled: true));
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

      final saveButtonFinder = find.byType(AppFilledButton);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations('Incredible-WiFi - Wifi list view - save confirm modal - MLO warning',
        (tester, locale) async {
      final wifiState = WiFiState.fromMap(wifiListGuestEnabledTestState);
      when(mockWiFiListNotifier.build()).thenReturn(wifiState);

      when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        final wifiState = WiFiState.fromMap(wifiListTestState);

        return wifiState.copyWith(
            guestWiFi: wifiState.guestWiFi.copyWith(isEnabled: false));
      });
      final radios = Map.fromIterables(
          wifiState.mainWiFi.map((e) => e.radioID), wifiState.mainWiFi);
      when(mockWiFiListNotifier.checkingMLOSettingsConflicts(radios,
              isMloEnabled: true))
          .thenReturn(true);

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

      final saveButtonFinder = find.byType(AppFilledButton);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();
    });
  });

  group('Incredible-WiFi - WiFi Advanced settings view', () {
    testLocalizations('Incredible-WiFi - Advanced settings view',
        (tester, locale) async {
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

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.last);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ]);

    testLocalizations('Incredible-WiFi - Advanced settings view - MLO warning',
        (tester, locale) async {
      final wifiState = WiFiState.fromMap(wifiListGuestEnabledTestState);
      when(mockWiFiListNotifier.build()).thenReturn(wifiState);

      final radios = Map.fromIterables(
          wifiState.mainWiFi.map((e) => e.radioID), wifiState.mainWiFi);
      when(mockWiFiListNotifier.checkingMLOSettingsConflicts(radios))
          .thenReturn(true);

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

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.last);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ]);

    testLocalizations(
        'Incredible-WiFi - Advanced settings view - DFS warning modal',
        (tester, locale) async {
      when(mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
          WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));

      when(mockWiFiAdvancedSettingsNotifier.fetch())
          .thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState)
            .copyWith(isDFSEnabled: false);
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

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.last);
      await tester.pumpAndSettle();

      final saveButtonFinder = find.byType(AppFilledButton);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();
    });
  });

  // group('Guest WiFi', () {
  //   testLocalizations('Guest wifi view - disabled', (tester, locale) async {
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();

  //     await tester.scrollUntilVisible(
  //         find.byType(AppCard, skipOffstage: false).last, 10,
  //         scrollable: find
  //             .descendant(
  //                 of: find.byType(StyledAppPageView),
  //                 matching: find.byType(Scrollable))
  //             .last);
  //     await tester.pumpAndSettle();
  //   });

  //   testLocalizations(
  //     'Guest wifi view - enabled',
  //     (tester, locale) async {
  //       when(mockWiFiListNotifier.build())
  //           .thenReturn(WiFiState.fromMap(wifiListGuestEnabledTestState));
  //       final widget = testableSingleRoute(
  //         overrides: [
  //           wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //           wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //           wifiAdvancedProvider
  //               .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         ],
  //         locale: locale,
  //         child: const WiFiMainView(),
  //       );
  //       await tester.pumpWidget(widget);
  //       await tester.pumpAndSettle();
  //       await tester.scrollUntilVisible(
  //           find.byType(AppCard, skipOffstage: false).last, 10,
  //           scrollable: find
  //               .descendant(
  //                   of: find.byType(StyledAppPageView),
  //                   matching: find.byType(Scrollable))
  //               .last);
  //       await tester.pumpAndSettle();
  //     },
  //   );

  //   testLocalizations(
  //     'Guest wifi view - edit guest ssid',
  //     (tester, locale) async {
  //       when(mockWiFiListNotifier.build())
  //           .thenReturn(WiFiState.fromMap(wifiListGuestEnabledTestState));
  //       final widget = testableSingleRoute(
  //         overrides: [
  //           wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //           wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //           wifiAdvancedProvider
  //               .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         ],
  //         locale: locale,
  //         child: const WiFiMainView(),
  //       );
  //       await tester.pumpWidget(widget);
  //       await tester.pumpAndSettle();
  //       await tester.scrollUntilVisible(
  //           find.byType(AppCard, skipOffstage: false).last, 10,
  //           scrollable: find
  //               .descendant(
  //                   of: find.byType(StyledAppPageView),
  //                   matching: find.byType(Scrollable))
  //               .last);
  //       await tester.pumpAndSettle();
  //       final guestFinder = find.ancestor(
  //           of: find.byType(AppCard, skipOffstage: false).last,
  //           matching: find.byType(AppCard));
  //       final editFinder = find.descendant(
  //           of: guestFinder, matching: find.byIcon(LinksysIcons.edit));
  //       await tester.tap(editFinder.first);
  //       await tester.pumpAndSettle();
  //     },
  //   );

  //   testLocalizations(
  //     'Guest wifi view - edit guest password',
  //     (tester, locale) async {
  //       when(mockWiFiListNotifier.build())
  //           .thenReturn(WiFiState.fromMap(wifiListGuestEnabledTestState));
  //       final widget = testableSingleRoute(
  //         overrides: [
  //           wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //           wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //           wifiAdvancedProvider
  //               .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         ],
  //         locale: locale,
  //         child: const WiFiMainView(),
  //       );
  //       await tester.pumpWidget(widget);
  //       await tester.pumpAndSettle();
  //       await tester.scrollUntilVisible(
  //           find.byType(AppCard, skipOffstage: false).last, 10,
  //           scrollable: find
  //               .descendant(
  //                   of: find.byType(StyledAppPageView),
  //                   matching: find.byType(Scrollable))
  //               .last);
  //       await tester.pumpAndSettle();
  //       final guestFinder = find.ancestor(
  //           of: find.byType(AppCard, skipOffstage: false).last,
  //           matching: find.byType(AppCard));
  //       final editFinder = find.descendant(
  //           of: guestFinder, matching: find.byIcon(LinksysIcons.edit));
  //       await tester.tap(editFinder.last);
  //       await tester.pumpAndSettle();
  //     },
  //   );
  // });

  // group('WiFi Advanced settings', () {
  //   testLocalizations(
  //     'WiFi Advanced settings',
  //     (tester, locale) async {
  //       final widget = testableSingleRoute(
  //         overrides: [
  //           wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //           wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //           wifiAdvancedProvider
  //               .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //         ],
  //         locale: locale,
  //         child: const WiFiMainView(),
  //       );
  //       await tester.pumpWidget(widget);
  //       await tester.pumpAndSettle();

  //       final topologyTabFinder = find.byType(Tab).last;
  //       await tester.tap(topologyTabFinder);

  //       await tester.pumpAndSettle();
  //     },
  //   );

  //   testLocalizations('WiFi Advanced settings - display MLO warning',
  //       (tester, locale) async {
  //     final wifiState = WiFiState.fromMap(wifiListTestState);
  //     when(mockWiFiListNotifier.checkingMLOSettingsConflicts(Map.fromIterables(
  //             wifiState.mainWiFi.map((e) => e.radioID), wifiState.mainWiFi)))
  //         .thenReturn(true);
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
  //         wifiListProvider.overrideWith(() => mockWiFiListNotifier),
  //         wifiAdvancedProvider
  //             .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
  //       ],
  //       locale: locale,
  //       child: const WiFiMainView(),
  //     );
  //     await tester.pumpWidget(widget);
  //     await tester.pumpAndSettle();

  //     final topologyTabFinder = find.byType(Tab).last;
  //     await tester.tap(topologyTabFinder);

  //     await tester.pumpAndSettle();
  //     final appCardFinder = find.byType(AppCard);
  //     await tester.scrollUntilVisible(appCardFinder.last, 10,
  //         scrollable: find
  //             .descendant(
  //                 of: find.byType(StyledAppPageView),
  //                 matching: find.byType(Scrollable))
  //             .last);
  //     await tester.pumpAndSettle();
  //   });
  // });
}
