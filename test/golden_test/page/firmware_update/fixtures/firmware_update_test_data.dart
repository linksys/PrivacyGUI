import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart'
    hide FirmwareImageUIModel;
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';

// -----------------------------------------------------------------------------
// Firmware Banks Data
// -----------------------------------------------------------------------------

const testActiveBank = FirmwareImageUIModel(
  instance: 1,
  instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
  name: 'Bank1',
  version: '1.0.16.26013014',
  status: 'Active',
  available: true,
);

const testAvailableBank = FirmwareImageUIModel(
  instance: 2,
  instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
  name: 'Bank2',
  version: '1.0.15.25090212',
  status: 'Available',
  available: true,
);

const testUpdatedActiveBank = FirmwareImageUIModel(
  instance: 2,
  instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
  name: 'Bank2',
  version: '1.0.17.26050100',
  status: 'Active',
  available: true,
);

/// The measured shape of the spare NAND bank: `Available=1` but no readable
/// version, because only the running image can report one.
const testEmptyVersionBank = FirmwareImageUIModel(
  instance: 2,
  instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
  alias: 'fw2',
  name: '',
  version: '',
  status: 'Available',
  available: true,
);

/// The virtual third instance. Not a bank — it carries the version the router
/// could update *to*, so it must never appear where banks are listed.
const testOtaInstance = FirmwareImageUIModel(
  instance: 3,
  instancePath: 'Device.DeviceInfo.FirmwareImage.3.',
  alias: 'ota',
  name: '',
  version: '2.0.1.26091009',
  status: 'Available',
  available: true,
);

/// The same virtual row on a router that is holding nothing.
///
/// `Status=NoImage`, `Available=0`, no version — measured, and the reason #1550's
/// "found nothing" verdict comes from a deadline rather than from a reading: this is
/// also exactly what the row looks like when the router has *never* been asked. What
/// it is not is a router that cannot be asked; that one has no `ota` row at all, and
/// [testBanksData] is it.
const testIdleOtaInstance = FirmwareImageUIModel(
  instance: 3,
  instancePath: 'Device.DeviceInfo.FirmwareImage.3.',
  alias: 'ota',
  name: '',
  version: '',
  status: 'NoImage',
  available: false,
);

FirmwareBanksData get testBanksData => const FirmwareBanksData(
      banks: [testActiveBank, testAvailableBank],
    );

/// A router with the fwup stack that is holding nothing to install.
///
/// The pair to [testThreeInstanceBanksData]: same two physical banks, same virtual
/// row, and the row says no. Pumped where a page must offer the check and report
/// nothing found.
FirmwareBanksData get testThreeInstanceBanksDataNoImage =>
    const FirmwareBanksData(
      banks: [testActiveBank, testEmptyVersionBank, testIdleOtaInstance],
    );

/// What a 2.0 router with the fwup stack actually reports: two physical banks
/// plus the virtual ota row.
FirmwareBanksData get testThreeInstanceBanksData => const FirmwareBanksData(
      banks: [
        FirmwareImageUIModel(
          instance: 1,
          instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
          alias: 'fw1',
          name: 'Bank1',
          version: '1.0.16.26013014',
          status: 'Active',
          available: true,
        ),
        testEmptyVersionBank,
        testOtaInstance,
      ],
    );

FirmwareBanksData get testEmptyBanksData => const FirmwareBanksData(
      banks: [],
    );

// -----------------------------------------------------------------------------
// System Info Data
// -----------------------------------------------------------------------------

const testSystemInfoModel = SystemInfoUIModel(
  manufacturer: 'Linksys',
  modelName: 'M60TB-EU',
  serialNumber: 'ABC123456789',
  hardwareVersion: '1.0',
  softwareVersion: '1.0.16.26013014',
  uptime: 86400,
  totalMemory: 524288,
  freeMemory: 262144,
  cpuUsage: 25,
);

SystemInfoData get testSystemInfoData => const SystemInfoData(
      model: testSystemInfoModel,
    );

// -----------------------------------------------------------------------------
// Firmware Update States
// -----------------------------------------------------------------------------

FirmwareUpdateState get idleNoFileState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.idle,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
    );

FirmwareUpdateState get idleFileSelectedState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.idle,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
      selectedFileName: 'linksys-m60tb-1.0.17.img',
      selectedFileSize: 73400320,
      selectedFileMd5: 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
    );

/// The OTA page's own busy phase: the check is in flight, so no verdict has
/// arrived yet and there is nothing to install.
///
/// The only phase in the enum that belongs to exactly one page. It has no
/// `selectedFile*`, because an OTA check has no local file, and leaves `otaCheck`
/// at `notChecked`, because that is what it is waiting for — #1550 moved the check
/// from the cloud API to the router and replaced the old `otaInfo`/`otaUpToDate`
/// pair with that one field.
FirmwareUpdateState get checkingOtaState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.checkingOta,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
    );

FirmwareUpdateState get pickingState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.picking,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
    );

FirmwareUpdateState get validatingState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.validating,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
      selectedFileName: 'linksys-m60tb-1.0.17.img',
    );

FirmwareUpdateState get uploadingState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.uploading,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
      selectedFileName: 'linksys-m60tb-1.0.17.img',
      selectedFileSize: 73400320,
      selectedFileMd5: 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
      uploadedChunks: 50,
      totalChunks: 100,
    );

FirmwareUpdateState get triggeringState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.triggering,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
      selectedFileName: 'linksys-m60tb-1.0.17.img',
      selectedFileSize: 73400320,
      uploadedChunks: 100,
      totalChunks: 100,
    );

FirmwareUpdateState get installingState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.installing,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
      selectedFileName: 'linksys-m60tb-1.0.17.img',
      uploadedChunks: 100,
      totalChunks: 100,
    );

FirmwareUpdateState get rebootingState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.rebooting,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
      rebootRemaining: Duration(minutes: 3, seconds: 45),
    );

FirmwareUpdateState get verifyingState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.verifying,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
    );

FirmwareUpdateState get doneState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.done,
      activeBank: testUpdatedActiveBank,
      targetBank: testActiveBank,
    );

FirmwareUpdateState get failedState => const FirmwareUpdateState(
      phase: FirmwareUpdatePhase.failed,
      activeBank: testActiveBank,
      targetBank: testAvailableBank,
      errorMessage: 'Upload failed: Connection timeout after 30 seconds',
    );
