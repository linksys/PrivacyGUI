import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../../mocks/test_data/scenes/wifi_settings_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// The Quick Setup switch is inside the WiFi tab, so the tab-switch dirty guard
/// never sees it. Before this, flipping it carried the per-network edits along
/// silently: `setQuickSetupEnabled` made them the new `original`, Quick Setup
/// hid them, and a later save built its read-back proof from values the router
/// did not hold (#1499 review round 2).
///
/// Now an edited tab asks first, the way leaving a tab does.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> pumpWifi(WidgetTester tester, {required bool dirty}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspWifiSettingsView(),
      locale: const Locale('en'),
      overrides: wifiSettingsOverrides(
        wifiState: dirty ? editDirtyState : quickSetupOffState,
        advancedState: defaultAdvancedState,
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  // By widget, not by semantics: a semantics finder reads the binding when it
  // is built, and this one is built before any test runs.
  final quickSetupSwitch = find.byWidgetPredicate(
    (w) => w is AppSwitch && w.identifier == 'wifi-quick-setup',
    description: 'the Quick Setup switch',
  );
  final discard = find.byKey(const Key('unsavedAlert_discardButton'));
  final goBack = find.byKey(const Key('unsavedAlert_goBackButton'));

  ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(
      tester.element(find.byType(UspWifiSettingsView)));

  bool quickSetupOn(WidgetTester tester) => container(tester)
      .read(uspWifiSettingsProvider)
      .settings
      .current
      .quickSetupEnabled;

  bool dirty(WidgetTester tester) =>
      container(tester).read(uspWifiSettingsProvider.notifier).isDirty();

  testWidgets('an edited tab asks before Quick Setup switches on',
      (tester) async {
    await pumpWifi(tester, dirty: true);

    await tester.tap(quickSetupSwitch);
    await tester.pumpAndSettle();

    expect(discard, findsOneWidget);
    expect(find.textContaining('Quick Setup'), findsWidgets);
    expect(quickSetupOn(tester), isFalse, reason: 'nothing changes yet');
  });

  testWidgets('"Go back" keeps the edits and leaves Quick Setup off',
      (tester) async {
    await pumpWifi(tester, dirty: true);
    await tester.tap(quickSetupSwitch);
    await tester.pumpAndSettle();

    await tester.tap(goBack);
    await tester.pumpAndSettle();

    expect(quickSetupOn(tester), isFalse);
    expect(dirty(tester), isTrue, reason: 'the edits are still there');
  });

  testWidgets('"Discard" drops the edits, then switches Quick Setup on',
      (tester) async {
    await pumpWifi(tester, dirty: true);
    await tester.tap(quickSetupSwitch);
    await tester.pumpAndSettle();

    await tester.tap(discard);
    await tester.pumpAndSettle();

    expect(quickSetupOn(tester), isTrue);
    expect(dirty(tester), isFalse,
        reason: 'no per-network edit may ride into Quick Setup');
  });

  testWidgets('an unedited tab switches without asking', (tester) async {
    await pumpWifi(tester, dirty: false);

    await tester.tap(quickSetupSwitch);
    await tester.pumpAndSettle();

    expect(discard, findsNothing);
    expect(quickSetupOn(tester), isTrue);
  });
}
