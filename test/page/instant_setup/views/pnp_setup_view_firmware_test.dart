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
// Deliberately untagged, for the same reason the sibling `pnp_setup_view_test.dart`
// is: `run_tests.sh` excludes `golden||loc||ui`, so a `ui` tag would keep these out
// of the set a PR cannot merge past. A wizard that offers a Done button mid-flash
// sends a user to a dashboard whose router is rebooting.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_setup_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/collector.dart';
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
  /// The phase is a choice and the only safe one for this file. The card renders a
  /// retry button on `failed`, and a retry *is* an affordance — so pinning `failed`
  /// would make the "no affordances" assertion below fail for a reason that is not
  /// a defect. A failure never reaches this screen anyway: `_runFirmwareStage`
  /// catches it and finishes setup, which is REQ-B3.
  const installing = FirmwareUpdateState(
    phase: FirmwareUpdatePhase.installing,
    otaProgress: FirmwareOtaInstallProgress(
      status: FirmwareAutoUpdateStatus.downloading,
      rawProgress: 42,
      rawState: 'downloading',
    ),
  );

  Widget host(PnpPhase phase, {FirmwareUpdateState firmware = installing}) =>
      pageSurfaceHost(
        view: const PnpSetupView(),
        locale: const Locale('en'),
        overrides: [
          ...pnpOverrides(PnpState(phase: phase, serialNumber: 'SN-TEST')),
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
      // The widest configuration the wizard has: main Wi-Fi + guest + a mesh
      // network. `_buildStepperForm` computes `1 + guest + mesh`, so three is the
      // maximum, and a firmware step would make it four.
      await pump(tester, pnpWizardConfiguringState.phase);

      final stepper = tester.widget<AppStepper>(find.byType(AppStepper));
      expect(stepper.steps, hasLength(3),
          reason:
              'REQ-B0: the firmware update runs after the form is saved, so '
              'it must not appear as a step. A fourth entry here means someone '
              'added it to `_buildStepperForm` instead of to the phase machine.');
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
}
