import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
