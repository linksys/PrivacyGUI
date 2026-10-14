import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/device_manager_notifier_mocks.dart';
import '../../../mocks/local_network_settings_notifier_mocks.dart';
import '../../../test_data/device_details_test_state.dart';
import '../../../test_data/device_manager_test_state.dart';
import '../../../test_data/local_network_settings_state.dart';

class _DeviceList extends DeviceListNotifier {
  _DeviceList(this.item);
  final DeviceListItem item;

  @override
  DeviceListState build() => DeviceListState(devices: [item]);

  void remove() => state = const DeviceListState();
}

void main() {
  mockDependencyRegister();
  late MockDeviceManagerNotifier manager;
  late _DeviceList devices;
  final fixture =
      ExternalDeviceDetailState.fromMap(deviceDetailsTestState1).item;

  Future<void> pumpDetail(WidgetTester tester,
      {bool online = false, bool writable = true, bool mobile = false}) async {
    await tester.setScreenSize(mobile ? device480w : device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    manager = MockDeviceManagerNotifier();
    when(manager.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    devices = _DeviceList(fixture.copyWith(isOnline: online, isWired: true));
    final settings = MockLocalNetworkSettingsNotifier();
    when(settings.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    final router = GoRouter(initialLocation: '/devices/detail', routes: [
      LinksysRoute(
          name: RouteNamed.menuInstantDevices,
          path: '/devices',
          builder: (_, __) => const Scaffold(body: Text('Device list')),
          routes: [
            LinksysRoute(
                path: 'detail', builder: (_, __) => const DeviceDetailView()),
          ]),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(testableRouter(
      router: router,
      locale: const Locale('en'),
      overrides: [
        deviceManagerProvider.overrideWith(() => manager),
        deviceListProvider.overrideWith(() => devices),
        deviceDetailIdProvider.overrideWith((_) => fixture.deviceId),
        localNetworkSettingProvider.overrideWith(() => settings),
        accessPolicyProvider
            .overrideWithValue(AccessPolicy(canWrite: writable)),
      ],
    ));
    await tester.pumpAndSettle();
  }

  Future<void> askToDelete(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Delete device'));
    await tester.tap(find.text('Delete device'));
    await tester.pumpAndSettle();
  }

  for (final mobile in [false, true]) {
    testWidgets(
        'offline detail offers confirmed deletion (${mobile ? 'mobile' : 'desktop'})',
        (tester) async {
      await pumpDetail(tester, mobile: mobile);
      when(manager.deleteDevices(deviceIds: [fixture.deviceId]))
          .thenAnswer((_) async => devices.remove());
      await askToDelete(tester);
      expect(find.text('Delete device'), findsNWidgets(2));
      expect(find.textContaining('reappear in the list'), findsOneWidget);
      verifyNever(manager.deleteDevices(deviceIds: anyNamed('deviceIds')));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      verify(manager.deleteDevices(deviceIds: [fixture.deviceId])).called(1);
      expect(find.text('Device list'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cancel leaves the client untouched', (tester) async {
    await pumpDetail(tester);
    await askToDelete(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(manager.deleteDevices(deviceIds: anyNamed('deviceIds')));
    expect(find.text(fixture.name), findsWidgets);
  });

  testWidgets('online clients cannot be deleted', (tester) async {
    await pumpDetail(tester, online: true);
    expect(find.text('Delete device'), findsNothing);
  });

  testWidgets('read-only login cannot confirm deletion', (tester) async {
    await pumpDetail(tester, writable: false);
    await askToDelete(tester);
    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(manager.deleteDevices(deviceIds: anyNamed('deviceIds')));
  });

  testWidgets('failure retains the detail and shows an error', (tester) async {
    await pumpDetail(tester);
    when(manager.deleteDevices(deviceIds: [fixture.deviceId]))
        .thenAnswer((_) async => throw TimeoutException('router timeout'));
    await askToDelete(tester);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Device list'), findsNothing);
    expect(find.text(fixture.name), findsWidgets);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('removed device does not throw while details rebuild', () {
    expect(
        ExternalDeviceDetailNotifier().createState([], fixture.deviceId).item,
        const DeviceListItem());
  });
}
