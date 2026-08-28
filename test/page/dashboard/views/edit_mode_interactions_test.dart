/// #1395 AC2 — the edit-mode gestures the bump could have changed, on the real
/// page: keyboard reorder, drag-to-trash, and resize by the handle.
///
/// AC2 asks for these by hand. The ones a test can hold are held here instead, so
/// the next person to move `sliver_dashboard` does not have to rediscover how each
/// gesture arms — which, for two of the three, is the whole difficulty.
///
/// ## The pointer regime is a platform decision, not a screen size
///
/// `DashboardOverlay` picks how a gesture arms from `defaultTargetPlatform`
/// (`_isMobile`, `dashboard_overlay.dart:604`): with a mouse it arms on
/// pointer-down (`:882`), and on touch it arms on `onLongPressStart` (`:954`) —
/// which a move before the long-press timeout cancels outright. `flutter_test`
/// reports `TargetPlatform.android` unless told otherwise, so an un-overridden
/// widget test measures the touch path only. The first draft of the resize test
/// below did exactly that, read `active=null` at pointer-down, and looked like a
/// regression in the bump; it was the harness pressing a corner and moving 50ms
/// later. Every test here therefore states its regime, and resize runs under both.
///
/// This is not a test-only detail: the app is served to phone browsers, where
/// `defaultTargetPlatform` really is android, and the two paths are separately
/// breakable.
///
/// ## What a resize is allowed to do
///
/// Width is bounded per breakpoint. `maxW` is derived for the grid on screen
/// (`UspWidgetSpecs`), and `device_info` measures `w 6 / maxW 8` at 12 columns,
/// `3 / 3` at 8 and `4 / 4` at 4 — so only the desktop grid leaves the card any
/// horizontal room, and the narrow ones are already at their maximum. That makes
/// one rule for all six cases: drag right past the edge and `w` ends at `maxW`,
/// whether that means growing to it or staying on it. Height has room everywhere
/// (`maxH 6` against `h 3`), so `h` grows in all of them.
///
/// ## The two waits in the trash test are both load-bearing
///
/// The trash zone slides in from off-screen when a drag starts — `bottom: -100`
/// to `0` over 200ms (`AnimatedPositioned`, `dashboard_overlay.dart:1202`) — so a
/// test that reads its box on the next frame gets a rect below the viewport and
/// drops the card into nothing. And the drop only arms after `trashHoverDelay`
/// (600ms) of hovering, so a `moveTo` immediately followed by `up()` deletes
/// nothing either. Both waits are spelled out where they happen.
///
/// ## Mutation table
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | usp_layout_controller (`_shortcuts`) | add `grab: {}` to the policy, as if Space had been dropped with Delete and Select-All | both keyboard tests, at the grab itself: the card is never picked up, and the arrows and the second Space go to whatever encloses the grid |
/// | 2 | usp_layout_controller (`_shortcuts`) | add `cancel: {}` — the plausible reading of "we only kept grab, arrows and drop" | 'Escape abandons the move' only, which is why the cancel key is asserted separately from the drop |
/// | 3 | usp_sliver_dashboard_view | `trashBuilder: null` | 'dragging a card onto the trash zone removes it', at the premise: no pill to drag onto |
/// | 4 | usp_widget_specs | `device_info`'s `maxH` 6 → 3, so the card is already at its full height | all six resize tests |
/// | 5 | this file | drop the `debugDefaultTargetPlatformOverride` from the mouse cases | the three mouse resize tests — this is the harness bug the docstring above describes, kept as a row because it is the one that cost the most time |
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_dashboard_page.dart';
import '../../../util/settle.dart';

final _theme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// The card these tests move, resize and delete.
///
/// Picked because it is built on the first frame at every breakpoint — the sliver
/// is lazy, so a card further down the page would be a test that measures the
/// viewport height — and because it is neither static nor width-locked at 12
/// columns, which is what leaves the resize case something to assert.
const _id = 'device_info';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps the real page at [size] and enters edit mode.
  ///
  /// The real controller, factory and edit-mode notifier, over the fixture the
  /// layout gate already uses for this page. A stand-in grid would measure the
  /// package's gestures against a configuration we do not ship — and the input
  /// policy that narrows them lives on our controller.
  Future<ProviderContainer> pumpEditing(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: dashboardPageOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: _theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: UspSliverDashboardView()),
      ),
    ));
    // Not `pumpAndSettle`: edit mode adds a `JiggleShake` that never ends.
    await settleIgnoringAnimations(tester);
    await container.read(dashboardEditModeProvider.notifier).enterEditMode();
    await settleIgnoringAnimations(tester);
    return container;
  }

  /// The stored geometry of [id], as the controller holds it.
  Map<String, dynamic> itemOf(DashboardController controller, String id) =>
      controller.exportLayout().firstWhere((item) => item['id'] == id);

  /// Runs [body] with [platform] reported as the host.
  ///
  /// Reset inside the test body rather than from `addTearDown`: the binding
  /// verifies that no foundation debug variable is left set, and it does so at the
  /// end of the body, before any teardown runs.
  Future<void> asPlatform(
    TargetPlatform platform,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  group('reordering a card with the keyboard (#1395)', () {
    /// Focuses [_id]'s tile and grabs it.
    ///
    /// The tap is what moves focus — the tile is a `FocusableActionDetector`
    /// whose shortcuts are only installed in edit mode
    /// (`dashboard_item_widget.dart:560`) — and `warnIfMissed` is off because the
    /// press lands on the overlay above the tile, which is the arrangement under
    /// test everywhere else in this file.
    Future<ProviderContainer> grab(WidgetTester tester) async {
      final container = await pumpEditing(tester, const Size(1280, 1600));
      final controller = container.read(uspSliverDashboardControllerProvider);

      await tester.tap(find.byKey(const ValueKey<String>(_id)),
          warnIfMissed: false);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(controller.isDragging.value, isTrue,
          reason: 'Space over a focused card grabs it — the keyboard move goes '
              'through the same drag state a pointer does. This is also how the '
              'test knows the tap put focus on the right tile; the alternative '
              'is asserting a debug label.');
      expect(controller.activeItemId.value, _id,
          reason: 'and the grabbed card is the pivot, not merely the selection '
              'the tap left behind');
      return container;
    }

    testWidgets('grab, move, drop moves the card and cascades its column',
        (tester) async {
      await asPlatform(TargetPlatform.macOS, () async {
        final container = await grab(tester);
        final controller = container.read(uspSliverDashboardControllerProvider);

        // The right-hand column, which the move pushes down: the fixture opens
        // with `device_info@0,1 w6` and `network_status@6,1 w6` side by side.
        final neighbourBefore = itemOf(controller, 'network_status');
        expect(itemOf(controller, _id)['x'], 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await settleIgnoringAnimations(tester);

        expect(controller.isDragging.value, isFalse,
            reason: 'the second Space drops it');
        expect(itemOf(controller, _id)['x'], 1,
            reason: 'one column right, which is the whole gesture');
        expect(
            itemOf(controller, 'network_status')['y'],
            greaterThan(neighbourBefore['y'] as num),
            reason: 'and the card it now overlaps was pushed down rather than '
                'covered — a keyboard move goes through the same reflow a drag '
                'does, which is the half of it that a shortcut binding alone '
                'would not prove');
      });
    });

    testWidgets('Escape abandons the move', (tester) async {
      await asPlatform(TargetPlatform.macOS, () async {
        final container = await grab(tester);
        final controller = container.read(uspSliverDashboardControllerProvider);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settleIgnoringAnimations(tester);

        expect(controller.isDragging.value, isFalse);
        expect(itemOf(controller, _id)['x'], 0,
            reason: 'the card goes back where it was grabbed from. Without a '
                'cancel key the only way out of a grab is to commit it, and a '
                'user who grabbed the wrong card has to undo — which is off '
                'here (`maxHistoryLength: 0`).');
      });
    });
  });

  group('drag-to-trash (#1395)', () {
    testWidgets('dragging a card onto the trash zone removes it',
        (tester) async {
      // Touch, which is the regime the trash zone is really for: it is the only
      // removal gesture on a phone, where there is no context menu.
      await asPlatform(TargetPlatform.android, () async {
        final container = await pumpEditing(tester, const Size(1280, 1600));
        final controller = container.read(uspSliverDashboardControllerProvider);
        final before = controller.exportLayout().map((e) => e['id']).toList();
        expect(before, contains(_id), reason: 'the premise');

        final gesture =
            await tester.startGesture(tester.getCenter(find.byKey(
          const ValueKey<String>(_id),
        )));
        // Past the long-press timeout, then a move to start the drag.
        await tester.pump(const Duration(milliseconds: 600));
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 50));
        expect(controller.isDragging.value, isTrue,
            reason: 'a long press then a move is a drag');
        expect(controller.activeItemId.value, _id,
            reason: 'and this card is the one being dragged');

        // The zone slides in over 200ms. Reading its box before that gives a
        // rect below the viewport — see the docstring.
        await tester.pump(const Duration(milliseconds: 300));

        final pill = find.text(loc(tester.element(find.byType(
          UspSliverDashboardView,
        ))).dragHereToRemove);
        expect(pill, findsOneWidget,
            reason: 'the drag brings the trash zone in');
        final pillRect = tester.getRect(pill);
        final viewport = tester.getRect(find.byType(DashboardOverlay));
        expect(pillRect.bottom, lessThanOrEqualTo(viewport.bottom),
            reason: 'and it lands inside the viewport: a zone still sliding, or '
                'anchored off the bottom, is one the user cannot drop on');

        await gesture.moveTo(pillRect.center);
        await tester.pump(const Duration(milliseconds: 100));
        // `trashHoverDelay` — the drop is not armed before it elapses.
        await tester.pump(const Duration(milliseconds: 700));
        await gesture.up();
        await settleIgnoringAnimations(tester);

        final after = controller.exportLayout().map((e) => e['id']).toList();
        expect(after, isNot(contains(_id)));
        expect(after.length, before.length - 1,
            reason: 'one card removed, and only the one that was dragged');
      });
    });
  });

  group('resizing by the handle (#1395)', () {
    /// The three grids, by the width that produces them: ui_kit maps a viewport
    /// width to 4, 8 or 12 columns, and the grid is handed that number
    /// (`breakpoints: {0: context.currentMaxColumns}`).
    const surfaces = <int, Size>{
      12: Size(1280, 1600),
      8: Size(905, 1600),
      4: Size(480, 1600),
    };

    for (final entry in surfaces.entries) {
      for (final platform in [TargetPlatform.macOS, TargetPlatform.android]) {
        final touch = platform == TargetPlatform.android;
        testWidgets(
            '${entry.key} columns, ${touch ? 'touch' : 'mouse'}: the corner '
            'handle grows the card to its bounds', (tester) async {
          await asPlatform(platform, () async {
            final container = await pumpEditing(tester, entry.value);
            final controller =
                container.read(uspSliverDashboardControllerProvider);
            expect(controller.slotCount.value, entry.key,
                reason: 'the premise: this width really is that grid');

            final tile = find.byKey(const ValueKey<String>(_id));
            final rect = tester.getRect(tile);
            final before = itemOf(controller, _id);

            // Inside the 20px band at the bottom-right corner, which is where
            // `calculateResizeHandle` reads a two-axis resize.
            final gesture =
                await tester.startGesture(rect.bottomRight - const Offset(8, 8));
            // Touch arms on the long press; a move before it cancels the gesture
            // instead of starting one.
            await tester.pump(Duration(milliseconds: touch ? 700 : 50));
            expect(controller.activeItemId.value, _id,
                reason: 'the gesture landed on this card — on touch only after '
                    'the long press, which is the difference the two regimes '
                    'are here for');
            expect(controller.isDragging.value, isFalse,
                reason: 'and it armed a resize rather than a drag. `isResizing` '
                    'would say so directly, but it is on the implementation and '
                    'not on the `DashboardController` interface we hold; a '
                    'corner press that missed the 20px band would arm a body '
                    'drag, which this catches.');

            // Right and down, in steps, past whatever bound comes first.
            for (var i = 0; i < 3; i++) {
              await gesture.moveBy(const Offset(60, 90));
              await tester.pump(const Duration(milliseconds: 50));
            }
            await gesture.up();
            await settleIgnoringAnimations(tester);

            final after = itemOf(controller, _id);
            expect(after['h'], greaterThan(before['h'] as num),
                reason: 'the card got taller: the vertical half of the gesture');
            expect(after['h'], lessThanOrEqualTo(before['maxH'] as num),
                reason: 'and stopped at the height the spec allows');
            expect((after['w'] as num).toDouble(), before['maxW'],
                reason: 'width ends at maxW at every breakpoint — grown into it '
                    'at 12 columns, already on it at 8 and 4, which is the '
                    'clamp holding rather than a gap in the sweep');
          });
        });
      }
    }
  });
}
