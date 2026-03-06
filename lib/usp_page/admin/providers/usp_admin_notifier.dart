import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/admin_users.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/usp_page/admin/providers/usp_admin_state.dart';
import 'package:privacy_gui/usp_page/admin/services/usp_admin_service.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';

final uspAdminProvider =
    AsyncNotifierProvider.autoDispose<UspAdminNotifier, UspAdminState>(
  UspAdminNotifier.new,
);

class UspAdminNotifier extends AutoDisposeAsyncNotifier<UspAdminState> {
  bool _mutating = false;

  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }

  UspAdminService get _svc => ref.read(uspAdminServiceProvider);

  @override
  Future<UspAdminState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final results = await Future.wait([
      AdminUsers.fetch(usp),
      TimeSettings.fetch(usp),
    ]);

    final adminUsers = results[0] as AdminUsers;
    final timeSettings = results[1] as TimeSettings;
    final svc = _svc;

    return UspAdminState(
      adminUser: svc.buildAdminUserUIModel(adminUsers),
      timeSettings: svc.buildTimeSettingsUIModel(timeSettings),
    );
  }

  Future<T> _withLock<T>(Future<T> Function() action) async {
    if (_mutating) throw StateError('Another mutation is in progress');
    _mutating = true;
    try {
      return await action();
    } finally {
      _mutating = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------------

  Future<void> setAdminPassword(String newPassword) async {
    await _withLock(() async {
      final adminPath = state.requireValue.adminUser.instancePath;
      await AdminUsers.update(
        _usp,
        AdminUserUpdate(instancePath: adminPath, password: newPassword),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Timezone
  // ---------------------------------------------------------------------------

  Future<void> updateTimezone({
    String? localTimeZone,
    String? ntpServer1,
    String? ntpServer2,
    bool? enable,
  }) async {
    await _withLock(() async {
      await TimeSettings.save(
        _usp,
        localTimeZone: localTimeZone,
        ntpServer1: ntpServer1,
        ntpServer2: ntpServer2,
        enable: enable,
      );
      final ts = await TimeSettings.fetch(_usp);
      state = AsyncData(state.requireValue.copyWith(
        timeSettings: _svc.buildTimeSettingsUIModel(ts),
      ));
    });
  }

  // ---------------------------------------------------------------------------
  // Reboot / Factory Reset
  // ---------------------------------------------------------------------------

  Future<void> reboot() async {
    await _withLock(() async {
      await _usp.operate('Device.Reboot()');
    });
  }

  Future<void> factoryReset() async {
    await _withLock(() async {
      await _usp.operate('Device.FactoryReset()');
    });
  }
}
