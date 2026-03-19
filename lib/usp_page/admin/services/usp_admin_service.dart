import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/admin_users.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/admin/models/admin_ui_models.dart';
import 'package:privacy_gui/usp_page/_shared/models/time_settings_ui_model.dart';

final uspAdminServiceProvider = Provider<UspAdminService>(
  (ref) => UspAdminService(ref.read(uspServiceProvider)!),
);

/// Service layer for Admin — encapsulates codegen CRUD + transform.
class UspAdminService {
  final UspService _usp;

  UspAdminService(this._usp);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Fetch admin users and return the admin user UI model.
  Future<AdminUserUIModel> fetchAdmin() async {
    final adminUsers = await AdminUsers.fetch(_usp);
    return _buildAdminUserUIModel(adminUsers);
  }

  /// Update the admin user password.
  Future<void> updatePassword({
    required String instancePath,
    required String newPassword,
  }) async {
    await AdminUsers.update(
      _usp,
      AdminUserUpdate(instancePath: instancePath, password: newPassword),
    );
  }

  // ---------------------------------------------------------------------------
  // Transform
  // ---------------------------------------------------------------------------

  AdminUserUIModel _buildAdminUserUIModel(AdminUsers users) {
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
