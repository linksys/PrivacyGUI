// The wizard's firmware stage as a *screen*, behind linksys/PrivacyGUI#1553.
//
// Two requirements land here, and both are about shape rather than about state:
//
// REQ-B0 — the firmware update is a phase of the flow, not a fourth step of the
// form. The stepper counts steps the user fills in; a flash is not one of them, and
// the ticket's acceptance criterion is that the step count does not move.
//
// REQ-B2 — while the router is being flashed there is no way back to the form, no
// way on to the dashboard, and no Skip. The half of that lock which lives in
// routing has its own file (`test/route/pnp_firmware_exit_guard_test.dart`, which
// also records why the two guards read different predicates); this file measures
// the half that lives in the page.
//
// Since #1511 P4 these screens are drawn by `PnpFlowFrameView`, over the step Save
// was pressed on; they were `PnpSetupView`'s.
//
// Deliberately untagged, for the same reason the sibling `pnp_step_views_test.dart`
// is: `run_tests.sh` excludes `golden||loc||ui`, so a `ui` tag would keep these out
// of the set a PR cannot merge past. A wizard that offers a Done button mid-flash
// sends a user to a dashboard whose router is rebooting.


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_update_warning_note.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_flow_frame_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_your_network_step_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/collector.dart';
import '../../../layout_gate/surface.dart';
import '../../../util/dashboard/text_readability_probe.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_firmware_update.dart';
import '../../../mocks/provider_overrides/mock_pnp.dart';
import '../../../mocks/test_data/scenes/pnp_scene_data.dart';
import '../../../util/app_test_fonts.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  /// The router is mid-flash: `installing` with progress on the wire.
  ///
  /// Shared with the wizard's golden state and its layout-gate cell (#1554 §4) rather
  /// than declared here — `gatePnpFirmwareInstallingState` carries the reasoning for
  /// the phase and the percentage, including why `failed` would break the
  /// "no affordances" assertion below for a reason that is not a defect.
  const installing = gatePnpFirmwareInstallingState;

  /// The frame on Your Network — the step Save is pressed on — at [phase], with
  /// the plan of a router with a guest SSID (#1511 P4). The step is underneath
  /// every status screen, so "no button to press" below also proves it hidden.
  Widget host(PnpPhase phase, {FirmwareUpdateState firmware = installing}) =>
      pageSurfaceHost(
        view: const PnpFlowFrameView(
          stepId: 'network',
          child: PnpYourNetworkStepView(),
        ),
        locale: const Locale('en'),
        overrides: [
          ...pnpOverrides(PnpState(
            phase: phase,
            plan: pnpPlanWithGuest,
            meshNodes: pnpMeshNodes,
            serialNumber: 'SN-TEST',
          )),
          // The firmware phase watches `firmwareUpdateNotifierProvider` and hands
          // the state straight to W5's card, so without this the card renders
          // whatever a real notifier's `build()` returns — and its `loadBanks`
          // would reach the USP client.
          ...firmwareUpdateOverrides(state: firmware),
        ],
      );

  /// Same surface as the sibling view test's, and for the same reason: the form is
  /// taller and wider than 800×600, and a `RenderFlex` overflow is a `FlutterError`
  /// that would fail these tests over a layout the gate already owns.
  void enlargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Bounded pump. `WizardUpdatingFirmware` renders a linear `AppLoader`, which is
  /// an indeterminate animation when its value is null — `pumpAndSettle` would
  /// spin until it timed out.
  Future<void> pump(WidgetTester tester, PnpPhase phase,
      {FirmwareUpdateState firmware = installing}) async {
    await runWithOverflowCollection((_) async {
      enlargeSurface(tester);
      await tester.pumpWidget(host(phase, firmware: firmware));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    });
  }

  group('#1553 REQ-B0 — the firmware stage is not a step', () {
    testWidgets('the form still has exactly three steps', (tester) async {
      // The widest plan the wizard has: main Wi-Fi, guest and Your Network, so
      // three is the maximum, and a firmware step would make it four.
      await pump(tester, pnpWizardConfiguringState.phase);

      final stepper = tester.widget<AppStepper>(find.byType(AppStepper));
      expect(stepper.steps, hasLength(3),
          reason:
              'REQ-B0: the firmware update runs after the form is saved, so '
              'it must not appear as a step. A fourth entry here means someone '
              'added it to the plan instead of to the phase machine.');
    });

    testWidgets('the firmware phase renders no stepper at all', (tester) async {
      // The other direction of the same requirement: the stage is a full-screen
      // flow phase. If it rendered inside the stepper's `Column` the user would see
      // a progress bar with a form's chrome around it, and the step indices would
      // have to mean something during a flash.
      await pump(
          tester, const WizardUpdatingFirmware(version: '1.0.17.220118'));

      expect(find.byType(AppStepper), findsNothing);
    });
  });

  group('#1553 REQ-B2 — the wizard is locked while flashing', () {
    testWidgets('offers no button to press', (tester) async {
      // `AppButton` is what every affordance on this page is built from — the two
      // `Save`s, the three `Next`s and both `Done`s. Asserting on the type rather
      // than on labels is what makes this hold for a Skip nobody has written yet:
      // a new button cannot be added to this phase without turning it red.
      await pump(
          tester, const WizardUpdatingFirmware(version: '1.0.17.220118'));

      expect(find.byType(AppButton), findsNothing,
          reason: 'REQ-B2: no going back to the form, no proceeding to the '
              'dashboard, and no Skip. The router is being flashed and this '
              'wizard is the only thing that can finish the setup.');
    });

    testWidgets('shows the version it is installing', (tester) async {
      // The half of REQ-B2 that is not a lock: the user is told what is happening
      // to their router, since they cannot do anything else about it.
      await pump(
          tester, const WizardUpdatingFirmware(version: '1.0.17.220118'));

      expect(find.textContaining('1.0.17.220118'), findsOneWidget);
    });

    testWidgets('tells the user how long the wait is', (tester) async {
      // The lock has no cancel — REQ-B2 forbids one — so the only thing that makes
      // it tolerable is a bound. `_awaitFirmwareReboot` waits up to six minutes with
      // `_rebooting` rendering "Restarting router…" and no duration, which is a
      // spinner a user cannot distinguish from a hang.
      //
      // The shared note rather than a new string: `firmwareUpdateWarning` already
      // states the 5–8 minutes and the do-not-power-off, in 26 locales, and both
      // firmware pages already show it. A wizard flashing the same image had the
      // same install and none of the warning.
      await pump(
          tester, const WizardUpdatingFirmware(version: '1.0.17.220118'));

      expect(find.byType(FirmwareUpdateWarningNote), findsOneWidget);
      // Through the localization, so this measures the string that reached the
      // screen rather than the widget having been placed. A note that renders
      // empty is the failure the widget check alone would pass.
      final context = tester.element(find.byType(FirmwareInstallPhaseCard));
      expect(find.text(loc(context).firmwareUpdateWarning), findsOneWidget);
    });

    testWidgets('omits the version line when the router did not report one',
        (tester) async {
      // Some builds publish `Available=true` with an empty `Version`. A blank
      // "Version " line is worse than no line.
      await pump(tester, const WizardUpdatingFirmware(version: ''));

      expect(find.textContaining('Available:'), findsNothing,
          reason: 'an empty version must drop the line, not render '
              '"Available: " with nothing after it');
      expect(find.byType(FirmwareInstallPhaseCard), findsOneWidget,
          reason: 'the progress card is the screen; only the version line is '
              'conditional');
    });

    testWidgets('the completion screen does offer Done', (tester) async {
      // The control case, and the one that stops the lock from being "this page
      // never has buttons": the very next phase is the one the user leaves through.
      await pump(tester,
          const WizardWifiReady(ssid: 'MyWiFi', password: 'MyPass1234'));

      expect(find.byType(AppButton), findsWidgets);
    });
  });

  group('#1553 REQ-B4 — the completion screen and its way out', () {
    const ready = WizardWifiReady(ssid: 'MyWiFi', password: 'MyPass1234');

    /// The wizard on the completion screen, with the dashboard declared so Done has
    /// somewhere to land. Its own pump rather than the file's, because this route is
    /// one the other cases must not have.
    ///
    /// Two cases used to live here, both about deleting a persisted copy of the
    /// credentials — one on any unmount, one ordered before the navigation. That copy
    /// is gone (2026-09-16): the credentials live in the phase object and nowhere
    /// else, so leaving the screen *is* forgetting them, and there is no deletion left
    /// to order anything against. What survives is the half that is still behaviour —
    /// Done goes to the dashboard.
    Future<void> pumpReady(WidgetTester tester) async {
      await runWithOverflowCollection((_) async {
        enlargeSurface(tester);
        await tester.pumpWidget(pageSurfaceHost(
          view: const PnpFlowFrameView(stepId: null, child: SizedBox.shrink()),
          locale: const Locale('en'),
          overrides: [
            ...pnpOverrides(
                const PnpState(phase: ready, serialNumber: 'SN-TEST')),
            ...firmwareUpdateOverrides(state: const FirmwareUpdateState()),
          ],
          extraRoutes: [
            GoRoute(
              path: RoutePath.uspDashboard,
              name: 'test_dashboard',
              builder: (context, state) => const Text('DASHBOARD'),
            ),
          ],
        ));
        await tester.pumpAndSettle();
      });
    }

    testWidgets(
        'the credentials are on screen, and Done leaves for the '
        'dashboard', (tester) async {
      await pumpReady(tester);

      expect(find.text('MyWiFi'), findsOneWidget);
      expect(find.text('MyPass1234'), findsOneWidget);

      final context = tester.element(find.byType(PnpFlowFrameView));
      await tester.tap(find.widgetWithText(AppButton, loc(context).done));
      // Settled, not a single frame: `go_router` resolves a location through an
      // async parser, so one zero-duration pump does not render the destination even
      // when the navigation was dispatched immediately.
      await tester.pumpAndSettle();

      expect(find.text('DASHBOARD'), findsOneWidget);
    });
  });

  /// Bounded pump — the frame's spinners never settle.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
      'the reconnect screen says the router is restarting, and lays out at '
      '320px in every locale', (tester) async {
    // The copy is new (the old line said "connect your devices to your new WiFi"
    // while that network was not on the air yet), and the reconnect screen is in
    // no layout-gate case — so this is the only thing that renders it per locale.
    // 320px is the product floor and overflow is monotonic in width.
    final overflows = <String>[];
    for (final locale in AppLocalizations.supportedLocales) {
      await setLayoutSurface(tester, const Size(320, 1600));
      final errors = await runWithOverflowCollection((sink) async {
        await tester.pumpWidget(KeyedSubtree(
          key: ValueKey(locale.toString()),
          child: pageSurfaceHost(
            view:
                const PnpFlowFrameView(stepId: null, child: SizedBox.shrink()),
            locale: locale,
            overrides: pnpOverrides(pnpWizardNeedsReconnectState),
          ),
        ));
        await settle(tester);
        return sink;
      });
      if (errors.isNotEmpty) overflows.add('$locale: $errors');

      final copy = lookupAppLocalizations(locale).pnpReconnectWiFiRestarting;
      expect(find.text(copy), findsOneWidget, reason: '$locale');
    }

    expect(overflows, isEmpty, reason: overflows.join('\n'));
  });

  testWidgets(
      'neither completion-screen action button clips its label at 320px, in any '
      'locale', (tester) async {
    // **The assertion the layout gate structurally cannot make here, and the
    // second thing #1602's fix needs pinned.** That fix turned the `Print` /
    // `Done` `Row` into a `Wrap`, which removes the `RenderFlex` overflow the gate
    // was reading. It does not remove the failure mode: `RenderWrap` hands each
    // child the line's width as a *constraint*, so a button that wants more room
    // than the line has does not overflow — it **shrinks, and squeezes its
    // label**. Green gate, unreadable button.
    //
    // A first draft of this test asserted `buttonWidth <= wrap.constraints
    // .maxWidth` and was **inert**: mutation-checked by wrapping the `Wrap` in a
    // `SizedBox(width: 100)`, it stayed green, because that inequality is what
    // `RenderWrap` already guarantees. The oracle has to be the label, not the box.
    //
    // Measured 2026-09-21 at 320px, all 26 locales: the line is **174.0px**, the
    // widest button is `nl` at **146.0px** (`el` 143.1, `fr`/`fr_CA` 136.7), and
    // every locale's `Wrap` lays out **two runs** (104.0px tall) — so the
    // degradation really happens rather than the pair merely fitting, and no
    // label is squeezed: tightest headroom **28.0px**, ~19% of the button.
    //
    // 320px is the product floor (`kMinSupportedScreenWidth`) and overflow is
    // monotonic in width, so one width is the whole claim.
    final offenders = <String>[];
    for (final locale in AppLocalizations.supportedLocales) {
      await setLayoutSurface(tester, const Size(320, 1600));
      await tester.pumpWidget(KeyedSubtree(
        // A fresh subtree per locale, the same reason the gate's runner keys its
        // cell hosts: reused render objects would measure the first locale's
        // layout 26 times.
        key: ValueKey(locale.toString()),
        child: pageSurfaceHost(
          view: const PnpFlowFrameView(stepId: null, child: SizedBox.shrink()),
          locale: locale,
          overrides: pnpOverrides(pnpWizardWifiReadyUnifiedState),
        ),
      ));
      await settle(tester);

      // The unified completion screen builds exactly one `Wrap`. If a second ever
      // appears this throws rather than silently measuring the wrong one.
      final buttons = find.descendant(
          of: find.byType(Wrap), matching: find.byType(AppButton));
      expect(buttons, findsNWidgets(2),
          reason: 'the action Wrap should hold Print and Done');

      for (var i = 0; i < 2; i++) {
        final label =
            find.descendant(of: buttons.at(i), matching: find.byType(Text));
        if (label.evaluate().length != 1) continue;
        final paragraph = tester.paragraphOf(label);
        final text = paragraph.text.toPlainText();
        // Both verdicts, in the order rule 4 of the gate skill puts them: neither
        // subsumes the other. An ellipsis leaves every surviving token fitting, and
        // a mid-word break drops nothing, so `didExceedMaxLines` stays false.
        if (tester.isTextClipped(label)) {
          offenders.add('$locale: "$text" is truncated inside its button — '
              'granted ${paragraph.size.width.toStringAsFixed(1)}px');
        } else if (!kLocalesWithoutWordSpaces.contains(locale.toString()) &&
            tester.hasSplitToken(label)) {
          offenders.add('$locale: "$text" broke mid-word inside its button — '
              'granted ${paragraph.size.width.toStringAsFixed(1)}px, widest token '
              '${tester.widestTokenWidth(label).toStringAsFixed(1)}px');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a `Wrap` constrains its children to the line, so a button with too '
          'little room squeezes its label instead of overflowing — invisible to '
          'every one of the 234 cells in page.pnp_setup_complete_unified:\n'
          '${offenders.join('\n')}',
    );
  });
}
