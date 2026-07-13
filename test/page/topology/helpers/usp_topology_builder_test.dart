import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
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

      test('Ethernet backhaul has default level', () {
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
        // No signal → 0.5 default
        expect(extender.level, 0.5);
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
  });
}
