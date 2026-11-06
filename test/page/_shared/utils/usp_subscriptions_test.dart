import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/page/_shared/utils/usp_subscriptions.dart';

const _macFilterMode = 'mac-filter-mode-valuechange';

void main() {
  group('coreSubscriptionsFor — capability gate', () {
    test('a router with the MAC filter gets every core subscription', () {
      final rows = coreSubscriptionsFor(
          DeviceCapabilities(const {DeviceCapability.wifiMacFilter}));

      expect(rows, coreSubscriptions);
      expect(rows.map((r) => r.$1), contains(_macFilterMode));
    });

    // Without the leaf the router refuses the subscription, and Remote
    // Assistance counts the refusal as a failed core subscription: every
    // session there would end on the "partial" snackbar (#1755 review).
    test('a router without it is not asked for the MAC filter mode', () {
      final rows = coreSubscriptionsFor(DeviceCapabilities.empty);

      expect(rows.map((r) => r.$1), isNot(contains(_macFilterMode)));
      expect(rows,
          coreSubscriptions.where((r) => r.$1 != _macFilterMode).toList());
    });
  });
}
