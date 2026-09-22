import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/admin_users.g.dart';
import 'package:privacy_gui/generated/device_operations.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
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

  /// `Device.Time.X_LINKSYS_LocalTimeZoneName` — see [updateTimezone].
  static const _zoneNamePath = 'Device.Time.X_LINKSYS_LocalTimeZoneName';

  /// Update timezone and optionally NTP servers / enable.
  ///
  /// Pass **either** [zoneName] or [localTimeZone], never both (#1609). The two
  /// leaves are wired together in the firmware and they clobber each other:
  /// writing the name derives the POSIX string (`Asia/Taipei` → `CST-8`, DST
  /// rule included), and writing the POSIX string clears the name. Putting both
  /// in one `Set` would make the outcome depend on the order the firmware
  /// happens to apply them. [zoneName] is the one to prefer — it is an identity,
  /// so the zone that was chosen is the zone that reads back — and
  /// [localTimeZone] remains for the three table entries that have no faithful
  /// IANA name.
  Future<void> updateTimezone({
    String? zoneName,
    String? localTimeZone,
    String? ntpServer1,
    String? ntpServer2,
    bool? enable,
  }) async {
    // Thrown, not asserted: asserts are stripped from the release web build, and
    // this is the one guard standing between a future caller and a write whose
    // result depends on the order the firmware applies two leaves in.
    if (zoneName != null && localTimeZone != null) {
      throw ArgumentError(
          'pass either zoneName or localTimeZone, never both — the firmware '
          'derives one from the other and clears it on the reverse write, so a '
          'combined Set is order-dependent');
    }
    try {
      // The name goes in its own `Set` because it is not on the codegen model:
      // `time_settings.yaml` does not declare the leaf, and widening the
      // generated `_paths` by hand would be undone by the next codegen run.
      // Folding it upstream is the follow-up. In the ordinary case — a zone
      // change with the Advanced section untouched — the call below short-
      // circuits on an empty param map, so this is still one request; only
      // changing the zone and an NTP server together costs the atomicity #814
      // introduced.
      if (zoneName != null) {
        _check(await _usp.set({_zoneNamePath: zoneName}));
      }
      _check(
        await TimeSettings.update(
          _usp,
          localTimeZone: localTimeZone,
          ntpServer1: ntpServer1,
          ntpServer2: ntpServer2,
          enable: enable,
        ),
        // Naming what already landed, because this is where #814's atomicity is
        // spent: if the name went in and this call fails, the zone really did
        // change while the user is told the edit failed. Nothing rolls it back,
        // so the least we owe them is a message that says so.
        alreadyApplied: zoneName != null ? 'timezone' : null,
      );
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Turns a raw Set result into a throw, or nothing.
  ///
  /// [alreadyApplied] names what an earlier `Set` in the same edit committed, so
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
