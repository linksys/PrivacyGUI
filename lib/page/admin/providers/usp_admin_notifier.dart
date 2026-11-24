import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/operation_guard.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/timezone_info.dart';
import 'package:privacy_gui/page/admin/models/network_action_models.dart';
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
  ///
  /// [zone] is saved through `SetTimeSettings`, or left null for an NTP-only
  /// edit — see `UspAdminService.updateTimezone`.
  Future<void> updateTimezone({
    TimeZoneSelection? zone,
    String? ntpServer1,
  }) async {
    // A call that supplies no zone and no NTP server writes nothing. Checked
    // here as well as in the service so it throws before the `finally` below
    // re-reads the card for a write that was never attempted.
    if (zone == null && ntpServer1 == null) {
      throw ArgumentError('updateTimezone was given nothing to write');
    }
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.updateTimezone(zone: zone, ntpServer1: ntpServer1);
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Admin]: Timezone update failed', error: e);
      rethrow;
    } finally {
      // `finally`, not after the `try`: a failure here can still have changed the
      // device. The zone and the NTP server go out as two requests, so the
      // first can land and the second fail, and re-reading is the only way the
      // card stops showing a zone that is no longer set. Refreshing after a
      // failure that changed nothing costs one `Get`; not refreshing after one
      // that did leaves the user looking at a lie.
      //
      // The nothing-to-write guard above throws before this block, so a
      // programmer error does not trigger a pointless fetch.
      ref.invalidate(timeDataProvider);
    }
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
  ///
  /// Returns how the router took it: the whole network, the router alone, or
  /// not at all because a whole-network action is already running. See
  /// `UspAdminService.reboot`.
  Future<RouterRestartStart> reboot() async {
    ref
        .read(operationGuardProvider)
        .enforce(DisruptionClass.transientRestart, operation: 'reboot');
    try {
      return await ref
          .read(uspMutationLockProvider)
          .withLock(() => _svc.reboot());
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
  ///
  /// Returns how the router took it, as [reboot] does.
  Future<RouterRestartStart> factoryReset() async {
    ref
        .read(operationGuardProvider)
        .enforce(DisruptionClass.credentialLoss, operation: 'factory reset');
    try {
      return await ref
          .read(uspMutationLockProvider)
          .withLock(() => _svc.factoryReset());
    } on ServiceError catch (e) {
      logger.e('[USP][Admin]: Factory reset failed', error: e);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Whole-network action — waits for the controller's turn
  // ---------------------------------------------------------------------------

  /// How often [awaitNetworkAction] reads the network status.
  static const networkActionPollInterval = Duration(seconds: 2);

  /// How long [awaitNetworkAction] waits for the controller's turn.
  ///
  /// Each hop level waits up to 25 s for its agents and the controller's own
  /// command up to 30 s (Architecture#195), so this covers six levels. Timed
  /// by a timer, not by counting reads, so slow reads — through Guardian, in
  /// Remote Assistance — do not stretch it.
  static const networkActionLimit = Duration(minutes: 3);

  /// Waits, after [reboot] or [factoryReset] started a whole-network action,
  /// until the controller's own turn comes.
  ///
  /// The command replies at once and the controller goes down last, after
  /// every agent, so the reply says nothing about when to start counting down.
  /// This reads `NetworkActionStatus` every [networkActionPollInterval] and
  /// returns at the first answer that settles it: `Completed`, `Failed`, or a
  /// failed read. A failed read ends the wait without a retry: either the
  /// controller has gone down, or the node this app reaches it through has,
  /// and in both the recovery probe is what can tell when it is back. A read
  /// after the controller restarted would also go out on a credential a
  /// factory reset has wiped.
  ///
  /// `""`, an absent leaf and a value the definition does not name settle
  /// nothing, and the wait goes on. The
  /// definition gives `""` no meaning once an action has started, and an absent
  /// leaf is also what a read looks like when the router answered it with a
  /// per-path error (`UspClient.extractGetResult` throws only for a Get that
  /// failed as a whole, and leaves a failed path out).
  /// Reading either as the end would declare the router back while the
  /// controller is still to go.
  ///
  /// Stops reading once the app is no longer waiting for the router, as when
  /// the user leaves the recovery dialog for the login page.
  Future<NetworkActionOutcome> awaitNetworkAction() async {
    var expired = false;
    final limit = Timer(networkActionLimit, () => expired = true);
    try {
      while (true) {
        await Future<void>.delayed(networkActionPollInterval);
        if (ref.read(appConnectionStateProvider) !=
            AppConnectionState.waitingForRecovery) {
          return NetworkActionOutcome.abandoned;
        }
        if (expired) {
          logger.w('[USP][Admin]: Network action not settled after '
              '$networkActionLimit');
          return NetworkActionOutcome.timedOut;
        }
        final NetworkActionStatus? status;
        try {
          status = await _svc.readNetworkActionStatus();
        } on ServiceError catch (e) {
          logger.i('[USP][Admin]: Network status unreadable, '
              'leaving the wait to the recovery probe: $e');
          return NetworkActionOutcome.unreachable;
        }
        switch (status) {
          case NetworkActionStatus.completed:
            return NetworkActionOutcome.controllerGoingDown;
          case NetworkActionStatus.failed:
            logger.w('[USP][Admin]: Network action Failed');
            return NetworkActionOutcome.failed;
          case NetworkActionStatus.running:
          case NetworkActionStatus.idle:
          case NetworkActionStatus.unknown:
          case null:
            break;
        }
      }
    } finally {
      limit.cancel();
    }
  }
}
