import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/admin_users.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/usp_page/admin/models/admin_ui_models.dart';
import 'package:privacy_gui/usp_page/dashboard/models/time_settings_ui_model.dart';

/// Stateless service — Data Model → UI Model transformation for Admin page.
final uspAdminServiceProvider = Provider<UspAdminService>(
  (ref) => UspAdminService(),
);

class UspAdminService {
  AdminUserUIModel buildAdminUserUIModel(AdminUsers users) {
    // Find the admin user (User.1 with username 'admin')
    final admin = users.items.firstWhere(
      (u) => u.username == 'admin',
      orElse: () => users.items.first,
    );
    return AdminUserUIModel(
      instancePath: admin.instancePath,
      username: admin.username,
      enable: admin.enable,
    );
  }

  TimeSettingsUIModel buildTimeSettingsUIModel(TimeSettings ts) {
    return TimeSettingsUIModel(
      enable: ts.enable,
      status: ts.status,
      currentLocalTime: ts.currentLocalTime,
      localTimeZone: ts.localTimeZone,
      ntpServer1: ts.ntpServer1,
      ntpServer2: ts.ntpServer2,
    );
  }
}
