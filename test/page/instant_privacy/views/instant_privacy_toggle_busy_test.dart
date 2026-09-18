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
/// a null `onChanged` — a treatment it also gives a switch that is simply
/// unavailable, so "saving" and "you cannot use this" were the same picture for
/// as long as a USP mutation takes. #1059 answered that with a `Stack` over a
/// size-maintaining switch plus an [AppLoader]; #1542 replaced the whole
/// arrangement with `AppSwitch.isLoading` (ui_kit v3.3.0), which draws the busy
/// figure over the track the switch already occupies.
///
/// So the loader is gone and the switch never leaves the tree, and what is left
/// to assert is what the loader was standing in for: the slot does not move, and
/// a screen reader is told this is work in progress rather than that the control
/// is unavailable. (That a busy switch also refuses input is asserted where a
/// call site can pass a live `onChanged` alongside it —
/// `test/page/_shared/components/layout_blocks/row_busy_test.dart`. Here
/// `isToggleDisabled` covers `isToggleLocked`, so there is no callback to swallow.)
///
/// **Untagged on purpose**, so `run_tests.sh` — which excludes `golden||loc||ui`
/// — runs it. It has to: after #1542 this file is the *only* thing that can fail
/// when the busy treatment stops rendering. The layout gate still forbids
/// [AppLoader] on this page (`kInstantPrivacyPageCase.forbids`), but that is now
/// a guard against the spinner swap coming *back*, not coverage of the state
/// below — no code path on this page can render a loader over the toggle any
/// more.
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

  testWidgets('a locked toggle goes busy in place, without moving the switch',
      (tester) async {
    // The default 800×600 surface is shorter than this page with three device
    // rows, and a `RenderFlex` overflow is a `FlutterError` — which would fail
    // this test for a reason that is the layout gate's to report, not this
    // file's.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // `try`/`finally` rather than `addTearDown`: tear-downs run *after* the
    // framework's live-handle check, so a leaked handle would add a second
    // failure on top of whichever assertion actually regressed.
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(host('idle', enabledWithDevicesState));
      await settle(tester);

      expect(
          tester.widget<AppSwitch>(find.byType(AppSwitch)).isLoading, isFalse,
          reason: 'an unlocked toggle is not busy');
      expect(tester.getSemantics(find.byType(AppSwitch)).hint, isEmpty,
          reason: 'and says nothing about work in progress');
      // Both axes are the switch's own: measured `56 × 48` here, not stretched
      // to the surrounding column, so the equality below can see a footprint
      // change in either direction. (A row hosted in a tight-height box does
      // stretch — see the note on the host in `row_busy_test.dart`.)
      final idleRect = tester.getRect(find.byType(AppSwitch));

      await tester.pumpWidget(host(
        'locked',
        enabledWithDevicesState.copyWith(isToggleLocked: true),
      ));
      await settle(tester);

      // The switch itself carries the busy treatment now, so it never leaves the
      // tree and there is no second footprint to keep in sync with the theme's
      // `spacingFactor`.
      expect(find.byType(AppSwitch), findsOneWidget);
      expect(
          tester.widget<AppSwitch>(find.byType(AppSwitch)).isLoading, isTrue);
      expect(tester.getRect(find.byType(AppSwitch)), idleRect,
          reason: 'the busy treatment must not resize or displace the switch');
      // What the loader was standing in for, said to a screen reader rather than
      // only in pixels — and localised, which the loader's `semanticLabel` was
      // and the kit's own `Busy` fallback is not. This page is where that
      // actually reaches the tree: the switch is not inside an [AppListTile], so
      // nothing excludes it (contrast `row_busy_test.dart`'s last case).
      expect(tester.getSemantics(find.byType(AppSwitch)).hint, 'Processing...');
      // The page's own loading state is a different picture, and this page is not
      // in it: an [AppLoader] here would mean the whole surface went blank.
      expect(find.byType(AppLoader), findsNothing);
    } finally {
      handle.dispose();
    }
  });
}
