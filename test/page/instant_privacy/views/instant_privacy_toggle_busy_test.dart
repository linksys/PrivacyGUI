import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_instant_privacy.dart';
import '../../../mocks/test_data/scenes/instant_privacy_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// What the toggle card must show while an enable/disable write is in flight.
///
/// Until #1059 the only busy signal was the dimmed track `AppSwitch` renders for
/// a null `onChanged` (`app_switch.dart:201`) — a treatment it also gives a
/// switch that is simply unavailable, so "saving" and "you cannot use this" were
/// the same picture for as long as a USP mutation takes.
///
/// **Untagged on purpose.** `run_tests.sh` excludes `golden||loc||ui`, and the
/// half of this contract that can regress silently is the one below: the layout
/// gate already forbids [AppLoader] on this page
/// (`kInstantPrivacyPageCase.forbids`), so a loader that renders when it should
/// not is caught there, across every width and locale. Nothing catches a loader
/// that stops rendering when it should.
void main() {
  setUpAll(() async {
    // The assertions compare pixel rects, and Ahem gives every glyph the same
    // box — the toggle row's label column is what leaves the switch its width.
    await loadAppFonts();
  });

  /// Hosted through the layout gate's [pageSurfaceHost] for the reason
  /// `pnp_setup_view_test.dart` records: `UspTopBar` inside `UiKitPageView`
  /// reaches `GoRouter.of(context)` unguarded, so a plain `MaterialApp` throws
  /// before the page is reached.
  ///
  /// Keyed, because both states below are pumped into the same tester and an
  /// unkeyed `ProviderScope` of the same type would be updated rather than
  /// rebuilt, leaving the first override in place.
  Widget host(String key, UspInstantPrivacyState state) => KeyedSubtree(
        key: ValueKey(key),
        child: pageSurfaceHost(
          view: const InstantPrivacyView(),
          locale: const Locale('en'),
          overrides: instantPrivacyOverrides(state),
        ),
      );

  /// Bounded pump — the loader animates forever, so `pumpAndSettle` would time
  /// out on the state this file is about.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
      'a locked toggle shows a loader where the switch was, without '
      'moving it', (tester) async {
    // The default 800×600 surface is shorter than this page with three device
    // rows, and a `RenderFlex` overflow is a `FlutterError` — which would fail
    // this test for a reason that is the layout gate's to report, not this
    // file's.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host('idle', enabledWithDevicesState));
    await settle(tester);

    expect(find.byType(AppLoader), findsNothing,
        reason: 'an unlocked toggle is not busy');
    final idleRect = tester.getRect(find.byType(AppSwitch));

    await tester.pumpWidget(host(
      'locked',
      enabledWithDevicesState.copyWith(isToggleLocked: true),
    ));
    await settle(tester);

    expect(find.byType(AppLoader), findsOneWidget);
    // Still in the tree, invisible and non-interactive: that is what reserves
    // the space the loader sits in. `AppSwitch` sizes itself from the theme's
    // `spacingFactor`, so the call site cannot restate its footprint as a
    // constant, and a plain ternary would reflow the row.
    expect(find.byType(AppSwitch), findsOneWidget);
    expect(tester.getRect(find.byType(AppSwitch)), idleRect,
        reason: 'the loader must not resize or displace the switch slot');
    // The one assertion that would still hold if the loader were rendered
    // somewhere else on the page: it replaces the switch, it does not accompany
    // it.
    expect(tester.getCenter(find.byType(AppLoader)), idleRect.center);
  });
}
