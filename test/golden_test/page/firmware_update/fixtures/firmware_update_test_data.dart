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

FirmwareBanksData get testBanksData => const FirmwareBanksData(
      banks: [testActiveBank, testAvailableBank],
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
