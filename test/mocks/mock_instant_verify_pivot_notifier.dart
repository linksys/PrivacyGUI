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
  Future<void> fetch() async {}

  @override
  Future<void> restartRouter() async {}

  @override
  Future<void> triggerFirmwareUpdate() async {}

  @override
  void loadMockFails() {}
}
