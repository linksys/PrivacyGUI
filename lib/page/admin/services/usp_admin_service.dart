import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/admin_users.g.dart';
import 'package:privacy_gui/generated/data_elements_network_operations.g.dart';
import 'package:privacy_gui/generated/device_operations.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/time_settings_operations.g.dart';
import 'package:privacy_gui/page/_shared/services/empty_row.dart';
import 'package:privacy_gui/page/_shared/models/timezone_info.dart';
import 'package:privacy_gui/page/admin/models/admin_ui_models.dart';
import 'package:privacy_gui/page/admin/models/network_action_models.dart';

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

  /// Reboots the router, and with it every node in its mesh.
  ///
  /// On firmware with Architecture#195, `Device.Reboot()` restarts the
  /// controller alone, and the whole network is `X_LINKSYS_RebootAll()`. Which
  /// one this router has is read right before the call (see
  /// [readNetworkActionStatus]): the leaf is present with the commands and
  /// absent without them, on older firmware and on a unit with the mesh off.
  /// Read here rather than at login, so that a Remote Assistance session, which
  /// resolves no capabilities, takes the same path as a local one. A failed
  /// read sends nothing: guessing `Device.Reboot()` would restart only the
  /// controller on firmware that has the new command.
  Future<RouterRestartStart> reboot() => _restart(
        network: DataElementsNetworkOperations.rebootAll,
        router: DeviceOperations.reboot,
      );

  /// Factory-resets the router, and with it every node in its mesh: as
  /// [reboot], with `X_LINKSYS_FactoryResetAll()` and `Device.FactoryReset()`.
  /// The controller is reset even when an agent does not confirm; such an agent
  /// keeps the old network and has to be reset with its button.
  Future<RouterRestartStart> factoryReset() => _restart(
        network: DataElementsNetworkOperations.factoryResetAll,
        router: DeviceOperations.factoryReset,
      );

  /// Reads `Network.X_LINKSYS_NetworkActionStatus` (Architecture#195), or null
  /// when this router does not have it — and so has no whole-network commands.
  ///
  /// Read fresh, past the throttler's cache: a waiter polls it while the value
  /// moves. The leaf reads `""` until a whole-network action runs, so presence
  /// is the test, never the value.
  Future<NetworkActionStatus?> readNetworkActionStatus() async {
    try {
      final response = await _usp.get([_networkActionStatus], fresh: true);
      if (!response.containsKey(_networkActionStatus)) return null;
      return NetworkActionStatus.fromValue(
          response[_networkActionStatus]?.toString() ?? '');
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  static const _networkActionStatus =
      'Device.WiFi.DataElements.Network.X_LINKSYS_NetworkActionStatus';

  /// The fault a whole-network command answers while one is already running.
  static const _networkActionBusy = 7002;

  Future<RouterRestartStart> _restart({
    required Future<Map<String, dynamic>> Function(UspClient) network,
    required Future<Map<String, dynamic>> Function(UspClient) router,
  }) async {
    final status = await readNetworkActionStatus();
    if (status == null) {
      try {
        await router(_usp);
      } catch (e) {
        throw mapUspErrorToServiceError(e);
      }
      return RouterRestartStart.router;
    }

    // Already running, by the read just made: sending would only be refused,
    // and a command sent into another one is not something to find out about
    // on a live network.
    if (status == NetworkActionStatus.running) {
      return RouterRestartStart.alreadyRunning;
    }

    final Map<String, dynamic> output;
    try {
      output = await network(_usp);
    } catch (e) {
      final error = mapUspErrorToServiceError(e);
      // Another client may have started one since the read.
      if (error.code == _networkActionBusy) {
        return RouterRestartStart.alreadyRunning;
      }
      throw error;
    }
    // `Started` is the answer, and a reply with no Status is taken as the
    // command accepted. `Busy` is read here as well as from the fault, because
    // the definition names it as a Status value and which of the two shapes
    // the agent sends has not been measured.
    final reply = output['Status'];
    switch (reply) {
      case null || 'Started':
        return RouterRestartStart.network;
      case 'Busy':
        return RouterRestartStart.alreadyRunning;
    }
    // Any other Status — `Failed`, or a value this app does not know — is not
    // the start the definition names, and waiting on it would only time out.
    // But an agent that answers in its own words may have started anyway, and
    // reporting that as a failure would leave the network restarting under an
    // error and outside recovery. So the leaf decides.
    NetworkActionStatus? after;
    try {
      after = await readNetworkActionStatus();
    } on ServiceError {
      // Unreadable is no evidence it started; the reply is reported as it is.
    }
    if (after == NetworkActionStatus.running) return RouterRestartStart.network;
    throw UspCompleteFailureError(
      summary: 'The whole-network command replied Status $reply',
      failures: const [],
    );
  }

  AdminUserUIModel _buildAdminUserUIModel(AdminUsers users) {
    // A row with every value blank is no user (usp-codegen 0.17 dropped it).
    final rows = users.items.where((u) => !isEmptyAdminUser(u)).toList();
    final admin = rows.firstWhere(
      (u) => u.username == 'admin',
      orElse: () => rows.first,
    );
    return AdminUserUIModel(
      instancePath: admin.instancePath,
      username: admin.username,
      enable: admin.enable,
    );
  }
}
