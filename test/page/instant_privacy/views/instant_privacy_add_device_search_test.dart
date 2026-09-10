import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_instant_privacy.dart';
import '../../../mocks/test_data/scenes/instant_privacy_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// What the Add-device field's hint promises: a connected device can be found by
/// name, by MAC **or by IP**.
///
/// The IP is the half that is easy to lose. `AppSelectAutoComplete` filters on
/// `label`, `value` and `subtitle`, so the address is searchable only for as long
/// as someone keeps putting it in `subtitle` — and nothing about a missing
/// subtitle looks broken: the dropdown still works, it just silently stops
/// answering one third of what the hint says. Hence a test that types an address
/// and nothing else.
///
/// **Untagged on purpose**, like `instant_privacy_toggle_busy_test.dart`: the
/// suggestion overlay only exists while the field has focus and a query, so no
/// golden and no layout-gate cell ever renders it.
void main() {
  setUpAll(() async {
    // The dialog and its overlay are laid out for real here, and Ahem's uniform
    // glyph box is 1.8-2.7x wider than the app's font — wide enough to overflow
    // a dialog that is fine in production.
    await loadAppFonts();
  });

  /// Hosted through the layout gate's [pageSurfaceHost] because `UspTopBar`
  /// reaches `GoRouter.of(context)` unguarded — see the note in
  /// `instant_privacy_toggle_busy_test.dart`.
  Widget host() => pageSurfaceHost(
        view: const InstantPrivacyView(),
        locale: const Locale('en'),
        overrides: instantPrivacyOverrides(enabledWithConnectedDevicesState),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Opens the add-device dialog. Anchored on the label rather than
  /// `find.byType(AppButton).first`, which is a positional selector that the next
  /// button added above it would silently redirect.
  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.ancestor(
      of: find.text('Add device'),
      matching: find.byType(AppButton),
    ));
    await settle(tester);
  }

  testWidgets('a connected device can be found by typing its IP address',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await settle(tester);
    await openDialog(tester);

    expect(find.byType(AppTextField), findsOneWidget,
        reason: 'the add-device dialog is open');

    // MacBook Pro's address, and only its second half — a `contains` match, so
    // this also pins that the filter is not an equality test on the whole field.
    await tester.enterText(find.byType(AppTextField), '168.1.102');
    await settle(tester);

    expect(find.text('MacBook Pro'), findsOneWidget,
        reason: 'the device holding 192.168.1.102 is suggested');
    // The other two devices differ only in the last octet, so their absence is
    // what shows the query reached the address rather than matching everything.
    expect(find.text('iPhone'), findsNothing);
    expect(find.text('iPad'), findsNothing);
  });
}
