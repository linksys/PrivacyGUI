import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';

import '../../../common/_index.dart';
import '../../../common/di.dart';
import '../../../layout_gate/fully_shown.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/wifi_view_notifier_mocks.dart';
import '../../../test_data/_index.dart';

// Constitution 3.4. An SSID is useless when cut, and takes up to 32
// characters. The cards give it 144px at 480 and 195px at 1241, so a long
// one wraps onto a second line. Capping it at one line turned every case
// red (#1802 P4).
const _ssid24 = 'Linksys-Home-Network-24GHz-Main1';
const _ssid5 = 'Linksys-Home-Network-5GHz-Main01';
const _guestSsid = 'Linksys-Home-Network-Guest-Wi-Fi';

void main() {
  late WiFiViewNotifier mockWiFiViewNotifier;
  late MockWifiListNotifier mockWiFiListNotifier;
  late MockWifiAdvancedSettingsNotifier mockWiFiAdvancedSettingsNotifier;
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;

  mockDependencyRegister();
  final mockServiceHelper = getIt.get<ServiceHelper>();

  WiFiState longSsids() {
    final map = jsonDecode(jsonEncode(wifiListGuestEnabledTestState))
        as Map<String, dynamic>;
    final [band24, band5] = map['mainWiFi'] as List;
    (band24 as Map<String, dynamic>)['ssid'] = _ssid24;
    (band5 as Map<String, dynamic>)['ssid'] = _ssid5;
    (map['guestWiFi'] as Map<String, dynamic>)['ssid'] = _guestSsid;
    return WiFiState.fromMap(map);
  }

  setUp(() {
    mockWiFiViewNotifier = MockWiFiViewNotifier();
    mockWiFiListNotifier = MockWifiListNotifier();
    mockWiFiAdvancedSettingsNotifier = MockWifiAdvancedSettingsNotifier();
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();

    when(mockServiceHelper.isSupportGuestNetwork()).thenReturn(true);
    when(mockWiFiListNotifier.build()).thenReturn(longSsids());
    when(mockWiFiListNotifier.fetch(any)).thenAnswer((_) async {
      await Future.delayed(Durations.extralong1);
      return longSsids();
    });
    when(mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(mockWiFiAdvancedSettingsNotifier.fetch(any)).thenAnswer((_) async {
      await Future.delayed(Durations.extralong1);
      return WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState);
    });
    when(mockWiFiViewNotifier.build()).thenReturn(WiFiViewState());
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockInstantPrivacyNotifier.fetch(fetchRemote: anyNamed('fetchRemote')))
        .thenAnswer((_) async {
      await Future.delayed(Durations.extralong1);
      return InstantPrivacyState.fromMap(instantPrivacyTestState);
    });
  });

  for (final (name, value) in [
    ('2.4 GHz SSID', find.text(_ssid24)),
    ('5 GHz SSID', find.text(_ssid5)),
    ('guest SSID', find.text(_guestSsid)),
  ]) {
    for (final screen in const [
      ScreenSize('480', 480, 900, 1),
      ScreenSize('1241', 1241, 900, 1),
    ]) {
      for (final locale in AppLocalizations.supportedLocales) {
        testWidgets(
            'Wi-Fi settings show the $name in full at ${screen.name} in '
            '${locale.toLanguageTag()}', (tester) async {
          await loadTestFonts();
          await tester.setScreenSize(screen);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(testableSingleRoute(
            overrides: [
              wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
              wifiListProvider.overrideWith(() => mockWiFiListNotifier),
              wifiAdvancedProvider
                  .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
              instantPrivacyProvider
                  .overrideWith(() => mockInstantPrivacyNotifier),
            ],
            locale: locale,
            child: const WiFiMainView(),
          ));
          await tester.pumpAndSettle();
          await tester.ensureVisible(value);
          await tester.pumpAndSettle();

          expect(value, isFullyShown);
        });
      }
    }
  }
}
