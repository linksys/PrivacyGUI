import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';

class MockInstantVerifyPivotNotifier extends InstantVerifyPivotNotifier
    with Mock {
  final InstantVerifyPivotState _initialState;

  MockInstantVerifyPivotNotifier(this._initialState);

  @override
  InstantVerifyPivotState build() => _initialState;

  @override
  Future<void> fetch({bool forceSpeedTest = false}) async {}

  @override
  Future<void> restartRouter() async {}

  @override
  Future<void> triggerFirmwareUpdate() async {}

  @override
  Future<void> deauthClient(String macAddress) async {}

  @override
  Future<bool> changeRadioChannel(String radioID, int channel) async => false;

  @override
  Future<void> disableMacFilter() async {}

  @override
  Future<void> setGuestNetworkEnabled(bool enabled) async {}

  @override
  void loadMockFails() {}
}
