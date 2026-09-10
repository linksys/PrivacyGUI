import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_instant_privacy.dart';
import '../../../mocks/test_data/scenes/instant_privacy_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// #1059 as reported: type a MAC into the Add-device field and submit it without
/// ever leaving the field.
///
/// Both halves of that sentence were broken. The text was destroyed as it was
/// typed, and once that stopped, Add still refused the value until focus left the
/// field — while the tap that moved focus landed on the scrim and closed the
/// dialog, discarding the input. Nothing in the suite typed a MAC into this
/// dialog before this file, so the reported behaviour could come back with the
/// whole suite still green.
///
/// Lower case on purpose: the issue names it (`aa` was being eaten the same as
/// `AA`), and normalisation is deliberately deferred to `normalizeMac` at submit
/// rather than applied to the keystroke.
///
/// **Untagged on purpose**, like the other two view tests in this directory: no
/// golden and no layout-gate cell types into this field.
void main() {
  const typedMac = 'aa:bb:cc:dd:ee:ff';
  const confirmId = 'instant-privacy-add-mac-confirm';

  setUpAll(() async {
    // The dialog is laid out for real here, and Ahem's uniform glyph box is
    // 1.8-2.7x wider than the app's font — wide enough to overflow a dialog that
    // is fine in production.
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

  Future<void> openDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await settle(tester);
    // Anchored on the label rather than `find.byType(AppButton).first`, which is
    // a positional selector that the next button added above it would silently
    // redirect.
    await tester.tap(find.ancestor(
      of: find.text('Add device'),
      matching: find.byType(AppButton),
    ));
    await settle(tester);

    expect(find.byType(AppTextField), findsOneWidget,
        reason: 'the add-device dialog is open');
  }

  AppTextField macField(WidgetTester tester) =>
      tester.widget<AppTextField>(find.byType(AppTextField));

  Finder confirmFinder() => find.byWidgetPredicate(
        (w) => w is AppButton && w.identifier == confirmId,
      );

  testWidgets('a typed MAC stays in the field, exactly as typed',
      (tester) async {
    await openDialog(tester);

    await tester.enterText(find.byType(AppTextField), typedMac);
    await settle(tester);

    expect(macField(tester).controller!.text, typedMac,
        reason: 'neither rewritten nor cleared while typing (#1059)');
  });

  testWidgets('Add enables from typing alone, with the field still focused',
      (tester) async {
    await openDialog(tester);

    expect(tester.widget<AppButton>(confirmFinder()).onTap, isNull,
        reason: 'nothing typed yet');

    await tester.enterText(find.byType(AppTextField), typedMac);
    await settle(tester);

    // The two assertions together are the fix: enabled *and* never unfocused.
    // Checking only the button would pass on the old code as well, because
    // `enterText` leaves focus where it is and the test would simply not notice
    // that a user has to tab away first.
    expect(macField(tester).focusNode!.hasFocus, isTrue,
        reason: 'no unfocus was needed to get here');
    expect(tester.widget<AppButton>(confirmFinder()).onTap, isNotNull);
  });

  testWidgets('tapping Add submits the typed MAC and closes the dialog',
      (tester) async {
    await openDialog(tester);

    await tester.enterText(find.byType(AppTextField), typedMac);
    await settle(tester);
    await tester.tap(confirmFinder());
    // Longer than [settle]: this waits out the dialog's exit transition, not a
    // rebuild. Still bounded rather than `pumpAndSettle` — the page keeps
    // animations alive that would never let that return.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Add device manually'), findsNothing,
        reason: 'the dialog accepted the value and popped');
  });
}
