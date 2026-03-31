import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------

  const masterNode = NodeUIModel(
    deviceId: 'AA:BB:CC:DD:EE:01',
    model: 'MR7500',
    isMaster: true,
    connectedDeviceCount: 2,
  );

  const extenderNode = NodeUIModel(
    deviceId: 'AA:BB:CC:DD:EE:02',
    model: 'MX5500',
    isMaster: false,
    connectedDeviceCount: 1,
  );

  const device1 = DeviceUIModel(
    mac: '11:22:33:44:55:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    isWifi: true,
    parentNodeId: 'AA:BB:CC:DD:EE:01',
  );

  const device2 = DeviceUIModel(
    mac: '11:22:33:44:55:02',
    ip: '192.168.1.101',
    hostName: 'MacBook',
    isActive: true,
    isWifi: false,
    parentNodeId: 'AA:BB:CC:DD:EE:01',
  );

  const device3 = DeviceUIModel(
    mac: '11:22:33:44:55:03',
    ip: '192.168.1.102',
    hostName: 'iPad',
    isActive: false,
    isWifi: true,
    parentNodeId: 'AA:BB:CC:DD:EE:02',
  );

  final meshData = DevicesData(
    nodeModels: const [masterNode, extenderNode],
    deviceModels: const [device1, device2, device3],
    meshTopology: const MeshTopologyInfo(
      nodes: [
        MeshNodeInfo(
          instancePath: 'Device.1.',
          deviceId: 'AA:BB:CC:DD:EE:01',
          model: 'MR7500',
        ),
        MeshNodeInfo(
          instancePath: 'Device.2.',
          deviceId: 'AA:BB:CC:DD:EE:02',
          model: 'MX5500',
        ),
      ],
      clientToNodeMap: {},
    ),
  );

  ProviderContainer createContainer({DevicesData? data}) {
    return ProviderContainer(
      overrides: [
        devicesDataProvider.overrideWith(() => _FakeDevicesNotifier(data)),
      ],
    );
  }

  group('UspNodeDetailProvider', () {
    // -----------------------------------------------------------------------
    // Basic lookup
    // -----------------------------------------------------------------------

    test('returns node and connected devices for master node', () async {
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(detail.node, masterNode);
      expect(detail.connectedDevices, hasLength(2));
      expect(detail.connectedDevices, contains(device1));
      expect(detail.connectedDevices, contains(device2));
      container.dispose();
    });

    test('returns node and connected devices for extender node', () async {
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:02'));

      expect(detail.node, extenderNode);
      expect(detail.connectedDevices, hasLength(1));
      expect(detail.connectedDevices.first.hostName, 'iPad');
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Case-insensitive matching
    // -----------------------------------------------------------------------

    test('deviceId lookup is case-insensitive', () async {
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('aa:bb:cc:dd:ee:01'));

      expect(detail.node, masterNode);
      expect(detail.connectedDevices, hasLength(2));
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Gateway fallback (non-mesh)
    // -----------------------------------------------------------------------

    test('GATEWAY lookup treats null parentNodeId as connected to gateway',
        () async {
      const nonMeshData = DevicesData(
        nodeModels: [
          NodeUIModel(
            deviceId: 'GATEWAY',
            model: 'MR7500',
            isMaster: true,
          ),
        ],
        deviceModels: [
          DeviceUIModel(
            mac: '11:22:33:44:55:01',
            ip: '192.168.1.100',
            hostName: 'iPhone',
            isActive: true,
            isWifi: true,
            parentNodeId: null, // non-mesh: no parent
          ),
          DeviceUIModel(
            mac: '11:22:33:44:55:02',
            ip: '192.168.1.101',
            hostName: 'MacBook',
            isActive: true,
            isWifi: false,
            parentNodeId: null,
          ),
        ],
      );

      final container = createContainer(data: nonMeshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('GATEWAY'));

      expect(detail.connectedDevices, hasLength(2));
      container.dispose();
    });

    test('GATEWAY lookup is case-insensitive', () async {
      const nonMeshData = DevicesData(
        nodeModels: [
          NodeUIModel(deviceId: 'GATEWAY', model: 'MR7500', isMaster: true),
        ],
        deviceModels: [
          DeviceUIModel(
            mac: '11:22:33:44:55:01',
            ip: '192.168.1.100',
            hostName: 'Phone',
            isActive: true,
            isWifi: true,
            parentNodeId: null,
          ),
        ],
      );

      final container = createContainer(data: nonMeshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('gateway'));

      expect(detail.connectedDevices, hasLength(1));
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // activeDeviceCount
    // -----------------------------------------------------------------------

    test('activeDeviceCount counts only active devices', () async {
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      // Master has device1 (active) + device2 (active) = 2
      final masterDetail =
          container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:01'));
      expect(masterDetail.activeDeviceCount, 2);

      // Extender has device3 (inactive) = 0
      final extenderDetail =
          container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:02'));
      expect(extenderDetail.activeDeviceCount, 0);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Edge cases
    // -----------------------------------------------------------------------

    test('returns empty state when devices data is null', () {
      final container = createContainer(data: null);

      final detail = container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(detail.node, isNull);
      expect(detail.connectedDevices, isEmpty);
      container.dispose();
    });

    test('returns null node for unknown deviceId', () async {
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('UNKNOWN'));

      expect(detail.node, isNull);
      expect(detail.connectedDevices, isEmpty);
      container.dispose();
    });

    test('node with no connected devices returns empty list', () async {
      const data = DevicesData(
        nodeModels: [masterNode],
        deviceModels: [],
      );

      final container = createContainer(data: data);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(detail.node, masterNode);
      expect(detail.connectedDevices, isEmpty);
      expect(detail.activeDeviceCount, 0);
      container.dispose();
    });
  });
}

// ---------------------------------------------------------------------------
// Fake DevicesDataNotifier
// ---------------------------------------------------------------------------

class _FakeDevicesNotifier extends AsyncNotifier<DevicesData>
    implements DevicesDataNotifier {
  final DevicesData? _data;
  _FakeDevicesNotifier(this._data);

  @override
  Future<DevicesData> build() async => _data ?? const DevicesData();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
