import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';
import 'package:privacy_gui/page/mac_filter/views/mac_filter_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_instant_privacy.dart';
import '../../../mocks/provider_overrides/mock_mac_filter.dart';
import '../../../util/app_test_fonts.dart';

/// Both pages over the one device mode they share (#1636).
///
/// Instant Privacy owns `Allow`, MAC Filter owns `Deny`, and only `Disabled` is
/// off for both. So each page must be pumped against the *other* page's mode too:
/// that is the state in which a page reading `mode != Disabled` shows itself on,
/// lists the other page's addresses as its own, and — because the pages are
/// mutually exclusive — is also the state in which turning it on must ask first.
///
/// Only one page is ever on screen, so the confirm cannot depend on the other
/// page's provider having loaded. Each case below overrides exactly one page's
/// provider, which is what a user visiting that page has.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  const devices = [
    MacFilterDeviceUIModel(
        mac: 'AA:BB:CC:DD:EE:01',
        displayName: 'Laptop',
        ipAddress: '192.168.1.10'),
  ];
  const blocked = 'AA:BB:CC:DD:EE:99';
  const allowed = 'AA:BB:CC:DD:EE:01';

  Preservable<MacFilterSettings> clean(MacFilterMode mode, List<String> macs) {
    final s = MacFilterSettings(mode: mode, macs: macs);
    return Preservable(original: s, current: s);
  }

  UspInstantPrivacyState privacy(MacFilterMode mode, List<String> macs,
          {List<MacFilterDeviceUIModel> online = devices}) =>
      UspInstantPrivacyState(
        settings: clean(mode, macs),
        status: MacFilterStatus(connectedDevices: online),
      );

  MacFilterState macFilter(MacFilterMode mode, List<String> macs) =>
      MacFilterState(
        settings: clean(mode, macs),
        status: const MacFilterStatus(connectedDevices: devices),
      );

  Future<void> pumpPage(WidgetTester tester, String key, Widget view,
      List<dynamic> overrides) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KeyedSubtree(
      key: ValueKey(key),
      child: pageSurfaceHost(
        view: view,
        locale: const Locale('en'),
        overrides: overrides.cast(),
      ),
    ));
    await settle(tester);
  }

  AppSwitch toggle(WidgetTester tester, String id) => tester.widget<AppSwitch>(
      find.byWidgetPredicate((w) => w is AppSwitch && w.identifier == id));

  Finder saveButton() => find
      .byWidgetPredicate((w) => w is AppButton && w.identifier == 'page-save');

  group('Instant Privacy', () {
    const view = InstantPrivacyView();
    const toggleId = 'instant-privacy-enable';

    testWidgets('Deny (MAC Filter on): off, and the block list is not shown',
        (tester) async {
      await pumpPage(tester, 'ip-deny', view,
          instantPrivacyOverrides(privacy(MacFilterMode.deny, [blocked])));

      expect(toggle(tester, toggleId).value, isFalse);
      expect(find.text(blocked), findsNothing);
    });

    testWidgets('Deny: turning on asks first, and Cancel changes nothing',
        (tester) async {
      await pumpPage(tester, 'ip-deny-confirm', view,
          instantPrivacyOverrides(privacy(MacFilterMode.deny, [blocked])));

      await tester.tap(find.byWidgetPredicate(
          (w) => w is AppSwitch && w.identifier == toggleId));
      await settle(tester);

      expect(find.byType(AppDialog), findsOneWidget,
          reason: 'turning Instant Privacy on turns MAC Filter off');
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await settle(tester);

      expect(toggle(tester, toggleId).value, isFalse);
      expect(saveButton(), findsNothing);
    });

    testWidgets('Disabled: turning on does not ask', (tester) async {
      await pumpPage(tester, 'ip-off', view,
          instantPrivacyOverrides(privacy(MacFilterMode.disabled, [])));

      await tester.tap(find.byWidgetPredicate(
          (w) => w is AppSwitch && w.identifier == toggleId));
      await settle(tester);

      expect(find.byType(AppDialog), findsNothing);
      expect(toggle(tester, toggleId).value, isTrue);
    });

    testWidgets('no device online: the switch cannot be turned on',
        (tester) async {
      await pumpPage(
          tester,
          'ip-empty',
          view,
          instantPrivacyOverrides(
              privacy(MacFilterMode.disabled, [], online: const [])));

      expect(toggle(tester, toggleId).onChanged, isNull,
          reason: 'on with nothing online is an empty Allow list, which the '
              'firmware refuses — the switch must not offer it');
    });

    testWidgets('an emptied allow list cannot be saved', (tester) async {
      await pumpPage(tester, 'ip-emptied', view,
          instantPrivacyOverrides(privacy(MacFilterMode.allow, [allowed])));

      await tester.tap(find.byWidgetPredicate((w) =>
          w is AppIconButton &&
          w.identifier == 'instant-privacy-remove-$allowed'));
      await settle(tester);

      final save = tester.widget<AppButton>(saveButton());
      expect(save.onTap, isNull,
          reason: 'Save would send Allow with an empty list and fail');
    });

    // Turning on pre-fills every online device, so with more than 64 online the
    // list starts over the limit. The firmware refuses more than 64, so Save
    // stays off until rows are removed — and comes back once they are.
    testWidgets('an over-full allow list cannot be saved until trimmed',
        (tester) async {
      final online = [
        for (var i = 0; i <= UspMacFilterService.maxAddresses; i++)
          MacFilterDeviceUIModel(
            mac: 'AA:BB:CC:DD:EE:${i.toRadixString(16).padLeft(2, '0')}'
                .toUpperCase(),
            displayName: 'Device $i',
          ),
      ];
      await pumpPage(
          tester,
          'ip-over',
          view,
          instantPrivacyOverrides(
              privacy(MacFilterMode.disabled, [], online: online)));

      await tester.tap(find.byWidgetPredicate(
          (w) => w is AppSwitch && w.identifier == toggleId));
      await settle(tester);

      expect(tester.widget<AppButton>(saveButton()).onTap, isNull,
          reason: '${online.length} addresses is over the '
              '${UspMacFilterService.maxAddresses} the firmware accepts');

      // 65 rows reach past the surface, so scroll the last one in — and pump,
      // because the scroll only moves the row on the next layout; tapping
      // straight after taps where the row used to be.
      final remove = find.byWidgetPredicate((w) =>
          w is AppIconButton &&
          w.identifier == 'instant-privacy-remove-${online.last.mac}');
      await tester.ensureVisible(remove);
      await settle(tester);
      await tester.tap(remove);
      await settle(tester);

      expect(tester.widget<AppButton>(saveButton()).onTap, isNotNull,
          reason: 'at exactly the limit the list is saveable again');
    });

    testWidgets('a full allow list offers no Add', (tester) async {
      final full = [
        for (var i = 0; i < UspMacFilterService.maxAddresses; i++)
          'AA:BB:CC:DD:${(i ~/ 256).toRadixString(16).padLeft(2, '0')}:'
                  '${(i % 256).toRadixString(16).padLeft(2, '0')}'
              .toUpperCase(),
      ];
      await pumpPage(tester, 'ip-full', view,
          instantPrivacyOverrides(privacy(MacFilterMode.allow, full)));

      final add = tester.widget<AppButton>(find.byWidgetPredicate((w) =>
          w is AppButton && w.identifier == 'instant-privacy-add-device'));
      expect(add.onTap, isNull);
    });
  });

  group('MAC Filter', () {
    const view = MacFilterView();
    const toggleId = 'mac-filter-enable';

    testWidgets(
        'Allow (Instant Privacy on): off, and the allow list is not '
        'shown', (tester) async {
      await pumpPage(tester, 'mf-allow', view,
          macFilterOverrides(macFilter(MacFilterMode.allow, [allowed])));

      expect(toggle(tester, toggleId).value, isFalse);
      expect(find.text(allowed), findsNothing);
    });

    testWidgets('Allow: turning on asks first, and Cancel changes nothing',
        (tester) async {
      await pumpPage(tester, 'mf-allow-confirm', view,
          macFilterOverrides(macFilter(MacFilterMode.allow, [allowed])));

      await tester.tap(find.byWidgetPredicate(
          (w) => w is AppSwitch && w.identifier == toggleId));
      await settle(tester);

      expect(find.byType(AppDialog), findsOneWidget,
          reason: 'turning MAC Filter on turns Instant Privacy off');
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await settle(tester);

      expect(toggle(tester, toggleId).value, isFalse);
      expect(saveButton(), findsNothing);
    });

    testWidgets('Disabled: turning on does not ask', (tester) async {
      await pumpPage(tester, 'mf-off', view,
          macFilterOverrides(macFilter(MacFilterMode.disabled, [])));

      await tester.tap(find.byWidgetPredicate(
          (w) => w is AppSwitch && w.identifier == toggleId));
      await settle(tester);

      expect(find.byType(AppDialog), findsNothing);
      expect(toggle(tester, toggleId).value, isTrue);
      // Unlike Instant Privacy, MAC Filter never pre-fills: the online devices
      // are the Add picker's options, not the starting block list.
      for (final d in devices) {
        expect(find.text(d.mac), findsNothing,
            reason: '${d.mac} is online, and must not start out blocked');
      }
    });
  });
}

/// Bounded — `pumpAndSettle` is not used on these pages because the switch's
/// busy treatment animates for as long as it shows.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
