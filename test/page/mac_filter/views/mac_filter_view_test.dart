import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_mac_filter.dart';
import '../../../mocks/test_data/scenes/mac_filter_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// The MAC Filtering tab of Wi-Fi Settings: a single Deny/Off toggle (not a radio), and a list
/// editor only when on. Untagged on purpose so `run_tests.sh` runs it. Hosted
/// through the layout gate's [pageSurfaceHost] because `UspTopBar` reaches
/// `GoRouter.of(context)` unguarded.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Widget host(String key, MacFilterState state) => KeyedSubtree(
        key: ValueKey(key),
        child: pageSurfaceHost(
          view: const UspWifiSettingsView(
              initialTab: UspWifiSettingsView.macFilterTab),
          locale: const Locale('en'),
          overrides: wifiMacFilterTabOverrides(state: state),
        ),
      );

  testWidgets('shows a single toggle switch, not a radio list', (tester) async {
    await tester.pumpWidget(host('off', disabledState));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
        find.byWidgetPredicate(
            (w) => w is AppSwitch && w.identifier == 'mac-filter-enable'),
        findsOneWidget);
    expect(find.byType(AppRadioList<Object?>), findsNothing);
  });

  testWidgets('Off hides the device list', (tester) async {
    await tester.pumpWidget(host('off', disabledState));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
        find.byWidgetPredicate(
            (w) => w is AppButton && w.identifier == 'mac-filter-add-device'),
        findsNothing);
  });

  testWidgets('Deny shows the list with its devices', (tester) async {
    await tester.pumpWidget(host('deny', denyWithDevicesState));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('AA:BB:CC:DD:EE:01'), findsOneWidget);
    expect(find.text('7A:BB:CC:DD:EE:03'), findsOneWidget);
    expect(
        find.byWidgetPredicate(
            (w) => w is AppButton && w.identifier == 'mac-filter-add-device'),
        findsOneWidget);
  });

  testWidgets('Deny with an empty list shows the empty message',
      (tester) async {
    await tester.pumpWidget(host('deny-empty', denyEmptyState));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('AA:BB:CC:DD:EE:01'), findsNothing);
  });

  testWidgets('a clean page shows no Save bar', (tester) async {
    await tester.pumpWidget(host('clean', denyWithDevicesState));
    await tester.pump(const Duration(milliseconds: 100));

    // The bottom Save bar only appears when dirty; a pinned (clean) scene has
    // none, so the page-save affordance is absent.
    expect(
        find.byWidgetPredicate(
            (w) => w is AppButton && w.identifier == 'page-save'),
        findsNothing);
  });
}
