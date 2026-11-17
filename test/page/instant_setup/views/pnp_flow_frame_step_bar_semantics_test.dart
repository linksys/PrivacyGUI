// The PnP step bar must reach the semantics tree under the real ShellRoute
// (linksys/PrivacyGUI#1841).
//
// Since #1816 the stepper is drawn by `PnpFlowFrameView`, around the PnP
// shell's nested `Navigator`. Every step is a `MaterialPage`, i.e. a
// `ModalRoute`, whose `ModalBarrier` is a `BlockSemantics`: it drops the
// semantics of everything painted before it in the same semantics container.
// The stepper shared that container and was painted first, so its segments
// (`wifi` / `guest` / `network`) were on screen but not in the semantics tree —
// screen readers could not announce them, and E2E P30 could not find them.
//
// The test is the shape of the app: a real go_router `ShellRoute` whose builder
// hands its `child` (the nested Navigator) to `PnpFlowFrameView`. A plain-widget
// child would not reproduce the bug, so none is used here.
//
// Deliberately untagged: `run_tests.sh` excludes `golden||loc||ui`, and this is
// a regression guard a PR must not merge past.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_flow_frame_view.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_pnp.dart';
import '../../../mocks/test_data/scenes/pnp_scene_data.dart';
import '../../../util/app_test_fonts.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  const segmentIds = ['wifi', 'guest', 'network'];
  const pageAnchor = 'pnp-1841-step-page';

  /// Pumps `PnpFlowFrameView` exactly as `pnpShellRoute` does — as the builder
  /// of a `ShellRoute` — and navigates to the step [stepId].
  Future<void> pumpUnderShellRoute(WidgetTester tester, String stepId) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(pageSurfaceHost(
      view: const Text('ROOT'),
      locale: const Locale('en'),
      overrides: pnpOverrides(pnpWizardConfiguringState),
      childRoutes: [
        ShellRoute(
          builder: (context, state, child) => PnpFlowFrameView(
            stepId: state.uri.pathSegments.last,
            child: child,
          ),
          routes: [
            for (final id in segmentIds)
              GoRoute(
                path: id,
                builder: (context, state) => Semantics(
                  identifier: pageAnchor,
                  child: Text('STEP BODY $id'),
                ),
              ),
          ],
        ),
      ],
    ));
    await tester.pump();
    GoRouter.of(tester.element(find.text('ROOT'))).go('/$stepId');
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  for (final stepId in segmentIds) {
    testWidgets(
        'on step "$stepId" every step-bar segment is in the semantics tree',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpUnderShellRoute(tester, stepId);

      // Premise: the step page is routed through the nested Navigator and the
      // frame drew the stepper. Without this, a missing segment could mean the
      // stepper simply was not built.
      expect(find.text('STEP BODY $stepId'), findsOneWidget);
      expect(find.byType(PnpFlowFrameView), findsOneWidget);

      for (final id in segmentIds) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget,
            reason: 'step-bar segment "$id" must be in the semantics tree '
                '(#1841: the route\'s ModalBarrier must not block it)');
      }

      // The fix must not hide the page: its own semantics stay in the tree
      // (an ExcludeSemantics over the routed child would pass the check above
      // and fail this one).
      expect(find.bySemanticsIdentifier(pageAnchor), findsOneWidget,
          reason: 'the step page\'s own semantics must still be present');
      handle.dispose();
    });
  }
}
