/// #1395 AC2 — the frame the grid is withheld for, and why it has to be.
///
/// `SliverDashboard` compares the width it is handed against
/// `controller.slotCount` and, when they differ, schedules `setSlotCount` in a
/// post-frame callback. Until 2.0.0 it *also* returned an empty sliver for that
/// one frame — a "skip frame optimization" — and 2.x kept the callback and
/// dropped the early return, so the outgoing grid's geometry is now laid out at
/// the incoming grid's width: at 320px every half-width desktop card is drawn six
/// columns wide in a four-column viewport. The overflow gate reported the whole
/// page overflowing at all four widths below desktop, in every locale, on 2.6.0
/// and on none of them on 0.9.1.
///
/// So `usp_sliver_dashboard_view` does the skip itself. The gate's four narrow
/// cells are what caught the regression and they would catch it again, but they
/// take minutes and they cannot say *which* of the fix's two halves is
/// load-bearing: at 320 and 480 the seed alone stops the throw
/// (`layout_engine.dart:963`), and only at 601 and 905 does the withheld frame
/// matter. This file pins the withhold on its own, in the unit lane, in a second.
///
/// ## Mutation table
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | usp_sliver_dashboard_view | drop the `!slotsAreCurrent` ternary, always build the grid | all three — and two of them not by a finder but by `A RenderFlex overflowed by 21 pixels`, which is the gate's own narrow-width failure, reproduced here in one second |
/// | 2 | usp_sliver_dashboard_view | drop the post-frame `setSlotCount`, keep the ternary | all three: without the catch-up the withheld frame is every frame |
/// | 3 | usp_sliver_dashboard_view | read the slot count (`.value`) instead of watching it | 'and the frame after it does' — the catch-up runs, but nothing brings the build back to notice, so the empty sliver is permanent |
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
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

/// Desktop and phone, either side of a `currentMaxColumns` boundary: 12 columns
/// at 1280 and 4 at 480. The height is the page sweep's, so the same cards are
/// built as the gate builds.
const _desktop = Size(1280, 1600);
const _phone = Size(480, 1600);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpAt(WidgetTester tester, Size size) async {
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
    await settleIgnoringAnimations(tester);
    return container;
  }

  testWidgets('the frame that observes a new breakpoint has no grid in it',
      (tester) async {
    final container = await pumpAt(tester, _desktop);
    expect(find.byType(SliverDashboard), findsOneWidget,
        reason: 'the premise: a settled page at a breakpoint the controller is '
            'already on does render the grid');
    expect(container.read(uspSliverDashboardControllerProvider).slotCount.value,
        12);

    // The resize the user does by dragging a window edge. One frame only: the
    // page has observed 4 columns, the controller has not been moved to them yet,
    // and laying the 12-column geometry out here is what overflowed.
    tester.view.physicalSize = _phone;
    await tester.pump();

    expect(find.byType(SliverDashboard), findsNothing,
        reason: 'the frame is withheld rather than laid out at the wrong width');
    // The catch-up is scheduled post-frame and `pump` retires post-frame
    // callbacks, so it has already run by the time this line reads it — what the
    // assertion above records is that it did not run *during* the build, which is
    // the ordering that matters: `setSlotCount` writes a beacon half the grid is
    // watching.
    expect(container.read(uspSliverDashboardControllerProvider).slotCount.value,
        4);
  });

  testWidgets('and the frame after it does', (tester) async {
    final container = await pumpAt(tester, _desktop);

    tester.view.physicalSize = _phone;
    await tester.pump();
    await tester.pump();

    expect(container.read(uspSliverDashboardControllerProvider).slotCount.value,
        4,
        reason: 'the post-frame callback ran');
    expect(find.byType(SliverDashboard), findsOneWidget,
        reason: 'and the grid is back, on the grid it is being rendered at — a '
            'withhold that is not followed by a catch-up is a blank dashboard');
  });

  testWidgets('a page opened on a phone renders the phone grid', (tester) async {
    // The boot case, which is what the gate's 320 and 480 cells measure: a fresh
    // controller starts on the desktop breakpoint whatever width the page is
    // about to be laid out at, so the first frame is withheld and the settled
    // page is the phone grid — never the desktop one, and never an assertion
    // from `correctBounds` leaving `minW: 6` on a four-column grid.
    final container = await pumpAt(tester, _phone);

    expect(container.read(uspSliverDashboardControllerProvider).slotCount.value,
        4);
    expect(find.byType(SliverDashboard), findsOneWidget);
  });
}
