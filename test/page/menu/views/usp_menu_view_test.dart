import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/styled/menus/widgets/app_menu_card.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';
import 'package:privacy_gui/page/menu/views/usp_menu_view.dart';
import 'package:privacy_gui/page/models/menu_badge.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_menu.dart';
import '../../../mocks/test_data/scenes/dhcp_scene_data.dart' as dhcp;
import '../../../util/app_test_fonts.dart';

/// The menu's entries onto the shared MAC filter (#1636).
///
/// Only Instant Privacy has a card: MAC Filtering is a tab of Wi-Fi Settings,
/// and its capability gate (#1635) lives on that page.
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

  testWidgets('there is no MAC Filtering card — it is a Wi-Fi Settings tab',
      (tester) async {
    await pumpMenu(tester, 'no-mf-card',
        capabilities:
            DeviceCapabilities(const {DeviceCapability.wifiMacFilter}));

    expect(card('menu-mac-filter'), findsNothing,
        reason: 'even on firmware that serves the filter (#1636)');
    expect(card('menu-wifi-settings'), findsOneWidget);
  });

  // Instant Privacy is the shared MAC filter in Allow mode, so on firmware without
  // the filter (#1635) it has nothing to read or write: the card must go, and the
  // menu must not build its provider — which fetches on build, fails there
  // ("Required fields missing", measured on 2.0.2.26091900), and would read Off.
  group('Instant Privacy card', () {
    testWidgets('hidden when the device lacks the filter, and never fetched',
        (tester) async {
      final privacy = _CountingPrivacy();
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(pageSurfaceHost(
        view: const UspMenuView(),
        locale: const Locale('en'),
        overrides: [
          ...menuOverrides(
              lanInfo: dhcp.testLanInfo, privacyMode: MacFilterMode.disabled),
          uspInstantPrivacyProvider.overrideWith(() => privacy),
          deviceCapabilitiesProvider
              .overrideWithValue(DeviceCapabilities.empty),
        ],
      ));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(card('menu-instant-privacy'), findsNothing);
      expect(card('menu-wifi-settings'), findsOneWidget,
          reason: 'only the gated card leaves');
      expect(privacy.builds, 0,
          reason: 'building it fetches the filter the device does not have');
    });

    testWidgets('shown when it has it', (tester) async {
      await pumpMenu(tester, 'ip-card-on',
          capabilities:
              DeviceCapabilities(const {DeviceCapability.wifiMacFilter}));

      expect(card('menu-instant-privacy'), findsOneWidget);
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
            capabilities:
                DeviceCapabilities(const {DeviceCapability.wifiMacFilter}),
            mode: mode);

        expect(
            find.descendant(
                of: card('menu-instant-privacy'),
                matching: find.text(badge.label)),
            findsOneWidget);
      });
    }
  });
}

/// Counts `build()` calls — the provider fetches on build, so a build is a fetch.
class _CountingPrivacy extends FixedInstantPrivacyNotifier {
  _CountingPrivacy()
      : super(UspInstantPrivacyState(
          settings: Preservable(
            original: MacFilterSettings.empty(),
            current: MacFilterSettings.empty(),
          ),
          status: const MacFilterStatus(),
        ));

  int builds = 0;

  @override
  UspInstantPrivacyState build() {
    builds++;
    return super.build();
  }
}
