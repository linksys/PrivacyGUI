/// Provider overrides for `firmware_update_view` (#1380, wave 4).
///
/// Three providers, and the third is the one that matters. The view is a
/// `ConsumerStatefulWidget` whose `initState` posts a frame callback that calls
/// `loadBanks()`, which awaits `firmwareBanksDataProvider.future` and then reaches
/// `UspFirmwareUpdateService`. Overriding the two data providers is therefore not
/// enough on its own — the notifier itself has to be pinned, or every cell runs a
/// real service call whose failure the sweep would report as a page that renders
/// nothing.
///
/// **Written beside `test/golden_test/golden_framework/mocks/mock_firmware_update.dart`
/// rather than moved out of it, which is the one place wave 4 departed from #1361's
/// rule.** Nine of that wave's builders were moved; this one was not, because the
/// golden mock overrides nine notifier methods for the install/reboot/verify flows,
/// carries a second loading variant and the recovery-dialog overrides, and takes its
/// three fixtures as *required* parameters. Moving it would have meant merging two
/// fixture philosophies and editing golden call sites this branch cannot verify —
/// golden baselines are gitignored, so a golden run here proves nothing.
///
/// What that costs, stated so it is not discovered later: `firmwareUpdateOverrides`,
/// `FixedFirmwareUpdateNotifier` and `FixedFirmwareBanksDataNotifier` are each
/// declared twice in the tree. The failure mode is bounded — this file's builder takes
/// named parameters with defaults and the golden one requires all three, so importing
/// the wrong one fails to compile rather than rendering the wrong page — but it is
/// still duplication #1361 owes, and merging the two is the right fix whenever
/// someone can run the golden suite to prove it.
///
/// **That condition is now met, and the merge is still not done** (#1554 §1/§4,
/// 2026-09-16). Two golden suites were added and generated in that work, so "nobody can
/// run the golden suite" has stopped being the blocker; what is left is scope — merging
/// two fixture philosophies and editing every golden call site is not a test ticket's
/// change. Two things did get reconciled rather than forked further: the failing-banks
/// notifier is now one public class in the golden mock, shared with
/// `test/page/firmware_update/`, and `gatePnpFirmwareInstallingState` below is one
/// fixture read by three carriers instead of three copies of a phase. The *named
/// parameters* still differ between the two builders (`state:`/`banks:`/`systemInfo:`
/// here, `updateState:`/`banksData:`/`systemInfoData:` there), which is the part a
/// reader trips over: a file needing both cannot import them unprefixed.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart'
    hide FirmwareImageUIModel;
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_failure.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';

/// A [FirmwareUpdateNotifier] that starts in a fixed state and never loads.
///
/// `loadBanks()` is overridden to a no-op rather than left to run against the
/// overridden `firmwareBanksDataProvider`, because letting it run would mean the
/// page's state is written by a post-frame callback — so the cell measured would be
/// whichever of the two frames the sweep happened to settle on. Pinning the state
/// and silencing the loader makes the cell one deterministic layout.
class FixedFirmwareUpdateNotifier extends FirmwareUpdateNotifier {
  FixedFirmwareUpdateNotifier(this._fixedState);

  final FirmwareUpdateState _fixedState;

  @override
  FirmwareUpdateState build() => _fixedState;

  @override
  Future<void> loadBanks({bool refresh = false}) async {}

  /// Answers with the verdict already in the fixed state instead of asking the
  /// router.
  ///
  /// Overridden for the same reason as [loadBanks], plus one this method adds:
  /// the real one dispatches `Download()` on the `ota` instance and then polls for
  /// up to ten seconds. A cell or a widget test that reaches it does not fail — it
  /// hangs, and `pumpAndSettle` times out somewhere unrelated to the tap.
  @override
  Future<FirmwareOtaCheckResult> checkForUpdate() async => _fixedState.otaCheck;

  /// The router-side install watch (#1551), and the one override on this class that
  /// is not about a tap.
  ///
  /// `FirmwareOtaView.initState` calls this on **every** open, because auto-update
  /// can start a flash with nobody watching (REQ-A6) — so a cell that merely lays
  /// the page out would start a twenty-minute poll loop against a router that is
  /// not there. `abandoned` is the verdict `_applyInstallOutcome` deliberately
  /// writes nothing for, so answering it cannot move the fixed state out from under
  /// the cell that pinned it.
  @override
  Future<FirmwareOtaInstallResult> observeRunningOtaInstall() async =>
      const FirmwareOtaInstallResult(
          verdict: FirmwareOtaInstallVerdict.abandoned);

  /// The install dispatch, silenced for the reason [checkForUpdate] gives: a cell
  /// that taps Update Now would reach `Download(ota,"true")` — a real flash, if the
  /// bridge in front of it ever answered.
  @override
  Future<FirmwareOtaInstallResult> triggerRouterOtaInstall({
    required int otaInstance,
  }) async =>
      const FirmwareOtaInstallResult(
          verdict: FirmwareOtaInstallVerdict.abandoned);
}

class FixedFirmwareBanksDataNotifier extends FirmwareBanksDataNotifier {
  FixedFirmwareBanksDataNotifier(this._fixedData);

  final FirmwareBanksData _fixedData;

  @override
  Future<FirmwareBanksData> build() async => _fixedData;
}

/// A [FirmwareAutoUpdateDataNotifier] pinned to one reading.
///
/// [setPolicy] is overridden to publish locally without a service call, because the
/// real one writes to the router: a cell that toggles the switch would otherwise
/// reach `UspFirmwareUpdateService` and fail, and the sweep would report the
/// failure as a card that renders nothing.
class FixedFirmwareAutoUpdateNotifier extends FirmwareAutoUpdateDataNotifier {
  FixedFirmwareAutoUpdateNotifier(this._fixedData);

  final FirmwareAutoUpdateUIModel _fixedData;

  @override
  Future<FirmwareAutoUpdateUIModel> build() async => _fixedData;

  @override
  Future<FirmwareAutoUpdateUIModel> refresh() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }

  @override
  Future<void> setPolicy(FirmwareAutoUpdatePolicy policy) async {
    state = AsyncData((state.valueOrNull ?? _fixedData).withPolicy(policy));
  }
}

class FixedSystemInfoDataNotifierForFirmware extends SystemInfoDataNotifier {
  FixedSystemInfoDataNotifierForFirmware(this._fixedData);

  final SystemInfoData _fixedData;

  @override
  Future<SystemInfoData> build() async => _fixedData;
}

/// Overrides for `firmware_update_view`.
List<Override> firmwareUpdateOverrides({
  FirmwareUpdateState state = gateFirmwareNoUpdateFoundState,
  FirmwareBanksData banks = gateFirmwareBanks,
  SystemInfoData systemInfo = gateFirmwareSystemInfo,
  FirmwareAutoUpdateUIModel? autoUpdate,
}) =>
    [
      firmwareUpdateNotifierProvider
          .overrideWith(() => FixedFirmwareUpdateNotifier(state)),
      firmwareBanksDataProvider
          .overrideWith(() => FixedFirmwareBanksDataNotifier(banks)),
      systemInfoDataProvider.overrideWith(
          () => FixedSystemInfoDataNotifierForFirmware(systemInfo)),
      // The router's own last-check record, which the OTA check card's history line
      // reads (#1572). **Left unoverridden by default on purpose**: without it the
      // real provider cannot fetch in a widget test, lands in `AsyncError`, and the
      // card draws no history line — which is the rendering every cell measured
      // before #1572 and the one the page sweep's declared cell counts are built on.
      // A cell that wants the line asks for it.
      if (autoUpdate != null)
        firmwareAutoUpdateDataProvider
            .overrideWith(() => FixedFirmwareAutoUpdateNotifier(autoUpdate)),
    ];

/// The router that has not looked for firmware since it started (#1572).
///
/// The widest of the two history lines: "not checked yet" is a longer sentence than
/// any verdict the card renders, and it lands in the same slot as the one #1380
/// measured overflowing in all 26 locales.
const gateFirmwareNotCheckedAfterBoot = FirmwareAutoUpdateUIModel(
  status: FirmwareAutoUpdateStatus.idle,
  progress: 0,
  rawState: '0',
  policy: FirmwareAutoUpdatePolicy.autoInstall,
  rawFlags: '2',
  checkedAfterBoot: false,
);

/// The router still holding the reason its last check failed (#1572).
///
/// Two stacked sentences in the slot, which is the taller of the two history lines
/// even though each line is shorter than [gateFirmwareNotCheckedAfterBoot]'s one.
const gateFirmwareLastCheckFailed = FirmwareAutoUpdateUIModel(
  status: FirmwareAutoUpdateStatus.idle,
  progress: 0,
  rawState: '0',
  policy: FirmwareAutoUpdatePolicy.autoInstall,
  rawFlags: '2',
  checkedAfterBoot: true,
  errorCode: FirmwareUpdateErrorCode.serverUnreachable,
);

/// The landing state, plus the one verdict that widens the row that overflowed.
///
/// `idle` is where a user arrives and where every terminal check returns to, so the
/// phase is not a choice. The verdict is a choice, and a deliberate one: the `Row` in
/// `_OtaCheckCard` holds a button and — only once a check has returned something — a
/// status line beside it. #1370 recorded the overflow at
/// `firmware_update_view.dart:546` with no verdict at all, which means it recorded the
/// narrow half of that row. Pinning one measures the whole reachable row, which is the
/// widest thing this phase can render and therefore the one worth one cell.
///
/// **`noUpdateFound` rather than `updateAvailable`, because it is the wider of the
/// two.** #1550 replaced `otaUpToDate: true` with this field; the sentence it renders
/// ("No new firmware was found") is longer than "Update available" in `en` and in
/// every locale the sweep reported at 320px, and the `updateAvailable` arm splits its
/// text over two shorter lines instead of one long one. The third rendering —
/// `otaCheckNotSupported`, for a router with no `ota` row — carries **no button** and
/// so is not this row at all; it cannot overflow, and it is covered by the widget
/// test rather than by a cell.
///
/// What stays unmeasured is the other eight phases. Seven of them are a title, a body
/// line and a linear `AppLoader` in a `Column` — no `Row`, nothing that can overflow
/// horizontally — and the eighth, `idle` with a file picked, swaps the body for three
/// lines of file detail and adds a second button to a `Wrap` that already wraps.
/// Recorded here rather than in the case so the reason sits next to the fixture that
/// would have to change to cover them.
///
/// **The verdict is only a choice for one of the two pages that take this default.**
/// This is the default `state` of `firmwareUpdateOverrides`, so it also feeds
/// `page.firmware_update` — and `firmware_update_view.dart` does not read `otaCheck`
/// at all (measured: zero references), so on that page the verdict above renders
/// nothing and picking the wider of the two is inert. It decides a row only on
/// `page.firmware_ota`, whose case doc owns the consequences — including the offer
/// state this verdict excludes, and why that gap is left open there rather than closed
/// by editing this line.
const gateFirmwareNoUpdateFoundState = FirmwareUpdateState(
  otaCheck: FirmwareOtaCheckResult.noUpdateFound(),
);

/// The router mid-flash, with a reading on the wire — what the **PnP wizard's**
/// firmware stage renders (#1553 REQ-B2, #1554 §4).
///
/// One fixture read by three carriers, which is why it is here rather than in any of
/// them: the wizard's golden state, its layout-gate cell, and the screen-shape tests
/// in `pnp_setup_view_firmware_test.dart`. Three copies of a phase-plus-progress pair
/// is three chances for one of them to drift onto a phase the others do not render.
///
/// **`installing` is a choice, and the only safe one for the tests that assert
/// absence.** `FirmwareInstallPhaseCard` draws a retry button on `failed`, and a retry
/// *is* an affordance — so pinning `failed` would fail REQ-B2's "no button on this
/// screen" for a reason that is not a defect. `failed` never reaches this screen
/// anyway: `_runFirmwareStage` catches it and finishes setup, which is REQ-B3.
///
/// **A non-zero, non-round percentage.** The card feeds `rawProgress` to a linear
/// `AppLoader`, which since ui_kit 3.3.2 is a real `LinearProgressIndicator` — so the
/// number decides a *width* on screen. `0` would draw an empty bar indistinguishable
/// from the indeterminate one, and `50` is the value a real install was observed
/// holding for ~40 seconds, which makes it the one number a reader would mistake for
/// the stall rather than for the fixture.
///
/// **`rawState` is `'3'`, not `'downloading'`**, because the field's contract is
/// "`fwup_state` as the router spelled it" and the router spells it as a digit. The
/// first draft of this fixture put the enum's English name there, which is the same
/// defect the l10n work removed from `errorMessage`: a diagnostic string no router
/// ever emits, reachable by a consumer —
/// `FirmwareFailure.progressStalled(fwupState: result.rawState)` and the
/// `(fwup_state=...)` log line both print it verbatim.
const gatePnpFirmwareInstallingState = FirmwareUpdateState(
  phase: FirmwareUpdatePhase.installing,
  otaProgress: FirmwareOtaInstallProgress(
    status: FirmwareAutoUpdateStatus.downloading,
    rawProgress: 42,
    rawState: '3',
  ),
);

/// The manual page in its **`failed`** phase, with a reason the router named.
///
/// The fixture for `page.firmware_failed`, and it exists because a live overflow was
/// sitting behind the one phase no cell rendered. `FirmwareInstallPhaseCard`'s `_failed`
/// and `_done` arms each open with a bare `Row` of a 24px icon, an `AppGap.sm()` and an
/// `AppText.titleMedium` — no `Expanded` until this work added one — and at the 320px
/// product floor that leaves the sentence about 198px. Measured before the fix, on this
/// state, at nine widths in 26 locales: **`pl` +30.0px, `it` +21.0px, `es` +12.0px,
/// `sv` +11.0px**, every one of them at 320px and none at any other width.
///
/// **`routerReported` rather than a file or service failure**, because #1572's seven
/// error-code sentences are the longest thing this card's body can hold and this is the
/// only constructor that carries one. The body is a direct child of the `Column`, so it
/// wraps freely and cannot overflow horizontally — the *title* was the defect, and the
/// reason is here so the cell measures the card at its full height as well.
const gateFirmwareFailedState = FirmwareUpdateState(
  phase: FirmwareUpdatePhase.failed,
  failure:
      FirmwareFailure.routerReported(FirmwareUpdateErrorCode.serverUnreachable),
);

/// Two banks, one active, which is what an M60TB-class router reports.
///
/// Two rather than one because `_buildBanksList` puts an `AppGap.sm()` between rows
/// and `_StatusLabel` renders a *different* string per row (`active` / `standby`) —
/// a one-bank fixture would measure neither the gap nor the longer of the two labels.
const gateFirmwareBanks = FirmwareBanksData(banks: [
  FirmwareImageUIModel(
    instance: 1,
    instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
    name: 'firmware-bank-1',
    version: '1.0.16.213451',
    status: 'Active',
    available: true,
    isBootTarget: true,
  ),
  FirmwareImageUIModel(
    instance: 2,
    instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
    name: 'firmware-bank-2',
    version: '1.0.15.211003',
    status: 'Standby',
    available: true,
  ),
]);

/// The same two banks plus a virtual `ota` row reporting an image is waiting.
///
/// The banner half of #1552 needs `otaInstance.available` true, and that flag only
/// exists on the third row — `physicalBanks` deliberately excludes it, so the two
/// fixtures cannot be merged: a page that lists banks must not grow a third slot,
/// and a banner must not appear on a router with nothing to install.
const gateFirmwareBanksWithOta = FirmwareBanksData(banks: [
  FirmwareImageUIModel(
    instance: 1,
    instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
    alias: 'fw1',
    name: 'firmware-bank-1',
    version: '1.0.16.213451',
    status: 'Active',
    available: true,
    isBootTarget: true,
  ),
  FirmwareImageUIModel(
    instance: 2,
    instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
    alias: 'fw2',
    name: 'firmware-bank-2',
    version: '1.0.15.211003',
    status: 'Standby',
    available: true,
  ),
  FirmwareImageUIModel(
    instance: 3,
    instancePath: 'Device.DeviceInfo.FirmwareImage.3.',
    alias: 'ota',
    name: '',
    version: '1.0.17.220118',
    status: 'Available',
    available: true,
  ),
]);

/// The auto-update reading the OTA card's switch renders in its ON position.
///
/// `autoInstall` rather than `notifyOnly` because the two are one pixel apart on
/// the switch and `autoInstall` is the firmware's own default, so it is the state a
/// user most often sees. `idle` because a busy daemon locks the switch, and a locked
/// switch measures the busy figure instead of the control.
const gateFirmwareAutoUpdateOn = FirmwareAutoUpdateUIModel(
  status: FirmwareAutoUpdateStatus.idle,
  progress: 0,
  rawState: '0',
  policy: FirmwareAutoUpdatePolicy.autoInstall,
  rawFlags: '2',
);

/// The router the status card describes.
///
/// A real model name and a real-shaped serial for the reason every fixture in this
/// wave gives: both sit in an `Expanded` column beside a fixed 56px image, so a
/// placeholder would measure a card that cannot overflow. `MX6200` also resolves to a
/// real asset through `routerIconTestByModel`, so the image the card lays out is the
/// size the app lays out rather than a fallback.
const gateFirmwareSystemInfo = SystemInfoData(
  model: SystemInfoUIModel(
    manufacturer: 'Linksys',
    modelName: 'MX6200',
    serialNumber: '24J10K56789012',
    hardwareVersion: '1',
    softwareVersion: '1.0.16.213451',
    uptime: 186400,
    totalMemory: 1048576,
    freeMemory: 524288,
    cpuUsage: 17,
  ),
);
