/// #1032 — the grid keeps its scroll position when edit mode opens and closes.
///
/// The toggle remounts the grid's scroll view, by two independent routes. Edit
/// mode hands `DashboardOverlay` a non-null `gridStyle`, and the overlay answers
/// by inserting a grid-background child at the *front* of its own `Stack`: the
/// content child — the `CustomScrollView` this view passes as `child:` — moves
/// from index 0 to index 1, and none of those children carry a key, so the
/// framework matches them by index and inflates the whole subtree again one slot
/// down. Independently, `CardFormToolbarLayer` starts wrapping the grid, which
/// changes the tree shape above the same `Scrollable`. A fresh `Scrollable` means
/// a fresh `ScrollPosition`, and the grid silently jumps back to the top.
///
/// Two things that are visible to the user come out of that one remount:
///
///  1. The jump itself. Scroll down, tap the edit icon, and the cards you were
///     looking at are gone from the viewport.
///  2. The navigation bar stays hidden. `uspBarsVisibleProvider` is a latch fed
///     only by scroll *direction* (`usp_dashboard_shell.dart`), and a remount
///     emits no direction notification at all — so the bar the scroll-down hid
///     is never told the page is back at the top. On a mouse it cannot be
///     recovered either: `ScrollPositionWithSingleContext.pointerScroll` returns
///     early when the target offset equals the current one, so a wheel-up at the
///     top emits nothing. Hence the report's "scroll down first, then up".
///
/// The fix remembers the offset in the [State] and hands it to the next build's
/// `ScrollController` as its `initialScrollOffset`, which the remounted
/// `ScrollPosition` starts at. Not a [GlobalKey] on the scroll view, which also
/// works and is what this landed as first: moving a subtree that size trips
/// `identical(childRenderObject, parentRenderObject)` in `flushSemantics`, which
/// the dashboard golden test caught and which the offset memo does not provoke.
/// The reasoning is on `_gridScrollOffset`.
///
/// ## Mutation table
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | usp_sliver_dashboard_view | drop `initialScrollOffset:` from the per-build `ScrollController` | both tests, measured: offset 0 where 380 was expected — this is #1032 itself |
/// | 2 | usp_sliver_dashboard_view | drop the controller listener, so the memo is never written | both tests, measured: same 380 → 0, from the other end |
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';

import '../../../util/dashboard_page_harness.dart';
import '../../../util/settle.dart';

/// Desktop, tall enough that the grid scrolls and short enough that it has to.
const _desktop = Size(1280, 900);

/// Far enough down that a reset to the top cannot be mistaken for rounding.
const _dragDistance = Offset(0, -400);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The grid's own offset.
  ///
  /// Read off the widget rather than held, because the view builds a fresh
  /// `ScrollController` every build — see the note on it. The one this reads is
  /// whichever the current build handed the scroll view, which is the one
  /// attached to the live position.
  double gridOffset(WidgetTester tester) => tester
      .widget<CustomScrollView>(find.byType(CustomScrollView))
      .controller!
      .offset;

  /// Pumps the page and scrolls the grid down, as the reporter's step 2 does.
  Future<(DashboardEditModeNotifier, double)> pumpScrolledDown(
      WidgetTester tester) async {
    final container = await pumpDashboardPage(tester, size: _desktop);
    await tester.drag(find.byType(CustomScrollView), _dragDistance,
        warnIfMissed: false);
    await settleIgnoringAnimations(tester);

    final scrolled = gridOffset(tester);
    expect(scrolled, greaterThan(0),
        reason: 'the premise: the grid at this size does scroll, so there is a '
            'position for the toggle below to lose');
    return (container.read(dashboardEditModeProvider.notifier), scrolled);
  }

  testWidgets('entering edit mode keeps the grid where the user left it',
      (tester) async {
    final (notifier, scrolled) = await pumpScrolledDown(tester);

    await notifier.enterEditMode();
    await settleIgnoringAnimations(tester);

    expect(gridOffset(tester), scrolled);
  });

  testWidgets('and so does leaving it', (tester) async {
    final (notifier, scrolled) = await pumpScrolledDown(tester);

    await notifier.enterEditMode();
    await settleIgnoringAnimations(tester);
    await notifier.commitEditMode();
    await settleIgnoringAnimations(tester);

    expect(gridOffset(tester), scrolled,
        reason: 'the reported step — "click the apply/save or cancel icon"');
  });
}
