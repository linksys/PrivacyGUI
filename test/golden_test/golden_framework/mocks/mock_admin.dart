import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_state.dart';

class FixedAdminNotifier extends UspAdminNotifier {
  final UspAdminState _fixedState;

  FixedAdminNotifier(this._fixedState);

  @override
  Future<UspAdminState> build() async => _fixedState;

  @override
  Future<void> setAdminPassword(String newPassword) async {}

  @override
  Future<void> updateTimeSettings({
    bool? enable,
    String? ntpServer1,
    String? ntpServer2,
  }) async {}

  @override
  Future<void> updateTimezone({
    required String localTimeZone,
    String? ntpServer1,
  }) async {}

  @override
  Future<void> reboot() async {}

  @override
  Future<void> factoryReset() async {}
}

List<Override> adminOverrides(UspAdminState state) => [
      uspAdminProvider.overrideWith(() => FixedAdminNotifier(state)),
    ];
