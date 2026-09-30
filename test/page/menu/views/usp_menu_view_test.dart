import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/styled/menus/widgets/app_menu_card.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';
import 'package:privacy_gui/page/menu/views/usp_menu_view.dart';
import 'package:privacy_gui/page/models/menu_badge.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_menu.dart';
import '../../../mocks/test_data/scenes/dhcp_scene_data.dart' as dhcp;
import '../../../util/app_test_fonts.dart';

/// The menu's two entries onto the shared MAC filter (#1635, #1636).
///
/// The MAC Filter card is the first consumer of the capability layer, and the
/// only thing that hides it on firmware without `X_LINKSYS_MACFilterMode` — so
/// both directions are asserted here, off `deviceCapabilitiesProvider` alone,
/// the way a feature is meant to ask.
///
/// The Instant Privacy badge reads the device's applied mode, and Instant
/// Privacy is on only in `Allow` — MAC Filter's `Deny` must read as Off.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> pumpMenu(WidgetTester tester, String key,
      {required DeviceCapabilities capabilities,
      MacFilterMode mode = MacFilterMode.disabled}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KeyedSubtree(
      key: ValueKey(key),
      child: pageSurfaceHost(
        view: const UspMenuView(),
        locale: const Locale('en'),
        overrides: [
          ...menuOverrides(lanInfo: dhcp.testLanInfo, privacyMode: mode),
          deviceCapabilitiesProvider.overrideWithValue(capabilities),
        ],
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder card(String id) =>
      find.byWidgetPredicate((w) => w is AppMenuCard && w.identifier == id);

  group('MAC Filter entry', () {
    testWidgets('shown when the device serves the filter', (tester) async {
      await pumpMenu(tester, 'cap-on',
          capabilities:
              DeviceCapabilities(const {DeviceCapability.wifiMacFilter}));

      expect(card('menu-mac-filter'), findsOneWidget);
    });

    testWidgets('hidden when it does not', (tester) async {
      await pumpMenu(tester, 'cap-off', capabilities: DeviceCapabilities.empty);

      expect(card('menu-mac-filter'), findsNothing);
      expect(card('menu-instant-privacy'), findsOneWidget,
          reason: 'only the gated entry leaves; the rest of the menu stays');
    });
  });

  group('Instant Privacy badge', () {
    for (final (mode, badge) in [
      (MacFilterMode.allow, MenuBadge.on),
      (MacFilterMode.deny, MenuBadge.off),
      (MacFilterMode.disabled, MenuBadge.off),
    ]) {
      testWidgets('${mode.name} reads ${badge.label}', (tester) async {
        await pumpMenu(tester, 'badge-${mode.name}',
            capabilities: DeviceCapabilities.empty, mode: mode);

        expect(
            find.descendant(
                of: card('menu-instant-privacy'),
                matching: find.text(badge.label)),
            findsOneWidget);
      });
    }
  });
}
