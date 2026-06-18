import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/admin/models/admin_ui_models.dart';
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
