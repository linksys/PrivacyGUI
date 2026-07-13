import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------

  final wifiDevice = ClientDevice(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(signalStrength: -55),
  );

  final ethernetDevice = ClientDevice(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'Desktop',
    isActive: true,
    connectionType: ConnectionType.wired,
  );

  final reservation = DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    enable: true,
  );

  final devicesData = DevicesData(
    meshNetwork: MeshNetwork(
      master: MasterNode(
        deviceId: 'GATEWAY',
        model: 'TestRouter',
        connectedClients: [wifiDevice, ethernetDevice],
      ),
    ),
  );

  final dhcpData = DhcpData(
    clientModels: const [],
    reservationModels: [reservation],
  );

  ProviderContainer createContainer({
    DevicesData? devices,
    DhcpData? dhcp,
  }) {
    return ProviderContainer(
      overrides: [
        devicesDataProvider.overrideWith(() => _FakeDevicesNotifier(devices)),
        dhcpDataProvider.overrideWith(() => _FakeDhcpNotifier(dhcp)),
      ],
    );
  }

  group('DeviceDetailProvider', () {
    // -----------------------------------------------------------------------
    // Success cases
    // -----------------------------------------------------------------------

    test('returns device with reservation', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: dhcpData,
      );
      addTearDown(container.dispose);

      // Wait for async providers to complete
      await container.read(devicesDataProvider.future);
      await container.read(dhcpDataProvider.future);

      final result =
          container.read(uspDeviceDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(result.device, isNotNull);
      expect(result.device!.mac, 'AA:BB:CC:DD:EE:01');
      expect(result.reservation, isNotNull);
      expect(result.reservation!.mac, 'AA:BB:CC:DD:EE:01');
    });

    test('returns device without reservation', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: dhcpData,
      );
      addTearDown(container.dispose);

      // Wait for async providers to complete
      await container.read(devicesDataProvider.future);
      await container.read(dhcpDataProvider.future);

      final result =
          container.read(uspDeviceDetailProvider('AA:BB:CC:DD:EE:02'));

      expect(result.device, isNotNull);
      expect(result.device!.mac, 'AA:BB:CC:DD:EE:02');
      expect(result.reservation, isNull);
    });

    // -----------------------------------------------------------------------
    // Not found cases
    // -----------------------------------------------------------------------

    test('returns empty when device not found', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: dhcpData,
      );
      addTearDown(container.dispose);

      // Wait for async providers to complete
      await container.read(devicesDataProvider.future);
      await container.read(dhcpDataProvider.future);

      final result =
          container.read(uspDeviceDetailProvider('NOT:FO:UN:DD:EV:IC'));

      expect(result, DeviceDetailState.empty());
    });

    // -----------------------------------------------------------------------
    // Case-insensitive MAC lookup
    // -----------------------------------------------------------------------

    test('finds device with lowercase MAC', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: dhcpData,
      );
      addTearDown(container.dispose);

      // Wait for async providers to complete
      await container.read(devicesDataProvider.future);
      await container.read(dhcpDataProvider.future);

      final result =
          container.read(uspDeviceDetailProvider('aa:bb:cc:dd:ee:01'));

      expect(result.device, isNotNull);
      expect(result.device!.mac.toUpperCase(), 'AA:BB:CC:DD:EE:01');
    });

    test('finds device with mixed-case MAC', () async {
      final container = createContainer(
        devices: devicesData,
        dhcp: dhcpData,
      );
      addTearDown(container.dispose);

      // Wait for async providers to complete
      await container.read(devicesDataProvider.future);
      await container.read(dhcpDataProvider.future);

      final result =
          container.read(uspDeviceDetailProvider('Aa:Bb:Cc:Dd:Ee:01'));

      expect(result.device, isNotNull);
      expect(result.device!.mac.toUpperCase(), 'AA:BB:CC:DD:EE:01');
    });
  });
}

// ---------------------------------------------------------------------------
// Fake notifiers
// ---------------------------------------------------------------------------

class _FakeDevicesNotifier extends AsyncNotifier<DevicesData>
    implements DevicesDataNotifier {
  final DevicesData? _data;
  _FakeDevicesNotifier(this._data);

  @override
  Future<DevicesData> build() async =>
      _data ??
      DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'TestRouter'),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDhcpNotifier extends AsyncNotifier<DhcpData>
    implements DhcpDataNotifier {
  final DhcpData? _data;
  _FakeDhcpNotifier(this._data);

  @override
  Future<DhcpData> build() async =>
      _data ?? const DhcpData(clientModels: [], reservationModels: []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
