import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacygui_widgets/theme/custom_responsive.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

import '../../../common/di.dart';
import '../../../common/screen.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../common/theme_data.dart';
import '../../../layout_gate/fully_shown.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../test_data/_index.dart';

// Constitution 3.4. The device count on a Wi-Fi card wraps within its two
// lines since #1802; before, it had no width limit and ran past the card in
// Japanese. This checks the count still fits its lines in every locale,
// on the narrowest card the dashboard lays out: two cards side by side in 8
// columns at 1241, the narrowest desktop page. 0, 1, 2 and 188 cover the
// plural forms, which differ in length: Japanese's "no devices", the one
// that overflowed, and Russian's "few" and "many".
void main() {
  late MockDashboardHomeNotifier mockDashboardHomeNotifier;
  late MockWifiListNotifier mockWifiListNotifier;
  late MockPollingNotifier mockPollingNotifier;

  mockDependencyRegister();

  setUp(() {
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
    mockWifiListNotifier = MockWifiListNotifier();
    mockPollingNotifier = MockPollingNotifier();
    initBetterActions();
    final wifiState = WiFiState.fromMap(wifiListTestState);
    when(mockWifiListNotifier.build()).thenReturn(wifiState);
    when(mockPollingNotifier.build()).thenReturn(
        const CoreTransactionData(lastUpdate: 0, isReady: true, data: {}));
  });

  // One card as wide as the grid makes it in the 8-column layout, two side
  // by side. The single-route harness lays a whole grid out one card to a
  // row.
  Future<void> pumpCard(
      WidgetTester tester, Locale locale, DashboardHomeState state) async {
    when(mockDashboardHomeNotifier.build()).thenReturn(state);
    await loadTestFonts();
    await tester.setScreenSize(const ScreenSize('1241', 1241, 900, 1));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: locale,
      overrides: [
        accessPolicyProvider.overrideWithValue(AccessPolicy.full),
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
        wifiListProvider.overrideWith(() => mockWifiListNotifier),
        pollingProvider.overrideWith(() => mockPollingNotifier),
      ],
      child: Builder(
        builder: (context) => Center(
          child: SizedBox(
            width: (8.col - ResponsiveLayout.columnPadding(context)) / 2,
            height: 176,
            child: WiFiCard(
              item: state.wifis.first,
              index: 0,
              canBeDisabled: true,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  DashboardHomeState stateWith(void Function(Map<String, dynamic> wifi) edit) {
    final state = jsonDecode(jsonEncode(dashboardHomeCherry7TestState))
        as Map<String, dynamic>;
    for (final wifi in state['wifis'] as List) {
      edit(wifi as Map<String, dynamic>);
    }
    return DashboardHomeState.fromMap(state);
  }

  for (final devices in [0, 1, 2, 188]) {
    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets(
          '$devices devices fit their lines in ${locale.toLanguageTag()}',
          (tester) async {
        await pumpCard(tester, locale,
            stateWith((wifi) => wifi['numOfConnectedDevices'] = devices));

        expect(find.text(lookupAppLocalizations(locale).nDevices(devices)),
            isFullyShown);
      });
    }
  }

  // The SSID is capped at one line, inside a FittedBox that shrinks it to
  // the card instead. An SSID takes up to 32 characters. Without the
  // FittedBox, every case went red (#1802 P4).
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
        'a 32-character SSID is shown in full in '
        '${locale.toLanguageTag()}', (tester) async {
      const ssid = 'Linksys-Home-Network-5GHz-Guest1';
      await pumpCard(tester, locale, stateWith((wifi) => wifi['ssid'] = ssid));

      expect(find.text(ssid), isFullyShown);
    });
  }
}
