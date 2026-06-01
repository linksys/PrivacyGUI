import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/device_classifier.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  // OUI database for testing (minimal set for topology tests)
  const testOuiDatabase = <String, String>{
    '112233': 'Test Vendor',
  };

  setUpAll(() {
    OuiLookup.initializeForTesting(testOuiDatabase);
  });

  tearDownAll(() {
    OuiLookup.reset();
  });

  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------

  const sysInfo = SystemInfoUIModel(
    manufacturer: 'Linksys',
    modelName: 'MR7500',
    serialNumber: 'SN123',
    hardwareVersion: '1.0',
    softwareVersion: '2.0.0',
    uptime: 3600,
    totalMemory: 512000,
    freeMemory: 256000,
    cpuUsage: 30,
  );

  const meshGateway = NodeUIModel(
    deviceId: 'AA:BB:CC:DD:EE:01',
    model: 'MR7500',
    isMaster: true,
  );

  const meshExtender = NodeUIModel(
    deviceId: 'AA:BB:CC:DD:EE:02',
    model: 'MX5500',
    isMaster: false,
  );

  const wifiDevice = DeviceUIModel(
    mac: '11:22:33:44:55:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    isWifi: true,
    signalStrength: -55,
    parentNodeId: 'AA:BB:CC:DD:EE:01',
  );

  const ethernetDevice = DeviceUIModel(
    mac: '11:22:33:44:55:02',
    ip: '192.168.1.101',
    hostName: 'Desktop',
    isActive: true,
    isWifi: false,
    parentNodeId: 'AA:BB:CC:DD:EE:01',
  );

  const offlineDevice = DeviceUIModel(
    mac: '11:22:33:44:55:03',
    ip: '192.168.1.102',
    hostName: 'Tablet',
    isActive: false,
    isWifi: true,
    signalStrength: -80,
    parentNodeId: 'AA:BB:CC:DD:EE:02',
  );

  // ---------------------------------------------------------------------------
  // Non-mesh topology (single router)
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - non-mesh', () {
    test('builds gateway node with synthetic id when no mesh nodes', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice],
        nodeModels: [],
      );

      expect(topo.nodes.where((n) => n.type == MeshNodeType.gateway),
          hasLength(1));
      final gateway = topo.nodes.first;
      expect(gateway.id, 'gateway');
      expect(gateway.name, 'MR7500');
      expect(gateway.metadata?['deviceId'], 'gateway');
    });

    test('all client nodes link to gateway when no mesh', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice, ethernetDevice],
        nodeModels: [],
      );

      final clientLinks =
          topo.links.where((l) => l.sourceId == 'gateway').toList();
      expect(clientLinks, hasLength(2));
    });

    test('no extender nodes when mesh is empty', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice],
        nodeModels: [],
      );

      final extenders =
          topo.nodes.where((n) => n.type == MeshNodeType.extender);
      expect(extenders, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Mesh topology (gateway + extenders)
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - mesh', () {
    test('builds gateway with real deviceId from first mesh node', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, meshExtender],
      );

      final gateway =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
      expect(gateway.metadata?['deviceId'], 'AA:BB:CC:DD:EE:01');
    });

    test('builds extender nodes from mesh nodes (skip first)', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, meshExtender],
      );

      final extenders =
          topo.nodes.where((n) => n.type == MeshNodeType.extender).toList();
      expect(extenders, hasLength(1));
      expect(extenders.first.name, 'MX5500');
      expect(extenders.first.metadata?['deviceId'], 'AA:BB:CC:DD:EE:02');
    });

    test('extender links to gateway', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, meshExtender],
      );

      final extenderLink =
          topo.links.where((l) => l.targetId.startsWith('extender-')).toList();
      expect(extenderLink, hasLength(1));
      expect(extenderLink.first.sourceId, 'gateway');
      expect(extenderLink.first.connectionType, ConnectionType.wifi);
    });

    test('client node links to correct extender based on parentNodeId', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [offlineDevice],
        nodeModels: [meshGateway, meshExtender],
      );

      final clientLink = topo.links
          .where((l) => l.targetId == 'client-${offlineDevice.mac}')
          .first;
      expect(clientLink.sourceId, 'extender-AA:BB:CC:DD:EE:02');
    });

    test('client node links to gateway when parentNodeId is not an extender',
        () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice],
        nodeModels: [meshGateway, meshExtender],
      );

      final clientLink = topo.links
          .where((l) => l.targetId == 'client-${wifiDevice.mac}')
          .first;
      // wifiDevice's parentNodeId is AA:BB:CC:DD:EE:01 which is the gateway,
      // not in extenderNodeIds set, so falls back to gateway
      expect(clientLink.sourceId, 'gateway');
    });

    test('client links to extender when parentNodeId matches dataElementsId',
        () {
      // Slave's Hosts MAC differs from its DataElements ID — clientToNodeMap
      // uses the DataElements ID (no colons).
      const slaveWithDifferentDeId = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02', // Hosts MAC
        dataElementsId: '11:11:11:22:22:22', // DataElements node id
        model: 'MX5500',
        isMaster: false,
      );
      const clientWithDeParent = DeviceUIModel(
        mac: '99:88:77:66:55:44',
        ip: '192.168.1.150',
        hostName: 'LivingRoomTV',
        isActive: true,
        isWifi: true,
        signalStrength: -60,
        // parentNodeId from clientToNodeMap is normalized (no colons, upper)
        parentNodeId: '111111222222',
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [clientWithDeParent],
        nodeModels: [meshGateway, slaveWithDifferentDeId],
      );

      final clientLink = topo.links
          .where((l) => l.targetId == 'client-${clientWithDeParent.mac}')
          .first;
      // Should attach to the extender (built from Hosts deviceId), not gateway
      expect(clientLink.sourceId, 'extender-AA:BB:CC:DD:EE:02');
    });

    test(
        'client links to extender when parentNodeId matches Hosts MAC '
        '(normalized)', () {
      // parentNodeId in normalized form (no colons) should still match
      // against the slave's Hosts deviceId.
      const clientWithNormalizedParent = DeviceUIModel(
        mac: '99:88:77:66:55:55',
        ip: '192.168.1.151',
        hostName: 'Phone',
        isActive: true,
        isWifi: true,
        signalStrength: -60,
        parentNodeId: 'AABBCCDDEE02', // no colons
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [clientWithNormalizedParent],
        nodeModels: [meshGateway, meshExtender],
      );

      final clientLink = topo.links
          .where(
              (l) => l.targetId == 'client-${clientWithNormalizedParent.mac}')
          .first;
      expect(clientLink.sourceId, 'extender-AA:BB:CC:DD:EE:02');
    });
  });

  // ---------------------------------------------------------------------------
  // Client node properties
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - client nodes', () {
    test('wifi client has wifi connection type', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice],
        nodeModels: [],
      );

      final link =
          topo.links.where((l) => l.targetId.startsWith('client-')).first;
      expect(link.connectionType, ConnectionType.wifi);
      expect(link.rssi, -55);
    });

    test('ethernet client has ethernet connection type', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [ethernetDevice],
        nodeModels: [],
      );

      final link =
          topo.links.where((l) => l.targetId.startsWith('client-')).first;
      expect(link.connectionType, ConnectionType.ethernet);
      expect(link.rssi, isNull);
    });

    test('online client has online status', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.status, MeshNodeStatus.online);
    });

    test('offline client has offline status', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [offlineDevice],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.status, MeshNodeStatus.offline);
    });

    test('client name uses displayName (hostName if available)', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.name, 'iPhone');
    });
  });

  // ---------------------------------------------------------------------------
  // Signal quality and level mapping
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - signal mapping', () {
    test('strong wifi signal maps to high level', () {
      const device = DeviceUIModel(
        mac: 'AA:AA:AA:AA:AA:AA',
        ip: '192.168.1.1',
        hostName: 'Strong',
        isActive: true,
        isWifi: true,
        signalStrength: -45,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 0.9);
      expect(client.linkQuality, LinkQuality.excellent);
    });

    test('medium wifi signal maps to medium level', () {
      // wifi.dart thresholds: [-65, -71, -78]
      // -75 is >= -78 (fair) → level 0.4, LinkQuality.good
      const device = DeviceUIModel(
        mac: 'AA:AA:AA:AA:AA:AA',
        ip: '192.168.1.1',
        hostName: 'Medium',
        isActive: true,
        isWifi: true,
        signalStrength: -75,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 0.4);
      expect(client.linkQuality, LinkQuality.good);
    });

    test('good wifi signal (-68) maps to level 0.65', () {
      // wifi.dart thresholds: [-65, -71, -78]
      // -68 is in (-71, -65] → good → level 0.65, LinkQuality.excellent
      const device = DeviceUIModel(
        mac: 'AA:AA:AA:AA:AA:AB',
        ip: '192.168.1.1',
        hostName: 'Good',
        isActive: true,
        isWifi: true,
        signalStrength: -68,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 0.65);
      expect(client.linkQuality, LinkQuality.excellent);
    });

    test('weak wifi signal maps to low level', () {
      // wifi.dart thresholds: [-65, -71, -78]
      // -80 is < -78 (poor) → LinkQuality.fair
      const device = DeviceUIModel(
        mac: 'AA:AA:AA:AA:AA:AA',
        ip: '192.168.1.1',
        hostName: 'Weak',
        isActive: true,
        isWifi: true,
        signalStrength: -80,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 0.1);
      expect(client.linkQuality, LinkQuality.fair);
    });

    test('ethernet device maps to wired signal quality and level 1.0', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [ethernetDevice],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 1.0);
      expect(client.linkQuality, LinkQuality.stable);
    });

    test('wifi device with null RSSI maps to unknown quality', () {
      const device = DeviceUIModel(
        mac: 'AA:AA:AA:AA:AA:AA',
        ip: '192.168.1.1',
        hostName: 'NoRSSI',
        isActive: true,
        isWifi: true,
        signalStrength: null,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 0.0);
      expect(client.linkQuality, LinkQuality.unknown);
    });
  });

  // ---------------------------------------------------------------------------
  // Total node/link counts
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - totals', () {
    test('correct total nodes and links for mesh + clients', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice, ethernetDevice, offlineDevice],
        nodeModels: [meshGateway, meshExtender],
      );

      // 1 gateway + 1 extender + 3 clients = 5 nodes
      expect(topo.nodes, hasLength(5));
      // 1 gateway→extender link + 3 client links = 4 links
      expect(topo.links, hasLength(4));
    });

    test('empty devices produces only infrastructure nodes', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, meshExtender],
      );

      // 1 gateway + 1 extender = 2 nodes
      expect(topo.nodes, hasLength(2));
      // 1 gateway→extender link
      expect(topo.links, hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Gateway metadata (enriched in topology enhancements)
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - gateway metadata', () {
    test('gateway metadata includes all system info fields', () {
      const meshGatewayWithFullInfo = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        model: 'MR7500',
        manufacturer: 'Linksys',
        serialNumber: 'SN123',
        softwareVersion: '2.0.0',
        isMaster: true,
      );
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGatewayWithFullInfo],
      );

      final gateway =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
      expect(gateway.metadata?['model'], 'MR7500');
      expect(gateway.metadata?['manufacturer'], 'Linksys');
      expect(gateway.metadata?['serialNumber'], 'SN123');
      expect(gateway.metadata?['softwareVersion'], '2.0.0');
      expect(gateway.metadata?['isMaster'], isTrue);
    });

    test('gateway metadata deviceId uses mesh node deviceId when available',
        () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway],
      );

      final gateway =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
      expect(gateway.metadata?['deviceId'], 'AA:BB:CC:DD:EE:01');
    });

    test('gateway metadata deviceId is "gateway" when no mesh nodes', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [],
      );

      final gateway =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
      expect(gateway.metadata?['deviceId'], 'gateway');
    });
  });

  // ---------------------------------------------------------------------------
  // Extender metadata
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - extender metadata', () {
    const extenderWithFullInfo = NodeUIModel(
      deviceId: 'AA:BB:CC:DD:EE:02',
      model: 'MX5500',
      manufacturer: 'Linksys',
      serialNumber: 'SN456',
      softwareVersion: '1.5.0',
      isMaster: false,
    );

    test('extender metadata includes all mesh node fields', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, extenderWithFullInfo],
      );

      final extender =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.extender);
      expect(extender.metadata?['deviceId'], 'AA:BB:CC:DD:EE:02');
      expect(extender.metadata?['model'], 'MX5500');
      expect(extender.metadata?['manufacturer'], 'Linksys');
      expect(extender.metadata?['serialNumber'], 'SN456');
      expect(extender.metadata?['softwareVersion'], '1.5.0');
      expect(extender.metadata?['isMaster'], isFalse);
    });

    test('extender metadata includes backhaul fields', () {
      const extenderWithBackhaul = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        model: 'MX5500',
        isMaster: false,
        backhaulLinkType: 'Wi-Fi',
        backhaulParentDeviceId: 'AA:BB:CC:DD:EE:01',
        backhaulSignalStrength: -45,
        backhaulUplinkRate: 500000,
        backhaulDownlinkRate: 600000,
        lastContactTime: '2026-06-01T10:00:00Z',
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, extenderWithBackhaul],
      );

      final extender =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.extender);
      expect(extender.metadata?['backhaulLinkType'], 'Wi-Fi');
      expect(extender.metadata?['backhaulParentDeviceId'], 'AA:BB:CC:DD:EE:01');
      expect(extender.metadata?['backhaulSignalStrength'], -45);
      expect(extender.metadata?['backhaulUplinkRate'], 500000);
      expect(extender.metadata?['backhaulDownlinkRate'], 600000);
      expect(extender.metadata?['lastContactTime'], '2026-06-01T10:00:00Z');
    });
  });

  // ---------------------------------------------------------------------------
  // Multi-layer mesh (Slave → Slave → Master)
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - multi-layer mesh', () {
    test(
        'slave links to another slave when backhaulParentDeviceId points to slave',
        () {
      const slaveA = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        model: 'MX5500',
        isMaster: false,
        backhaulParentDeviceId: 'AA:BB:CC:DD:EE:01', // Points to master
      );
      const slaveB = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:03',
        model: 'MX5500',
        isMaster: false,
        backhaulParentDeviceId: 'AA:BB:CC:DD:EE:02', // Points to slaveA
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, slaveA, slaveB],
      );

      // SlaveA should link to gateway
      final slaveALink = topo.links
          .firstWhere((l) => l.targetId == 'extender-AA:BB:CC:DD:EE:02');
      expect(slaveALink.sourceId, 'gateway');

      // SlaveB should link to slaveA
      final slaveBLink = topo.links
          .firstWhere((l) => l.targetId == 'extender-AA:BB:CC:DD:EE:03');
      expect(slaveBLink.sourceId, 'extender-AA:BB:CC:DD:EE:02');
    });

    test('slave links to gateway when backhaulParentDeviceId is null', () {
      const slaveWithoutParent = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        model: 'MX5500',
        isMaster: false,
        backhaulParentDeviceId: null,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, slaveWithoutParent],
      );

      final link = topo.links
          .firstWhere((l) => l.targetId == 'extender-AA:BB:CC:DD:EE:02');
      expect(link.sourceId, 'gateway');
    });

    test('slave links to gateway when backhaulParentDeviceId matches master',
        () {
      const slaveConnectedToMaster = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        model: 'MX5500',
        isMaster: false,
        backhaulParentDeviceId: 'AA:BB:CC:DD:EE:01', // Points to master
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, slaveConnectedToMaster],
      );

      final link = topo.links
          .firstWhere((l) => l.targetId == 'extender-AA:BB:CC:DD:EE:02');
      expect(link.sourceId, 'gateway');
    });

    test(
        'slave links via dataElementsId when backhaulParentDeviceId uses DE ID',
        () {
      const slaveAWithDeId = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        dataElementsId: '11:11:11:22:22:22',
        model: 'MX5500',
        isMaster: false,
        backhaulParentDeviceId: 'AA:BB:CC:DD:EE:01',
      );
      const slaveBPointingToDeId = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:03',
        model: 'MX5500',
        isMaster: false,
        backhaulParentDeviceId: '11:11:11:22:22:22', // Points to slaveA's DE ID
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, slaveAWithDeId, slaveBPointingToDeId],
      );

      final slaveBLink = topo.links
          .firstWhere((l) => l.targetId == 'extender-AA:BB:CC:DD:EE:03');
      expect(slaveBLink.sourceId, 'extender-AA:BB:CC:DD:EE:02');
    });
  });

  // ---------------------------------------------------------------------------
  // Backhaul link type
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - backhaul link type', () {
    test('Ethernet backhaul uses ethernet connection type', () {
      const ethernetSlave = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        model: 'MX5500',
        isMaster: false,
        backhaulLinkType: 'Ethernet',
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, ethernetSlave],
      );

      final link = topo.links
          .firstWhere((l) => l.targetId == 'extender-AA:BB:CC:DD:EE:02');
      expect(link.connectionType, ConnectionType.ethernet);
    });

    test('Wi-Fi backhaul uses wifi connection type', () {
      const wifiSlave = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        model: 'MX5500',
        isMaster: false,
        backhaulLinkType: 'Wi-Fi',
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, wifiSlave],
      );

      final link = topo.links
          .firstWhere((l) => l.targetId == 'extender-AA:BB:CC:DD:EE:02');
      expect(link.connectionType, ConnectionType.wifi);
    });

    test('null backhaul link type defaults to wifi connection type', () {
      const slavWithoutLinkType = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        model: 'MX5500',
        isMaster: false,
        backhaulLinkType: null,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        nodeModels: [meshGateway, slavWithoutLinkType],
      );

      final link = topo.links
          .firstWhere((l) => l.targetId == 'extender-AA:BB:CC:DD:EE:02');
      expect(link.connectionType, ConnectionType.wifi);
    });
  });

  // ---------------------------------------------------------------------------
  // Client node icons (DeviceClassifier integration)
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - client icons', () {
    test('iPhone hostname gets phone icon', () {
      const device = DeviceUIModel(
        mac: '11:22:33:44:55:01',
        ip: '192.168.1.100',
        hostName: 'iPhone',
        isActive: true,
        isWifi: true,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.iconData, DeviceCategory.phone.icon);
    });

    test('MacBook hostname gets computer icon', () {
      const device = DeviceUIModel(
        mac: '11:22:33:44:55:02',
        ip: '192.168.1.101',
        hostName: 'MacBook-Pro',
        isActive: true,
        isWifi: true,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.iconData, DeviceCategory.computer.icon);
    });

    test('PlayStation hostname gets game console icon', () {
      const device = DeviceUIModel(
        mac: '11:22:33:44:55:03',
        ip: '192.168.1.102',
        hostName: 'PlayStation5',
        isActive: true,
        isWifi: false,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.iconData, DeviceCategory.gameConsole.icon);
    });

    test('unknown hostname with unknown OUI gets unknown icon', () {
      // Use universally administered MAC (bit 1 of first byte = 0)
      // that's not in our test OUI database
      const device = DeviceUIModel(
        mac: '00:FF:FF:44:55:04',
        ip: '192.168.1.103',
        hostName: 'device-12345',
        isActive: true,
        isWifi: true,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.iconData, DeviceCategory.unknown.icon);
    });

    test('client metadata includes mac address', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice],
        nodeModels: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.metadata?['mac'], '11:22:33:44:55:01');
    });
  });
}
