import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/page/mac_filter/views/mac_filter_tab.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_mac_filter.dart';
import '../../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../../mocks/test_data/scenes/mac_filter_scene_data.dart';
import '../../../mocks/test_data/scenes/wifi_settings_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// MAC Filtering lives as a tab of Wi-Fi Settings (#1636), and only on firmware
/// that serves the filter (#1635) — so both directions of the capability, and
/// the `?tab=` a deep link lands on, are asserted on the real page.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> pumpWifi(WidgetTester tester, String key,
      {required DeviceCapabilities capabilities, int initialTab = 0}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KeyedSubtree(
      key: ValueKey(key),
      child: pageSurfaceHost(
        view: UspWifiSettingsView(initialTab: initialTab),
        locale: const Locale('en'),
        overrides: [
          ...wifiSettingsOverrides(
            wifiState: quickSetupOffState,
            advancedState: defaultAdvancedState,
          ),
          ...macFilterOverrides(denyWithDevicesState),
          deviceCapabilitiesProvider.overrideWithValue(capabilities),
        ],
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  final supported = DeviceCapabilities(const {DeviceCapability.wifiMacFilter});

  testWidgets('the tab is there when the device serves the filter',
      (tester) async {
    await pumpWifi(tester, 'cap-on', capabilities: supported);

    expect(find.widgetWithText(Tab, 'MAC Filtering'), findsOneWidget);
  });

  testWidgets('and absent when it does not', (tester) async {
    await pumpWifi(tester, 'cap-off', capabilities: DeviceCapabilities.empty);

    expect(find.widgetWithText(Tab, 'MAC Filtering'), findsNothing);
    expect(find.widgetWithText(Tab, 'Advanced'), findsOneWidget,
        reason: 'only the gated tab leaves');
  });

  testWidgets('?tab=2 opens MAC Filtering', (tester) async {
    await pumpWifi(tester, 'deep-link',
        capabilities: supported, initialTab: UspWifiSettingsView.macFilterTab);

    expect(find.byType(MacFilterTab), findsOneWidget);
    expect(
        find.byWidgetPredicate(
            (w) => w is AppSwitch && w.identifier == 'mac-filter-enable'),
        findsOneWidget);
  });

  testWidgets('?tab=2 without the capability falls back to the first tab',
      (tester) async {
    await pumpWifi(tester, 'deep-link-off',
        capabilities: DeviceCapabilities.empty,
        initialTab: UspWifiSettingsView.macFilterTab);

    expect(find.byType(MacFilterTab), findsNothing);
  });

  testWidgets('a MAC Filtering edit shows the page Save bar', (tester) async {
    await pumpWifi(tester, 'save-bar',
        capabilities: supported, initialTab: UspWifiSettingsView.macFilterTab);

    await tester.tap(find.byWidgetPredicate((w) =>
        w is AppIconButton &&
        w.identifier == 'mac-filter-remove-AA:BB:CC:DD:EE:01'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
        find.byWidgetPredicate(
            (w) => w is AppButton && w.identifier == 'page-save'),
        findsOneWidget);
  });
}
