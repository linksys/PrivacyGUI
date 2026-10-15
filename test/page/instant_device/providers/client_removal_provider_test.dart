import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_device/providers/client_removal_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/client_access_policy_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';

import '../../../common/di.dart';
import '../../../mocks/device_manager_notifier_mocks.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../test_data/device_manager_test_state.dart';

const _mac = '02:AA:BB:CC:DD:01';
const _otherMac = '02:00:00:00:00:02';
const _client = DeviceListItem(
    deviceId: 'phone', name: 'Phone', macAddress: _mac, isOnline: true);

class _Devices extends DeviceListNotifier {
  _Devices(this.client);
  final DeviceListItem client;
  @override
  DeviceListState build() => DeviceListState(devices: [client]);
  void update(DeviceListItem item) => state = DeviceListState(devices: [item]);
}

class _Connectivity extends ConnectivityNotifier {
  @override
  ConnectivityState build() => const ConnectivityState(
      hasInternet: true,
      connectivityInfo: ConnectivityInfo(
          gatewayIp: '192.168.1.1', routerType: RouterType.behindManaged));
}

/// Executes the real JNAP command path against a router simulator. A write
/// changes its admission policy; the readback must see that before deauth.
class _Router with JNAPCommandExecutor<Response> {
  MACFilterSettings settings = const MACFilterSettings(
      macFilterMode: 'Disabled', maxMACAddresses: 32, macAddresses: []);
  String localId = 'administrator';
  final commands = <JNAPHttpCommand>[];
  JNAPAction? fail;
  bool applyWrites = true;
  List<String> bssids = [];
  Future<void> Function()? beforeSettingsRead;

  List<String> get actions =>
      commands.map((command) => command.spec.action).toList();
  List<JNAPHttpCommand> sent(JNAPAction action) => commands
      .where((command) => command.spec.action == action.actionValue)
      .toList();

  @override
  Future<Response> execute(BaseCommand command) async {
    final request = command as JNAPHttpCommand;
    commands.add(request);
    final action = command.spec.action;
    if (fail != null && action == fail!.actionValue) {
      return Response(jsonEncode({'result': 'ErrorTestFailure'}), 200);
    }
    Map<String, dynamic> output = {};
    if (action == JNAPAction.getLocalDevice.actionValue) {
      output = {'deviceID': localId};
    } else if (action == JNAPAction.getSTABSSIDs.actionValue) {
      output = {'staBSSIDS': bssids};
    } else if (action == JNAPAction.getMACFilterSettings.actionValue) {
      await beforeSettingsRead?.call();
      output = {
        'macFilterMode': settings.macFilterMode,
        'macAddresses': settings.macAddresses,
        'maxMACAddresses': settings.maxMACAddresses,
      };
    } else if (action == JNAPAction.setMACFilterSettings.actionValue &&
        applyWrites) {
      settings = settings.copyWith(
        macFilterMode: request.spec.data['macFilterMode'] as String,
        macAddresses: List<String>.from(request.spec.data['macAddresses']),
      );
    }
    return Response(jsonEncode({'result': 'OK', 'output': output}), 200);
  }

  @override
  void dropCommand(String id) {}
}

class _Repository extends RouterRepository {
  _Repository(super.ref, this.router);
  final _Router router;
  @override
  JNAPCommandExecutor get executor => router;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  mockDependencyRegister();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path);
  messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (_) async => null);
  messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (_) async => <String, Object>{});

  late _Router router;
  late ProviderContainer container;
  late _Devices devices;
  late MockPollingNotifier polling;

  void create(
      {DeviceListItem client = _client,
      DeviceManagerState managerState = const DeviceManagerState(),
      bool writable = true,
      bool remote = false}) {
    devices = _Devices(client);
    final manager = MockDeviceManagerNotifier();
    when(manager.build()).thenReturn(managerState);
    container = ProviderContainer(overrides: [
      deviceListProvider.overrideWith(() => devices),
      deviceManagerProvider.overrideWith(() => manager),
      connectivityProvider.overrideWith(() => _Connectivity()),
      accessPolicyProvider.overrideWithValue(AccessPolicy(canWrite: writable)),
      isRemoteLoginProvider.overrideWithValue(remote),
      pollingProvider.overrideWith(() => polling),
      routerRepositoryProvider.overrideWith((ref) => _Repository(ref, router)),
    ]);
    addTearDown(container.dispose);
  }

  Future<ClientRemovalOutcome> remove() =>
      container.read(clientRemovalProvider).remove('phone');
  Matcher failure(ClientRemovalFailure reason) =>
      throwsA(isA<ClientRemovalException>()
          .having((error) => error.failure, 'reason', reason));

  Future<List<DeviceListItem>> restrictedList() async {
    final subscription =
        container.listen(restrictedDevicesProvider, (_, __) {});
    addTearDown(subscription.close);
    await container.read(clientAccessPolicyProvider.future);
    return container.read(restrictedDevicesProvider).requireValue;
  }

  setUp(() {
    buildBetterActions(JNAPService.appSupportedServices
        .map((service) => service.value)
        .toList());
    when(serviceHelper.isSupportClientDeauth()).thenReturn(true);
    when(serviceHelper.isSupportGetSTABSSID()).thenReturn(false);
    router = _Router();
    polling = MockPollingNotifier();
    when(polling.forcePolling()).thenAnswer((_) async {});
  });

  test('disabled policy becomes a one-device deny list before deauth',
      () async {
    router.settings = router.settings.copyWith(macAddresses: [_otherMac]);
    create();
    expect(await remove(), ClientRemovalOutcome.disconnectRequested);
    expect(router.settings.macFilterMode, 'Deny');
    expect(router.settings.macAddresses, [_mac]);
    expect(
        router.actions,
        [
          JNAPAction.getLocalDevice,
          JNAPAction.getMACFilterSettings,
          JNAPAction.setMACFilterSettings,
          JNAPAction.getMACFilterSettings,
          JNAPAction.clientDeauth,
        ].map((action) => action.actionValue).toList());
    expect(router.sent(JNAPAction.clientDeauth).single.spec.data,
        {'macAddress': _mac});
    expect(
        router.commands.every(
            (command) => command.header.containsKey('X-JNAP-Authorization')),
        isTrue);
    verify(polling.forcePolling()).called(1);
  });

  test('deny policy preserves other denied clients', () async {
    router.settings = router.settings
        .copyWith(macFilterMode: 'Deny', macAddresses: [_otherMac]);
    create();
    await remove();
    expect(router.settings.macAddresses, [_otherMac, _mac]);
  });

  test('allow policy removes only the selected station', () async {
    router.settings = router.settings.copyWith(
        macFilterMode: 'Allow',
        macAddresses: [_otherMac, _mac.toLowerCase(), '02:00:00:00:00:03']);
    create();
    await remove();
    expect(router.settings.macFilterMode, 'Allow');
    expect(router.settings.macAddresses, [_otherMac, '02:00:00:00:00:03']);
  });

  test('already denied station still gets deauth without a duplicate write',
      () async {
    router.settings = router.settings
        .copyWith(macFilterMode: 'Deny', macAddresses: [_mac.toLowerCase()]);
    create();
    await remove();
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
    expect(router.sent(JNAPAction.clientDeauth), hasLength(1));
  });

  test('failed policy save never sends deauth', () async {
    router.fail = JNAPAction.setMACFilterSettings;
    create();
    await expectLater(remove(), throwsA(anything));
    expect(router.sent(JNAPAction.clientDeauth), isEmpty);
    expect(router.settings.macFilterMode, 'Disabled');
  });

  test('failed readback does not deauth or pretend the removal was verified',
      () async {
    router.applyWrites = false;
    create();
    expect(await remove(), ClientRemovalOutcome.unverified);
    expect(router.sent(JNAPAction.clientDeauth), isEmpty);
  });

  test('failed deauth retains the saved policy and reports partial success',
      () async {
    router.fail = JNAPAction.clientDeauth;
    create();
    expect(await remove(), ClientRemovalOutcome.disconnectFailed);
    expect(router.settings.macAddresses, [_mac]);
  });

  test('routers without deauth support still persist the admission restriction',
      () async {
    when(serviceHelper.isSupportClientDeauth()).thenReturn(false);
    create();
    expect(await remove(), ClientRemovalOutcome.policyOnly);
    expect(router.settings.macAddresses, [_mac]);
    expect(router.sent(JNAPAction.clientDeauth), isEmpty);
  });

  test('refresh failure does not undo or misreport a saved access restriction',
      () async {
    when(polling.forcePolling())
        .thenAnswer((_) async => throw StateError('poll failed'));
    create();
    expect(await remove(), ClientRemovalOutcome.disconnectRequested);
    expect(router.settings.macAddresses, [_mac]);
  });

  test('current client is protected before any write', () async {
    router.localId = 'phone';
    create();
    await expectLater(remove(), failure(ClientRemovalFailure.protectedDevice));
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
    expect(router.sent(JNAPAction.clientDeauth), isEmpty);
  });

  test('empty local identity cannot silently disable self-protection',
      () async {
    router.localId = '';
    create();
    await expectLater(remove(), failure(ClientRemovalFailure.unavailable));
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
  });

  test('current device MAC alias is protected even under a different ID',
      () async {
    final state = DeviceManagerState.fromMap(deviceManagerCherry7TestState);
    final administrator = state.externalDevices.first.copyWith(
      connections: const [RawDeviceConnection(macAddress: _mac)],
    );
    router.localId = administrator.deviceID;
    create(managerState: state.copyWith(deviceList: [administrator]));
    await expectLater(remove(), failure(ClientRemovalFailure.protectedDevice));
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
  });

  test(
      'full-access remote login does not identify the cloud server as a local client',
      () async {
    create(remote: true);
    expect(await remove(), ClientRemovalOutcome.disconnectRequested);
    expect(router.sent(JNAPAction.getLocalDevice), isEmpty);
  });

  test('removal uses the active station MAC instead of another known interface',
      () async {
    final state = DeviceManagerState.fromMap(deviceManagerCherry7TestState);
    final client = state.externalDevices.first.copyWith(
      deviceID: 'phone',
      connections: const [RawDeviceConnection(macAddress: _mac)],
    );
    create(
        client: _client.copyWith(macAddress: _otherMac),
        managerState: state.copyWith(deviceList: [client]));
    await remove();
    expect(router.settings.macAddresses, [_mac]);
    expect(router.sent(JNAPAction.clientDeauth).single.spec.data,
        {'macAddress': _mac});
  });

  test('mesh node MAC alias is protected', () async {
    final state = DeviceManagerState.fromMap(deviceManagerCherry7TestState);
    final node = state.nodeDevices.first;
    final mac = node.knownInterfaces!.first.macAddress;
    create(client: _client.copyWith(macAddress: mac), managerState: state);
    await expectLater(remove(), failure(ClientRemovalFailure.protectedDevice));
    expect(router.commands, isEmpty);
  });

  test('mesh backhaul BSSID is protected', () async {
    when(serviceHelper.isSupportGetSTABSSID()).thenReturn(true);
    router.bssids = [_mac.toLowerCase()];
    create();
    await expectLater(remove(), failure(ClientRemovalFailure.protectedDevice));
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
  });

  test('full deny list sends neither a policy change nor deauth', () async {
    router.settings = const MACFilterSettings(
        macFilterMode: 'Deny', maxMACAddresses: 1, macAddresses: [_otherMac]);
    create();
    await expectLater(remove(), failure(ClientRemovalFailure.capacity));
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
    expect(router.sent(JNAPAction.clientDeauth), isEmpty);
  });

  test('unknown policy is preserved without a write', () async {
    router.settings = router.settings.copyWith(macFilterMode: 'Unknown');
    create();
    await expectLater(
        remove(), failure(ClientRemovalFailure.unsupportedPolicy));
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
  });

  for (final client in [
    _client.copyWith(isWired: true),
    _client.copyWith(isOnline: false),
    _client.copyWith(macAddress: ''),
    _client.copyWith(macAddress: 'FF:FF:FF:FF:FF:FF'),
  ]) {
    test('non-WiFi, stale or invalid target is refused: $client', () async {
      create(client: client);
      await expectLater(remove(), failure(ClientRemovalFailure.unavailable));
      expect(router.commands, isEmpty);
    });
  }

  test('read-only access refuses the operation before any router command',
      () async {
    create(writable: false);
    await expectLater(remove(), throwsA(isA<ReadOnlyAccessException>()));
    expect(router.commands, isEmpty);
  });

  test('moving to Ethernet during the reads prevents all writes', () async {
    create();
    router.beforeSettingsRead =
        () async => devices.update(_client.copyWith(isWired: true));
    await expectLater(remove(), failure(ClientRemovalFailure.unavailable));
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
    expect(router.sent(JNAPAction.clientDeauth), isEmpty);
  });

  test('concurrent attempts cannot overwrite each other', () async {
    final waiting = Completer<void>();
    final entered = Completer<void>();
    router.beforeSettingsRead = () async {
      if (!entered.isCompleted) entered.complete();
      await waiting.future;
    };
    create();
    final first = remove();
    await entered.future;
    await expectLater(remove(), failure(ClientRemovalFailure.busy));
    waiting.complete();
    await first;
    expect(router.sent(JNAPAction.setMACFilterSettings), hasLength(1));
  });

  for (final mode in ['Deny', 'Allow']) {
    test('restore preserves $mode mode and every other client, without deauth',
        () async {
      router.settings = router.settings.copyWith(
          macFilterMode: mode,
          macAddresses: mode == 'Deny' ? [_otherMac, _mac] : [_otherMac]);
      create();
      expect(
          await container
              .read(clientRemovalProvider)
              .restore(_mac.toLowerCase()),
          isTrue);
      expect(router.settings.macFilterMode, mode);
      expect(router.settings.macAddresses,
          mode == 'Deny' ? [_otherMac] : [_otherMac, _mac]);
      expect(router.sent(JNAPAction.clientDeauth), isEmpty);
      expect(
          router.actions,
          [
            JNAPAction.getMACFilterSettings,
            JNAPAction.setMACFilterSettings,
            JNAPAction.getMACFilterSettings
          ].map((a) => a.actionValue));
    });
  }

  test('restore does not claim success if the router ignores the write',
      () async {
    router.settings =
        router.settings.copyWith(macFilterMode: 'Deny', macAddresses: [_mac]);
    router.applyWrites = false;
    create();
    expect(await container.read(clientRemovalProvider).restore(_mac), isFalse);
    expect(router.settings.macAddresses, [_mac]);
  });

  test('read-only restore sends no router commands', () async {
    create(writable: false);
    await expectLater(container.read(clientRemovalProvider).restore(_mac),
        throwsA(isA<ReadOnlyAccessException>()));
    expect(router.commands, isEmpty);
  });

  test('restore refuses a full allow list without changing other access',
      () async {
    router.settings = const MACFilterSettings(
        macFilterMode: 'Allow', maxMACAddresses: 1, macAddresses: [_otherMac]);
    create();
    await expectLater(container.read(clientRemovalProvider).restore(_mac),
        failure(ClientRemovalFailure.capacity));
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
  });

  test(
      'disabled filtering is already restored without activating inactive rules',
      () async {
    router.settings = router.settings.copyWith(macAddresses: [_mac]);
    create();
    expect(await container.read(clientRemovalProvider).restore(_mac), isTrue);
    expect(router.sent(JNAPAction.setMACFilterSettings), isEmpty);
  });

  test('denied MACs remain visible even when the device record is gone',
      () async {
    router.settings =
        router.settings.copyWith(macFilterMode: 'Deny', macAddresses: [_mac]);
    create(client: _client.copyWith(macAddress: _otherMac, isOnline: false));
    final removed = await restrictedList();
    expect(removed.map((d) => d.macAddress), [_mac]);
    expect(removed.single.name, _mac);
    expect(removed.any((d) => d.macAddress == _otherMac), isFalse);
  });

  test('allow mode finds restricted WiFi aliases and excludes wired interfaces',
      () async {
    router.settings = router.settings
        .copyWith(macFilterMode: 'Allow', macAddresses: [_otherMac]);
    final state = DeviceManagerState.fromMap(deviceManagerCherry7TestState);
    final client = state.externalDevices.first
        .copyWith(deviceID: 'phone', connections: [], knownInterfaces: const [
      RawDeviceKnownInterface(macAddress: _mac, interfaceType: 'Wireless'),
      RawDeviceKnownInterface(macAddress: _otherMac, interfaceType: 'Wired')
    ]);
    create(
        client: _client.copyWith(
            macAddress: _otherMac, isOnline: false, isWired: true),
        managerState: state.copyWith(deviceList: [client]));
    final removed = await restrictedList();
    expect(removed.map((d) => d.macAddress), [_mac]);
    expect(removed.single.name, 'Phone');
  });

  test('inactive MAC entries never make ordinary offline clients removed',
      () async {
    router.settings = router.settings.copyWith(macAddresses: [_mac]);
    create(client: _client.copyWith(isOnline: false));
    expect(await restrictedList(), isEmpty);
  });

  test(
      'a failed policy fetch reports an error instead of an empty restricted list',
      () async {
    router.fail = JNAPAction.getMACFilterSettings;
    create();
    final subscription =
        container.listen(restrictedDevicesProvider, (_, __) {});
    addTearDown(subscription.close);
    await expectLater(
        container.read(clientAccessPolicyProvider.future), throwsA(anything));
    expect(container.read(restrictedDevicesProvider).hasError, isTrue);
  });
}
