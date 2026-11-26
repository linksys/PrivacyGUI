import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';

import 'pnp_router_data.dart';

void main() {
  final router = NodeDeviceInfo.fromJson(pnpDeviceInfo);

  group('PnpState', () {
    test('reads an unknown device mode as configured', () {
      expect(const PnpState(deviceInfo: null).isRouterUnConfigured, isFalse);
      expect(
          const PnpState(deviceInfo: null, isUnconfigured: true)
              .isRouterUnConfigured,
          isTrue);
    });

    test('starts with no rotation recorded and nothing forced', () {
      const state = PnpState(deviceInfo: null);

      expect(state.autoMasterRotatedSinceLogin, isFalse);
      expect(state.forceLogin, isFalse);
      expect(state.isPrePaired, isFalse);
      expect(state.stepStateList, isEmpty);
      expect(state.childNodes, isEmpty);
    });

    test('copyWith keeps the attached password unless told to clear it', () {
      final state = PnpState(deviceInfo: router, attachedPassword: 'admin123');

      expect(state.copyWith(forceLogin: true).attachedPassword, 'admin123');
      expect(state.copyWith(attachedPassword: () => null).attachedPassword,
          isNull);
    });

    test('copyWith keeps the Auto Master status on entry unless told to clear',
        () {
      final state = PnpState(
          deviceInfo: router,
          autoMasterStatusOnEntry: AutoMasterStatus.complete);

      expect(state.copyWith(isPrePaired: true).autoMasterStatusOnEntry,
          AutoMasterStatus.complete);
      expect(
          state
              .copyWith(autoMasterStatusOnEntry: () => null)
              .autoMasterStatusOnEntry,
          isNull);
    });

    test('a recorded rotation makes a different state', () {
      final state = PnpState(deviceInfo: router, isUnconfigured: true);

      expect(state.copyWith(), state);
      expect(state.copyWith(autoMasterRotatedSinceLogin: true), isNot(state));
      expect(
          state
              .copyWith(autoMasterRotatedSinceLogin: true)
              .copyWith(autoMasterRotatedSinceLogin: false),
          state);
    });
  });
}
