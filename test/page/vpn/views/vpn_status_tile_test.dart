import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';
import 'package:privacy_gui/page/vpn/views/vpn_status_tile.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/device_manager_test_state.dart';

/// A VPN notifier whose save always fails, the way a refused or failed write
/// does. Everything else is the real notifier.
class _FailingSaveVPN extends VPNNotifier {
  @override
  VPNState build() => const VPNState.init();

  @override
  Future<VPNState> save() async {
    // Fails after a round trip, as a real save does. doSomethingWithSpinner
    // only attaches to the task once its spinner is up, about 100 ms in.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw Exception('save failed');
  }
}

class _FakeDeviceManager extends DeviceManagerNotifier {
  @override
  DeviceManagerState build() =>
      DeviceManagerState.fromMap(deviceManagerTestData);
}

class _FakeDashboardHome extends DashboardHomeNotifier {
  @override
  DashboardHomeState build() => const DashboardHomeState();
}

void main() {
  mockDependencyRegister();

  // #1637: the toggle set the new value on state before saving, and nothing
  // put it back when the save failed. Polling refreshes only the tunnel status,
  // so the switch went on showing a VPN the router never turned on.
  testWidgets('a failed save puts the switch back', (tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(overrides: [
      vpnProvider.overrideWith(_FailingSaveVPN.new),
      deviceManagerProvider.overrideWith(_FakeDeviceManager.new),
      dashboardHomeProvider.overrideWith(_FakeDashboardHome.new),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(testableSingleRoute(
      provider: container,
      locale: const Locale('en'),
      child: const Scaffold(body: VPNStatusTile()),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse);

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();

    expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse,
        reason: 'the router never turned it on');
    expect(
        container.read(vpnProvider).settings.serviceSettings.enabled, isFalse);
  });
}
