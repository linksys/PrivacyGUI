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
        // populated yet; rcpiToRssi maps that to null while mediaType stays set,
        // so hasInfo is true. Reading 0.0 there paints a healthy node's water
        // level empty — visually identical to a dead node. AC4's "no fabricated
        // 0.5" is about an ABSENT backhaul (asserted 0.0 in the test above),
        // not about a real backhaul with a missing reading.
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
        // AC3 / qodo#3. ui_kit's ConnectionType has only ethernet and wifi and
        // MeshLink.connectionType is non-nullable, so an absent backhaul must
        // claim one of them; `wifi` is chosen because it routes BOTH views
        // through topologySpec.linkStyleFor(linkQuality) — with `unknown` that
        // lands on the neutral wifiUnknownStyle, whereas `ethernet` would
        // hard-wire ethernetLinkStyle and assert a wired backhaul.
        //
        // So the assertion that carries the correctness is linkQuality, not
        // connectionType: no RSSI ⇒ unknown ⇒ neutral. When ui_kit ships
        // ConnectionType.unknown (linksys/privacyGUI-UI-kit#87), the
        // connectionType expectation below is the one to change.
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
        // The forced claim. Not correct, only least-wrong — see the comment
        // above and at the call site.
        expect(link.connectionType, ConnectionType.wifi);
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

    // The backhaul level's inputs are two independent strings and one nullable
    // int, and nothing in `BackhaulInfo` couples them: `isEthernet` reads
    // `linkType`, `hasInfo` reads `mediaType`. So the four states are a table,
    // not a ladder, and the row that matters is the one the field-by-field
    // fixtures never produce — `linkType:'Ethernet'` with an empty `mediaType`.
    // A guard order that answered that row differently from the link's
    // `connectionType` and from the node-detail card's arm chain is what this
    // table exists to pin (#1449 review).
    group('backhaul level decision table', () {
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

      const cases = <String, (BackhaulInfo, double)>{
        'absent (no mediaType, no linkType) → 0.0': (
          BackhaulInfo(mediaType: ''),
          0.0,
        ),
        'Ethernet, both fields set → 1.0': (
          BackhaulInfo(mediaType: 'Ethernet', linkType: 'Ethernet'),
          1.0,
        ),
        'Wi-Fi with a reading → the RSSI level': (
          BackhaulInfo(
            mediaType: 'IEEE 802.11ax',
            linkType: 'Wi-Fi',
            signalStrength: -50,
          ),
          0.9,
        ),
        'Wi-Fi with no reading → neutral 0.5': (
          BackhaulInfo(mediaType: 'IEEE 802.11ax', linkType: 'Wi-Fi'),
          0.5,
        ),
        // The uncoupled row. `linkType` is a positive statement and
        // `mediaType` is merely missing, so the positive one wins.
        'linkType Ethernet with an empty mediaType → 1.0, not 0.0': (
          BackhaulInfo(mediaType: '', linkType: 'Ethernet'),
          1.0,
        ),
      };

      cases.forEach((name, row) {
        final (backhaul, expected) = row;
        test(name, () => expect(levelFor(backhaul), expected));
      });

      test('the level and the link agree on every row', () {
        // The divergence this table was added for is not a wrong level on its
        // own — it is one builder answering the same fields two ways in one
        // pass, so the graph draws a wired link into a node painted dead.
        // Both sides are read from the same build, not compared against the
        // table's expectation: an assertion against `expected` would agree with
        // itself and pass under the very guard order that caused the split.
        for (final entry in cases.entries) {
          final (backhaul, _) = entry.value;
          final isWired =
              connectionTypeFor(backhaul) == ConnectionType.ethernet;
          expect(isWired, levelFor(backhaul) == 1.0,
              reason: '${entry.key}: connectionType and level disagree');
        }
      });
    });
  });
}
