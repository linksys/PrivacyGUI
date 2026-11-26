import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------

  final masterNode = MasterNode(
    deviceId: 'AA:BB:CC:DD:EE:01',
    model: 'MR7500',
    connectedClients: [],
  );

  final extenderNode = SlaveNode(
    deviceId: 'AA:BB:CC:DD:EE:02',
    model: 'MX5500',
    connectedClients: [],
    backhaul: const BackhaulInfo(linkType: 'Wi-Fi'),
  );

  final device1 = ClientDevice(
    mac: '11:22:33:44:55:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    connectionType: ConnectionType.wifi,
    parentNodeId: 'AA:BB:CC:DD:EE:01',
  );

  final device2 = ClientDevice(
    mac: '11:22:33:44:55:02',
    ip: '192.168.1.101',
    hostName: 'MacBook',
    isActive: true,
    connectionType: ConnectionType.wired,
    parentNodeId: 'AA:BB:CC:DD:EE:01',
  );

  final device3 = ClientDevice(
    mac: '11:22:33:44:55:03',
    ip: '192.168.1.102',
    hostName: 'iPad',
    isActive: false,
    connectionType: ConnectionType.wifi,
    parentNodeId: 'AA:BB:CC:DD:EE:02',
  );

  DevicesData createMeshData() {
    return DevicesData(
      meshNetwork: MeshNetwork(
        master: masterNode.copyWith(
          connectedClients: [device1, device2],
        ),
        slaves: [
          extenderNode.copyWith(
            connectedClients: [device3],
          ),
        ],
      ),
      meshTopology: const MeshTopologyInfo(
        nodes: [],
        clientToNodeMap: {},
      ),
    );
  }

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
      final meshData = createMeshData();
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(detail.node, isNotNull);
      expect(detail.node!.deviceId, 'AA:BB:CC:DD:EE:01');
      expect(detail.connectedClients, hasLength(2));
      expect(detail.connectedClients.any((d) => d.mac == device1.mac), isTrue);
      expect(detail.connectedClients.any((d) => d.mac == device2.mac), isTrue);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Parent node
    // -----------------------------------------------------------------------

    group('parent node', () {
      SlaveNode childOf(String parentId) => SlaveNode(
            deviceId: 'AA:BB:CC:DD:EE:03',
            dataElementsId: 'AA:BB:CC:DD:EE:03',
            model: 'MX5500',
            backhaul: BackhaulInfo(linkType: 'Wi-Fi', parentNodeId: parentId),
          );

      DevicesData meshWith(SlaveNode parent) => DevicesData(
            meshNetwork: MeshNetwork(
              master: masterNode,
              slaves: [parent, childOf(parent.deviceId)],
            ),
          );

      test('resolves an online parent', () async {
        final parent =
            extenderNode.copyWith(dataElementsId: extenderNode.deviceId);
        final container = createContainer(data: meshWith(parent));
        await container.read(devicesDataProvider.future);

        final detail =
            container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:03'));

        expect(detail.parentNode?.deviceId, parent.deviceId);
        container.dispose();
      });

      // #1443: a node still naming an extender that went offline reports a
      // stale parent. The topology draws it under the gateway, so its page
      // does not claim a link to the offline node either.
      test('does not resolve an offline parent', () async {
        final container = createContainer(data: meshWith(extenderNode));
        await container.read(devicesDataProvider.future);
        expect(extenderNode.isOnline, isFalse);

        final detail =
            container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:03'));

        expect(detail.node, isNotNull);
        expect(detail.parentNode, isNull);
        container.dispose();
      });
    });

    test('returns node and connected devices for extender node', () async {
      final meshData = createMeshData();
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:02'));

      expect(detail.node, isNotNull);
      expect(detail.node!.deviceId, 'AA:BB:CC:DD:EE:02');
      expect(detail.connectedClients, hasLength(1));
      expect(detail.connectedClients.first.hostName, 'iPad');
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Case-insensitive matching
    // -----------------------------------------------------------------------

    test('deviceId lookup is case-insensitive', () async {
      final meshData = createMeshData();
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('aa:bb:cc:dd:ee:01'));

      expect(detail.node, isNotNull);
      expect(detail.connectedClients, hasLength(2));
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Gateway fallback (non-mesh)
    // -----------------------------------------------------------------------

    test('GATEWAY lookup treats null parentNodeId as connected to gateway',
        () async {
      final device1NoParent = ClientDevice(
        mac: '11:22:33:44:55:01',
        ip: '192.168.1.100',
        hostName: 'iPhone',
        isActive: true,
        connectionType: ConnectionType.wifi,
        parentNodeId: null, // non-mesh: no parent
      );
      final device2NoParent = ClientDevice(
        mac: '11:22:33:44:55:02',
        ip: '192.168.1.101',
        hostName: 'MacBook',
        isActive: true,
        connectionType: ConnectionType.wired,
        parentNodeId: null,
      );

      final nonMeshData = DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(
            deviceId: 'GATEWAY',
            model: 'MR7500',
            connectedClients: [device1NoParent, device2NoParent],
          ),
        ),
      );

      final container = createContainer(data: nonMeshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('GATEWAY'));

      expect(detail.connectedClients, hasLength(2));
      container.dispose();
    });

    test('GATEWAY lookup is case-insensitive', () async {
      final phone = ClientDevice(
        mac: '11:22:33:44:55:01',
        ip: '192.168.1.100',
        hostName: 'Phone',
        isActive: true,
        connectionType: ConnectionType.wifi,
        parentNodeId: null,
      );

      final nonMeshData = DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(
            deviceId: 'GATEWAY',
            model: 'MR7500',
            connectedClients: [phone],
          ),
        ),
      );

      final container = createContainer(data: nonMeshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('gateway'));

      expect(detail.connectedClients, hasLength(1));
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // activeClientCount
    // -----------------------------------------------------------------------

    test('activeClientCount counts only active devices', () async {
      final meshData = createMeshData();
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      // Master has device1 (active) + device2 (active) = 2
      final masterDetail =
          container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:01'));
      expect(masterDetail.activeClientCount, 2);

      // Extender has device3 (inactive) = 0
      final extenderDetail =
          container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:02'));
      expect(extenderDetail.activeClientCount, 0);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Edge cases
    // -----------------------------------------------------------------------

    test('returns empty state when devices data is null', () {
      final container = createContainer(data: null);

      final detail = container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(detail.node, isNull);
      expect(detail.connectedClients, isEmpty);
      container.dispose();
    });

    test('returns null node for unknown deviceId', () async {
      final meshData = createMeshData();
      final container = createContainer(data: meshData);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('UNKNOWN'));

      expect(detail.node, isNull);
      expect(detail.connectedClients, isEmpty);
      container.dispose();
    });

    test('node with no connected devices returns empty list', () async {
      final data = DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(
            deviceId: 'AA:BB:CC:DD:EE:01',
            model: 'MR7500',
            connectedClients: [],
          ),
        ),
      );

      final container = createContainer(data: data);
      await container.read(devicesDataProvider.future);

      final detail = container.read(uspNodeDetailProvider('AA:BB:CC:DD:EE:01'));

      expect(detail.node, isNotNull);
      expect(detail.connectedClients, isEmpty);
      expect(detail.activeClientCount, 0);
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
  Future<DevicesData> build() async {
    if (_data == null) {
      return DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'Unknown'),
        ),
      );
    }
    return _data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
