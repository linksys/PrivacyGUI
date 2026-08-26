import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_setup_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/collector.dart';
import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/incident.dart';
import '../../../mocks/provider_overrides/mock_pnp.dart';
import '../../../mocks/test_data/scenes/pnp_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// Lifecycle tests for [PnpSetupView] — deliberately **untagged**.
///
/// `run_tests.sh` runs `--exclude-tags="golden||loc||ui"`, so the sibling
/// `pnp_no_internet_view_test.dart`'s `@Tags(['ui'])` keeps it out of the PR
/// gate. The defect below is a production crash, so its regression test has to
/// be in the set a PR cannot merge past.
///
/// ## The defect (#1378)
///
/// The four unified-mode controllers were `late final` fields assigned only
/// inside `_initControllers(WizardConfiguring)`, while `dispose()` disposed all
/// four unconditionally. Every phase other than `WizardConfiguring` renders
/// through `_ => const Center(child: AppLoader())` and never calls
/// `_initControllers`, so any user who left the wizard before it finished
/// initialising — back button, a `WizardError`, a `WizardSaving` that navigated
/// away — tore the widget down into a `LateInitializationError`.
///
/// It surfaced as a *gate* finding rather than a *field* report because #1378
/// tried to sweep this page across 208 cells and every cell died at teardown.
/// The fix is in the widget: the controllers are created with the field, and
/// `_initControllers` assigns `.text`.
///
/// ## The second finding, and why it is pinned here
///
/// Sweeping this page also found a layout overflow that is **not ours to fix**:
/// `AppStepper`'s bar variant divides `constraints.maxWidth` among its bars while
/// each bar carries a permanent 4px of horizontal focus-ring offset, so it
/// overflows by `stepCount × 4` at every width in every locale. The last test in
/// this file pins that arithmetic, because it is the thing standing between this
/// page and the gate — see its own doc comment.
void main() {
  setUpAll(() async {
    // Real fonts, because the last test measures an overflow in pixels and Ahem
    // makes every glyph the same box.
    await loadAppFonts();
  });

  /// Hosted through the layout gate's [pageSurfaceHost] rather than a local
  /// `MaterialApp`, because this page needs the app's real route scaffolding: the
  /// `UspTopBar` inside `UiKitPageView` reaches `GoRouter.of(context)` unguarded
  /// from `MenuHolderState.didChangeDependencies`, so a plain `MaterialApp` throws
  /// `No GoRouter found in context` before the phase under test is ever reached.
  /// That host's own header records it as the single place a real page is pumped
  /// and `test/util/detail_view_probe.dart` already delegates to it, so this is
  /// reuse rather than a third copy.
  ///
  /// `pnpOverrides` pins the phase, so each test below states which branch of the
  /// view's `switch` it is tearing down rather than inheriting whatever
  /// `PnpNotifier.build()` happens to return.
  Widget host(PnpPhase phase) => pageSurfaceHost(
        view: const PnpSetupView(),
        locale: const Locale('en'),
        overrides: pnpOverrides(
          PnpState(phase: phase, serialNumber: 'SN-TEST'),
        ),
      );

  /// The wizard form is taller and wider than the default 800×600 test surface,
  /// and a `RenderFlex` overflow is a `FlutterError` — so a cramped surface would
  /// fail these tests for a reason that has nothing to do with the lifecycle they
  /// are about. Width and locale coverage is the layout gate's job
  /// (`test/page/_shared/page_surface_overflow_test.dart`), not this file's.
  void enlargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Bounded pump — same reason as the sibling view test's.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Pumps [phase], then replaces the tree so `dispose()` runs, and returns
  /// whatever the framework captured.
  ///
  /// Replacing the tree rather than ending the test is what makes the teardown
  /// observable: an error thrown while finalizing the tree at the *end* of a
  /// `testWidgets` body is reported against the test either way, but only a
  /// mid-test disposal lets the assertion name the phase that caused it.
  ///
  /// Wrapped in [runWithOverflowCollection] so a `RenderFlex` overflow lands in
  /// `sink` instead of in `takeException()`. Without it the `WizardConfiguring`
  /// cases below would report `AppStepper`'s overflow (see the last test) as
  /// though the page had failed to tear down — a layout defect masquerading as a
  /// lifecycle one. Genuine errors are still forwarded, which is what keeps the
  /// `LateInitializationError` these tests exist for visible. `cell: null`
  /// (the default) keeps these pumps out of the coverage dataset: they are not
  /// sweep coordinates.
  Future<Object?> exceptionOnDispose(
    WidgetTester tester,
    PnpPhase phase,
  ) {
    return runWithOverflowCollection((_) async {
      enlargeSurface(tester);
      await tester.pumpWidget(host(phase));
      await settle(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      return tester.takeException();
    });
  }

  // The phases the switch in `build` routes to the loader — i.e. every phase a
  // user can be in *before* the wizard has anything to edit. `WizardError` is
  // in the list on purpose: it renders its own tree, so it is the one case
  // where the page was visibly useful and still could not be torn down.
  final phasesThatNeverInitControllers = <String, PnpPhase>{
    'AdminCheckingInternet': const AdminCheckingInternet(),
    'WizardInitializing': const WizardInitializing(),
    'WizardSaving': const WizardSaving(),
    'WizardError': const WizardError(message: 'boom'),
  };

  for (final entry in phasesThatNeverInitControllers.entries) {
    testWidgets('disposes cleanly from ${entry.key}', (tester) async {
      final error = await exceptionOnDispose(tester, entry.value);

      expect(
        error,
        isNull,
        reason: 'leaving PnpSetupView at ${entry.key} threw on dispose. The '
            'four unified-mode controllers are only assigned inside '
            '_initControllers(WizardConfiguring), and dispose() disposes them '
            'unconditionally — so every phase that renders the loader crashes '
            'on teardown. Initialize them with the field, not in the phase '
            'handler.',
      );
    });
  }

  testWidgets('disposes cleanly from WizardConfiguring too', (tester) async {
    // The path that always worked, kept so the fix cannot be "make dispose
    // conditional and never dispose anything".
    final error = await exceptionOnDispose(
      tester,
      WizardConfiguring(wifiConfig: pnpUnifiedWifiConfig),
    );

    expect(error, isNull);
  });

  testWidgets('prefills the unified-mode fields from the phase\'s config',
      (tester) async {
    // The behaviour eager initialization must not lose: the controllers exist
    // before the config arrives, so their text has to be assigned when it does.
    await runWithOverflowCollection((_) async {
      enlargeSurface(tester);
      await tester.pumpWidget(host(
        WizardConfiguring(wifiConfig: pnpUnifiedWifiConfig),
      ));
      await settle(tester);
    });

    // `find.text` reads `EditableText.controller.text`, so it sees the obscured
    // password field too.
    expect(find.text(pnpUnifiedWifiConfig.ssid), findsOneWidget);
    expect(find.text(pnpUnifiedWifiConfig.password), findsOneWidget);
  });

  /// A **tripwire on someone else's bug**, and the reason this page is not in
  /// `kPageSurfaceCases` yet (#1378).
  ///
  /// `AppStepper._buildBarStepper` (ui_kit v2.40.1,
  /// `lib/src/molecules/stepper/app_stepper.dart:232`) sizes its bars by dividing
  /// the width it was given:
  ///
  /// ```dart
  /// final barWidth = (totalWidth - totalGaps) / stepCount;
  /// ```
  ///
  /// but each bar is wrapped in `AppInteractionSensor` → `AppFocusIndicator`,
  /// which pads `EdgeInsets.all(focusStyle.ringOffset)` **unconditionally** —
  /// `needsOffset` is `!useGlow && ringOffset > 0`, with no reference to whether
  /// anything is focused (`app_focus_indicator.dart:148`). `ringOffset` defaults
  /// to `2.0` and this app never overrides `focusStyle`, so every bar is 4px wider
  /// than the arithmetic above allows and the `Row` overflows by
  /// `stepCount × 4` — at every width, in every locale, in production as much as
  /// in this test.
  ///
  /// Three things follow, and this test exists to keep all three honest:
  ///
  /// 1. It cannot be fixed here. `AppStepper` is the only ui_kit component this
  ///    app renders (one call site, `pnp_setup_view.dart:257`) and ui_kit is a
  ///    tag-pinned git dependency, so the fix is a PR there plus a bump here.
  /// 2. It cannot be fixed in the fixture either. The one wizard shape that lays
  ///    out clean is a single-step one — `_buildStepperForm` renders no
  ///    `AppStepper` at all when `totalSteps == 1` — i.e. the fixture that hides
  ///    the widget under test. #1378 forbids exactly that move.
  /// 3. So `pnp_setup` stays `queued` in `test/fixtures/page_roster.tsv` while the
  ///    other eight instant_setup pages are declared. Queued **with a figure**, and
  ///    the roster's `# blocked` header block says why: #1378 did sweep this page's
  ///    208 cells through `pnpWizardConfiguringState` and all 208 failed at
  ///    +12.0px — a 3-step wizard — so it is sweep debt, not fixture debt.
  ///
  /// **When ui_kit is fixed this test goes red.** That is the intended signal: at
  /// that point declare a `kPnpSetupPageCase` in
  /// `test/layout_gate/families/page_surface_cases.dart` over
  /// `pnpOverrides(pnpWizardConfiguringState)` — requiring `AppStepper` and
  /// forbidding `AppLoader` — flip the roster row to `swept`, and then delete this
  /// test, in that order.
  testWidgets('ui_kit AppStepper still overflows by stepCount x 4 — so this '
      'page cannot be declared in the layout gate yet', (tester) async {
    final incidents = <OverflowIncident>[];
    await runWithOverflowCollection((sink) async {
      enlargeSurface(tester);
      await tester.pumpWidget(host(
        WizardConfiguring(wifiConfig: pnpUnifiedWifiConfig),
      ));
      await settle(tester);
      incidents.addAll(sink);
    });

    final steps = tester.widget<AppStepper>(find.byType(AppStepper)).steps.length;
    expect(steps, 2, reason: 'main + guest, from pnpUnifiedWifiConfig');
    expect(
      incidents.map((i) => i.pixels),
      [steps * 4.0],
      reason: 'the bar stepper overflow is stepCount x 2 x ringOffset(2.0). If '
          'this list is now empty, ui_kit fixed it: delete this test and declare '
          'kPnpSetupPageCase. If the number moved, re-derive it before trusting '
          'either side — the roster row and #1369\'s cost projection both quote '
          'it.',
    );
    expect(
      incidents.single.file,
      contains('app_stepper.dart'),
      reason: 'an overflow of the same size from one of our own Rows would be '
          'ours to fix, and must not pass as this known one',
    );
  });
}
