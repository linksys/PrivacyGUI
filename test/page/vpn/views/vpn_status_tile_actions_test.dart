// The dashboard VPN tile's switch with full access.
//
// The switch saves the VPN service the moment it is flipped - no confirmation,
// no Save bar. These tests pin that with full access it is live and reaches the
// save with the new enabled value.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/views/vpn_status_tile.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/vpn_notifier_mocks.dart';
import '../../../test_data/_index.dart';
import '../../../test_data/vpn_test_state.dart';

void main() {
  late MockVPNNotifier mockVPNNotifier;
  late MockDashboardHomeNotifier mockDashboardHomeNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;

  mockDependencyRegister();

  setUp(() {
    mockVPNNotifier = MockVPNNotifier();
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    initBetterActions();

    when(mockVPNNotifier.build()).thenReturn(VPNTestState.defaultState);
    when(mockVPNNotifier.save())
        .thenAnswer((_) async => VPNTestState.defaultState);
    when(mockVPNNotifier.setVPNService(any)).thenAnswer((_) async {});
    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeCherry7TestState));
    // A non-empty device list is what takes the tile out of its loading state.
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
  });

  Future<void> pumpTile(WidgetTester tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        vpnProvider.overrideWith(() => mockVPNNotifier),
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
      ],
      child: const VPNStatusTile(),
    ));
    await tester.pumpAndSettle();
  }

  final vpnSwitch = find.descendant(
      of: find.byType(VPNStatusTile), matching: find.byType(AppSwitch));

  testWidgets('the switch is live', (tester) async {
    await pumpTile(tester);

    expect(tester.widget<AppSwitch>(vpnSwitch).onChanged, isNotNull);
    expect(find.byTooltip('This feature is unavailable in remote mode'),
        findsNothing);
  });

  testWidgets('flipping it saves the service at once', (tester) async {
    await pumpTile(tester);

    await tester.tap(vpnSwitch);
    await tester.pumpAndSettle();

    final settings = verify(mockVPNNotifier.setVPNService(captureAny))
        .captured
        .single as VPNServiceSetSettings;
    expect(settings.enabled, isFalse);
    verify(mockVPNNotifier.save()).called(1);
  });
}
