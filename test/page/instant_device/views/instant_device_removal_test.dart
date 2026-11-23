import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/instant_device/providers/client_access_policy_provider.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/dashboard_manager_notifier_mocks.dart';
import '../../../mocks/device_filter_config_notifier_mocks.dart';
import '../../../mocks/device_manager_notifier_mocks.dart';
import '../../../mocks/wifi_list_notifier_mocks.dart';
import '../../../test_data/wifi_list_test_state.dart';

final _restrictionActive = StateProvider((_) => true);

void main() {
  mockDependencyRegister();
  late MockDeviceManagerNotifier manager;
  late MockDeviceFilterConfigNotifier filter;
  const clients = [
    DeviceListItem(deviceId: 'client-1', name: 'Old phone'),
    DeviceListItem(deviceId: 'client-2', name: 'Old laptop'),
  ];

  Future<void> pumpList(WidgetTester tester,
      {bool online = false,
      bool writable = true,
      bool mobile = false,
      bool hasRestrictions = true,
      bool wired = true}) async {
    await tester.setScreenSize(mobile ? device480w : device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    manager = MockDeviceManagerNotifier();
    when(manager.build()).thenReturn(const DeviceManagerState());
    filter = MockDeviceFilterConfigNotifier();
    when(filter.build()).thenReturn(DeviceFilterConfigState(
        connectionFilter: online,
        nodeFilter: const [],
        wifiFilter: const [],
        bandFilter: const []));
    final wifi = MockWifiListNotifier();
    when(wifi.build()).thenReturn(WiFiState.fromMap(wifiListTestState));
    final dashboard = MockDashboardManagerNotifier();
    when(dashboard.build()).thenReturn(const DashboardManagerState());
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        deviceManagerProvider.overrideWith(() => manager),
        deviceFilterConfigProvider.overrideWith(() => filter),
        filteredDeviceListProvider.overrideWith((_) => clients
            .map((device) => device.copyWith(
                isOnline: online,
                isWired: wired,
                macAddress: device.deviceId == 'client-1'
                    ? '02:00:00:00:00:01'
                    : '02:00:00:00:00:02'))
            .toList()),
        wifiListProvider.overrideWith(() => wifi),
        dashboardManagerProvider.overrideWith(() => dashboard),
        accessPolicyProvider
            .overrideWithValue(AccessPolicy(canWrite: writable)),
        _restrictionActive.overrideWith((_) => hasRestrictions),
        clientAccessPolicyProvider.overrideWith((_) async =>
            const MACFilterSettings(
                macFilterMode: 'Deny',
                maxMACAddresses: 32,
                macAddresses: ['02:00:00:00:00:01'])),
        restrictedDevicesProvider.overrideWith((ref) => AsyncData(
            ref.watch(_restrictionActive)
                ? const [
                    DeviceListItem(
                        name: 'Removed phone', macAddress: '02:00:00:00:00:01')
                  ]
                : const <DeviceListItem>[])),
      ],
      child: const InstantDeviceView(),
      extraRoutes: [
        LinksysRoute(
          name: RouteNamed.deviceDetails,
          path: '/details',
          builder: (_, __) => const Scaffold(body: Text('Client details')),
        ),
      ],
    ));
    await tester.pumpAndSettle();
  }

  for (final mobile in [false, true]) {
    testWidgets(
        'row delete confirms only the chosen client (${mobile ? 'mobile' : 'desktop'})',
        (tester) async {
      await pumpList(tester, mobile: mobile);
      await tester.tap(find.byIcon(LinksysIcons.delete).first);
      await tester.pumpAndSettle();
      expect(find.text('Delete device'), findsOneWidget);
      verifyNever(manager.deleteDevices(deviceIds: anyNamed('deviceIds')));
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Delete')));
      await tester.pumpAndSettle();
      verify(manager.deleteDevices(deviceIds: ['client-1'])).called(1);
      expect(find.text('Device deleted.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('online view links directly to offline devices', (tester) async {
    await pumpList(tester, online: true);
    expect(find.byIcon(LinksysIcons.delete), findsNothing);
    await tester.tap(find.text('Offline devices'));
    verify(filter.updateConnectionFilter(false)).called(1);
  });

  testWidgets('live wireless clients offer Remove in the list', (tester) async {
    await pumpList(tester, online: true, wired: false);
    expect(find.byIcon(LinksysIcons.bidirectional), findsNothing);
    expect(find.byTooltip('Device actions'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Device actions').first);
    await tester.pumpAndSettle();
    expect(find.text('Remove'), findsOneWidget);
    expect(find.text('Block'), findsNothing);
  });

  testWidgets('cancel does not delete the client', (tester) async {
    await pumpList(tester);
    await tester.tap(find.byIcon(LinksysIcons.delete).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(manager.deleteDevices(deviceIds: anyNamed('deviceIds')));
  });

  testWidgets('read-only row action does not open confirmation',
      (tester) async {
    await pumpList(tester, writable: false);
    await tester.tap(find.byIcon(LinksysIcons.delete).first,
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(manager.deleteDevices(deviceIds: anyNamed('deviceIds')));
  });

  testWidgets('bulk deletion remains available', (tester) async {
    await pumpList(tester);
    await tester.tap(find.text('Select All'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppFilledButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Delete devices'), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Delete')));
    await tester.pumpAndSettle();
    verify(manager.deleteDevices(deviceIds: ['client-1', 'client-2']))
        .called(1);
  });

  for (final mobile in [false, true]) {
    testWidgets(
        'restricted devices are separate from offline (${mobile ? 'mobile' : 'desktop'})',
        (tester) async {
      await pumpList(tester, mobile: mobile);
      expect(find.text('Old phone'), findsOneWidget);
      expect(find.text('Removed phone'), findsNothing);
      if (mobile) {
        await tester.tap(find.text('Filters'));
        await tester.pumpAndSettle();
      }
      expect(
          tester.getTopLeft(find.text('Blocked / Removed devices')).dy,
          greaterThan(tester
              .getTopLeft(find.descendant(
                  of: find.byType(FilterChip), matching: find.text('Offline')))
              .dy));
      await tester.tap(find.text('Blocked / Removed devices'));
      await tester.pumpAndSettle();
      expect(find.text('Removed phone'), findsOneWidget);
      expect(find.text('Old phone'), findsNothing);
      expect(find.byIcon(LinksysIcons.delete), findsNothing);
      expect(find.text('Select All'), findsNothing);
      await tester.tap(find.text('Offline devices'));
      await tester.pumpAndSettle();
      expect(find.text('Old phone'), findsOneWidget);
      expect(find.text('Removed phone'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final mobile in [false, true]) {
    testWidgets(
        'empty restrictions hide the bubble (${mobile ? 'mobile' : 'desktop'})',
        (tester) async {
      await pumpList(tester, mobile: mobile, hasRestrictions: false);
      if (mobile) {
        await tester.tap(find.text('Filters'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Blocked / Removed devices'), findsNothing);
    });
  }

  testWidgets(
      'clearing the last restriction hides the bubble and returns to Offline',
      (tester) async {
    await pumpList(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(InstantDeviceView)));
    await tester.tap(find.text('Blocked / Removed devices'));
    await tester.pumpAndSettle();
    expect(find.text('Removed phone'), findsOneWidget);
    container.read(_restrictionActive.notifier).state = false;
    await tester.pumpAndSettle();
    expect(find.text('Blocked / Removed devices'), findsNothing);
    expect(find.text('Old phone'), findsOneWidget);
    verify(filter.updateConnectionFilter(false)).called(1);
    expect(tester.takeException(), isNull);
  });
}
