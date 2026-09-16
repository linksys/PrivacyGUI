import 'package:privacy_gui/page/firmware_update/views/firmware_ota_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_firmware_update.dart';
import '../fixtures/firmware_update_test_data.dart';

// The OTA entry point's first suite (#1554 §1). #1549 split one firmware page in
// two and this half went out with no golden of any state — the sibling file says why
// that was deliberate at the time, and the entry condition it was waiting on (the
// design being settled) is met: `92bf02a9` and `11c8c100` were the last shape
// changes, and the flow has since been run on hardware.
//
// **`shell: ShellType.custom` and `height: 900`, both matching the sibling**, and for
// the same two reasons: this view builds its own `UiKitPageView.withSliver` including
// the top bar, and the page is taller than either device's default, so a shorter
// surface would photograph a scroll position instead of a page.
//
// ## What is photographed, and what a picture buys over the tests already here
//
// Six states. The ordering below is the page's own: the two states of a check in
// flight or not yet run, then the two verdicts a completed check produces, then the
// two states that are about the *router* rather than about a check. (Three verdicts
// exist, not four — `notChecked` is the resting one, which is why `idle_not_checked`
// heads the list rather than being counted again further down.)
//
// Three of the six are the only image of themselves anywhere, because the
// layout-gate case for this page (`page.firmware_ota`, 234 cells) pins exactly one
// fixture and cannot reach them:
//
//   * **`idle_update_available`** — the install button. The gate case's own doc
//     records this as a named coverage gap: swapping its verdict would break the
//     readability guard built on `firmwareNoUpdateFound`, and the *overflow* risk was
//     separately measured at zero. Zero overflow risk is not a picture, though. The
//     offer line, its icon and the second full-width button have never been seen in
//     any locale.
//   * **`ota_absent`** — REQ-A1's router, which has no virtual `ota` row and is
//     therefore never offered the check at all. The gate case pins
//     `gateFirmwareBanksWithOta` precisely so it does *not* land here.
//   * **`state_unreadable`** — the read-failure card. It needs the banks read to have
//     failed, and every gate fixture answers.
//
// The other three are swept, and are photographed anyway for what a sweep cannot
// see. `checking` is the headline of the ticket and the reason this file is not just
// three new pictures: it is the only state in the app where `AppButton.isLoading`
// renders on this page, and busy is drawn as a `BusyFigureLayer` — the active
// language's `AppDesignTheme.busyFigure` in the button's own `AppButtonStyle.busyColor`,
// clipped to the button's shape and sitting *over* the label rather than replacing
// it. That is per-language and per-component at once, and no assertion can say
// whether the label survived underneath it.
//
// **What the first capture of it showed, recorded because it is the only reading
// anyone has** (`en`, both devices, 2026-09-16): the label survives — "Check for
// Updates" is legible — but at markedly lower contrast than the resting state's, pale
// blue on white inside a dashed outline where the idle button is dark navy on white
// inside a solid one. That is the theme's `busyFigure` doing what it is configured to
// do, not a defect this suite found, and it is *not* asserted here: a golden's job is
// to make the frame reviewable, and whether that contrast is acceptable is a design
// call on ui_kit rather than a number this file can pin. Written down so the next
// person to look does not have to re-derive that the pale button is the busy one.
//
// ## What is deliberately not here
//
// **The six shared install phases** (`triggering` → `failed`). They are already
// photographed twelve-deep on `firmware_update`, they render the same
// `FirmwareInstallPhaseCard` under the same card padding, and this page's only
// contribution to them is the card list above — which `idle_*` above already
// photographs. #1554 §1 recommends skipping them and asking that the decision be
// stated rather than left as an absence, so: skipped, and it is a choice. What would
// reverse it is this page gaining a phase the manual page does not have, or the two
// pages' card lists diverging above the phase card.
//
// **`updating_firmware`'s empty-version variant** is likewise absent: the difference
// is one line not being drawn, which `firmware_ota_install_offer_widget_test.dart`
// already pins by assertion. A picture of a missing line is a picture of the line
// above it.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'firmware_ota',
      view: () => const FirmwareOtaView(),
      shell: ShellType.custom,
      height: 900,
      states: {
        // The page as it opens. `notChecked` is both the resting verdict and where a
        // failed check lands, so the check card renders its button and no verdict
        // line — the state every other one below is a departure from.
        'idle_not_checked': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: idleNoFileState,
                banksData: testThreeInstanceBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        // The `BusyFigureLayer` state. `checkingOtaState` is the one phase in the
        // enum that belongs to exactly one page, and the fixture leaves `otaCheck` at
        // `notChecked` because that is what the page is waiting for: the busy button
        // must be legible with no verdict line under it.
        'checking': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: checkingOtaState,
                banksData: testThreeInstanceBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        // A check that ran and found nothing — the sentence the gate's readability
        // guard is built on, here in 26 languages rather than at nine widths in one.
        // Banks that still carry the virtual row with `Available=0`, which is the
        // shape a router in this state actually reports.
        'idle_no_update_found': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: otaNoUpdateFoundState,
                banksData: testThreeInstanceBanksDataNoImage,
                systemInfoData: testSystemInfoData,
              ),
            ),
        // The offer, and the only image of the install button. Both halves are
        // required to reach it: the verdict *and* the virtual row the `Download()`
        // would be dispatched on, which is why this pairs with the three-instance
        // banks rather than the no-image ones above.
        'idle_update_available': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: otaUpdateAvailableState,
                banksData: testThreeInstanceBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        // REQ-A1: two physical banks and no virtual row, so the check is not offered
        // at all rather than offered and then failing. `testBanksData` *is* that
        // router — the fixture whose absence of a third instance is the subject.
        'ota_absent': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: idleNoFileState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        // The router could not be asked. Needs the banks read to have *failed* rather
        // than answered — see `firmwareUpdateOverridesWithBanksError` — so this is the
        // one state here that cannot take a banks fixture at all.
        //
        // Two cards about one failure, in one column, in every language, and their
        // agreement is what this picture is for: the status card draws its banks list
        // as a bare em-dash (its `banksUnreadable` arm) instead of the sentence "No
        // firmware banks reported", which would be a claim about the router's slots
        // directly above a card saying the router answered nothing at all.
        'state_unreadable': (overrides) => overrides.addAll(
              firmwareUpdateOverridesWithBanksError(
                updateState: firmwareStateUnreadableState,
                systemInfoData: testSystemInfoData,
              ),
            ),
      },
    ),
  );
}
