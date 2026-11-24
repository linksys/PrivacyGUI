import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/components/wifi_quick_setup_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../../mocks/test_data/scenes/wifi_settings_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// Whether Quick Setup asks for a password when only the security mode changes
/// (#1720).
///
/// Switching between two WPA modes keeps the router's passphrase — measured on
/// FW 2.0.4: a Set of `ModeEnabled` alone left the key unchanged, and a phone
/// that knew the old key came back on WPA3 by itself. So the card says
/// "(Unchanged)" and Save is available. A network that is open now has no
/// passphrase to keep, so a mode change there still asks.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> pumpWifi(WidgetTester tester, UspWifiSettingsState state) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspWifiSettingsView(),
      locale: const Locale('en'),
      overrides: wifiSettingsOverrides(
        wifiState: state,
        advancedState: defaultAdvancedState,
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  final mainCard = find.byWidgetPredicate(
    (w) => w is WifiQuickSetupCard && !w.isGuest,
    description: 'the Main Quick Setup card',
  );
  Finder inMainCard(Finder f) => find.descendant(of: mainCard, matching: f);

  /// Picks [mode] in the Main card's security mode dialog, the way a user does.
  Future<void> pickMainSecurityMode(
    WidgetTester tester, {
    required String from,
    required String to,
  }) async {
    await tester.tap(inMainCard(find.text(from)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(to).last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Ok'));
    await tester.pumpAndSettle();
  }

  final save = find.byWidgetPredicate(
    (w) => w is AppButton && w.identifier == 'page-save',
    description: 'the page Save button',
  );
  bool saveEnabled(WidgetTester tester) =>
      tester.widget<AppButton>(save).onTap != null;

  testWidgets('WPA2 to WPA3 keeps the password: "(Unchanged)", Save enabled',
      (tester) async {
    await pumpWifi(tester, quickSetupOnState);

    await pickMainSecurityMode(tester,
        from: 'WPA2-Personal', to: 'WPA3-Personal');

    expect(inMainCard(find.text('WPA3-Personal')), findsOneWidget,
        reason: 'the new mode is picked');
    expect(inMainCard(find.text('(Unchanged)')), findsOneWidget);
    expect(inMainCard(find.text('(Required)')), findsNothing);
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets(
      'a main band that is open now: "(Required)", Save disabled until a '
      'password is typed', (tester) async {
    await pumpWifi(tester, quickSetupOnMainBandOpenState);
    expect(inMainCard(find.text('(Unchanged)')), findsOneWidget,
        reason: 'nothing asks before the mode changes');

    await pickMainSecurityMode(tester,
        from: 'WPA2-Personal', to: 'WPA3-Personal');

    expect(inMainCard(find.text('(Required)')), findsOneWidget);
    expect(inMainCard(find.text('(Unchanged)')), findsNothing);
    expect(saveEnabled(tester), isFalse);

    await tester.tap(inMainCard(find.text('(Required)')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'longenough1');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Ok'));
    await tester.pumpAndSettle();

    expect(inMainCard(find.text('(Required)')), findsNothing);
    expect(saveEnabled(tester), isTrue);
  });
}
