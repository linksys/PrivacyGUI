import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

import '../../../../common/config.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/_index.dart';
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
  group('WiFi list view', () {
    testLocalizations('Wifi list view - advanced view', (tester, locale) async {
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
    });

    testLocalizations('Wifi list view - advanced view discard editing modal',
        (tester, locale) async {
      final widget = testableSingleRoute(
        overrides: [
          wifiViewProvider.overrideWith(() => MockWiFiViewChangedNotifier()),
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

    testLocalizations('Wifi list view - advanced view - edit SSID',
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
    });

    testLocalizations('Wifi list view - advanced view - edit password',
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

    testLocalizations('Wifi list view - advanced view - edit security mode',
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

    testLocalizations('Wifi list view - advanced view - edit WiFi mode',
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

    testLocalizations('Wifi list view - advanced view - edit channel width',
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

    testLocalizations('Wifi list view - advanced view - edit channel',
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
      await tester.tap(editIconFinder.at(5));
      await tester.pumpAndSettle();
    });

    testLocalizations('Wifi list view - simple view', (tester, locale) async {
      when(mockWiFiListNotifier.build())
          .thenReturn(WiFiState.fromMap(wifiListTestStateSimple));
      when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        return WiFiState.fromMap(wifiListTestStateSimple);
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
    });

    testLocalizations('Wifi list view - simple view - edit ssid',
        (tester, locale) async {
      when(mockWiFiListNotifier.build())
          .thenReturn(WiFiState.fromMap(wifiListTestStateSimple));
      when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        return WiFiState.fromMap(wifiListTestStateSimple);
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.at(0));
      await tester.pumpAndSettle();
    });

    testLocalizations('Wifi list view - simple view - edit password',
        (tester, locale) async {
      when(mockWiFiListNotifier.build())
          .thenReturn(WiFiState.fromMap(wifiListTestStateSimple));
      when(mockWiFiListNotifier.fetch()).thenAnswer((realInvocation) async {
        await Future.delayed(Durations.extralong1);
        return WiFiState.fromMap(wifiListTestStateSimple);
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
      final editIconFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editIconFinder.at(1));
      await tester.pumpAndSettle();
    });
  });

  group('Guest WiFi', () {
    testLocalizations('Guest wifi view - disabled', (tester, locale) async {
      
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

      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(1));
      await tester.pumpAndSettle();
    }, screens: responsiveDesktopScreens);

    testLocalizations('Guest wifi view - disabled', (tester, locale) async {
      
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
      final menuFinder = find.byIcon(LinksysIcons.moreHoriz);
      await tester.tap(menuFinder);
      await tester.pumpAndSettle();
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(1));
      await tester.pumpAndSettle();
    }, screens: responsiveMobileScreens);

    testLocalizations('Guest wifi view - enabled', (tester, locale) async {
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

      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(1));
      await tester.pumpAndSettle();
    }, screens: responsiveDesktopScreens);

    testLocalizations('Guest wifi view - enabled', (tester, locale) async {
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
      final menuFinder = find.byIcon(LinksysIcons.moreHoriz);
      await tester.tap(menuFinder);
      await tester.pumpAndSettle();
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(1));
      await tester.pumpAndSettle();

    }, screens: responsiveMobileScreens);

    testLocalizations('Guest wifi view - edit guest ssid',
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

      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(1));
      await tester.pumpAndSettle();
      final editFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editFinder.first);
      await tester.pumpAndSettle();
    }, screens: responsiveDesktopScreens);

    testLocalizations('Guest wifi view - edit guest ssid',
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
      final menuFinder = find.byIcon(LinksysIcons.moreHoriz);
      await tester.tap(menuFinder);
      await tester.pumpAndSettle();
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(1));
      await tester.pumpAndSettle();
      final editFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editFinder.first);
      await tester.pumpAndSettle();
    }, screens: responsiveMobileScreens);

    testLocalizations('Guest wifi view - edit guest password',
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

      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(1));
      await tester.pumpAndSettle();
      final editFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editFinder.at(1));
      await tester.pumpAndSettle();
    }, screens: responsiveDesktopScreens);

    testLocalizations('Guest wifi view - edit guest password',
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
      final menuFinder = find.byIcon(LinksysIcons.moreHoriz);
      await tester.tap(menuFinder);
      await tester.pumpAndSettle();
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(1));
      await tester.pumpAndSettle();
      final editFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editFinder.at(1));
      await tester.pumpAndSettle();
    }, screens: responsiveMobileScreens);
  });

  group('Advanced settings', () {
    testLocalizations('Advanced settings', (tester, locale) async {
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

      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(2));
      await tester.pumpAndSettle();
    }, screens: responsiveDesktopScreens);

    testLocalizations('Advanced settings', (tester, locale) async {
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
      final menuFinder = find.byIcon(LinksysIcons.moreHoriz);
      await tester.tap(menuFinder);
      await tester.pumpAndSettle();
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(2));
      await tester.pumpAndSettle();
      await tester
          .tapAt(tester.getCenter(find.byType(WifiAdvancedSettingsView)));
      await tester.pumpAndSettle();
    }, screens: responsiveMobileScreens);

    testLocalizations('Advanced settings - display MLO warning',
        (tester, locale) async {
      final wifiState = WiFiState.fromMap(wifiListTestState);
      when(mockWiFiListNotifier.checkingMLOSettingsConflicts(Map.fromIterables(
              wifiState.mainWiFi.map((e) => e.radioID), wifiState.mainWiFi)))
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

      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(2));
      await tester.pumpAndSettle();
      final appCardFinder = find.byType(AppCard);
      await tester.scrollUntilVisible(appCardFinder.last, 10,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();
    }, screens: responsiveDesktopScreens);

    testLocalizations('Advanced settings - display MLO warning',
        (tester, locale) async {
      final wifiState = WiFiState.fromMap(wifiListTestState);
      when(mockWiFiListNotifier.checkingMLOSettingsConflicts(Map.fromIterables(
              wifiState.mainWiFi.map((e) => e.radioID), wifiState.mainWiFi)))
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
      final menuFinder = find.byIcon(LinksysIcons.moreHoriz);
      await tester.tap(menuFinder);
      await tester.pumpAndSettle();
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder.at(2));
      await tester.pumpAndSettle();
      await tester
          .tapAt(tester.getCenter(find.byType(WifiAdvancedSettingsView)));
      await tester.pumpAndSettle();
      final appCardFinder = find.byType(AppCard);
      await tester.scrollUntilVisible(appCardFinder.last, 10,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();
    }, screens: responsiveMobileScreens);
  });
}

class MockWiFiViewNotifier extends WiFiViewNotifier {
  @override
  WiFiViewState build() =>
      const WiFiViewState(isCurrentViewStateChanged: false);
}

class MockWiFiViewChangedNotifier extends WiFiViewNotifier {
  @override
  WiFiViewState build() => const WiFiViewState(isCurrentViewStateChanged: true);
  @override
  void setChanged(bool value) {}
}
