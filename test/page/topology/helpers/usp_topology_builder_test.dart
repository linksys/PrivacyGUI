import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
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

  const meshGateway = MeshNodeInfo(
    instancePath: 'Device.1.',
    deviceId: 'AA:BB:CC:DD:EE:01',
    model: 'MR7500',
  );

  const meshExtender = MeshNodeInfo(
    instancePath: 'Device.2.',
    deviceId: 'AA:BB:CC:DD:EE:02',
    model: 'MX5500',
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
        meshNodes: [],
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
        meshNodes: [],
      );

      final clientLinks =
          topo.links.where((l) => l.sourceId == 'gateway').toList();
      expect(clientLinks, hasLength(2));
    });

    test('no extender nodes when mesh is empty', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice],
        meshNodes: [],
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
        meshNodes: [meshGateway, meshExtender],
      );

      final gateway =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
      expect(gateway.metadata?['deviceId'], 'AA:BB:CC:DD:EE:01');
    });

    test('builds extender nodes from mesh nodes (skip first)', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        meshNodes: [meshGateway, meshExtender],
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
        meshNodes: [meshGateway, meshExtender],
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
        meshNodes: [meshGateway, meshExtender],
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
        meshNodes: [meshGateway, meshExtender],
      );

      final clientLink = topo.links
          .where((l) => l.targetId == 'client-${wifiDevice.mac}')
          .first;
      // wifiDevice's parentNodeId is AA:BB:CC:DD:EE:01 which is the gateway,
      // not in extenderNodeIds set, so falls back to gateway
      expect(clientLink.sourceId, 'gateway');
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
        meshNodes: [],
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
        meshNodes: [],
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
        meshNodes: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.status, MeshNodeStatus.online);
    });

    test('offline client has offline status', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [offlineDevice],
        meshNodes: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.status, MeshNodeStatus.offline);
    });

    test('client name uses displayName (hostName if available)', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [wifiDevice],
        meshNodes: [],
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
        meshNodes: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 0.9);
      expect(client.signalQuality, SignalQuality.strong);
    });

    test('medium wifi signal maps to medium level', () {
      const device = DeviceUIModel(
        mac: 'AA:AA:AA:AA:AA:AA',
        ip: '192.168.1.1',
        hostName: 'Medium',
        isActive: true,
        isWifi: true,
        signalStrength: -60,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        meshNodes: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 0.65);
      expect(client.signalQuality, SignalQuality.medium);
    });

    test('weak wifi signal maps to low level', () {
      const device = DeviceUIModel(
        mac: 'AA:AA:AA:AA:AA:AA',
        ip: '192.168.1.1',
        hostName: 'Weak',
        isActive: true,
        isWifi: true,
        signalStrength: -75,
      );

      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [device],
        meshNodes: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 0.1);
      expect(client.signalQuality, SignalQuality.weak);
    });

    test('ethernet device maps to wired signal quality and level 1.0', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [ethernetDevice],
        meshNodes: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 1.0);
      expect(client.signalQuality, SignalQuality.wired);
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
        meshNodes: [],
      );

      final client =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.client);
      expect(client.level, 0.0);
      expect(client.signalQuality, SignalQuality.unknown);
    });
  });

  // ---------------------------------------------------------------------------
  // Coverage rings
  // ---------------------------------------------------------------------------

  group('UspTopologyBuilder - coverage rings', () {
    test('gateway node has coverage rings when color provided', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        meshNodes: [meshGateway, meshExtender],
        coverageColor: const Color(0xFF0000FF),
      );

      final gateway =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
      expect(gateway.coverageRings, isNotNull);
      expect(gateway.coverageRings, hasLength(2));
    });

    test('no coverage rings when color is null', () {
      final topo = UspTopologyBuilder.build(
        info: sysInfo,
        devices: [],
        meshNodes: [meshGateway],
      );

      final gateway =
          topo.nodes.firstWhere((n) => n.type == MeshNodeType.gateway);
      expect(gateway.coverageRings, isNull);
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
        meshNodes: [meshGateway, meshExtender],
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
        meshNodes: [meshGateway, meshExtender],
      );

      // 1 gateway + 1 extender = 2 nodes
      expect(topo.nodes, hasLength(2));
      // 1 gateway→extender link
      expect(topo.links, hasLength(1));
    });
  });
}
