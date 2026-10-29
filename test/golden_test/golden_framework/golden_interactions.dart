import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart' show AppIconButton;

/// Shared interaction helpers for golden `Interaction.steps`.
///
/// These exist to keep interaction steps locale-independent and free of
/// brittle geometry-based gestures.

/// Pumps until no pending frames or timeout — whichever comes first.
///
/// Unlike raw `pumpAndSettle`, this won't fail on infinite animations
/// (e.g., spinners frozen by TickerMode or looping AnimationControllers).
///
/// This is the single settle strategy shared by the golden runner
/// (`pumpBeforeTest`) and interaction helpers like [switchToTab], so tuning it
/// here benefits both.
Future<void> settleWithTimeout(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(milliseconds: 500),
    );
  } on FlutterError {
    // pumpAndSettle timed out — widget tree has infinite animations.
    // The TickerMode freeze makes this safe; pump one last frame and move on.
    await tester.pump();
  }
}

/// Pumps an overlay opened from an interaction step until it is on screen and
/// fully transitioned in.
///
/// Two pumps, for two different waits. The first runs anything scheduled on a
/// zero-delay timer, which is how `doSomethingWithSpinner` opens its dialog: it
/// calls `showAppSpinnerDialog` from `Future.delayed(Duration.zero)` rather
/// than directly. The second advances 300ms: past that helper's own 100ms wait,
/// past `showAppDialog`'s 200ms enter transition, and past the 250ms one
/// `ScaffoldMessenger` gives a snackbar, which `disableAnimations` does not
/// shorten. The capture is the settled overlay, not a frame of it fading in.
Future<void> pumpOverlayIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Switches to the tab at [index] by driving the [TabController] directly,
/// then settles the tab-change animation via [settleWithTimeout].
///
/// Why not `tester.tap(find.byType(Tab).at(index))`? The USP pages use a
/// non-scrollable TabBar (`TabAlignment.fill`), so long localized labels
/// (e.g. Danish, German, Russian) push the rightmost tab's center off-screen.
/// A geometric tap then lands outside the surface, misses, and the tab never
/// switches — breaking every interaction that expects that tab's content, but
/// only in the locales with long labels. Driving the controller expresses the
/// real intent ("show the Nth tab") and works in every locale.
///
/// Assumes exactly one [TabBar] is on screen (the common case for USP detail
/// views). Pass [tabBarFinder] to disambiguate if a view ever nests TabBars.
Future<void> switchToTab(
  WidgetTester tester,
  int index, {
  Finder? tabBarFinder,
}) async {
  final finder = tabBarFinder ?? find.byType(TabBar);
  final tabBar = tester.widget<TabBar>(finder.first);
  final controller = tabBar.controller;
  if (controller == null) {
    throw StateError(
      'switchToTab($index): TabBar has no controller to drive — '
      'pass tabBarFinder if multiple TabBars exist.',
    );
  }
  controller.animateTo(index);

  // Let the tab-change + TabBarView transition settle before the caller
  // queries the tree for the target tab's content.
  await settleWithTimeout(tester);
}

// --- Rule dialogs, moved from the port forwarding golden for IPv6 (#1687) ---

/// Taps the Add button carrying [identifier] and waits for its dialog.
Future<void> tapAdd(WidgetTester tester, String identifier) async {
  await tester.tap(find.byWidgetPredicate(
      (w) => w is AppIconButton && w.identifier == identifier));
  await settleWithTimeout(tester);
  // One more frame so the dialog's fields reach the semantics tree.
  await tester.pump();
}

/// Types [text] into the field carrying [identifier], focusing it first so the
/// next field's focus-loss validates it, as a user moving through the form does.
///
/// A field's identifier lives only in the semantics tree, so call this inside
/// [withSemantics].
Future<void> typeInto(
    WidgetTester tester, String identifier, String text) async {
  final field = find.descendant(
    of: find.bySemanticsIdentifier(identifier),
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pump();
  tester.testTextInput.enterText(text);
  await tester.pump();
}

/// Runs [steps] with a semantics tree, which the runner does not build, so the
/// fields can be found by identifier. The handle is released before the case
/// ends, as `flutter_test` requires.
Future<void> Function(WidgetTester) withSemantics(
        Future<void> Function(WidgetTester) steps) =>
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pump();
        await steps(tester);
      } finally {
        handle.dispose();
      }
    };
