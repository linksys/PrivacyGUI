import 'package:privacy_gui/page/firmware_update/views/firmware_update_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_firmware_update.dart';
import '../fixtures/firmware_update_test_data.dart';

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
