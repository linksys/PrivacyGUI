import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/services/usp_ethernet_data_service.dart';

import '../../../mocks/test_data/devices_test_data.dart';

class MockUspEthernetDataService extends Mock
    implements UspEthernetDataService {}

void main() {
  late MockUspEthernetDataService mockEthernetSvc;

  final samplePortModels = [
    EthernetPortUIModel(
      name: 'eth0',
      label: 'WAN',
      isWan: true,
      isUp: true,
      instancePath: 'Device.Ethernet.Interface.2.',
      currentBitRate: 1000,
    ),
    EthernetPortUIModel(
      name: 'eth1',
      label: 'LAN',
      isWan: false,
      isUp: true,
      instancePath: 'Device.Ethernet.Interface.1.',
      currentBitRate: 1000,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(<ClientDevice>[]);
  });

  setUp(() {
    mockEthernetSvc = MockUspEthernetDataService();

    when(() => mockEthernetSvc.fetch(
          deviceModels: any(named: 'deviceModels'),
        )).thenAnswer(
      (_) async => EthernetDataFetchResult(portModels: samplePortModels),
    );
  });

  ProviderContainer createContainer({
    DevicesData? devicesData,
  }) {
    return ProviderContainer(
      overrides: [
        uspEthernetDataServiceProvider.overrideWithValue(mockEthernetSvc),
        devicesDataProvider.overrideWith(
          () => _TestDevicesDataNotifier(devicesData ?? _emptyDevicesData()),
        ),
      ],
    );
  }

  group('EthernetDataNotifier', () {
    test('build fetches via service and returns port models', () async {
      final container = createContainer();
      final data = await container.read(ethernetDataProvider.future);

      expect(data.ethernetPortModels, hasLength(2));
      expect(data.ethernetPortModels[0].label, 'WAN');
      expect(data.ethernetPortModels[1].label, 'LAN');
      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(1);
      container.dispose();
    });

    test('build throws when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(null),
          devicesDataProvider.overrideWith(
            () => _TestDevicesDataNotifier(_emptyDevicesData()),
          ),
        ],
      );

      expect(
        container.read(ethernetDataProvider.future),
        throwsA(isA<ServiceNotInitializedError>()),
      );
      container.dispose();
    });

    test('EthernetData copyWith works', () {
      const data = EthernetData();
      expect(data.ethernetPortModels, isEmpty);

      final same = data.copyWith();
      expect(same, equals(data));
    });

    test('EthernetData props uses list for equality', () {
      const a = EthernetData();
      const b = EthernetData();
      expect(a, equals(b));

      final port = EthernetPortUIModel(
        name: 'eth1',
        label: 'LAN',
        isWan: false,
        isUp: true,
        instancePath: 'p',
        currentBitRate: 100,
      );
      final c = EthernetData(ethernetPortModels: [port]);
      expect(a, isNot(equals(c)));
    });
  });

  // ---------------------------------------------------------------------------
  // The devicesDataProvider listener re-fetches only when the input it actually
  // consumes changed.
  //
  // `_fetch()` passes exactly `clientDevices` to the service, but DevicesData
  // emits on any device field (RSSI, band, SSID), and devicesDataProvider
  // assigns state directly rather than invalidating — so before #1502 every
  // unrelated device update cost one Ethernet USP fetch. Causes that are not the
  // device list arrive via the sseInvalidationProvider listener instead.
  // ---------------------------------------------------------------------------
  group('EthernetDataNotifier — devices listener', () {
    /// Builds a container whose devices provider can emit further states.
    (ProviderContainer, _PushableDevicesDataNotifier) pushableContainer(
      DevicesData initial,
    ) {
      final notifier = _PushableDevicesDataNotifier(initial);
      final container = ProviderContainer(
        overrides: [
          uspEthernetDataServiceProvider.overrideWithValue(mockEthernetSvc),
          devicesDataProvider.overrideWith(() => notifier),
        ],
      );
      return (container, notifier);
    }

    test('does not re-fetch when clientDevices is unchanged', () async {
      final client = DevicesTestData.createWiredClient();
      final (container, notifier) = pushableContainer(_devicesWith([client]));
      addTearDown(container.dispose);

      // A permanent subscription is required: invalidateSelf() on a provider
      // with no listeners only marks it dirty, and the rebuild is deferred to
      // the next read — so without this, the unguarded version would look
      // identical to the guarded one here.
      container.listen(ethernetDataProvider, (_, __) {});
      await container.read(ethernetDataProvider.future);
      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(1);

      // A fresh DevicesData carrying an equal client list. ClientDevice has
      // value equality (NetworkEntity with EquatableMixin), so this is the
      // "device changed in a way Ethernet does not read" case.
      notifier.emit(_devicesWith([DevicesTestData.createWiredClient()]));
      await Future.delayed(Duration.zero);

      verifyNever(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          ));
    });

    test('re-fetches when clientDevices changes', () async {
      final (container, notifier) = pushableContainer(_devicesWith([]));
      addTearDown(container.dispose);

      container.listen(ethernetDataProvider, (_, __) {});
      await container.read(ethernetDataProvider.future);
      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(1);

      notifier.emit(_devicesWith([DevicesTestData.createWiredClient()]));
      await Future.delayed(Duration.zero);

      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(1);
    });
  });
}

/// Test override for DevicesDataNotifier.
class _TestDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _data;

  _TestDevicesDataNotifier(this._data);

  @override
  Future<DevicesData> build() async => _data;
}

/// Test override that can emit further states, mirroring how the real notifier
/// assigns state directly (devices_data_provider.dart:296) rather than
/// invalidating — so there is no intervening loading frame.
class _PushableDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _initial;

  _PushableDevicesDataNotifier(this._initial);

  @override
  Future<DevicesData> build() async => _initial;

  void emit(DevicesData data) => state = AsyncData(data);
}

/// Creates DevicesData whose `clientDevices` is exactly [clients].
DevicesData _devicesWith(List<ClientDevice> clients) {
  return DevicesData(
    meshNetwork: MeshNetwork(
      master: MasterNode(deviceId: 'GATEWAY', model: 'TestRouter'),
      unassignedClients: clients,
    ),
  );
}

/// Creates an empty DevicesData for testing.
DevicesData _emptyDevicesData() {
  return DevicesData(
    meshNetwork: MeshNetwork(
      master: MasterNode(deviceId: 'GATEWAY', model: 'TestRouter'),
    ),
  );
}
