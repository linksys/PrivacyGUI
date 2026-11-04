import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/styled/menus/widgets/app_menu_card.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_data.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_data_provider.dart';
import 'package:privacy_gui/page/menu/views/usp_menu_view.dart';
import 'package:privacy_gui/page/models/menu_badge.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_mac_filter.dart';
import '../../../mocks/provider_overrides/mock_menu.dart';
import '../../../mocks/test_data/scenes/dhcp_scene_data.dart' as dhcp;
import '../../../util/app_test_fonts.dart';

/// The menu's entries onto the shared MAC filter (#1636).
///
/// Only Instant Privacy has a card: MAC Filtering is a tab of Wi-Fi Settings,
/// and its capability gate (#1635) lives on that page.
///
/// The Instant Privacy badge reads the device's applied mode, and Instant
/// Privacy is on only in `Allow` — MAC Filter's `Deny` must read as Off. It reads
/// the session-wide MAC filter (`macFilterDataProvider`), which the router keeps
/// current by pushing a mode change, the hardware privacy switch's too (#1755).
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> pumpMenu(WidgetTester tester, String key,
      {required DeviceCapabilities capabilities,
      MacFilterMode mode = MacFilterMode.disabled,
      List<Override> extra = const []}) async {
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
          ...extra,
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
          macFilterDataProvider.overrideWith(() => privacy),
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

    Finder badgeText(String label) => find.descendant(
        of: card('menu-instant-privacy'), matching: find.text(label));

    // The switch moved while the menu was open: the push re-read the filter,
    // and the badge follows without a reload.
    testWidgets('follows a pushed mode change without a reload',
        (tester) async {
      final privacy = FixedMacFilterDataNotifier(
          const MacFilterData(mode: MacFilterMode.disabled, macs: []));
      await pumpMenu(tester, 'badge-push',
          capabilities:
              DeviceCapabilities(const {DeviceCapability.wifiMacFilter}),
          extra: [macFilterDataProvider.overrideWith(() => privacy)]);
      expect(badgeText(MenuBadge.off.label), findsOneWidget);

      privacy.push(const MacFilterData(
          mode: MacFilterMode.allow, macs: ['AA:BB:CC:DD:EE:01']));
      await tester.pump();

      expect(badgeText(MenuBadge.on.label), findsOneWidget);
      expect(badgeText(MenuBadge.off.label), findsNothing);
    });

    testWidgets('shows no badge while the filter is still being read',
        (tester) async {
      await pumpMenu(tester, 'badge-loading',
          capabilities:
              DeviceCapabilities(const {DeviceCapability.wifiMacFilter}),
          extra: [macFilterDataProvider.overrideWith(_NeverReadMacFilter.new)]);

      expect(card('menu-instant-privacy'), findsOneWidget);
      expect(badgeText(MenuBadge.on.label), findsNothing);
      expect(badgeText(MenuBadge.off.label), findsNothing);
    });

    // Unchanged from before #1755: a failed read reads Off.
    testWidgets('a failed read reads Off', (tester) async {
      await pumpMenu(tester, 'badge-error',
          capabilities:
              DeviceCapabilities(const {DeviceCapability.wifiMacFilter}),
          extra: [macFilterDataProvider.overrideWith(_FailedMacFilter.new)]);

      expect(badgeText(MenuBadge.off.label), findsOneWidget);
    });
  });
}

/// Counts `build()` calls — the provider fetches on build, so a build is a fetch.
class _CountingPrivacy extends FixedMacFilterDataNotifier {
  _CountingPrivacy()
      : super(const MacFilterData(mode: MacFilterMode.disabled, macs: []));

  int builds = 0;

  @override
  Future<MacFilterData> build() {
    builds++;
    return super.build();
  }
}

/// A read that has not answered yet.
class _NeverReadMacFilter extends MacFilterDataNotifier {
  @override
  Future<MacFilterData> build() => Completer<MacFilterData>().future;
}

/// A read that failed.
class _FailedMacFilter extends MacFilterDataNotifier {
  @override
  Future<MacFilterData> build() async =>
      throw const UnexpectedError(detail: 'read failed');
}
