import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';

import '../../../mocks/test_data/devices_test_data.dart';

void main() {
  group('MeshNetwork', () {
    // =========================================================================
    // Accessors
    // =========================================================================

    group('allNodes', () {
      test('returns master only when no slaves', () {
        final network = DevicesTestData.createSingleNodeNetwork();

        expect(network.allNodes, hasLength(1));
        expect(network.allNodes.first, isA<MasterNode>());
      });

      test('returns master + slaves in mesh network', () {
        final network = DevicesTestData.createMultiSlaveMeshNetwork();

        expect(network.allNodes, hasLength(3));
        expect(network.allNodes[0], isA<MasterNode>());
        expect(network.allNodes[1], isA<SlaveNode>());
        expect(network.allNodes[2], isA<SlaveNode>());
      });
    });

    group('allClients', () {
      test('returns master clients in single-node network', () {
        final network = DevicesTestData.createSingleNodeNetwork();

        expect(network.allClients, hasLength(2));
      });

      test('combines clients from all nodes', () {
        final network = DevicesTestData.createMeshNetwork();

        // 1 client on master + 1 client on slave
        expect(network.allClients, hasLength(2));
      });

      test('includes unassigned clients', () {
        final network = DevicesTestData.createNetworkWithUnassignedClients();

        expect(network.allClients, hasLength(2));
        expect(network.unassignedClients, hasLength(2));
      });
    });

    group('client counts', () {
      test('totalClientCount returns correct count', () {
        final network = DevicesTestData.createSingleNodeNetwork();
        expect(network.totalClientCount, 2);
      });

      test('onlineClientCount filters active clients only', () {
        final mixedClients = [
          DevicesTestData.createWifiClient(isActive: true),
          DevicesTestData.createWiredClient(isActive: false),
          DevicesTestData.createOfflineClient(),
        ];
        final network = DevicesTestData.createSingleNodeNetwork(
          masterClients: mixedClients,
        );

        expect(network.onlineClientCount, 1);
        expect(network.offlineClientCount, 2);
      });

      test('wifiClientCount counts online WiFi clients', () {
        final clients = [
          DevicesTestData.createWifiClient(isActive: true),
          DevicesTestData.createWifiClient(
              mac: '11:22:33:44:55:99', isActive: false),
          DevicesTestData.createWiredClient(isActive: true),
        ];
        final network = DevicesTestData.createSingleNodeNetwork(
          masterClients: clients,
        );

        expect(network.wifiClientCount, 1);
        expect(network.wiredClientCount, 1);
      });
    });

    group('hasMesh', () {
      test('returns false for single-node network', () {
        final network = DevicesTestData.createSingleNodeNetwork();
        expect(network.hasMesh, isFalse);
      });

      test('returns true when slaves exist', () {
        final network = DevicesTestData.createMeshNetwork();
        expect(network.hasMesh, isTrue);
      });
    });

    group('nodeCount', () {
      test('returns 1 for single-node network', () {
        final network = DevicesTestData.createSingleNodeNetwork();
        expect(network.nodeCount, 1);
      });

      test('returns correct count for mesh network', () {
        final network = DevicesTestData.createMultiSlaveMeshNetwork();
        expect(network.nodeCount, 3);
      });
    });

    // =========================================================================
    // Lookups
    // =========================================================================

    group('findNode', () {
      test('finds master by deviceId', () {
        final network = DevicesTestData.createMeshNetwork();

        final found = network.findNode(DevicesTestData.masterMac);

        expect(found, isNotNull);
        expect(found, isA<MasterNode>());
      });

      test('finds slave by deviceId', () {
        final network = DevicesTestData.createMeshNetwork();

        final found = network.findNode(DevicesTestData.slaveMac1);

        expect(found, isNotNull);
        expect(found, isA<SlaveNode>());
      });

      test('finds node by dataElementsId', () {
        final slave = DevicesTestData.createWifiSlave(
          deviceId: DevicesTestData.slaveMac1,
          dataElementsId: 'DE:AA:BB:CC:DD:EE',
        );
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [slave],
        );

        final found = network.findNode('DE:AA:BB:CC:DD:EE');

        expect(found, isNotNull);
        expect(found?.deviceId, DevicesTestData.slaveMac1);
      });

      test('is case-insensitive', () {
        final network = DevicesTestData.createMeshNetwork();

        final lowercase =
            network.findNode(DevicesTestData.masterMac.toLowerCase());
        final uppercase =
            network.findNode(DevicesTestData.masterMac.toUpperCase());

        expect(lowercase, isNotNull);
        expect(uppercase, isNotNull);
        expect(lowercase, equals(uppercase));
      });

      test('returns null when not found', () {
        final network = DevicesTestData.createSingleNodeNetwork();

        expect(network.findNode('XX:XX:XX:XX:XX:XX'), isNull);
      });
    });

    group('findClient', () {
      test('finds client by MAC address', () {
        final network = DevicesTestData.createSingleNodeNetwork();

        final found = network.findClient(DevicesTestData.clientMac1);

        expect(found, isNotNull);
        expect(found?.mac, DevicesTestData.clientMac1);
      });

      test('finds client by additional interface MAC', () {
        final multiClient = DevicesTestData.createMultiInterfaceClient(
          mac: DevicesTestData.clientMac1,
          additionalInterfaces: [
            DevicesTestData.createWiredInterface(mac: 'FF:FF:FF:FF:FF:01'),
          ],
        );
        final network = DevicesTestData.createSingleNodeNetwork(
          masterClients: [multiClient],
        );

        final found = network.findClient('FF:FF:FF:FF:FF:01');

        expect(found, isNotNull);
        expect(found?.mac, DevicesTestData.clientMac1);
      });

      test('is case-insensitive', () {
        final network = DevicesTestData.createSingleNodeNetwork();

        final lowercase =
            network.findClient(DevicesTestData.clientMac1.toLowerCase());
        final uppercase =
            network.findClient(DevicesTestData.clientMac1.toUpperCase());

        expect(lowercase, isNotNull);
        expect(uppercase, isNotNull);
      });

      test('returns null when not found', () {
        final network = DevicesTestData.createSingleNodeNetwork();

        expect(network.findClient('XX:XX:XX:XX:XX:XX'), isNull);
      });
    });

    group('findParentNode', () {
      test('returns master when parentNodeId is null', () {
        final client = DevicesTestData.createWifiClient(parentNodeId: null);
        final network = DevicesTestData.createSingleNodeNetwork(
          masterClients: [client],
        );

        final parent = network.findParentNode(client);

        expect(parent, isA<MasterNode>());
      });

      test('returns correct slave node when parentNodeId is set', () {
        final client = DevicesTestData.createSlaveConnectedClient(
          parentNodeId: DevicesTestData.slaveMac1,
        );
        final network = DevicesTestData.createMeshNetwork(
          slaveClients: [client],
        );

        final parent = network.findParentNode(client);

        expect(parent, isA<SlaveNode>());
        expect(parent?.deviceId, DevicesTestData.slaveMac1);
      });

      test('returns null when parentNodeId not found', () {
        final client = DevicesTestData.createWifiClient(
          parentNodeId: 'XX:XX:XX:XX:XX:XX',
        );
        final network = DevicesTestData.createSingleNodeNetwork(
          masterClients: [client],
        );

        final parent = network.findParentNode(client);

        expect(parent, isNull);
      });

      // Issue #1439: the null-parentNodeId shortcut above must not answer for
      // an unattributed client. Its parent could not be resolved, so returning
      // the master would be the same false attribution the builder now avoids.
      test('returns null for an unattributed client, not the master', () {
        final client = DevicesTestData.createWifiClient(
          parentNodeId: null,
        ).copyWith(isUnattributed: true);
        final network = DevicesTestData.createSingleNodeNetwork(
          masterClients: [client],
        );

        expect(network.findParentNode(client), isNull);
      });
    });

    group('clientsForNode', () {
      test('returns clients for master node', () {
        final network = DevicesTestData.createSingleNodeNetwork();

        final clients = network.clientsForNode(DevicesTestData.masterMac);

        expect(clients, hasLength(2));
      });

      test('returns clients for slave node', () {
        final network = DevicesTestData.createMeshNetwork();

        final clients = network.clientsForNode(DevicesTestData.slaveMac1);

        expect(clients, hasLength(1));
      });

      test('returns empty list when node not found', () {
        final network = DevicesTestData.createSingleNodeNetwork();

        final clients = network.clientsForNode('XX:XX:XX:XX:XX:XX');

        expect(clients, isEmpty);
      });
    });

    group('clientsByNode', () {
      test('groups clients by node ID', () {
        final network = DevicesTestData.createMeshNetwork();

        final byNode = network.clientsByNode;

        expect(byNode.containsKey(DevicesTestData.masterMac), isTrue);
        expect(byNode.containsKey(DevicesTestData.slaveMac1), isTrue);
      });

      test('includes _unassigned key when unassigned clients exist', () {
        final network = DevicesTestData.createNetworkWithUnassignedClients();

        final byNode = network.clientsByNode;

        expect(byNode.containsKey('_unassigned'), isTrue);
        expect(byNode['_unassigned'], hasLength(2));
      });

      test('does not include _unassigned key when no unassigned clients', () {
        final network = DevicesTestData.createSingleNodeNetwork();

        final byNode = network.clientsByNode;

        expect(byNode.containsKey('_unassigned'), isFalse);
      });
    });

    // =========================================================================
    // Equatable
    // =========================================================================

    group('Equatable', () {
      test('equal networks are equal', () {
        final network1 = DevicesTestData.createSingleNodeNetwork();
        final network2 = DevicesTestData.createSingleNodeNetwork();

        expect(network1, equals(network2));
      });

      test('different masters are not equal', () {
        final network1 = DevicesTestData.createSingleNodeNetwork(
          master: DevicesTestData.createMaster(deviceId: 'AA:AA:AA:AA:AA:01'),
        );
        final network2 = DevicesTestData.createSingleNodeNetwork(
          master: DevicesTestData.createMaster(deviceId: 'AA:AA:AA:AA:AA:02'),
        );

        expect(network1, isNot(equals(network2)));
      });

      test('different slaves are not equal', () {
        final network1 = DevicesTestData.createMeshNetwork();
        final network2 = DevicesTestData.createMultiSlaveMeshNetwork();

        expect(network1, isNot(equals(network2)));
      });

      test('different unassigned clients are not equal', () {
        final network1 = DevicesTestData.createNetworkWithUnassignedClients(
          unassignedClients: [DevicesTestData.createWifiClient()],
        );
        final network2 = DevicesTestData.createNetworkWithUnassignedClients(
          unassignedClients: [
            DevicesTestData.createWifiClient(),
            DevicesTestData.createWiredClient(),
          ],
        );

        expect(network1, isNot(equals(network2)));
      });
    });

    // =========================================================================
    // copyWith
    // =========================================================================

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final original = DevicesTestData.createMeshNetwork();
        final copied = original.copyWith();

        expect(copied, equals(original));
      });

      test('updates master', () {
        final original = DevicesTestData.createMeshNetwork();
        final newMaster = DevicesTestData.createMaster(deviceId: 'NEW:MAC');
        final copied = original.copyWith(master: newMaster);

        expect(copied.master.deviceId, 'NEW:MAC');
        expect(copied.slaves, equals(original.slaves));
      });

      test('updates slaves', () {
        final original = DevicesTestData.createMeshNetwork();
        final copied = original.copyWith(slaves: []);

        expect(copied.slaves, isEmpty);
        expect(copied.master, equals(original.master));
      });

      test('updates unassignedClients', () {
        final original = DevicesTestData.createSingleNodeNetwork();
        final unassigned = [DevicesTestData.createWifiClient()];
        final copied = original.copyWith(unassignedClients: unassigned);

        expect(copied.unassignedClients, hasLength(1));
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('edge cases', () {
      test('empty network works correctly', () {
        final network = DevicesTestData.createEmptyNetwork();

        expect(network.allClients, isEmpty);
        expect(network.totalClientCount, 0);
        expect(network.onlineClientCount, 0);
        expect(network.offlineClientCount, 0);
        expect(network.wifiClientCount, 0);
        expect(network.wiredClientCount, 0);
        expect(network.hasMesh, isFalse);
        expect(network.nodeCount, 1);
      });

      test('all clients offline returns zero online counts', () {
        final offlineClients = [
          DevicesTestData.createOfflineClient(mac: '11:11:11:11:11:01'),
          DevicesTestData.createOfflineClient(mac: '11:11:11:11:11:02'),
        ];
        final network = DevicesTestData.createSingleNodeNetwork(
          masterClients: offlineClients,
        );

        expect(network.totalClientCount, 2);
        expect(network.onlineClientCount, 0);
        expect(network.offlineClientCount, 2);
      });
    });

    // =========================================================================
    // nodesBehind (#876)
    // =========================================================================

    group('nodesBehind', () {
      const a = 'AA:BB:CC:DD:EE:0A';
      const b = 'AA:BB:CC:DD:EE:0B';

      SlaveNode slave(String mac, {required String? parent}) =>
          DevicesTestData.createWifiSlave(
            deviceId: mac,
            dataElementsId: mac,
            backhaul: BackhaulInfo(linkType: 'Wi-Fi', parentNodeId: parent),
          );

      test('a chain lists the far node before the near one', () {
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            slave(a, parent: DevicesTestData.masterMac),
            slave(b, parent: a),
          ],
        );

        final behind = network.nodesBehind(a);

        expect(behind.nodes.map((n) => n.deviceId), [b, a]);
        expect(behind.mayMissNodes, isFalse);
      });

      // prplMesh leaves BackhaulDeviceID empty for a node cabled behind a
      // satellite and for one still joining (FWDEV#202 review), so such a node
      // may be behind the target without the chain saying so.
      test('a slave with no reported parent may be behind the target', () {
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            slave(a, parent: DevicesTestData.masterMac),
            slave(b, parent: null),
          ],
        );

        final behind = network.nodesBehind(a);

        expect(behind.nodes.map((n) => n.deviceId), [a]);
        expect(behind.mayMissNodes, isTrue);
      });

      // backhaul_parent_graph.dart breaks the same shape before the topology
      // renders it; a walk here has to survive it on its own.
      test('a parent cycle ends instead of looping', () {
        const c = 'AA:BB:CC:DD:EE:0C';
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            slave(a, parent: DevicesTestData.masterMac),
            slave(b, parent: c),
            slave(c, parent: b),
          ],
        );

        final behind = network.nodesBehind(a);

        expect(behind.nodes.map((n) => n.deviceId), [a]);
        expect(behind.mayMissNodes, isTrue);
      });

      test('a sibling on the master is not behind the target', () {
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            slave(a, parent: DevicesTestData.masterMac),
            slave(b, parent: DevicesTestData.masterMac),
          ],
        );

        final behind = network.nodesBehind(a);

        expect(behind.nodes.map((n) => n.deviceId), [a]);
        expect(behind.mayMissNodes, isFalse);
      });

      test('the parent is matched whatever its MAC case', () {
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            slave(a, parent: DevicesTestData.masterMac.toLowerCase()),
            slave(b, parent: a.toLowerCase()),
          ],
        );

        final behind = network.nodesBehind(a);

        expect(behind.nodes.map((n) => n.deviceId), [b, a]);
        expect(behind.mayMissNodes, isFalse);
      });

      test('the master and an unknown id have nothing behind them', () {
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [slave(a, parent: DevicesTestData.masterMac)],
        );

        expect(network.nodesBehind(DevicesTestData.masterMac).nodes, isEmpty);
        expect(network.nodesBehind('AA:BB:CC:DD:EE:FF').nodes, isEmpty);
      });
    });

    // =========================================================================
    // nodeActionPlan (#876)
    // =========================================================================

    group('nodeActionPlan', () {
      const a = 'AA:BB:CC:DD:EE:0A';
      const b = 'AA:BB:CC:DD:EE:0B';
      const c = 'AA:BB:CC:DD:EE:0C';

      SlaveNode slave(String mac, String parent, Set<NodeAction> actions) =>
          DevicesTestData.createWifiSlave(
            deviceId: mac,
            dataElementsId: mac,
            backhaul: BackhaulInfo(linkType: 'Wi-Fi', parentNodeId: parent),
          ).copyWith(actions: actions);

      const both = {NodeAction.reboot, NodeAction.factoryReset};

      // A node behind the target that does not run the command would be sent
      // it first, refuse with 7022 and stop the run before the target got it.
      // It goes down with the target anyway, so it is named and not sent.
      test('a node behind the target that cannot run the action is skipped',
          () {
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            slave(a, DevicesTestData.masterMac, both),
            slave(b, a, const {}),
            slave(c, b, both),
          ],
        );

        final plan = network.nodeActionPlan(NodeAction.reboot, a);

        expect(plan.targets.map((n) => n.deviceId), [c, a]);
        expect(plan.skipped.map((n) => n.deviceId), [b]);
        expect(plan.mayMissNodes, isFalse);
      });

      test('support is per action', () {
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            slave(a, DevicesTestData.masterMac, both),
            slave(b, a, const {NodeAction.reboot}),
          ],
        );

        expect(
          network
              .nodeActionPlan(NodeAction.factoryReset, a)
              .targets
              .map((n) => n.deviceId),
          [a],
        );
        expect(
          network
              .nodeActionPlan(NodeAction.reboot, a)
              .targets
              .map((n) => n.deviceId),
          [b, a],
        );
      });

      test('a target that cannot run the action plans nothing', () {
        final network = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [slave(a, DevicesTestData.masterMac, const {})],
        );

        expect(network.nodeActionPlan(NodeAction.reboot, a).targets, isEmpty);
      });
    });
  });
}
