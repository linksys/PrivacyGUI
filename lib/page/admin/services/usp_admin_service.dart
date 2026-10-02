import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/admin_users.g.dart';
import 'package:privacy_gui/generated/device_operations.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/time_settings_operations.g.dart';
import 'package:privacy_gui/page/_shared/models/timezone_info.dart';
import 'package:privacy_gui/page/admin/models/admin_ui_models.dart';

final uspAdminServiceProvider = Provider<UspAdminService>(
  (ref) => UspAdminService(ref.read(uspClientProvider)!),
);

/// Service layer for Admin — encapsulates codegen CRUD + transform.
class UspAdminService {
  final UspClient _usp;

  UspAdminService(this._usp);

  /// The `Result` output of `SetTimeSettings` that means the zone was saved.
  /// Every other value is a rejection (linksys/FWDEV#198).
  static const _setTimeSettingsOk = 'OK';

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
      final result = await AdminUsers.update(
        _usp,
        [AdminUserUpdate(instancePath: instancePath, password: newPassword)],
      );
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(
            :final errorSummary,
            :final successes,
            :final failures
          ):
          throw UspPartialFailureError(
            summary: 'Password update partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'Password update failed: $errorSummary',
            failures: errors,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
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
      final result = await TimeSettings.update(
        _usp,
        enable: enable,
        ntpServer1: ntpServer1,
        ntpServer2: ntpServer2,
      );
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(
            :final errorSummary,
            :final successes,
            :final failures
          ):
          throw UspPartialFailureError(
            summary: 'Time settings partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'Time settings update failed: $errorSummary',
            failures: errors,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Update the timezone and its daylight-savings setting, and optionally the
  /// NTP server (the timezone edit dialog).
  ///
  /// The zone is saved through `Device.Time.X_LINKSYS_SetTimeSettings()`
  /// (linksys/FWDEV#198), which sets the zone and DST together — hence one
  /// [zone] value. Leave it null when only the NTP server changed: re-sending the
  /// resolved zone would commit a guess for a zone the device could not name.
  ///
  /// The operate always succeeds; the firmware reports a rejection only in the
  /// output argument `Result` (`ErrorUnknownTimeZone`,
  /// `ErrorTimeZoneDoesNotObserveDST`, `ErrorInvalidInput`), and on a rejection
  /// nothing changes. So anything but `OK` is thrown here — checking the call
  /// alone would record a rejected zone as saved. The zone goes first so that a
  /// rejection stops the NTP write too, and the dialog's edit fails as one.
  Future<void> updateTimezone({
    TimeZoneSelection? zone,
    String? ntpServer1,
  }) async {
    // Thrown, not asserted: asserts are stripped from the release web build.
    // The notifier checks this too, but this service is the layer that writes.
    if (zone == null && ntpServer1 == null) {
      throw ArgumentError('updateTimezone was given nothing to write');
    }
    try {
      if (zone != null) {
        final output = await TimeSettingsOperations.setTimeSettings(
          _usp,
          timeZoneId: zone.id,
          autoAdjustForDst: zone.autoAdjustForDst,
        );
        final result = output['Result'];
        if (result != _setTimeSettingsOk) {
          throw InvalidInputError(
            field: 'timezone',
            detail: 'SetTimeSettings rejected ${zone.id}: $result',
          );
        }
      }
      if (ntpServer1 != null) {
        _check(
          await TimeSettings.update(_usp, ntpServer1: ntpServer1),
          // The zone is already saved by this point, and nothing rolls it back.
          alreadyApplied: zone != null ? 'timezone' : null,
        );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Turns a raw Set result into a throw, or nothing.
  ///
  /// [alreadyApplied] names what an earlier write in the same edit committed, so
  /// a failure here does not read as "nothing happened".
  void _check(Map<String, dynamic> result, {String? alreadyApplied}) {
    final landed =
        alreadyApplied == null ? '' : ' ($alreadyApplied was already applied)';
    final parsed = UspResultParser.parseSetResult(result);
    switch (parsed) {
      case UspSuccess():
        return;
      case UspPartialSuccess(
          :final errorSummary,
          :final successes,
          :final failures
        ):
        throw UspPartialFailureError(
          summary: 'Timezone update partial failure: $errorSummary$landed',
          successPaths: successes.map((s) => s.requestedPath).toList(),
          failures: failures,
        );
      case UspFailure(:final errorSummary, :final errors):
        throw UspCompleteFailureError(
          summary: 'Timezone update failed: $errorSummary$landed',
          failures: errors,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // System Operations
  // ---------------------------------------------------------------------------

  /// Reboot the router.
  Future<void> reboot() async {
    try {
      await DeviceOperations.reboot(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Factory reset the router.
  Future<void> factoryReset() async {
    try {
      await DeviceOperations.factoryReset(_usp);
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
