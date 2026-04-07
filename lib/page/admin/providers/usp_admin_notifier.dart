import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_state.dart';
import 'package:privacy_gui/page/admin/services/usp_admin_service.dart';

final uspAdminProvider =
    AsyncNotifierProvider.autoDispose<UspAdminNotifier, UspAdminState>(
  UspAdminNotifier.new,
);

class UspAdminNotifier extends AutoDisposeAsyncNotifier<UspAdminState> {
  UspAdminService get _svc => ref.read(uspAdminServiceProvider);

  @override
  Future<UspAdminState> build() async {
    try {
      // Time settings from shared data provider.
      final timeData = await ref.watch(timeDataProvider.future);
      final adminUser = await _svc.fetchAdmin();

      return UspAdminState(
        adminUser: adminUser,
        timeSettings: timeData.model,
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Admin] Fetch failed', error: e);
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
      logger.e('[USP][Admin] Password update failed', error: e);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Timezone — delegates to shared timeDataProvider
  // ---------------------------------------------------------------------------

  Future<void> updateTimezone({
    String? localTimeZone,
    String? ntpServer1,
    String? ntpServer2,
    bool? enable,
  }) async {
    await ref.read(timeDataProvider.notifier).updateTimezone(
          localTimeZone: localTimeZone,
          ntpServer1: ntpServer1,
          ntpServer2: ntpServer2,
          enable: enable,
        );
  }

  // ---------------------------------------------------------------------------
  // Reboot / Factory Reset — delegates to service
  // ---------------------------------------------------------------------------

  Future<void> reboot() async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.reboot();
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Admin] Reboot failed', error: e);
      rethrow;
    }
  }

  Future<void> factoryReset() async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.factoryReset();
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Admin] Factory reset failed', error: e);
      rethrow;
    }
  }
}
