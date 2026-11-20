import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
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
// characters. A 32-character SSID wraps onto a second line in the advanced
// mode's cards at both widths.
const _ssid24 = 'Linksys-Home-Network-24GHz-Main1';
const _ssid5 = 'Linksys-Home-Network-5GHz-Main01';
const _simpleSsid = 'Linksys-Home-Network-All-Bands-1';
const _guestSsid = 'Linksys-Home-Network-Guest-Wi-Fi';

void main() {
  late WiFiViewNotifier mockWiFiViewNotifier;
  late MockWifiListNotifier mockWiFiListNotifier;
  late MockWifiAdvancedSettingsNotifier mockWiFiAdvancedSettingsNotifier;
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;

  mockDependencyRegister();
  final mockServiceHelper = getIt.get<ServiceHelper>();

  WiFiState longSsids({required bool simpleMode}) {
    final map = jsonDecode(jsonEncode(wifiListGuestEnabledTestState))
        as Map<String, dynamic>;
    final [band24, band5] = map['mainWiFi'] as List;
    (band24 as Map<String, dynamic>)['ssid'] = _ssid24;
    (band5 as Map<String, dynamic>)['ssid'] = _ssid5;
    (map['guestWiFi'] as Map<String, dynamic>)['ssid'] = _guestSsid;
    map['isSimpleMode'] = simpleMode;
    map['simpleModeWifi'] = {...band24, 'ssid': _simpleSsid};
    return WiFiState.fromMap(map);
  }

  setUp(() {
    mockWiFiViewNotifier = MockWiFiViewNotifier();
    mockWiFiListNotifier = MockWifiListNotifier();
    mockWiFiAdvancedSettingsNotifier = MockWifiAdvancedSettingsNotifier();
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();

    when(mockServiceHelper.isSupportGuestNetwork()).thenReturn(true);
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

  for (final (mode, simpleMode, values) in [
    (
      'advanced',
      false,
      {
        '2.4 GHz SSID': find.text(_ssid24),
        '5 GHz SSID': find.text(_ssid5),
        'guest SSID': find.text(_guestSsid),
      }
    ),
    (
      'simple',
      true,
      {
        'SSID': find.text(_simpleSsid),
        'guest SSID': find.text(_guestSsid),
      }
    ),
  ]) {
    testFullyShown(
      'Wi-Fi settings in $mode mode',
      values: values,
      pump: (tester, locale) {
        final state = longSsids(simpleMode: simpleMode);
        when(mockWiFiListNotifier.build()).thenReturn(state);
        when(mockWiFiListNotifier.fetch(any)).thenAnswer((_) async {
          await Future.delayed(Durations.extralong1);
          return state;
        });
        return tester.pumpWidget(testableSingleRoute(
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
      },
    );
  }
}
