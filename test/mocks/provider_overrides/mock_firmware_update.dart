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
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart'
    hide FirmwareImageUIModel;
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
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
  Future<void> loadBanks() async {}
}

class FixedFirmwareBanksDataNotifier extends FirmwareBanksDataNotifier {
  FixedFirmwareBanksDataNotifier(this._fixedData);

  final FirmwareBanksData _fixedData;

  @override
  Future<FirmwareBanksData> build() async => _fixedData;
}

class FixedSystemInfoDataNotifierForFirmware extends SystemInfoDataNotifier {
  FixedSystemInfoDataNotifierForFirmware(this._fixedData);

  final SystemInfoData _fixedData;

  @override
  Future<SystemInfoData> build() async => _fixedData;
}

/// Overrides for `firmware_update_view`.
List<Override> firmwareUpdateOverrides({
  FirmwareUpdateState state = gateFirmwareUpToDateState,
  FirmwareBanksData banks = gateFirmwareBanks,
  SystemInfoData systemInfo = gateFirmwareSystemInfo,
}) =>
    [
      firmwareUpdateNotifierProvider
          .overrideWith(() => FixedFirmwareUpdateNotifier(state)),
      firmwareBanksDataProvider
          .overrideWith(() => FixedFirmwareBanksDataNotifier(banks)),
      systemInfoDataProvider.overrideWith(
          () => FixedSystemInfoDataNotifierForFirmware(systemInfo)),
    ];

/// The landing state, plus the one flag that widens the row that overflowed.
///
/// `idle` is where a user arrives and where every terminal check returns to, so the
/// phase is not a choice. `otaUpToDate: true` is a choice, and a deliberate one: the
/// `Row` in `_OtaCheckCard` holds a button and — only when this flag is set — a
/// check icon and "firmware is up to date" beside it. #1370 recorded the overflow at
/// `firmware_update_view.dart:546` with the flag *false*, which means it recorded the
/// narrow half of that row. Pinning it true measures the whole reachable row, which is
/// the widest thing this phase can render and therefore the one worth one cell.
///
/// What stays unmeasured is the other eight phases. Seven of them are a title, a body
/// line and a linear `AppLoader` in a `Column` — no `Row`, nothing that can overflow
/// horizontally — and the eighth, `idle` with a file picked, swaps the body for three
/// lines of file detail and adds a second button to a `Wrap` that already wraps.
/// Recorded here rather than in the case so the reason sits next to the fixture that
/// would have to change to cover them.
const gateFirmwareUpToDateState = FirmwareUpdateState(
  otaUpToDate: true,
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
