/// The one way the dashboard page tests put the real page on screen.
///
/// Hoisted out of three files that carried byte-identical copies of it
/// (`edit_mode_tile_rebuild_test.dart`, `breakpoint_catchup_test.dart`,
/// `edit_mode_interactions_test.dart`). The duplication mattered for the theme in
/// particular: a change to the design-theme contract — a new required key in the
/// JSON, a renamed style token — would have had to land in three places, and the
/// file that missed it would fail while constructing its theme, nowhere near what
/// it was testing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';
import 'package:privacy_gui/page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../mocks/provider_overrides/mock_dashboard_page.dart';
import 'settle.dart';

/// The theme these tests pump the page under.
///
/// A style is pinned rather than defaulted, so that the three files build the
/// same tree. `flat` is the one whose surfaces carry no enhanced effect — the
/// demo's default, glass, animates a shimmer border, which is one more endless
/// animation in a page that already has several.
final dashboardTestTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Pumps the real dashboard page at [size], optionally in edit mode.
///
/// The real controller, widget factory and edit-mode notifier, over
/// [dashboardPageOverrides] — the fixture the layout gate already uses for this
/// page. A stand-in grid or a stand-in `itemBuilder` would measure a
/// configuration we do not ship.
///
/// The returned container is disposed, and the view metrics reset, by teardowns
/// registered here — the caller only has to read from it.
Future<ProviderContainer> pumpDashboardPage(
  WidgetTester tester, {
  required Size size,
  bool editing = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: dashboardPageOverrides());
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: dashboardTestTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: UspSliverDashboardView()),
    ),
  ));
  // Not `pumpAndSettle`: the page carries looping animations, and edit mode adds
  // one — `JiggleShake` never ends, which is the point of it.
  await settleIgnoringAnimations(tester);

  if (editing) {
    await container.read(dashboardEditModeProvider.notifier).enterEditMode();
    await settleIgnoringAnimations(tester);
  }
  return container;
}
