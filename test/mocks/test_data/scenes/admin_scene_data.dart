/// Composed states for `usp_admin_view` — the golden suite's and the layout gate's.
///
/// Moved here from `test/golden_test/page/admin/fixtures/admin_test_data.dart` by
/// #1380 and renamed `_scene_data` on the way, per CLAUDE.md's testing-structure
/// rule: these are whole composed states ready to hand to a provider override, not
/// the per-model builders `test/mocks/test_data/*_test_data.dart` holds. The existing
/// names are unchanged, so the golden suite's only edit was its import.
library;

import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/admin/models/admin_ui_models.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_state.dart';

const testAdminUser = AdminUserUIModel(
  instancePath: 'Device.Users.User.1.',
  username: 'admin',
  enable: true,
);

const testTimeSettings = TimeSettingsUIModel(
  enable: true,
  status: 'Synchronized',
  currentLocalTime: '2026-05-22T10:30:00+08:00',
  localTimeZone: 'CST-8',
  ntpServer1: 'pool.ntp.org',
  ntpServer2: '',
);

UspAdminState get testAdminState => UspAdminState(
      adminUser: testAdminUser,
      timeSettings: testTimeSettings,
      timeFetchedAt: DateTime(2026, 5, 22, 10, 30),
    );

/// What `FirmwareUpdateCard` needs to render its version row rather than `N/A`.
///
/// One image, `Active`, with a four-part version — the longest string this row can
/// hold from a real router, and the one that shares an unpadded `Row` with a label
/// and an `AppButton.text`. The rest of `SystemInfoUIModel` is filled in because the
/// same provider feeds cards on other pages and an empty model there would read as
/// "this page needs nothing" rather than "this page needs one field".
const gateAdminSystemInfo = SystemInfoData(
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
    firmwareImages: [
      FirmwareImageUIModel(
        instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
        name: 'firmware-bank-1',
        version: '1.0.16.213451',
        status: 'Active',
        available: true,
        isActive: true,
        isBootTarget: true,
      ),
    ],
  ),
);
