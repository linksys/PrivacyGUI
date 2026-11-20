import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/guest_wifi_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/main_wifi_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_list_advanced_mode_view.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

import '../../../common/_index.dart';
import '../../../common/di.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/wifi_view_notifier_mocks.dart';
import '../../../test_data/_index.dart';

// The advanced Wi-Fi list is a Table of cards. ResponsiveLayout's layout flags
// pick how many columns it has and how many grid columns (N.col) each is wide.
// A Table whose columns are wider than the table reports no overflow, so the
// layout gate cannot see a list that runs off the page. These tests check
// where the cards are instead, on both sides of every breakpoint. At exactly
// 600 the flags used to pick two 4-column cards on the 4-column grid, so the
// list was twice as wide as the page and its second card was off screen
// (#1876).
void main() {
  late MockWiFiViewNotifier mockWiFiViewNotifier;
  late MockWifiListNotifier mockWiFiListNotifier;
  late MockWifiAdvancedSettingsNotifier mockWiFiAdvancedSettingsNotifier;
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;

  final dualBand = WiFiState.fromMap(wifiListTestState);
  final triBand = dualBand.copyWith(mainWiFi: [
    ...dualBand.mainWiFi,
    dualBand.mainWiFi.last.copyWith(radioID: WifiRadioBand.radio_6),
  ]);

  mockDependencyRegister();

  setUp(() {
    mockWiFiViewNotifier = MockWiFiViewNotifier();
    mockWiFiListNotifier = MockWifiListNotifier();
    mockWiFiAdvancedSettingsNotifier = MockWifiAdvancedSettingsNotifier();
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();

    when(mockWiFiViewNotifier.build()).thenReturn(WiFiViewState());
    when(mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(mockWiFiAdvancedSettingsNotifier.fetch(any)).thenAnswer((_) async =>
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockInstantPrivacyNotifier.fetch(fetchRemote: anyNamed('fetchRemote')))
        .thenAnswer(
            (_) async => InstantPrivacyState.fromMap(instantPrivacyTestState));
  });

  Future<void> pumpList(
      WidgetTester tester, WiFiState state, double width) async {
    await loadTestFonts();
    // Tall enough for both rows of cards.
    await tester.setScreenSize(ScreenSize('$width', width, 1600, 1));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(mockWiFiListNotifier.build()).thenReturn(state);
    when(mockWiFiListNotifier.fetch()).thenAnswer((_) async => state);

    await tester.pumpWidget(testableSingleRoute(
      overrides: [
        wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
        wifiListProvider.overrideWith(() => mockWiFiListNotifier),
        wifiAdvancedProvider
            .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
        instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
      ],
      locale: const Locale('en'),
      child: const WiFiMainView(),
    ));
    await tester.pumpAndSettle();
  }

  List<Rect> cardsIn(WidgetTester tester) => [
        for (final finder in [
          find.byType(MainWiFiCard),
          find.byType(GuestWiFiCard),
        ])
          for (var i = 0; i < finder.evaluate().length; i++)
            tester.getRect(finder.at(i)),
      ];

  for (final (bands, state) in [
    ('dual-band', dualBand),
    ('tri-band', triBand)
  ]) {
    for (final breakpoint in [
      ResponsiveLayout.small,
      ResponsiveLayout.medium,
      ResponsiveLayout.large,
      ResponsiveLayout.extraLarge,
    ]) {
      for (final width in [breakpoint - 1, breakpoint, breakpoint + 1]) {
        testWidgets('a $bands list keeps every card on the page at $width',
            (tester) async {
          await pumpList(tester, state, width);

          // The page's content box: the page without its margin on each side.
          final margin = ResponsiveLayout.pageHorizontalPadding(
              tester.element(find.byType(AdvancedModeView)));
          final (left, right) = (margin, width - margin);
          final cards = cardsIn(tester);

          expect(cards, hasLength(state.mainWiFi.length + 1));
          for (final card in cards) {
            // The window, which needs no ResponsiveLayout to work out.
            expect(
              card.left >= -0.5 && card.right <= width + 0.5,
              isTrue,
              reason: 'A card at $card runs past the window, 0 to $width.',
            );
            expect(
              card.left >= left - 0.5 && card.right <= right + 0.5,
              isTrue,
              reason: 'A card at $card runs past the content box, '
                  'from $left to $right.',
            );
          }
        });
      }
    }
  }
}
