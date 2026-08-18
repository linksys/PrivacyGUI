@Tags(['ui'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

/// #1299 spike — can a density control live on the card in edit mode?
///
/// The ticket gates its placement decision on this. An `AppIconButton` in the
/// card's edit-mode chrome opening an `AppPopupMenu` is the only control that
/// fits 191.4px (three chips do not), but the card sits inside
/// `DashboardOverlay`'s gesture region, and a prior incident is recorded at
/// `usp_sliver_dashboard_view.dart:573-578`: a `GestureDetector` there
/// conflicted with the overlay's raw `Listener` and caused accidental
/// deletions.
///
/// ## What the ticket predicted, and what is actually there
///
/// The ticket read the overlay's raw `Listener` as unconditional — pointer-down
/// arms a drag, `_onPointerMove` has no slop threshold, so one pixel of finger
/// travel drags the card. That reading is right for **one of two regimes** and
/// wrong for the other, because every one of those handlers is behind
/// `_isMobile` (`dashboard_overlay.dart:195`), which is
/// `defaultTargetPlatform == android || iOS` — **the platform, not the pointer
/// kind**:
///
/// | | drag is armed by | `onPointerMove` | a tap does |
/// |---|---|---|---|
/// | `_isMobile` (Android/iOS, incl. a phone browser) | `onLongPressStart` | not wired | `toggleSelection` only (`:360`) |
/// | desktop (macOS/Windows/Linux browser) | `onPointerDown` (`:295`) | wired, no slop | commits through `_onPointerUp` |
///
/// So on the form factor this ticket exists for — a phone, where the user has no
/// other influence over density — **a tap cannot start a drag at all**; it takes
/// a long press. The gesture risk is real only on desktop, where the pointer is
/// a mouse that does not wobble, and where the user has resize handles anyway.
///
/// Three further facts the spike establishes:
///
/// 1. A control inside the edit-mode `AbsorbPointer` receives nothing. The
///    on-card placement is not "add a button to the card"; it is "hoist a button
///    out of the wrapper that exists to make the card inert". See Q1.
/// 2. Displacement is quantized to the grid, so under desktop semantics a 3px
///    wobble changes no coordinate. The tolerance is a property of the grid's
///    arithmetic, not a guard anyone wrote.
/// 3. **`cancelInteraction()` does not cure the desktop case.** `_onPointerUp`
///    commits the drag after the restore, so the card is displaced anyway (Q3).
///
/// ## The conclusion the placement follows from
///
/// The one mitigation the public controller interface offers does not hold, and
/// that is the condition the ticket named for the fallback. **The control is not
/// drawn on the card** — it lives outside the overlay's gesture region, as
/// `CardFormBar` under the edit-mode toolbar, acting on the card the grid has
/// selected. Being off the card also removes the 191.4px constraint that forced an
/// icon-plus-menu shape in the first place, so it can be a named row with a plain
/// dropdown.
///
/// Note what this file does *not* decide. It rules the card out; it does not pick
/// the replacement. The first reading of it put the control in the Layout Settings
/// dialog, and that was rejected in review as counter-intuitive — see
/// `test/page/dashboard/views/components/card_form_bar_test.dart` and §2.6i item 2
/// of the design doc. The affordance that did answer it is measured here in passing
/// rather than concluded: Q1 shows a pointer-down on a card reaches the overlay and
/// selects it, which is the gesture the toolbar row reads.
///
/// These tests are the executable record: a package bump that moves any of these
/// answers fails here rather than in a user's layout.
///
/// ## Why there is no mutation table here
///
/// Every other #1299 test file carries one, per the ticket's last AC. This file
/// cannot: the code each assertion guards is `sliver_dashboard`'s, and mutating a
/// pub-cache package is not an edit anyone can commit or re-run. What a table buys
/// — proof the assertion can fail — is bought here by **positive controls**
/// instead: `a long press and drag still works — the harness can displace` and
/// `travel across the grid does displace the card` assert that this harness *can*
/// move a card, so the "nothing moved" answers are answers rather than a rig that
/// moves nothing. Both had to be fixed
/// to get there (a vertical drag proves nothing, because the engine compacts
/// vertically and the card floats back to `y: 0`; and `exportLayout()` reorders on
/// a drag while coordinates do not, so an order-sensitive comparison reads a
/// reshuffle as a displacement).
void main() {
  /// The two-item layout the questions are asked against. `device_info` is the
  /// card the control is tapped on; `lan_info` sits beside it so a displacement
  /// has somewhere to show up.
  List<LayoutItem> layout() => [
        LayoutItem(id: 'device_info', x: 0, y: 0, w: 6, h: 3),
        LayoutItem(id: 'lan_info', x: 6, y: 0, w: 6, h: 3),
      ];

  /// Coordinates per id, sorted by id.
  ///
  /// Two things are deliberately excluded. `moved` and friends flip on
  /// compaction, so comparing whole items would compare engine bookkeeping. And
  /// the *order* of `exportLayout()` is excluded because a drag reorders that
  /// list while leaving every coordinate alone — a real effect, but not the one
  /// being measured, and comparing order-sensitively made "the list was
  /// reshuffled" read as "the card was displaced".
  List<String> geometry(DashboardController controller) => (controller
          .exportLayout()
          .map((item) => '${item['id']}@${item['x']},${item['y']}'
              ' ${item['w']}x${item['h']}')
          .toList()
        ..sort())
      .toList();

  /// The production edit-mode item wrapping, with [control] standing in for the
  /// density button.
  ///
  /// [insideAbsorbPointer] mirrors `_buildItemWidget`: today everything the card
  /// renders is inside `AbsorbPointer`. Hoisting the control out of it is the
  /// change the on-card placement would need, so both arrangements are built.
  /// The label and the control are kept apart horizontally, and both are held
  /// clear of the 20px `resizeHandleSide` band at every edge. Tapping inside
  /// that band is a *resize*, not a drag, which silently answers a different
  /// question than the one being asked.
  Widget buildItem(
    LayoutItem layoutItem, {
    required Widget control,
    required bool insideAbsorbPointer,
  }) {
    final card = Container(
      color: Colors.blue.shade100,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 40),
          child: insideAbsorbPointer ? control : Text(layoutItem.id),
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(child: card),
        if (!insideAbsorbPointer)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 40),
              child: control,
            ),
          ),
      ],
    );
  }

  /// Runs [body] with [platform] in force, and clears the override before the
  /// body returns.
  ///
  /// Not `addTearDown`: `_verifyInvariants` runs at the end of the test body,
  /// *before* teardowns, and asserts every foundation debug variable is unset —
  /// so a teardown-based restore fails every test that uses one.
  Future<void> withPlatform(
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

  /// Pumps the grid in edit mode.
  ///
  /// Which of the overlay's two gesture regimes is under test comes from
  /// [withPlatform] around the call, not from an argument here: `flutter_test`
  /// defaults to Android, so a spike that does not set the platform deliberately
  /// measures the mobile regime while believing it measured the desktop one.
  /// That is the mistake this file was written to avoid repeating.
  Future<DashboardController> pumpDashboard(
    WidgetTester tester, {
    required bool insideAbsorbPointer,
    required Widget Function(DashboardController controller) controlBuilder,
    void Function(LayoutItem item)? onItemDragStart,
  }) async {
    final controller = DashboardController(
      initialSlotCount: 12,
      initialLayout: layout(),
    );
    controller.setEditMode(true);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    Widget itemBuilder(BuildContext context, LayoutItem item) => buildItem(
          item,
          control: controlBuilder(controller),
          insideAbsorbPointer: insideAbsorbPointer,
        );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardOverlay(
          controller: controller,
          scrollController: scrollController,
          itemBuilder: itemBuilder,
          onItemDragStart: onItemDragStart,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverDashboard(
                itemBuilder: itemBuilder,
                breakpoints: {0: 12},
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return controller;
  }

  /// A finger resting on a control, not a drag: press, travel [by], lift.
  ///
  /// Travel is horizontal wherever displacement is the thing being measured.
  /// Dragging a top-row card *down* proves nothing: the engine compacts
  /// vertically, so the card floats straight back to `y: 0` and the coordinates
  /// come back unchanged whether the drag was honoured or ignored. Sideways
  /// motion has no such restoring force.
  Future<void> pressWithTravel(
    WidgetTester tester,
    Offset target, {
    required Offset by,
  }) async {
    final gesture = await tester.startGesture(
      target,
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(by);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// Far enough to carry a 6-column card clear of its own column span on the
  /// default 800px test surface, so a honoured drag must change `x`.
  const acrossTheGrid = Offset(400, 0);

  /// A finger that does not mean to travel: below one slot in any direction.
  const aWobble = Offset(3, 3);

  Widget button(VoidCallback onPressed) => ElevatedButton(
        onPressed: onPressed,
        child: const Text('density'),
      );

  // ---------------------------------------------------------------------------
  // Q1 — does an on-card control get the tap at all?
  // ---------------------------------------------------------------------------
  // Platform-independent: AbsorbPointer is ours, not the package's.
  group('Q1: the edit-mode AbsorbPointer', () {
    testWidgets('swallows a control placed inside it', (tester) async {
      await withPlatform(TargetPlatform.android, () async {
        var taps = 0;
        await pumpDashboard(
          tester,
          insideAbsorbPointer: true,
          controlBuilder: (_) => button(() => taps++),
        );

        await tester.tap(find.text('density').first, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(taps, 0,
            reason: 'THE FIRST SPIKE FINDING, and the one that shapes the '
                'implementation: the on-card placement is not "add a button to '
                'the card". Everything the card renders in edit mode is inside '
                'AbsorbPointer, so the control has to be hoisted out of it — a '
                'sibling in the item Stack, not a child of the card.');
      });
    });

    testWidgets('a control hoisted out of it receives the tap', (tester) async {
      await withPlatform(TargetPlatform.android, () async {
        var taps = 0;
        await pumpDashboard(
          tester,
          insideAbsorbPointer: false,
          controlBuilder: (_) => button(() => taps++),
        );

        await tester.tap(find.text('density').first, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(taps, 1,
            reason: "The overlay's Listener is an ancestor and does not enter "
                'the gesture arena, so the button wins its own tap even though '
                'the overlay hit-tests through it to the item.');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Q2 — is a drag armed underneath the control?
  // ---------------------------------------------------------------------------
  group('Q2: mobile — drag needs a long press, so a tap is safe', () {
    testWidgets('tapping the control arms no drag and moves nothing',
        (tester) async {
      await withPlatform(TargetPlatform.android, () async {
        final dragStarts = <String>[];
        final controller = await pumpDashboard(
          tester,
          insideAbsorbPointer: false,
          controlBuilder: (_) => button(() {}),
          onItemDragStart: (item) => dragStarts.add(item.id),
        );
        final before = geometry(controller);

        await pressWithTravel(
          tester,
          tester.getCenter(find.text('density').first),
          by: aWobble,
        );

        expect(dragStarts, isEmpty,
            reason: 'THE DECIDING FINDING. On Android/iOS — which is what a '
                'phone browser reports, and the phone is the form factor this '
                'ticket exists for — onPointerDown does not call '
                '_onPointerDown and onPointerMove is not wired at all '
                '(dashboard_overlay.dart:295, :303). Drag is reached only '
                "through onLongPressStart. The ticket's premise that one pixel "
                'of travel starts a drag does not hold here.');
        expect(geometry(controller), before);
      });
    });

    testWidgets('a long press and drag still works — the harness can displace',
        (tester) async {
      // Without this the group above proves nothing: "no displacement" would be
      // indistinguishable from "this harness cannot displace anything".
      await withPlatform(TargetPlatform.android, () async {
        final controller = await pumpDashboard(
          tester,
          insideAbsorbPointer: false,
          controlBuilder: (_) => button(() {}),
        );
        final before = geometry(controller);

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('device_info').first),
          kind: PointerDeviceKind.touch,
        );
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
        await gesture.moveBy(acrossTheGrid);
        await tester.pump(const Duration(milliseconds: 16));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(geometry(controller), isNot(before),
            reason: 'A long press followed by a drag must still move the card. '
                'If this fails the harness is inert and every other answer in '
                'this file is a false negative.');
      });
    });
  });

  group('Q2: desktop — pointer-down does arm a drag', () {
    testWidgets('a click on the control arms a drag on the card',
        (tester) async {
      await withPlatform(TargetPlatform.macOS, () async {
        final dragStarts = <String>[];
        await pumpDashboard(
          tester,
          insideAbsorbPointer: false,
          controlBuilder: (_) => button(() {}),
          onItemDragStart: (item) => dragStarts.add(item.id),
        );

        await pressWithTravel(
          tester,
          tester.getCenter(find.text('density').first),
          by: aWobble,
        );

        expect(dragStarts, ['device_info'],
            reason: "The ticket's mechanism, confirmed for the desktop regime: "
                'the overlay hit-tests past our button to the item render box — '
                'our widget carries no SliverDashboardParentData, so _hitTest '
                'skips it and finds the item — and arms a drag on pointer-down.');
      });
    });

    testWidgets('3px of travel changes no coordinate', (tester) async {
      await withPlatform(TargetPlatform.macOS, () async {
        final controller = await pumpDashboard(
          tester,
          insideAbsorbPointer: false,
          controlBuilder: (_) => button(() {}),
        );
        final before = geometry(controller);

        await pressWithTravel(
          tester,
          tester.getCenter(find.text('density').first),
          by: aWobble,
        );

        expect(geometry(controller), before,
            reason: 'A drag is armed (previous test) but coordinates are '
                'quantized to slots, so a click that barely moves commits the '
                'geometry it started with. This is why the desktop regime is '
                'survivable — but it is arithmetic, not a threshold, so the '
                'mitigation below is kept.');
      });
    });

    testWidgets('travel across the grid does displace the card',
        (tester) async {
      await withPlatform(TargetPlatform.macOS, () async {
        final controller = await pumpDashboard(
          tester,
          insideAbsorbPointer: false,
          controlBuilder: (_) => button(() {}),
        );
        final before = geometry(controller);

        await pressWithTravel(
          tester,
          tester.getCenter(find.text('device_info').first),
          by: acrossTheGrid,
        );

        expect(geometry(controller), isNot(before),
            reason: 'The upper bound of the previous test. A pointer that '
                'travels far enough does move the card, so the desktop regime '
                'has a real if narrow exposure, and the harness is not inert.');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Q3 — is cancelInteraction() enough of a cure on desktop?
  // ---------------------------------------------------------------------------
  group('Q3: cancelInteraction is not a sufficient mitigation', () {
    testWidgets('the card is displaced anyway, from the control that cancels',
        (tester) async {
      await withPlatform(TargetPlatform.macOS, () async {
        final controller = await pumpDashboard(
          tester,
          insideAbsorbPointer: false,
          // What an on-card density button would do: open the menu, and undo
          // whatever gesture the same pointer armed.
          controlBuilder: (c) => button(c.cancelInteraction),
        );
        final before = geometry(controller);

        await pressWithTravel(
          tester,
          tester.getCenter(find.text('density').first),
          by: acrossTheGrid,
        );

        expect(geometry(controller), isNot(before),
            reason: 'THE DECIDING RESULT, and it is the negative one. '
                'cancelInteraction() restores originalLayoutOnStart, but '
                '_onPointerUp (dashboard_overlay.dart:761) still sees '
                '_activeItemId set and commits the drag *after* the restore, so '
                'the card ends up displaced regardless. The only mitigation the '
                'public controller interface offers therefore does not hold, '
                'which is the condition the ticket named for falling back to a '
                'placement off the card. This asserts the failure rather than '
                'the cure so the finding cannot quietly rot: if a package bump '
                'ever makes cancelInteraction() effective, this test fails and '
                'the on-card placement is worth reopening.');
      });
    });
  });
}
