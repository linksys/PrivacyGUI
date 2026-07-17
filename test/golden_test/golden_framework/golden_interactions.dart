import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared interaction helpers for golden `Interaction.steps`.
///
/// These exist to keep interaction steps locale-independent and free of
/// brittle geometry-based gestures.

/// Switches to the tab at [index] by driving the [TabController] directly,
/// then pumps until the tab-change animation settles.
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
  assert(controller != null, 'TabBar has no controller to drive.');
  controller!.animateTo(index);

  // Let the tab-change + TabBarView transition settle. TabController animations
  // run ~300ms; pump generously past that so the target tab's content is fully
  // built and interactive before the caller queries the tree.
  await tester.pump();
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
