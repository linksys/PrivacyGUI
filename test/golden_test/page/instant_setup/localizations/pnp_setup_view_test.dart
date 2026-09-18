import 'package:privacy_gui/page/instant_setup/views/pnp_setup_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_firmware_update.dart';
import '../../../../mocks/provider_overrides/mock_pnp.dart';
import '../../../../mocks/test_data/scenes/pnp_scene_data.dart';

// The setup wizard's first golden suite (#1554 §4), and the first for `instant_setup`
// at all: before this file, `test/golden_test/` held 31 suites and none of them pumped
// a PnP view. The ticket was written believing `pnp_setup` already had one and only
// wanted the firmware phase added to it; measured on 2026-09-16 it had zero, so the
// scope decision — which of the wizard's phases are worth a picture — had to be made
// here rather than inherited.
//
// ## Why the wizard is different from every other suite in this directory
//
// Every other view here is a *destination*: it fetches, and a state key names how the
// fetch went. `PnpSetupView` is a **state machine's screens** — one view over one
// provider, where `PnpState.phase` decides which page-sized tree is built. So a state
// key here names a phase, and the count of keys is decided by the phase→builder map
// rather than by the number of phases:
//
//   * **Nine phases reach seven builders.** `WizardSaving`, `WizardSaved` and
//     `WizardCheckingFirmware` all reach `_buildSavingOverlay`, which takes no
//     arguments — three phases, one tree, one picture. `saving` below stands for all
//     three, and `pnpWizardSavingState`'s doc says so, because the day one of them
//     grows its own copy is the day this key stops covering it.
//   * **One phase reaches two builders.** `WizardWifiReady` branches on `isSplitMode`
//     — `bands.length > 1`, derived rather than stored — into two structurally
//     different completion screens. Hence two keys.
//   * **The tenth branch is not a phase.** The `_ =>` arm draws a bare `AppLoader` for
//     every phase that belongs to another view (the admin checks, the troubleshooter,
//     the ISP forms). A picture of a centred spinner in 26 languages is a picture of a
//     spinner, so it is left out.
//
// ## `configuring` is photographed at step 0 only
//
// The stepper's other two steps are behind taps. That is a real limit and not one this
// file works around with an `Interaction`: the wizard's steps mutate provider state
// through `PnpNotifier`, and `FixedPnpNotifier` pins the phase — so a tap that
// "advanced" the stepper would be photographing a widget's internal `_currentStep`
// against a state that never moved. The layout gate has the same limit for the same
// reason, and its case doc records it. What step 0 does carry is the widest form the
// view has: split mode, three bands, guest bands, and a three-label `AppStepper`.
//
// ## `height: 1600`
//
// Larger than any other suite here, and measured rather than picked. The split-mode
// form at 480px is a per-band `LayoutBlock` — band label, SSID field, passphrase field
// and its three-rule list — three times over, under a stepper, so at the device's
// default 800 the picture would be a scroll position rather than a page.
//
// The number is the tallest state's measured content height plus headroom for
// translation, in that order. `configuring` at 480px, **decoded off the generated
// frames** rather than eyeballed: `en` **1301**, `de` **1393**, `fr` **1421**, `ru`
// **1422**. The growth is in the intro paragraph and in all three password rule lists,
// each of which gains a line. So 1600 clears the tallest by **~178px**, and `fr` is
// tied with `ru` for tallest — a first draft of this comment read ~205px off `ru`
// alone, having measured by looking.
//
// **Four of the 26 locales, not all of them**, so "the tallest" is the tallest
// *measured* and the headroom is what carries the rest. Erring high rather than low is
// deliberate and the two errors are not symmetric: too much height costs legible
// whitespace in a PNG, while too little silently crops the bottom of the form — and the
// bottom of the form is where `Next` is. A locale wrapping harder than `fr`/`ru` would
// lose the primary action with nothing failing, so this is a number to re-measure when
// a locale is added, not one to leave alone.
//
// ## What 1600 costs the other seven states, since the argument against 2000 applies
//
// `configuring` is the only top-aligned state here; `_buildStepperForm` is a Column and
// every other builder returns `Center(...)`. Measured extents at 480px: `complete_split`
// 1195, `needs_reconnect` 1032, `updating_firmware` 1022, `error` 992. So seven of the
// eight states carry 400–600px of ground, split above and below the card because they
// are centred — and this file rejected 2000 for spending 600px of whitespace on every
// state, which is the same objection at a smaller number.
//
// **One suite anyway, and the reason is arithmetic rather than convenience.** `height`
// is per-config, so the only way to give the centred states their own is a second
// `viewName` — a second golden namespace, a second baseline set in `golden-ci`, and a
// second place to keep the phase list in step with `PnpSetupView`'s switch. What that
// would buy is bounded by the tallest centred state: 1195 plus the same translation
// headroom is ~1400, i.e. **~12% fewer pixels** on those seven. Not worth splitting the
// wizard's phase list in two. Revisit if a centred state ever gets much shorter, or if
// `configuring` grows past 1600 and forces a re-measure anyway.
// ## Two of these states draw an indeterminate loader, and they are not flaky
//
// `saving` and `testing_reconnect` render a bare `AppLoader` with no value — an
// animation — which is the obvious way for a new suite to start failing golden-ci
// intermittently. Measured rather than assumed: two consecutive `--update-goldens`
// runs at one configuration produced **byte-identical** PNGs for all six states
// checked, both loader states included. The runner is what makes that true — it forces
// `disableAnimations: true` through a `MediaQuery` *inside* `MaterialApp`, so the views
// under test observe it, and it settles with a timeout rather than `pumpAndSettle`,
// which an indeterminate animation would never satisfy.
//
// The trap next to it, since it cost a wrong verdict here: two generations only compare
// if nothing about the config moved between them. The first comparison run for this file
// crossed a `height` edit and read as non-deterministic on all three states — including
// the *determinate* one, which is what said the diagnosis was wrong.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'pnp_setup',
      view: () => const PnpSetupView(),
      // The view builds its own `UiKitPageView` (the plain constructor, not
      // `.withSliver` — unlike both firmware pages) with
      // `appBarStyle: UiKitAppBarStyle.none`: the wizard deliberately has no back
      // affordance in its chrome, which is half of REQ-B2's lock. Wrapping it in
      // another shell would photograph a bar the app never draws here.
      shell: ShellType.custom,
      height: 1600,
      states: {
        // Step 0 of the three-step form — the only phase this view renders a form in,
        // and the fixture the layout gate sweeps.
        'configuring': (overrides) => overrides.addAll(
              pnpOverrides(pnpWizardConfiguringState),
            ),
        // `_buildSavingOverlay`, standing for `WizardSaving`, `WizardSaved` and
        // `WizardCheckingFirmware`.
        'saving': (overrides) => overrides.addAll(
              pnpOverrides(pnpWizardSavingState),
            ),
        // The only screen that asks the user to leave the app and join a different
        // network — so the SSID it prints is the thing to check per language.
        'needs_reconnect': (overrides) => overrides.addAll(
              pnpOverrides(pnpWizardNeedsReconnectState),
            ),
        // The poll, with `(5/5)` interpolated into a localized sentence — the last of
        // the five attempts `testReconnect()` makes, which is the whole domain this
        // phase has. The parenthetical is appended in `lib` rather than being part of
        // the ARB string, which is exactly the kind of construction a per-language
        // picture is for.
        'testing_reconnect': (overrides) => overrides.addAll(
              pnpOverrides(pnpWizardTestingReconnectState),
            ),
        // The firmware stage — the state #1554 §4 was filed for, and the one that needs
        // two overrides rather than one.
        //
        // `firmwareUpdateOverrides` is not optional here: the phase hands
        // `firmwareUpdateNotifierProvider`'s state straight to W5's
        // `FirmwareInstallPhaseCard`, so without it a real notifier's `build()` runs
        // and its `loadBanks` reaches the USP client — a golden that would either hang
        // or photograph whichever of two frames it settled on.
        //
        // What is in the picture and has never been in one: a determinate linear
        // `AppLoader` (a real `LinearProgressIndicator` since ui_kit 3.3.2, so the bar
        // has a *width* that is a function of the percentage), its numeric label, the
        // version line, and the shared 5–8-minute warning note — in 26 languages,
        // with no button anywhere on screen.
        'updating_firmware': (overrides) => overrides.addAll([
              ...pnpOverrides(pnpWizardUpdatingFirmwareState),
              ...firmwareUpdateOverrides(state: gatePnpFirmwareInstallingState),
            ]),
        // Setup complete, unified mode: one SSID and one passphrase.
        'complete_unified': (overrides) => overrides.addAll(
              pnpOverrides(pnpWizardWifiReadyUnifiedState),
            ),
        // Setup complete, split mode: `_buildCompleteSplitMode` draws one credential
        // row per band, so three bands is three rows of label-plus-SSID-plus-passphrase.
        // The taller of the two completion screens and the one that can run out of
        // width — a different builder, not a longer list.
        'complete_split': (overrides) => overrides.addAll(
              pnpOverrides(pnpWizardWifiReadySplitState),
            ),
        // The recoverable failure. `message` reaches the screen verbatim, so the
        // fixture carries a real sentence — see `pnpWizardErrorState`.
        'error': (overrides) => overrides.addAll(
              pnpOverrides(pnpWizardErrorState),
            ),
      },
    ),
  );
}
