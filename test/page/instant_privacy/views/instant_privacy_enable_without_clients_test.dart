import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_instant_privacy.dart';
import '../../../mocks/test_data/scenes/instant_privacy_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// #1735 as reported: with no wireless client online — e.g. the admin is the
/// only device and is wired — tapping the Instant Privacy switch did nothing.
///
/// The pre-fill source is the online *wireless* clients only (wired clients are
/// not filtered, FWDEV#194), so a wired-only network reads as "no devices" and
/// the switch was rendered with a null `onChanged`. Turning it on must still be
/// possible: the list then starts empty and is filled through Add device. The
/// firmware's refusal of an empty `Allow` list stays enforced at Save, which is
/// disabled until the list has an entry.
///
/// **Untagged on purpose**, like the other view tests in this directory, so
/// `run_tests.sh` (which excludes `golden||loc||ui`) runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('the switch turns on with no connected (wireless) client',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Off, no devices: the state a wired-only network loads into.
    expect(disabledEmptyState.connectedDevices, isEmpty);
    await tester.pumpWidget(pageSurfaceHost(
      view: const InstantPrivacyView(),
      locale: const Locale('en'),
      overrides: instantPrivacyOverrides(disabledEmptyState),
    ));
    await settle(tester);

    final switchFinder = find.byWidgetPredicate(
        (w) => w is AppSwitch && w.identifier == 'instant-privacy-enable');
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<AppSwitch>(switchFinder).value, isFalse);
    expect(tester.widget<AppSwitch>(switchFinder).onChanged, isNotNull,
        reason: 'the switch must respond with no client online (#1735)');

    await tester.tap(switchFinder);
    await settle(tester);

    expect(tester.widget<AppSwitch>(switchFinder).value, isTrue,
        reason: 'tapping the switch turns Instant Privacy on');
    // On, with an empty list the user fills by hand.
    expect(find.text('No devices in the allowed list.'), findsOneWidget);
    final addDevice = find.byWidgetPredicate(
        (w) => w is AppButton && w.identifier == 'instant-privacy-add-device');
    expect(addDevice, findsOneWidget);
    expect(tester.widget<AppButton>(addDevice).onTap, isNotNull,
        reason: 'the list can be filled through Add device');
  });
}
