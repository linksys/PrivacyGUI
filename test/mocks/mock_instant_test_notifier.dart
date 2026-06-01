import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';

class MockInstantTestNotifier extends InstantTestNotifier with Mock {
  final InstantTestState _initialState;

  MockInstantTestNotifier(this._initialState);

  @override
  InstantTestState build() => _initialState;

  @override
  Future<void> fetch({bool forceSpeedTest = false}) async {}

  @override
  void setPlanSpeed(double mbps) {}

  @override
  void setFlowEntered(String flowKey) {}

  @override
  void setEscalationReason(String reason) {}

  @override
  void clearError() {}
}
