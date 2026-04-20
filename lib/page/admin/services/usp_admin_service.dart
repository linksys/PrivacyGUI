import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/admin_users.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/admin/models/admin_ui_models.dart';

final uspAdminServiceProvider = Provider<UspAdminService>(
  (ref) => UspAdminService(ref.read(uspClientProvider)!),
);

/// Service layer for Admin — encapsulates codegen CRUD + transform.
class UspAdminService {
  final UspClient _usp;

  UspAdminService(this._usp);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Fetch admin users and return the admin user UI model.
  Future<AdminUserUIModel> fetchAdmin() async {
    try {
      final adminUsers = await AdminUsers.fetch(_usp);
      return _buildAdminUserUIModel(adminUsers);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Update the admin user password.
  Future<void> updatePassword({
    required String instancePath,
    required String newPassword,
  }) async {
    try {
      await AdminUsers.update(
        _usp,
        [AdminUserUpdate(instancePath: instancePath, password: newPassword)],
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Time Settings — mutations (from Dashboard card + Admin page)
  // ---------------------------------------------------------------------------

  /// Update time settings (enable toggle, NTP servers).
  Future<void> updateTimeSettings({
    bool? enable,
    String? ntpServer1,
    String? ntpServer2,
  }) async {
    try {
      await TimeSettings.update(
        _usp,
        enable: enable,
        ntpServer1: ntpServer1,
        ntpServer2: ntpServer2,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Update timezone and optionally NTP servers / enable.
  Future<void> updateTimezone({
    String? localTimeZone,
    String? ntpServer1,
    String? ntpServer2,
    bool? enable,
  }) async {
    try {
      await TimeSettings.update(
        _usp,
        localTimeZone: localTimeZone,
        ntpServer1: ntpServer1,
        ntpServer2: ntpServer2,
        enable: enable,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // System Operations
  // ---------------------------------------------------------------------------

  /// Reboot the router.
  Future<void> reboot() async {
    try {
      await _usp.operate('Device.Reboot()');
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Factory reset the router.
  Future<void> factoryReset() async {
    try {
      await _usp.operate('Device.FactoryReset()');
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

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
}
