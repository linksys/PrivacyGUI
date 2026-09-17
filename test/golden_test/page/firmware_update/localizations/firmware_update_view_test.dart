import 'package:privacy_gui/page/firmware_update/views/firmware_update_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_firmware_update.dart';
// `show`, to take one fixture without the same-named `firmwareUpdateOverrides` the gate
// mocks also declare. `gateFirmwareFailedState` is read by three carriers now — this
// picture, `page.firmware_failed`, and the probe that found the overflow behind it.
import '../../../../mocks/provider_overrides/mock_firmware_update.dart'
    show gateFirmwareFailedState;
import '../fixtures/firmware_update_test_data.dart';

// #1549 took `_OtaCheckCard` off this page, so all twelve photographs below lost a
// card. **No state was deleted, and that was checked rather than assumed**: none of
// the twelve exists *for* the OTA card — every one of them is a `phase` plus the file
// and bank fields the manual flow reads, and `FirmwareUpdateState` carries no OTA
// field any of them set. So there is no pair here that the removal collapsed into one
// picture, which is the thing a scene list has to be tidied for.
//
// What did change is that six of them — `triggering` through `failed` — now render
// `FirmwareInstallPhaseCard`, which both entry points share. Those six are therefore
// the same picture the OTA page would produce in the same phase, and they are kept
// here rather than moved because this page is still one of the two places a user
// reaches them from: a golden of a shared card is a golden of that page's use of it.
//
// The OTA page now has its own suite, `firmware_ota_view_test.dart` (#1554 §1).
// It did not when #1549 split the pages, and the reason was not oversight: goldens
// are not a verification tier in this repo (they run in the private golden-ci repo,
// and their baselines are gitignored), so a suite added in that PR could not have
// been verified by anything in it, and #1549's own bookkeeping row called the item
// bookkeeping rather than acceptance. What covered the page until then, and still
// does, is its layout-gate case (`page.firmware_ota`, 234 cells) and its identifier
// widget test — the sibling file says which of its six states those two cannot
// reach, which is what a golden was eventually needed for.
void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'firmware_update',
      view: () => const FirmwareUpdateView(),
      shell: ShellType.custom,
      height: 900,
      states: {
        'idle_no_file': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: idleNoFileState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'idle_file_selected': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: idleFileSelectedState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'picking': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: pickingState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'validating': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: validatingState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'uploading': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: uploadingState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'triggering': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: triggeringState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'installing': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: installingState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'rebooting': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: rebootingState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'verifying': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: verifyingState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'done': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: doneState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'failed': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: failedState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        // The failure as the *router* named it (#1572), which is where the seven
        // error-code sentences actually live: `_failed`'s body is the one persistent
        // surface any of them reaches, since the OTA page sends its reason to a snack
        // bar. `failed` above is the other kind — a dropped upload, a `ServiceError`
        // through `localizeServiceError` — so the two states exercise both mappers
        // rather than one twice.
        //
        // This state is also what found a live defect. Its title `Row` had no
        // `Expanded`, and at 320px `pl` overflowed it by 30.0px, `it` by 21.0, `es` by
        // 12.0 and `sv` by 11.0 — unseen because no gate cell rendered this phase.
        // Fixed in `lib/`, and `page.firmware_failed` now sweeps it at nine widths. The
        // picture is the other half: a sweep says the box holds, not that the sentence
        // beneath it reads.
        'failed_router_reason': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: gateFirmwareFailedState,
                banksData: testBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
        'banks_empty': (overrides) => overrides.addAll(
              firmwareUpdateOverrides(
                updateState: idleNoFileState,
                banksData: testEmptyBanksData,
                systemInfoData: testSystemInfoData,
              ),
            ),
      },
    ),
  );
}
