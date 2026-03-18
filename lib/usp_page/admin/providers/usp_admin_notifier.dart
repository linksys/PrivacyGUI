import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/usp_page/admin/providers/usp_admin_state.dart';
import 'package:privacy_gui/usp_page/admin/services/usp_admin_service.dart';

final uspAdminProvider =
    AsyncNotifierProvider.autoDispose<UspAdminNotifier, UspAdminState>(
  UspAdminNotifier.new,
);

class UspAdminNotifier extends AutoDisposeAsyncNotifier<UspAdminState> {
  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }

  UspAdminService get _svc => ref.read(uspAdminServiceProvider);

  @override
  Future<UspAdminState> build() async {
    // Time settings from shared data provider.
    final timeData = await ref.watch(timeDataProvider.future);

    final adminUser = await _svc.fetchAdmin();

    return UspAdminState(
      adminUser: adminUser,
      timeSettings: timeData.model,
    );
  }

  // ---------------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------------

  Future<void> setAdminPassword(String newPassword) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      await _svc.updatePassword(
        instancePath: state.requireValue.adminUser.instancePath,
        newPassword: newPassword,
      );
    });
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
  // Reboot / Factory Reset (direct USP operate — not codegen)
  // ---------------------------------------------------------------------------

  Future<void> reboot() async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      await _usp.operate('Device.Reboot()');
    });
  }

  Future<void> factoryReset() async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      await _usp.operate('Device.FactoryReset()');
    });
  }
}
