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
}

/// Test override for DevicesDataNotifier.
class _TestDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _data;

  _TestDevicesDataNotifier(this._data);

  @override
  Future<DevicesData> build() async => _data;
}

/// Creates an empty DevicesData for testing.
DevicesData _emptyDevicesData() {
  return DevicesData(
    meshNetwork: MeshNetwork(
      master: MasterNode(deviceId: 'GATEWAY', model: 'TestRouter'),
    ),
  );
}
