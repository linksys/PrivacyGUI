import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/devices_test_data.dart';

void main() {
  // OUI database for testing
  const testOuiDatabase = <String, String>{
    '112233': 'Test Vendor',
    'AABBCC': 'Linksys',
  };

  setUpAll(() {
    OuiLookup.initializeForTesting(testOuiDatabase);
  });

  tearDownAll(() {
    OuiLookup.reset();
  });

  const sysInfo = SystemInfoUIModel(
    manufacturer: 'Linksys',
    modelName: 'MR7500',
    hardwareVersion: '1.0',
    serialNumber: 'SN123456',
    softwareVersion: '1.0.16.26013014',
    uptime: 3600,
    totalMemory: 512000,
    freeMemory: 256000,
    cpuUsage: 25,
  );

  group('UspTopologyBuilder.buildFromMeshNetwork', () {
    // =========================================================================
    // Basic Topology Structure
    // =========================================================================

    group('basic structure', () {
      test('creates gateway node for single-node network', () {
        final meshNetwork = DevicesTestData.createSingleNodeNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        expect(topology.nodes, isNotEmpty);
        final gateway =
            topology.nodes.where((n) => n.type == MeshNodeType.gateway).first;
        expect(gateway.id, 'gateway');
        expect(gateway.status, MeshNodeStatus.online);
      });

      test('creates extender nodes for mesh network', () {
        final meshNetwork = DevicesTestData.createMeshNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extenders =
            topology.nodes.where((n) => n.type == MeshNodeType.extender);
        expect(extenders, hasLength(1));
        expect(extenders.first.id, startsWith('extender-'));
      });

      test('creates client nodes for connected devices', () {
        final meshNetwork = DevicesTestData.createSingleNodeNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final clients =
            topology.nodes.where((n) => n.type == MeshNodeType.client);
        expect(clients, hasLength(2)); // WiFi + Wired from test data
      });

      test('creates links between nodes', () {
        final meshNetwork = DevicesTestData.createMeshNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        expect(topology.links, isNotEmpty);
        // Should have link from gateway to extender (sourceId=parent, targetId=child)
        final extenderLink = topology.links
            .where((l) => l.targetId.startsWith('extender-'))
            .firstOrNull;
        expect(extenderLink, isNotNull);
        expect(extenderLink?.sourceId, 'gateway');
      });
    });

    // =========================================================================
    // Gateway Node Properties
    // =========================================================================

    group('gateway node', () {
      test('uses master displayName when available', () {
        final master = DevicesTestData.createMaster(
          friendlyName: 'My Router',
        );
        final meshNetwork = DevicesTestData.createSingleNodeNetwork(
          master: master,
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final gateway =
            topology.nodes.where((n) => n.type == MeshNodeType.gateway).first;
        expect(gateway.name, 'My Router');
      });

      test('falls back to systemInfo gatewayName', () {
        final master = DevicesTestData.createMaster(
          friendlyName: null,
          hostName: null,
        );
        final meshNetwork = DevicesTestData.createSingleNodeNetwork(
          master: master.copyWith(connectedClients: []),
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final gateway =
            topology.nodes.where((n) => n.type == MeshNodeType.gateway).first;
        // Falls back to model when displayName empty, or gatewayName from sysInfo
        expect(gateway.name, isNotEmpty);
      });

      test('includes metadata with deviceId and model', () {
        final meshNetwork = DevicesTestData.createSingleNodeNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final gateway =
            topology.nodes.where((n) => n.type == MeshNodeType.gateway).first;
        expect(gateway.metadata?['deviceId'], isNotNull);
        expect(gateway.metadata?['isMaster'], isTrue);
      });

      test('has level 1.0', () {
        final meshNetwork = DevicesTestData.createSingleNodeNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final gateway =
            topology.nodes.where((n) => n.type == MeshNodeType.gateway).first;
        expect(gateway.level, 1.0);
      });
    });

    // =========================================================================
    // Extender Node Properties
    // =========================================================================

    group('extender nodes', () {
      test('uses slave displayName', () {
        final slave = DevicesTestData.createWifiSlave(
          friendlyName: 'Living Room Extender',
        );
        final meshNetwork = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [slave],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extender =
            topology.nodes.where((n) => n.type == MeshNodeType.extender).first;
        expect(extender.name, 'Living Room Extender');
      });

      test('includes backhaul metadata', () {
        final meshNetwork = DevicesTestData.createMeshNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extender =
            topology.nodes.where((n) => n.type == MeshNodeType.extender).first;
        expect(extender.metadata?['backhaulLinkType'], isNotNull);
        expect(extender.metadata?['isMaster'], isFalse);
      });

      test('WiFi backhaul has level based on signal strength', () {
        final slave = DevicesTestData.createWifiSlave(
          backhaul: DevicesTestData.createWifiBackhaul(signalStrength: -50),
        );
        final meshNetwork = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [slave],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extender =
            topology.nodes.where((n) => n.type == MeshNodeType.extender).first;
        // Excellent signal (-50) should have high level (0.9)
        expect(extender.level, 0.9);
      });

      test('Ethernet backhaul level is full (wired)', () {
        final slave = DevicesTestData.createEthernetSlave();
        final meshNetwork = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [slave],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extender =
            topology.nodes.where((n) => n.type == MeshNodeType.extender).first;
        // Ethernet backhaul has no RSSI by design → full level, not a
        // fabricated 0.5 (#1430).
        expect(extender.level, 1.0);
      });

      test('parentId defaults to gateway', () {
        final meshNetwork = DevicesTestData.createMeshNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extender =
            topology.nodes.where((n) => n.type == MeshNodeType.extender).first;
        expect(extender.parentId, 'gateway');
      });
    });

    // =========================================================================
    // Client Node Properties
    // =========================================================================

    group('client nodes', () {
      test('creates client node with correct id format', () {
        final meshNetwork = DevicesTestData.createSingleNodeNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final clients =
            topology.nodes.where((n) => n.type == MeshNodeType.client);
        for (final client in clients) {
          expect(client.id, startsWith('client-'));
        }
      });

      test('WiFi client has level based on signal strength', () {
        final wifiClient = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createExcellentSignal(),
        );
        final meshNetwork = DevicesTestData.createSingleNodeNetwork(
          masterClients: [wifiClient],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final client =
            topology.nodes.where((n) => n.type == MeshNodeType.client).first;
        // Excellent signal should have high level (0.9)
        expect(client.level, 0.9);
      });

      test('wired client has level 1.0', () {
        final wiredClient = DevicesTestData.createWiredClient();
        final meshNetwork = DevicesTestData.createSingleNodeNetwork(
          masterClients: [wiredClient],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final client =
            topology.nodes.where((n) => n.type == MeshNodeType.client).first;
        expect(client.level, 1.0);
      });

      test('offline client has offline status', () {
        final offlineClient = DevicesTestData.createOfflineClient();
        final meshNetwork = DevicesTestData.createSingleNodeNetwork(
          masterClients: [offlineClient],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final client =
            topology.nodes.where((n) => n.type == MeshNodeType.client).first;
        expect(client.status, MeshNodeStatus.offline);
      });

      test('client parentId points to correct node', () {
        final slaveClient = DevicesTestData.createSlaveConnectedClient(
          parentNodeId: DevicesTestData.slaveMac1,
        );
        final meshNetwork = DevicesTestData.createMeshNetwork(
          slaveClients: [slaveClient],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final client = topology.nodes
            .where((n) =>
                n.type == MeshNodeType.client &&
                n.metadata?['mac'] == DevicesTestData.clientMac5)
            .firstOrNull;
        expect(client, isNotNull);
        expect(client?.parentId, startsWith('extender-'));
      });

      test('includes MAC in metadata', () {
        final meshNetwork = DevicesTestData.createSingleNodeNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final client =
            topology.nodes.where((n) => n.type == MeshNodeType.client).first;
        expect(client.metadata?['mac'], isNotNull);
      });
    });

    // =========================================================================
    // Link Properties
    // =========================================================================

    group('links', () {
      test('creates link from extender to gateway', () {
        final meshNetwork = DevicesTestData.createMeshNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        // Link direction: sourceId=parent, targetId=child
        // extender → gateway means link with sourceId='gateway', targetId='extender-*'
        final extenderLinks = topology.links
            .where((l) => l.targetId.startsWith('extender-'))
            .toList();
        expect(extenderLinks, isNotEmpty);
        expect(extenderLinks.first.sourceId, 'gateway');
      });

      test('creates links from clients to parent nodes', () {
        final meshNetwork = DevicesTestData.createSingleNodeNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        // Link direction: sourceId=parent, targetId=child
        final clientLinks = topology.links
            .where((l) => l.targetId.startsWith('client-'))
            .toList();
        expect(clientLinks, hasLength(2)); // 2 clients in test data
        for (final link in clientLinks) {
          expect(link.sourceId, 'gateway');
        }
      });

      test('WiFi link has quality based on signal', () {
        final wifiClient = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createExcellentSignal(),
        );
        final meshNetwork = DevicesTestData.createSingleNodeNetwork(
          masterClients: [wifiClient],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        // Link direction: sourceId=parent, targetId=child (client)
        final link =
            topology.links.where((l) => l.targetId.startsWith('client-')).first;
        expect(link.linkQuality, LinkQuality.excellent);
      });

      test('wired link has stable quality', () {
        final wiredClient = DevicesTestData.createWiredClient();
        final meshNetwork = DevicesTestData.createSingleNodeNetwork(
          masterClients: [wiredClient],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        // Link direction: sourceId=parent, targetId=child (client)
        final link =
            topology.links.where((l) => l.targetId.startsWith('client-')).first;
        expect(link.linkQuality, LinkQuality.stable);
      });
    });

    // =========================================================================
    // Multi-Slave Network
    // =========================================================================

    group('multi-slave network', () {
      test('creates all extender nodes', () {
        final meshNetwork = DevicesTestData.createMultiSlaveMeshNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extenders =
            topology.nodes.where((n) => n.type == MeshNodeType.extender);
        expect(extenders, hasLength(2));
      });

      test('clients connect to correct parent nodes', () {
        final meshNetwork = DevicesTestData.createMultiSlaveMeshNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        // Master client should connect to gateway
        final masterClients = topology.nodes
            .where(
                (n) => n.type == MeshNodeType.client && n.parentId == 'gateway')
            .toList();
        expect(masterClients, isNotEmpty);

        // Slave clients should connect to extenders
        final slaveClients = topology.nodes
            .where((n) =>
                n.type == MeshNodeType.client &&
                n.parentId != null &&
                n.parentId!.startsWith('extender-'))
            .toList();
        expect(slaveClients, hasLength(2)); // One per slave
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('edge cases', () {
      test('handles empty network (no clients)', () {
        final meshNetwork = DevicesTestData.createEmptyNetwork();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        expect(topology.nodes, hasLength(1)); // Gateway only
        final clients =
            topology.nodes.where((n) => n.type == MeshNodeType.client);
        expect(clients, isEmpty);
      });

      test('handles network with unassigned clients', () {
        final meshNetwork =
            DevicesTestData.createNetworkWithUnassignedClients();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final clients =
            topology.nodes.where((n) => n.type == MeshNodeType.client);
        expect(clients, hasLength(2));
        // Unassigned clients should connect to gateway
        for (final client in clients) {
          expect(client.parentId, 'gateway');
        }
      });

      test('handles client with poor signal', () {
        final poorSignalClient = DevicesTestData.createWifiClient(
          wifi: DevicesTestData.createPoorSignal(),
        );
        final meshNetwork = DevicesTestData.createSingleNodeNetwork(
          masterClients: [poorSignalClient],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final client =
            topology.nodes.where((n) => n.type == MeshNodeType.client).first;
        // Poor signal (-85) should have low level (0.1)
        expect(client.level, 0.1);

        // Link direction: sourceId=parent, targetId=child (client)
        final link =
            topology.links.where((l) => l.targetId.startsWith('client-')).first;
        // Poor signal maps to unknown quality
        expect(link.linkQuality, LinkQuality.unknown);
      });
    });

    // =========================================================================
    // E2E Semantics identifiers (Article XVI §16.3) — data-derived, stable,
    // decoupled from the human display label.
    // =========================================================================

    group('E2E node identifiers', () {
      test('master node carries the fixed, key-less identifier', () {
        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: DevicesTestData.createSingleNodeNetwork(),
          info: sysInfo,
        );

        final gateway =
            topology.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
        expect(gateway.identifier, 'topology-node-master');
      });

      test('slave / client identifiers embed the MAC suffix key', () {
        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: DevicesTestData.createMultiSlaveMeshNetwork(),
          info: sysInfo,
        );

        // slaveMac1 = AA:BB:CC:DD:EE:01, slaveMac2 = ...EE:02 → unique at 4.
        final slaves =
            topology.nodes.where((n) => n.type == MeshNodeType.extender);
        expect(
          slaves.map((n) => n.identifier),
          containsAll(
              <String>['topology-node-slave-EE01', 'topology-node-slave-EE02']),
        );

        // client MACs 11:22:33:44:55:0X → unique at 4.
        final clients =
            topology.nodes.where((n) => n.type == MeshNodeType.client);
        for (final client in clients) {
          expect(client.identifier, startsWith('topology-node-client-'));
        }
      });

      test('every node identifier is present and unique across the graph', () {
        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: DevicesTestData.createMultiSlaveMeshNetwork(),
          info: sysInfo,
        );

        final ids = topology.nodes.map((n) => n.identifier).toList();
        expect(ids.every((id) => id != null && id.isNotEmpty), isTrue);
        expect(ids.toSet().length, ids.length,
            reason: 'identifiers must be unique per node');
      });

      test('identifier is decoupled from the display label', () {
        // Two nodes with identical display names must still get distinct
        // identifiers (identity comes from the MAC, not the label).
        final network = DevicesTestData.createMeshNetwork(
          master: DevicesTestData.createMaster(hostName: 'Living Room'),
          slave: DevicesTestData.createWifiSlave(
            deviceId: DevicesTestData.slaveMac1,
            hostName: 'Living Room',
          ),
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: network,
          info: sysInfo,
        );

        final gateway =
            topology.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
        final slave =
            topology.nodes.firstWhere((n) => n.type == MeshNodeType.extender);
        expect(gateway.name, slave.name); // labels collide
        expect(gateway.identifier, isNot(slave.identifier)); // ids do not
      });

      test('identifier is stable regardless of client signal quality', () {
        // Same node, different quality% → identifier must not change.
        final strong = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: DevicesTestData.createSingleNodeNetwork(
            masterClients: [
              DevicesTestData.createWifiClient(
                mac: DevicesTestData.clientMac1,
                wifi: DevicesTestData.createExcellentSignal(),
              ),
            ],
          ),
          info: sysInfo,
        );
        final weak = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: DevicesTestData.createSingleNodeNetwork(
            masterClients: [
              DevicesTestData.createWifiClient(
                mac: DevicesTestData.clientMac1,
                wifi: DevicesTestData.createPoorSignal(),
              ),
            ],
          ),
          info: sysInfo,
        );

        String clientId(MeshTopology t) => t.nodes
            .firstWhere((n) => n.type == MeshNodeType.client)
            .identifier!;
        expect(clientId(strong), clientId(weak));
      });
    });

    // =========================================================================
    // Node liveness → MeshNodeStatus (#1430)
    //
    // AC2: node status is mapped from isOnline, not hardcoded online.
    // AC1: slave liveness is a DataElements match (dataElementsId != null); the
    //      Hosts row's `Active` is not a liveness signal for nodes (it reads 0
    //      whether the node is up or powered off). The master is the data source
    //      itself and stays online unconditionally.
    // AC5: an offline node carries no fabricated backhaul level.
    // AC6: an offline node reaches MeshNodeStatus.offline, which is the gate for
    //      usp_topology_view.dart:142 (offline nodes are not navigable) and
    //      node_detail_popup.dart:99 (Details button hidden when not online) —
    //      previously dead code because nodes were always online.
    // =========================================================================

    group('node liveness → status (#1430)', () {
      test('a DataElements-matched slave maps to MeshNodeStatus.online', () {
        final meshNetwork = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            // Matched a DataElements agent ⇒ online, regardless of isActive.
            DevicesTestData.createWifiSlave(
                dataElementsId: DevicesTestData.slaveMac1),
          ],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extender =
            topology.nodes.firstWhere((n) => n.type == MeshNodeType.extender);
        expect(extender.status, MeshNodeStatus.online);
        expect(extender.isOffline, isFalse);
      });

      test(
          'an unmatched slave maps to MeshNodeStatus.offline with no signal '
          'level', () {
        final meshNetwork = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            // No DataElements match (dataElementsId == null) ⇒ offline. This is
            // the powered-off shape: the Hosts row survives, the agent is gone.
            DevicesTestData.createWifiSlave(
              backhaul: DevicesTestData.emptyBackhaul,
            ),
          ],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extender =
            topology.nodes.firstWhere((n) => n.type == MeshNodeType.extender);
        // AC2 + AC6: reaches the offline state (was hardcoded online).
        expect(extender.status, MeshNodeStatus.offline);
        expect(extender.isOffline, isTrue);
        // AC5: no backhaul data ⇒ no fabricated mid-strength level.
        expect(extender.level, 0.0);
      });

      test(
          'an unmatched slave stays online when DataElements is unavailable '
          'for the whole network', () {
        // The C1 regression, at the layer that decides navigability. With
        // livenessKnown false the absent DataElements match is not a verdict, so
        // the node must NOT reach MeshNodeStatus.offline — that state gates the
        // tap handler (usp_topology_view.dart:142) and the Details button
        // (node_detail_popup.dart:99), and nothing on the page recovers from it
        // (devices_data_provider's _fetchMeshAndUpdate bails on an empty
        // topology, so the state never updates).
        final meshNetwork = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            DevicesTestData.createWifiSlave(
              livenessKnown: false,
              backhaul: DevicesTestData.emptyBackhaul,
            ),
          ],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extender =
            topology.nodes.firstWhere((n) => n.type == MeshNodeType.extender);
        expect(extender.status, MeshNodeStatus.online);
        expect(extender.isOffline, isFalse);
        // Unknown liveness still fabricates no signal: no backhaul ⇒ 0.0.
        expect(extender.level, 0.0);
      });

      test(
          'an online WiFi slave whose backhaul carries no RSSI keeps a neutral '
          'level, not zero', () {
        // Firmware ships RCPI 0 for a backhaul whose BackhaulStats are not
        // populated yet; rcpiToRssi maps that to null while the medium and the
        // parent stay set, so hasInfo is true. Reading 0.0 there paints a healthy
        // node's water level empty — visually identical to a dead node. AC4's "no
        // fabricated 0.5" is about an ABSENT backhaul (asserted 0.0 in the test
        // above), not about a real backhaul with a missing reading.
        final meshNetwork = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            DevicesTestData.createWifiSlave(
              dataElementsId: DevicesTestData.slaveMac1,
              backhaul: DevicesTestData.createWifiBackhaul(
                signalStrength: null,
              ),
            ),
          ],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final extender =
            topology.nodes.firstWhere((n) => n.type == MeshNodeType.extender);
        expect(extender.status, MeshNodeStatus.online);
        expect(extender.level, 0.5,
            reason:
                'a real WiFi backhaul with no reading is unknown, not dead');
      });

      test(
          'a slave with no backhaul info gets an unknown-quality link, not a '
          'graded one', () {
        // AC3 / qodo#3, and the change ui_kit#87 was waited on for (#1464 AC4).
        // This test used to expect `wifi` and say so in the words of a forced
        // choice: `ConnectionType` had two members and `MeshLink.connectionType`
        // is non-nullable, so an absent backhaul had to claim a medium, and
        // `wifi` was the claim that at least routed both views through the
        // neutral `wifiUnknownStyle` instead of asserting a wire.
        //
        // v3.2.0 shipped `ConnectionType.unknown` (this repo resolves v3.3.2), so
        // the claim is no longer forced and this row now asserts the medium as
        // well as the quality. They are different axes and both are unknown here:
        // no medium reported, and no RSSI to grade.
        final meshNetwork = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            DevicesTestData.createWifiSlave(
              livenessKnown: false,
              backhaul: DevicesTestData.emptyBackhaul,
            ),
          ],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final link = topology.links
            .firstWhere((l) => l.targetId.startsWith('extender-'));
        expect(link.linkQuality, LinkQuality.unknown,
            reason: 'no backhaul reading ⇒ neutral style in both views');
        expect(link.rssi, isNull);
        expect(link.throughput, isNull);
        expect(link.connectionType, ConnectionType.unknown,
            reason: 'no medium reported ⇒ no medium claimed');
        expect(link.isEthernet, isFalse,
            reason: 'an absent backhaul must not be styled as a wired link');
      });

      test(
          'the gateway stays online unconditionally, even without a '
          'DataElements match (AC1)', () {
        // The master is the data source itself; its liveness is not gated on a
        // DataElements agent match, so a null dataElementsId must not make it
        // offline (the retracted isActive-based remedy would have).
        final meshNetwork = MeshNetwork(
          master:
              DevicesTestData.createMaster(), // dataElementsId defaults null
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        final gateway =
            topology.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
        expect(gateway.status, MeshNodeStatus.online);
      });
    });

    // The emitted graph, end to end (#1441). The rules themselves are pinned in
    // `backhaul_parent_graph_test.dart`, which tests them as values; this group
    // is the wiring — that the builder puts the resolved parent on the `MeshNode`
    // *and* on the `MeshLink`, which are two separate assignments and were the
    // thing a pure-function test cannot see.
    group('parent resolution (#1441)', () {
      MeshNetwork networkOf(List<({String mac, String? parent})> slaves) =>
          MeshNetwork(
            master: DevicesTestData.createMaster(),
            slaves: [
              for (final s in slaves)
                DevicesTestData.createWifiSlave(
                  deviceId: s.mac,
                  dataElementsId: s.mac,
                  backhaul: BackhaulInfo(
                    linkType: 'Wi-Fi',
                    signalStrength: -55,
                    parentNodeId: s.parent,
                  ),
                ),
            ],
          );

      MeshTopology buildOf(List<({String mac, String? parent})> slaves) =>
          UspTopologyBuilder.buildFromMeshNetwork(
            meshNetwork: networkOf(slaves),
            info: sysInfo,
          );

      String parentIdOf(MeshTopology topology, String mac) =>
          topology.nodes.firstWhere((n) => n.id == 'extender-$mac').parentId!;

      test(
          'a node whose named parent is absent from the tree lands on the '
          'gateway', () {
        // AC3's second case. The attachment is what it always was; what this
        // pins is that it still happens — the MISS is a log line, not a dropped
        // node. A node the builder declines to emit disappears from the topology
        // page, which is worse than a hop drawn one level too high.
        final topology = buildOf([
          (mac: DevicesTestData.slaveMac1, parent: '99:99:99:99:99:99'),
        ]);

        expect(parentIdOf(topology, DevicesTestData.slaveMac1), 'gateway');
        expect(
          topology.links
              .firstWhere((l) => l.targetId.endsWith(DevicesTestData.slaveMac1))
              .sourceId,
          'gateway',
          reason: 'the link has to agree with the node it connects',
        );
      });

      test('a 2-cycle is not emitted', () {
        // AC1 + AC3's first case. Asserted as the property ui_kit's recursion
        // needs — every node reaches the gateway by following `parentId` — rather
        // than as "slave 1 is attached to the gateway", so it stays true if the
        // deterministic victim ever changes.
        final topology = buildOf([
          (mac: DevicesTestData.slaveMac1, parent: DevicesTestData.slaveMac2),
          (mac: DevicesTestData.slaveMac2, parent: DevicesTestData.slaveMac1),
        ]);

        final parentById = {
          for (final n in topology.nodes) n.id: n.parentId,
        };
        for (final node in topology.nodes) {
          var current = node.id;
          final seen = <String>{};
          while (parentById[current] != null) {
            expect(seen.add(current), isTrue,
                reason: 'following parentId from ${node.id} revisited $current '
                    '— ui_kit\'s layout recursion would not terminate here');
            current = parentById[current]!;
          }
        }
        // And the cycle's own edge is the only thing that went.
        expect(parentIdOf(topology, DevicesTestData.slaveMac2),
            'extender-${DevicesTestData.slaveMac1}');
      });

      test('the links agree with the nodes after a cycle is broken', () {
        // The wiring this group exists for: `parentId` and `MeshLink.sourceId`
        // are two assignments from one variable, and a fix applied to only one of
        // them draws an edge the layout does not know about.
        final topology = buildOf([
          (mac: DevicesTestData.slaveMac1, parent: DevicesTestData.slaveMac2),
          (mac: DevicesTestData.slaveMac2, parent: DevicesTestData.slaveMac1),
        ]);

        for (final node in topology.nodes.where((n) => n.parentId != null)) {
          final link = topology.links.firstWhere((l) => l.targetId == node.id);
          expect(link.sourceId, node.parentId,
              reason: '${node.id}: link source and node parent disagree');
        }
      });

      test('a client whose parent MAC is dashed still attaches to its node',
          () {
        // The fifth site the normaliser swap touched, and the one on the client
        // probe rather than the node one. It is not separable: the set it is
        // probed against is built in the same loop as the node keys, so the two
        // have to agree on the normal form — otherwise a dashed identifier misses
        // and the client is drawn on the gateway, which is #1441's defect pointed
        // at clients. Client attribution itself is #1439's and is untouched.
        final meshNetwork = MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            DevicesTestData.createWifiSlave(
              deviceId: DevicesTestData.slaveMac1,
              dataElementsId: DevicesTestData.slaveMac1,
              connectedClients: [
                DevicesTestData.createSlaveConnectedClient(
                  mac: DevicesTestData.clientMac3,
                  // The slave's own MAC, written the other way round.
                  parentNodeId: DevicesTestData.slaveMac1
                      .replaceAll(':', '-')
                      .toLowerCase(),
                  parentNodeName: 'Extender-1',
                ),
              ],
            ),
          ],
        );

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: meshNetwork,
          info: sysInfo,
        );

        expect(
          topology.nodes
              .firstWhere((n) => n.id == 'client-${DevicesTestData.clientMac3}')
              .parentId,
          'extender-${DevicesTestData.slaveMac1}',
          reason: 'a dashed parent MAC must key the same entry as a colon one',
        );
      });

      test(
          'a node parented by the gateway resolves to it, and a real hop '
          'survives', () {
        // The false-positive guard for both halves: naming the master must not
        // read as a miss, and a genuine two-hop chain must not be flattened.
        final topology = buildOf([
          (mac: DevicesTestData.slaveMac1, parent: DevicesTestData.masterMac),
          (mac: DevicesTestData.slaveMac2, parent: DevicesTestData.slaveMac1),
        ]);

        expect(parentIdOf(topology, DevicesTestData.slaveMac1), 'gateway');
        expect(parentIdOf(topology, DevicesTestData.slaveMac2),
            'extender-${DevicesTestData.slaveMac1}');
      });
    });
    // The backhaul level's inputs used to be two independent strings and one
    // nullable int with nothing coupling them — `isEthernet` read `linkType`,
    // `hasInfo` read `mediaType` — so the table's whole point was the row the
    // field-by-field fixtures never produce: `linkType:'Ethernet'` with an empty
    // `mediaType`, which one guard order painted dead while two other sites
    // called the same node wired (#1449 review).
    //
    // #1555 deleted `mediaType`: prplMesh has no `BackhaulMediaType` and no
    // replacement for it, so `isEthernet` and the medium half of `hasInfo` now
    // read the same `linkType` and that row is no longer constructible. The table
    // stays for the cross-check below — the failure it caught was never a wrong
    // level on its own but one build answering the same field two ways, which is
    // still possible whenever `_backhaulLevel` and the link's `connectionType`
    // are written apart.
    //
    // What #1555 adds in its place is the *other* half of `hasInfo`: a row with
    // an empty `LinkType` but a known `BackhaulDeviceID`. That is not a
    // hand-built edge case — `LinkType` is nullable in the new definition — and
    // it is where the same disagreement had moved to, this time between this
    // builder and `UnifiedDiagnosticsService`. The last two rows are that state.
    //
    // `linkType:'None'` is absent on purpose: `meshBackhaulLinkType` maps
    // firmware's `None` to null before a `BackhaulInfo` is built, so it arrives
    // here as the absent row. That mapping is pinned in
    // `mesh_topology_builder_test.dart`, which is where the wire string lives.
    group('backhaul level and medium decision table', () {
      double levelFor(BackhaulInfo backhaul) {
        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: MeshNetwork(
            master: DevicesTestData.createMaster(),
            slaves: [
              DevicesTestData.createWifiSlave(
                dataElementsId: DevicesTestData.slaveMac1,
                backhaul: backhaul,
              ),
            ],
          ),
          info: sysInfo,
        );
        return topology.nodes
            .firstWhere((n) => n.type == MeshNodeType.extender)
            .level;
      }

      ConnectionType connectionTypeFor(BackhaulInfo backhaul) {
        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: MeshNetwork(
            master: DevicesTestData.createMaster(),
            slaves: [
              DevicesTestData.createWifiSlave(
                dataElementsId: DevicesTestData.slaveMac1,
                backhaul: backhaul,
              ),
            ],
          ),
          info: sysInfo,
        );
        return topology.links
            .firstWhere((l) => l.targetId.startsWith('extender-'))
            .connectionType;
      }

      // Both axes per row, because the failure this table exists for is the two
      // being written apart — see the cross-check below. The medium column is
      // #1464's AC4: a backhaul firmware named no medium for is
      // [ConnectionType.unknown], not the `wifi` this builder used to claim.
      const cases = <String, (BackhaulInfo, double, ConnectionType)>{
        'absent (no linkType, no parent)': (
          BackhaulInfo.none,
          0.0,
          ConnectionType.unknown,
        ),
        'Ethernet': (
          BackhaulInfo(linkType: 'Ethernet'),
          1.0,
          ConnectionType.ethernet,
        ),
        // Firmware spells it `Ethernet`; the fold is robustness, and it is the
        // medium axis's half of what `isMeshBackhaulEthernet` already pins.
        'ethernet, lower-cased': (
          BackhaulInfo(linkType: 'ethernet'),
          1.0,
          ConnectionType.ethernet,
        ),
        'Wi-Fi with a reading': (
          BackhaulInfo(linkType: 'Wi-Fi', signalStrength: -50),
          0.9,
          ConnectionType.wifi,
        ),
        'Wi-Fi with no reading': (
          BackhaulInfo(linkType: 'Wi-Fi'),
          0.5,
          ConnectionType.wifi,
        ),
        // A medium *named* and not recognised stays `wifi`, deliberately: AC4
        // moves the arm for a medium firmware did not name, and the practical
        // vocabulary is closed at three values (`Wi-Fi`, `Ethernet`, `None` —
        // measured against `beerocks_controller`, #1464 AC1), so this row is not
        // a firmware state. It is here to pin that the change is keyed on
        // *absence* of a medium rather than on failing to match `Ethernet`.
        'a medium named but unrecognised': (
          BackhaulInfo(linkType: 'Ethernet over Coax'),
          0.5,
          ConnectionType.wifi,
        ),
        // #1555. `LinkType` is nullable in the prplMesh definition and arrives
        // empty on rows that still carry a `BackhaulDeviceID`, so these two rows
        // are firmware states, not constructed ones. They are 0.5/RSSI and not
        // 0.0 because `hasInfo` counts the parent: grading them dead here while
        // `UnifiedDiagnosticsService` defaults the medium to Wi-Fi and grades
        // them on RSSI is the disagreement the getter was rewritten to close.
        //
        // Their medium is `unknown` for the same reason the level is not 0.0:
        // the link is real and the *medium* is the thing nobody reported. This
        // is the row FL-WRT 2.0 makes ordinary rather than exotic — the
        // controller reports `LinkType = None`.
        'parent known, medium unnamed, no reading': (
          BackhaulInfo(parentNodeId: DevicesTestData.masterMac),
          0.5,
          ConnectionType.unknown,
        ),
        'parent known, medium unnamed, with a reading': (
          BackhaulInfo(
            parentNodeId: DevicesTestData.masterMac,
            signalStrength: -50,
          ),
          0.9,
          ConnectionType.unknown,
        ),
      };

      cases.forEach((name, row) {
        final (backhaul, expectedLevel, expectedMedium) = row;
        test('$name → level $expectedLevel',
            () => expect(levelFor(backhaul), expectedLevel));
        test('$name → ${expectedMedium.name} link',
            () => expect(connectionTypeFor(backhaul), expectedMedium));
      });

      test('an unknown medium keeps the quality we measured (#1464)', () {
        // The pair a reviewer had to re-derive across two packages, so it is
        // pinned here. `MeshLink.linkQuality` discards an RSSI carried beside
        // `ConnectionType.unknown` — but only when the app gives no override, and
        // this builder gives one.
        //
        // That is deliberate. `Backhaul.Stats.SignalStrength` is a reading of this
        // link and a wired backhaul has none, so a row with an RSSI and no named
        // medium is a link we measured and firmware did not label: medium unknown,
        // quality known. Collapsing the quality to `unknown` as well would throw a
        // real reading away to say something about a different axis.
        const measuredButUnlabelled = BackhaulInfo(
          parentNodeId: DevicesTestData.masterMac,
          signalStrength: -50,
        );
        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: MeshNetwork(
            master: DevicesTestData.createMaster(),
            slaves: [
              DevicesTestData.createWifiSlave(
                dataElementsId: DevicesTestData.slaveMac1,
                backhaul: measuredButUnlabelled,
              ),
            ],
          ),
          info: sysInfo,
        );
        final link = topology.links
            .firstWhere((l) => l.targetId.startsWith('extender-'));

        expect(link.connectionType, ConnectionType.unknown,
            reason: 'no medium was named');
        expect(link.linkQuality, LinkQuality.excellent,
            reason: '-50 dBm was measured, and the override is what says so');
        expect(link.rssi, -50);
      });

      test('the level and the link agree on every row', () {
        // The divergence this table was added for is not a wrong level on its
        // own — it is one builder answering the same fields two ways in one
        // pass, so the graph draws a wired link into a node painted dead.
        // Both sides are read from the same build, not compared against the
        // table's expectation: an assertion against `expected` would agree with
        // itself and pass under the very guard order that caused the split.
        for (final entry in cases.entries) {
          final (backhaul, _, _) = entry.value;
          final isWired =
              connectionTypeFor(backhaul) == ConnectionType.ethernet;
          expect(isWired, levelFor(backhaul) == 1.0,
              reason: '${entry.key}: connectionType and level disagree');
        }
      });
    });
  });
}
