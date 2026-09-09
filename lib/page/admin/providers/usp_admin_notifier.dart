import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/operation_guard.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_state.dart';
import 'package:privacy_gui/page/admin/services/usp_admin_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

final uspAdminProvider =
    AsyncNotifierProvider.autoDispose<UspAdminNotifier, UspAdminState>(
  UspAdminNotifier.new,
);

class UspAdminNotifier extends AutoDisposeAsyncNotifier<UspAdminState> {
  UspAdminService get _svc => ref.read(uspAdminServiceProvider);

  @override
  Future<UspAdminState> build() async {
    try {
      final timeData = await ref.watch(timeDataProvider.future);
      final adminUser = await _svc.fetchAdmin();

      return UspAdminState(
        adminUser: adminUser,
        timeSettings: timeData.model,
        timeFetchedAt: timeData.fetchedAt,
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Admin]: Fetch failed', error: e);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------------

  Future<void> setAdminPassword(String newPassword) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.updatePassword(
          instancePath: state.requireValue.adminUser.instancePath,
          newPassword: newPassword,
        );
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Admin]: Password update failed', error: e);
      rethrow;
    }

    // Re-authenticate with new password to get a fresh token.
    // The old token may be invalidated by the router after password change.
    // If relogin fails, logout to force user to re-enter password.
    try {
      await ref
          .read(uspAuthCoordinatorProvider)
          .reloginWithNewPassword(newPassword);
    } catch (e) {
      logger.w('[USP][Admin]: Relogin failed after password change, '
          'triggering logout: $e');
      await ref.read(authProvider.notifier).logout();
    }
  }

  // ---------------------------------------------------------------------------
  // Time Settings — delegates to Service, then invalidates L1
  // ---------------------------------------------------------------------------

  /// Update time settings (enable toggle, NTP servers).
  /// Called from Dashboard card.
  Future<void> updateTimeSettings({
    bool? enable,
    String? ntpServer1,
    String? ntpServer2,
  }) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.updateTimeSettings(
          enable: enable,
          ntpServer1: ntpServer1,
          ntpServer2: ntpServer2,
        );
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Admin]: Time settings update failed', error: e);
      rethrow;
    }
    ref.invalidate(timeDataProvider);
  }

  /// Update timezone and optionally NTP server (used by timezone edit dialog).
  Future<void> updateTimezone({
    required String localTimeZone,
    String? ntpServer1,
  }) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.updateTimezone(
          localTimeZone: localTimeZone,
          ntpServer1: ntpServer1,
        );
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Admin]: Timezone update failed', error: e);
      rethrow;
    }
    ref.invalidate(timeDataProvider);
  }

  // ---------------------------------------------------------------------------
  // Reboot / Factory Reset — delegates to service
  // ---------------------------------------------------------------------------

  /// Restarts the box. `transientRestart`: it comes back with the credential and
  /// the route intact, so every mode allows it — including Remote Assistance,
  /// where it is one of the two things an agent most often needs.
  ///
  /// The guard call is here even though it cannot refuse today, and that is
  /// deliberate: with only [factoryReset] guarded, these two methods would differ
  /// by the *presence* of a check, and a reader could not tell whether reboot is
  /// permitted or whether somebody forgot. Guarded both ways, the only difference
  /// between them is one enum value. See `lib/core/mode/operation_guard.dart`.
  Future<void> reboot() async {
    ref
        .read(operationGuardProvider)
        .enforce(DisruptionClass.transientRestart, operation: 'reboot');
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.reboot();
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Admin]: Reboot failed', error: e);
      rethrow;
    }
  }

  /// Wipes the box back to defaults. `credentialLoss`: the admin password
  /// becomes the one printed on the label, which is a recovery step only for
  /// someone who can read the label.
  ///
  /// Refused in Remote Assistance, and refused *here* rather than in the view.
  /// The view's affordance is phase 7's (#1497) to hide; this is the floor
  /// underneath it, and it has to be above `withLock` — a guard that threw after
  /// the command would leave a resetting router, an error dialog, and nobody in
  /// the building.
  Future<void> factoryReset() async {
    ref
        .read(operationGuardProvider)
        .enforce(DisruptionClass.credentialLoss, operation: 'factory reset');
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.factoryReset();
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Admin]: Factory reset failed', error: e);
      rethrow;
    }
  }
}
