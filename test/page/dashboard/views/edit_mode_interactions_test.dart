/// #1395 AC2 — the edit-mode gestures the bump could have changed, on the real
/// page: keyboard reorder, drag-to-trash, and resize by the handle.
///
/// AC2 asks for these by hand. The ones a test can hold are held here instead, so
/// the next person to move `sliver_dashboard` does not have to rediscover how each
/// gesture arms — which, for two of the three, is the whole difficulty.
///
/// ## A gesture's behaviour depends on two globals, and neither is the screen size
///
/// **The platform picks how a gesture arms.** `DashboardOverlay` reads
/// `defaultTargetPlatform` (`_isMobile`, `dashboard_overlay.dart:604`): with a
/// mouse it arms on pointer-down (`:882`), and on touch it arms on
/// `onLongPressStart` (`:954`) — which a move before the long-press timeout
/// cancels outright. `flutter_test` reports `TargetPlatform.android` unless told
/// otherwise, so an un-overridden widget test measures the touch path only. The
/// first draft of the resize test below did exactly that, read `active=null` at
/// pointer-down, and looked like a regression in the bump; it was the harness
/// pressing a corner and moving 50ms later.
///
/// **`kIsWeb` picks whether pointer moves are throttled.** New in 1.1.0, so new
/// relative to the 0.9.1 this branch replaces: on web every move goes through a
/// 16ms `Stopwatch` gate with a 17ms trailing flush (`:1641`). We ship *only* web
/// (`build_web.sh`), and the VM test lane has `kIsWeb == false` — so a suite that
/// says nothing routes every gesture down the one path no user ever takes. Hence
/// `debugOverrideIsWeb`, and hence [_kThrottleWindow].
///
/// Both are stated per test by [onHost], which is also what makes the mutation
/// rows below possible: drop either global and named tests fail.
///
/// ## What a resize is allowed to do
///
/// Width is bounded per breakpoint. `maxW` is derived for the grid on screen
/// (`UspWidgetSpecs`), and `device_info` measures `w 6 / maxW 8` at 12 columns,
/// `3 / 3` at 8 and `4 / 4` at 4 — so only the desktop grid leaves the card any
/// horizontal room, and the narrow ones are already at their maximum. That makes
/// one rule for all six cases: drag far enough and the card ends up *on* both
/// bounds, whether that means growing into them or already sitting there. The
/// drags below are deliberately oversized for this reason — a drag that merely
/// grew the card would pass against a clamp that had stopped working.
///
/// ## The two waits in the trash tests are both load-bearing
///
/// The trash zone slides in from off-screen when a drag starts — `bottom: -100`
/// to `0` over 200ms (`AnimatedPositioned`, `dashboard_overlay.dart:1202`) — so a
/// test that reads its box on the next frame gets a rect below the viewport and
/// drops the card into nothing. That is asserted rather than assumed: the pill's
/// position is read before the drag too, and it is off-screen. The drop then arms
/// only after [UspSliverDashboardView.trashHoverDelay] of hovering, so a `moveTo`
/// immediately followed by `up()` deletes nothing either.
///
/// ## Mutation table
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | usp_layout_controller (`_shortcuts`) | add `grab: {}` to the policy, as if Space had been dropped with Delete and Select-All | both keyboard tests, at the grab itself: the card is never picked up, and the arrows and the second Space go to whatever encloses the grid |
/// | 2 | usp_layout_controller (`_shortcuts`) | add `cancel: {}` — the plausible reading of "we only kept grab, arrows and drop" | 'Escape abandons the move' only, which is why the cancel key is asserted separately from the drop |
/// | 3 | usp_sliver_dashboard_view | `trashBuilder: null` | both trash tests, at the premise: no pill to drag onto |
/// | 4 | usp_widget_specs | `device_info`'s `maxH` 6 → 3, so the card is already at its full height | all seven resize tests |
/// | 5 | this file | make [onHost] ignore its `platform` argument and report android, i.e. the harness bug the docstring above describes | the seven tests that arm a pointer gesture with a mouse — three resize cases, the control, the desktop trash case and both throttle tests. The keyboard pair survives, which is the row's other half: those two are regime-independent, and a reader should not expect a platform mistake to show up there |
/// | 6 | this file | `web: false` on the two throttle tests | both of them: with no gate in the path no move is ever coalesced, so there is nothing pending for the flush to land and nothing held back at the release. Both had to be given an explicit premise assertion to earn this row — before that, "the commit equals the last frame" was trivially true off web |
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

import '../../../util/dashboard_page_harness.dart';
import '../../../util/settle.dart';

/// The card these tests move, resize and delete.
///
/// Picked because it is built on the first frame at every breakpoint — the sliver
/// is lazy, so a card further down the page would be a test that measures the
/// viewport height — and because it is neither static nor width-locked at 12
/// columns, which is what leaves the resize case something to assert.
const _id = 'device_info';

/// The card immediately to its right, which a move has to push out of the way.
const _neighbourId = 'network_status';

/// The three grids, by the width that produces them: ui_kit maps a viewport width
/// to 4, 8 or 12 columns, and the grid is handed that number
/// (`breakpoints: {0: context.currentMaxColumns}`).
const _surfaces = <int, Size>{
  12: Size(1280, 1600),
  8: Size(905, 1600),
  4: Size(480, 1600),
};

/// The web pointer-move gate, copied from `dashboard_overlay.dart:1650` because
/// the package does not export it. Only ever used to pump *past* it or to stay
/// inside it, so the copy drifting makes a test fail rather than lie.
const _kThrottleWindow = Duration(milliseconds: 16);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The stored geometry of [id], as the controller holds it.
  Map<String, dynamic> itemOf(DashboardController controller, String id) =>
      controller.exportLayout().firstWhere(
            (item) => item['id'] == id,
            orElse: () => fail(
              'No item "$id" in the layout. Either the fixture changed or a '
              'previous step deleted it; every geometry assertion after this '
              'point would otherwise fail as a type error on null.',
            ),
          );

  /// Runs [body] with the runtime stated: [platform] as the host, and [web]
  /// deciding whether pointer moves go through the throttle we actually ship.
  ///
  /// The throttle's clock is pointed at the binding's fake clock, so a test drives
  /// the gate by pumping rather than by sleeping (the package offers the hook for
  /// exactly this — a real `Stopwatch` makes the gate depend on suite load).
  ///
  /// The tree is unmounted before the globals are restored, so the overlay's
  /// `dispose` runs under the same regime its `initState` did — it tears down
  /// mouse-only and touch-only machinery on different branches.
  ///
  /// All three globals are reset inside the test body rather than from
  /// `addTearDown`: the binding verifies that no foundation debug variable is left
  /// set, and it does so at the end of the body, before any teardown runs.
  Future<void> onHost(
    WidgetTester tester,
    TargetPlatform platform,
    Future<void> Function() body, {
    bool web = true,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    debugOverrideIsWeb = web;
    final epoch = tester.binding.clock.now();
    debugThrottleClock = () => tester.binding.clock.now().difference(epoch);
    try {
      await body();
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      debugDefaultTargetPlatformOverride = null;
      debugOverrideIsWeb = false;
      debugThrottleClock = null;
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
      final container =
          await pumpDashboardPage(tester, size: _surfaces[12]!, editing: true);
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
      await onHost(tester, TargetPlatform.macOS, () async {
        final container = await grab(tester);
        final controller = container.read(uspSliverDashboardControllerProvider);

        // The right-hand column, which the move pushes down: the fixture opens
        // with `device_info@0,1 w6` and `network_status@6,1 w6` side by side.
        final neighbourBefore = itemOf(controller, _neighbourId);
        expect(itemOf(controller, _id)['x'], 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await settleIgnoringAnimations(tester);

        expect(controller.isDragging.value, isFalse,
            reason: 'the second Space drops it');
        expect(itemOf(controller, _id)['x'], 1,
            reason: 'one column right, which is the whole gesture');
        expect(itemOf(controller, _neighbourId)['y'],
            greaterThan(neighbourBefore['y'] as num),
            reason: 'and the card it now overlaps was pushed down rather than '
                'covered — a keyboard move goes through the same reflow a drag '
                'does, which is the half of it that a shortcut binding alone '
                'would not prove');
      });
    });

    testWidgets('Escape abandons the move, neighbour and all', (tester) async {
      await onHost(tester, TargetPlatform.macOS, () async {
        final container = await grab(tester);
        final controller = container.read(uspSliverDashboardControllerProvider);
        final neighbourBefore = itemOf(controller, _neighbourId);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        // The cascade is live *during* the grab, not on the drop: this is the
        // state Escape has to unwind, and asserting it here is what stops the
        // test from passing on a move that never happened.
        expect(itemOf(controller, _neighbourId)['y'],
            greaterThan(neighbourBefore['y'] as num),
            reason: 'the preview pushed the neighbour down');

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settleIgnoringAnimations(tester);

        expect(controller.isDragging.value, isFalse);
        expect(itemOf(controller, _id)['x'], 0,
            reason: 'the card goes back where it was grabbed from. Without a '
                'cancel key the only way out of a grab is to commit it, and a '
                'user who grabbed the wrong card has to undo — which is off '
                'here (`maxHistoryLength: 0`).');
        expect(itemOf(controller, _neighbourId)['y'], neighbourBefore['y'],
            reason:
                'and so does everything the preview displaced. A cancel that '
                'restored only the grabbed card would leave the rest of the '
                'column one row down, permanently and persisted.');
      });
    });
  });

  group('drag-to-trash (#1395)', () {
    // Both regimes, because both ship: touch is the only removal gesture on a
    // phone, where there is no context menu, and the desktop path arms
    // differently (pointer-down, no long press) on the way to the same zone.
    for (final (platform, size) in [
      (TargetPlatform.android, _surfaces[4]!),
      (TargetPlatform.macOS, _surfaces[12]!),
    ]) {
      final touch = platform == TargetPlatform.android;
      testWidgets(
          'dragging a card onto the trash zone removes it '
          '(${touch ? 'touch, phone' : 'mouse, desktop'})', (tester) async {
        await onHost(tester, platform, () async {
          final container =
              await pumpDashboardPage(tester, size: size, editing: true);
          final controller =
              container.read(uspSliverDashboardControllerProvider);
          final before = controller.exportLayout().map((e) => e['id']).toList();
          expect(before, contains(_id), reason: 'the premise');

          final pill = find.text(loc(tester.element(find.byType(
            UspSliverDashboardView,
          ))).dragHereToRemove);
          final viewport = tester.getRect(find.byType(DashboardOverlay));
          expect(tester.getRect(pill).top, greaterThan(viewport.bottom),
              reason: 'before the drag the zone is parked below the viewport: '
                  'the pill exists for all of edit mode and only its offset '
                  'changes, so "it is on screen" is a position claim, not a '
                  '`findsOneWidget`');

          final gesture = await tester.startGesture(tester.getCenter(find.byKey(
            const ValueKey<String>(_id),
          )));
          // Touch arms on the long press; a move before it cancels outright.
          if (touch) await tester.pump(const Duration(milliseconds: 600));
          await gesture.moveBy(const Offset(0, 20));
          await tester.pump(const Duration(milliseconds: 50));
          expect(controller.isDragging.value, isTrue,
              reason: touch
                  ? 'a long press then a move is a drag'
                  : 'a press '
                      'then a move is a drag');
          expect(controller.activeItemId.value, _id,
              reason: 'and this card is the one being dragged');

          // The zone slides in over 200ms. Reading its box before that gives a
          // rect below the viewport — see the docstring.
          await tester.pump(const Duration(milliseconds: 300));
          final pillRect = tester.getRect(pill);
          expect(pillRect.bottom, lessThanOrEqualTo(viewport.bottom),
              reason: 'the drag brings it inside the viewport, which is what '
                  'makes it droppable');

          await gesture.moveTo(pillRect.center);
          await tester.pump(const Duration(milliseconds: 100));
          // Read from production rather than repeated here: a test that waited
          // less than the real delay would drop on an unarmed zone and delete
          // nothing, which is precisely the failure it is meant to catch.
          await tester
              .pump(UspSliverDashboardView.trashHoverDelay + _kThrottleWindow);
          await gesture.up();
          await settleIgnoringAnimations(tester);

          final after = controller.exportLayout().map((e) => e['id']).toList();
          expect(after, isNot(contains(_id)));
          expect(after.length, before.length - 1,
              reason: 'one card removed, and only the one that was dragged');
        });
      });
    }
  });

  group('resizing by the handle (#1395)', () {
    /// Presses [_id]'s bottom-right corner and drags well past both bounds.
    ///
    /// Returns the geometry before the gesture. The drag is oversized on purpose:
    /// see the docstring on what a resize is allowed to do.
    Future<Map<String, dynamic>> saturate(
      WidgetTester tester,
      DashboardController controller, {
      required bool touch,
    }) async {
      final rect = tester.getRect(find.byKey(const ValueKey<String>(_id)));
      final before = itemOf(controller, _id);

      // Inside the 20px band at the bottom-right corner, which is where
      // `calculateResizeHandle` reads a two-axis resize.
      final gesture =
          await tester.startGesture(rect.bottomRight - const Offset(8, 8));
      await tester.pump(Duration(milliseconds: touch ? 700 : 50));
      expect(controller.activeItemId.value, _id,
          reason: 'the gesture landed on this card — on touch only after the '
              'long press, which is the difference the two regimes are here for');
      expect(controller.isDragging.value, isFalse,
          reason:
              'and it armed a resize rather than a drag. `isResizing` would '
              'say so directly, but it is on the implementation and not on the '
              '`DashboardController` interface we hold; a corner press that '
              'missed the 20px band would arm a body drag, which this catches.');

      // Right and down, past whatever bound comes first. Each pump clears the
      // web throttle window, so every move lands: the coalescing case is the
      // subject of its own group below, not a confound here.
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(const Offset(60, 90));
        await tester.pump(_kThrottleWindow * 2);
      }
      await gesture.up();
      await settleIgnoringAnimations(tester);
      return before;
    }

    /// Asserts the card ends up sitting on both of its bounds.
    void expectOnBounds(
        Map<String, dynamic> before, Map<String, dynamic> after) {
      // Premise: an unbounded axis is exported as null, so a spec that stopped
      // declaring bounds would make the comparisons below vacuous rather than
      // false (`layout_item.dart:74-96`).
      expect(before['maxH'], isNotNull,
          reason: 'the spec bounds height, or there is nothing to clamp to');
      expect(before['maxW'], isNotNull, reason: 'and width');

      expect(after['h'], greaterThan(before['h'] as num),
          reason: 'the card got taller: the vertical half of the gesture');
      expect((after['h'] as num).toDouble(), before['maxH'],
          reason:
              'and stopped exactly on the height the spec allows. Asserting '
              'the bound rather than `<=` it is the point: the drag is large '
              'enough to overshoot, so a clamp that had stopped working would '
              'land past this number, not short of it');
      expect((after['w'] as num).toDouble(), before['maxW'],
          reason:
              'width likewise ends on maxW at every breakpoint — grown into '
              'it at 12 columns, already on it at 8 and 4, which is the clamp '
              'holding rather than a gap in the sweep');
    }

    for (final entry in _surfaces.entries) {
      for (final platform in [TargetPlatform.macOS, TargetPlatform.android]) {
        final touch = platform == TargetPlatform.android;
        testWidgets(
            '${entry.key} columns, ${touch ? 'touch' : 'mouse'}: the corner '
            'handle grows the card onto its bounds', (tester) async {
          await onHost(tester, platform, () async {
            final container = await pumpDashboardPage(tester,
                size: entry.value, editing: true);
            final controller =
                container.read(uspSliverDashboardControllerProvider);
            expect(controller.slotCount.value, entry.key,
                reason: 'the premise: this width really is that grid');

            final before = await saturate(tester, controller, touch: touch);
            expectOnBounds(before, itemOf(controller, _id));
          });
        });
      }
    }

    testWidgets('the VM lane agrees with the web one (control)',
        (tester) async {
      // The six cases above run as the shipped web build. This one repeats the
      // desktop case with the throttle out of the path, so that a future failure
      // can be read: if this passes and its web twin does not, the throttle is
      // the difference, and nobody has to bisect to find that out.
      await onHost(tester, TargetPlatform.macOS, web: false, () async {
        final container = await pumpDashboardPage(tester,
            size: _surfaces[12]!, editing: true);
        final controller = container.read(uspSliverDashboardControllerProvider);
        final before = await saturate(tester, controller, touch: false);
        expectOnBounds(before, itemOf(controller, _id));
      });
    });
  });

  group("the web move throttle, which is what our users' moves go through", () {
    /// Presses the corner and drags in a burst faster than the throttle window,
    /// leaving the pointer down. Returns the gesture and the geometry before it.
    Future<(TestGesture, Map<String, dynamic>)> burst(
      WidgetTester tester,
      DashboardController controller,
    ) async {
      final rect = tester.getRect(find.byKey(const ValueKey<String>(_id)));
      final before = itemOf(controller, _id);
      final gesture =
          await tester.startGesture(rect.bottomRight - const Offset(8, 8));
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.activeItemId.value, _id, reason: 'the premise');

      // Eight moves inside a quarter of the window each — a high-polling mouse,
      // which is the case the throttle was added for.
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(const Offset(20, 30));
        await tester.pump(_kThrottleWindow ~/ 4);
      }
      return (gesture, before);
    }

    testWidgets('a move coalesced inside the window still lands, on the flush',
        (tester) async {
      await onHost(tester, TargetPlatform.macOS, () async {
        final container = await pumpDashboardPage(tester,
            size: _surfaces[12]!, editing: true);
        final controller = container.read(uspSliverDashboardControllerProvider);

        final (gesture, before) = await burst(tester, controller);
        final coalesced = itemOf(controller, _id);
        // Still holding: the trailing flush is a Timer, so time is all it wants.
        await tester.pump(_kThrottleWindow * 2);
        final flushed = itemOf(controller, _id);
        await gesture.up();
        await settleIgnoringAnimations(tester);

        expect(coalesced['w'], greaterThan(before['w'] as num),
            reason: 'the burst did resize the card — the gate drops '
                'intermediate moves, it does not swallow the gesture');
        expect(flushed['w'], greaterThan(coalesced['w'] as num),
            reason: 'and the last move of the burst was still pending when the '
                'burst ended, then landed with no further input. That is both '
                'halves of the gate in one assertion: it really is in the path '
                '(the card was behind the pointer), and its 17ms trailing flush '
                'really does catch up (the card is not left there). Under '
                '`web: false` neither is true and nothing is ever pending.');
      });
    });

    testWidgets(
        'releasing mid-burst commits exactly what the last frame showed',
        (tester) async {
      await onHost(tester, TargetPlatform.macOS, () async {
        final container = await pumpDashboardPage(tester,
            size: _surfaces[12]!, editing: true);
        final controller = container.read(uspSliverDashboardControllerProvider);

        final (gesture, before) = await burst(tester, controller);
        final onScreen = itemOf(controller, _id);
        // Premise, and the only thing that keeps the assertions below from being
        // trivially true: the card is still behind the pointer, so there really
        // is a coalesced move for the release to discard. Without the gate the
        // burst would have caught up to `maxW` here and this test would assert
        // nothing at all.
        expect(
            (onScreen['w'] as num).toDouble(), lessThan(before['maxW'] as num),
            reason: 'the burst is mid-flight: the gate is holding a move back');
        await gesture.up();
        await settleIgnoringAnimations(tester);

        // `_onPointerUp` cancels the flush Timer and discards the pending
        // position (`dashboard_overlay.dart:2046-2048`) instead of applying it,
        // so a release inside the window loses up to one window of pointer
        // travel. That is one frame of end-of-gesture latency and NOT a wrong
        // commit, which is what this asserts and why it is not a bump blocker:
        // what the user last saw is what gets saved. Worth an upstream note,
        // recorded on #1395. If the package starts flushing on up, this test
        // fails — and the fix is to assert the flushed geometry instead.
        expect(itemOf(controller, _id)['w'], onScreen['w'],
            reason:
                'no jump on release: the committed width is the painted one');
        expect(itemOf(controller, _id)['h'], onScreen['h'],
            reason:
                'and the committed height likewise. Our persist hook writes '
                'this straight to the pref (#1393), so a commit that differed '
                'from the last frame would be saved as well as shown.');
      });
    });
  });
}
