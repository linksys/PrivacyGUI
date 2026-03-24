import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';

class MockUspService extends Mock implements UspService {}

class MockUspDeviceService extends Mock implements UspDeviceService {}

void main() {
  late MockUspService mockUsp;
  late MockUspDeviceService mockDeviceSvc;

  setUpAll(() {
    registerFallbackValue(const EthernetInterfaces(items: []));
    registerFallbackValue(<DeviceUIModel>[]);
    registerFallbackValue(<String, String>{});
  });

  /// EthernetInterfaces codegen response (2 interfaces).
  final ethernetResponse = <String, dynamic>{
    'Device.Ethernet.Interface.1.Name': 'eth1',
    'Device.Ethernet.Interface.1.Status': 'Up',
    'Device.Ethernet.Interface.1.Upstream': true,
    'Device.Ethernet.Interface.1.CurrentBitRate': '1000',
    'Device.Ethernet.Interface.2.Name': 'eth0',
    'Device.Ethernet.Interface.2.Status': 'Up',
    'Device.Ethernet.Interface.2.Upstream': false,
    'Device.Ethernet.Interface.2.CurrentBitRate': '100',
  };

  /// Bridge port map response.
  final bridgeResponse = <String, dynamic>{
    'Device.Bridging.Bridge.1.Port.1.LowerLayers':
        'Device.Ethernet.Interface.1.',
  };

  setUp(() {
    mockUsp = MockUspService();
    mockDeviceSvc = MockUspDeviceService();

    when(() => mockUsp.get(any())).thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('Bridging'))) {
        return bridgeResponse;
      }
      return ethernetResponse;
    });

    // Return empty port models by default
    when(() => mockDeviceSvc.buildEthernetPortUIModels(
          ethernetInterfaces: any(named: 'ethernetInterfaces'),
          deviceModels: any(named: 'deviceModels'),
          bridgePortMap: any(named: 'bridgePortMap'),
        )).thenReturn([]);
  });

  ProviderContainer createContainer({
    DevicesData? devicesData,
  }) {
    return ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(mockUsp),
        uspDeviceServiceProvider.overrideWithValue(mockDeviceSvc),
        devicesDataProvider.overrideWith(
          () => _TestDevicesDataNotifier(devicesData ?? const DevicesData()),
        ),
      ],
    );
  }

  group('EthernetDataNotifier', () {
    test('build fetches interfaces and bridge port map', () async {
      final container = createContainer();
      await container.read(ethernetDataProvider.future);

      // Verify get() was called for both ethernet and bridge
      verify(() => mockUsp.get(any())).called(2);
      // Verify buildEthernetPortUIModels was called
      verify(() => mockDeviceSvc.buildEthernetPortUIModels(
            ethernetInterfaces: any(named: 'ethernetInterfaces'),
            deviceModels: any(named: 'deviceModels'),
            bridgePortMap: any(named: 'bridgePortMap'),
          )).called(1);
      container.dispose();
    });

    test('build throws when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(null),
          uspDeviceServiceProvider.overrideWithValue(mockDeviceSvc),
          devicesDataProvider.overrideWith(
            () => _TestDevicesDataNotifier(const DevicesData()),
          ),
        ],
      );

      expect(
        container.read(ethernetDataProvider.future),
        throwsA(isA<StateError>()),
      );
      container.dispose();
    });

    test('bridge port map fetch failure returns empty map', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async {
        final paths = _.positionalArguments[0] as List;
        if (paths.any((p) => p.toString().contains('Bridging'))) {
          throw Exception('bridge not supported');
        }
        return ethernetResponse;
      });

      final container = createContainer();
      await container.read(ethernetDataProvider.future);

      // Should still succeed with empty bridge map
      verify(() => mockDeviceSvc.buildEthernetPortUIModels(
            ethernetInterfaces: any(named: 'ethernetInterfaces'),
            deviceModels: any(named: 'deviceModels'),
            bridgePortMap: any(named: 'bridgePortMap'),
          )).called(1);
      container.dispose();
    });

    test('devices data change triggers rebuild of port models', () async {
      final samplePort = EthernetPortUIModel(
        name: 'eth1',
        label: 'LAN 1',
        isWan: false,
        isUp: true,
        instancePath: 'Device.Ethernet.Interface.1.',
        currentBitRate: 1000,
      );

      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(mockUsp),
          uspDeviceServiceProvider.overrideWithValue(mockDeviceSvc),
          devicesDataProvider.overrideWith(() => _MutableDevicesDataNotifier()),
        ],
      );

      // Initial build
      await container.read(ethernetDataProvider.future);
      verify(() => mockDeviceSvc.buildEthernetPortUIModels(
            ethernetInterfaces: any(named: 'ethernetInterfaces'),
            deviceModels: any(named: 'deviceModels'),
            bridgePortMap: any(named: 'bridgePortMap'),
          )).called(1);
      clearInteractions(mockDeviceSvc);

      // Return a port model on the rebuild call
      when(() => mockDeviceSvc.buildEthernetPortUIModels(
            ethernetInterfaces: any(named: 'ethernetInterfaces'),
            deviceModels: any(named: 'deviceModels'),
            bridgePortMap: any(named: 'bridgePortMap'),
          )).thenReturn([samplePort]);

      // Emit new devices data — triggers the ref.listen(devicesDataProvider) callback
      final devNotifier = container.read(devicesDataProvider.notifier)
          as _MutableDevicesDataNotifier;
      devNotifier.emit(DevicesData(
        deviceModels: [
          DeviceUIModel(
            mac: 'AA:BB:CC:DD:EE:01',
            ip: '192.168.1.101',
            hostName: 'NewDevice',
            isActive: true,
            isWifi: false,
          ),
        ],
      ));
      await Future.delayed(Duration.zero);

      // Verify listener triggered rebuild
      verify(() => mockDeviceSvc.buildEthernetPortUIModels(
            ethernetInterfaces: any(named: 'ethernetInterfaces'),
            deviceModels: any(named: 'deviceModels'),
            bridgePortMap: any(named: 'bridgePortMap'),
          )).called(1);

      // Verify state was updated with new port models
      final data = container.read(ethernetDataProvider).valueOrNull;
      expect(data?.ethernetPortModels, hasLength(1));
      expect(data?.ethernetPortModels.first.name, 'eth1');

      container.dispose();
    });

    test('EthernetData copyWith works', () {
      const data = EthernetData();
      expect(data.ethernetPortModels, isEmpty);

      // With explicit value
      final updated = data.copyWith(ethernetPortModels: []);
      expect(updated.ethernetPortModels, isEmpty);

      // Without parameter — falls back to this.ethernetPortModels
      final same = data.copyWith();
      expect(same.ethernetPortModels, isEmpty);
      expect(same, equals(data));
    });

    test('EthernetData props uses length for equality', () {
      const a = EthernetData();
      const b = EthernetData();
      expect(a, equals(b));
      expect(a.props, [0]);

      final c = EthernetData(ethernetPortModels: [
        EthernetPortUIModel(
          name: 'eth1',
          label: 'LAN',
          isWan: false,
          isUp: true,
          instancePath: 'p',
          currentBitRate: 100,
        ),
      ]);
      expect(a, isNot(equals(c)));
      expect(c.props, [1]);
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

/// Mutable DevicesData notifier for testing listener rebuild paths.
class _MutableDevicesDataNotifier extends DevicesDataNotifier {
  @override
  Future<DevicesData> build() async => const DevicesData();

  void emit(DevicesData data) {
    state = AsyncData(data);
  }
}
