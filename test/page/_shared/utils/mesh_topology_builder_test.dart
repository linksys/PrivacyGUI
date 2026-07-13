import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_topology_builder.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Test data
  // ---------------------------------------------------------------------------

  final masterNode = MeshNode(
    instancePath: 'Device.WiFi.DataElements.Network.Device.1.',
    id: 'AA:BB:CC:DD:EE:01',
    manufacturerModel: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'SN12345',
    softwareVersion: '2.0.0',
    backhaulAlId: '', // Empty = master node
    backhaulMacAddress: '',
    backhaulMediaType: '',
    backhaulPhyRate: 0,
    multiApLastContactTime: '',
    multiApAssocIEEE1905DeviceRef: '',
    multiApEasyMeshAgentOperationMode: '',
    backhaulBackhaulDeviceId: '',
    backhaulBackhaulMacAddress: '',
    backhaulLinkType: '',
    backhaulMacAddressMultiAp: '',
    backhaulStatsLastDataDownlinkRate: 0,
    backhaulStatsPacketsSent: 0,
    backhaulStatsPacketsReceived: 0,
    backhaulStatsErrorsSent: 0,
    backhaulStatsErrorsReceived: 0,
    backhaulStatsTimeStamp: '',
    backhaulStatsLastDataUplinkRate: 0,
    backhaulStatsSignalStrength: 0,
    radios: [
      MeshRadio(
        instancePath: 'Device.WiFi.DataElements.Network.Device.1.Radio.1.',
        bssList: [
          MeshBss(
            instancePath:
                'Device.WiFi.DataElements.Network.Device.1.Radio.1.BSS.1.',
            bssid: 'AA:BB:CC:DD:EE:01',
            ssid: 'HomeNetwork',
            stations: [
              MeshStation(
                instancePath:
                    'Device.WiFi.DataElements.Network.Device.1.Radio.1.BSS.1.STA.1.',
                macAddress: '11:22:33:44:55:01',
                signalStrength: 180,
              ),
              MeshStation(
                instancePath:
                    'Device.WiFi.DataElements.Network.Device.1.Radio.1.BSS.1.STA.2.',
                macAddress: '11:22:33:44:55:02',
                signalStrength: 160,
              ),
            ],
          ),
        ],
      ),
    ],
  );

  final slaveNode = MeshNode(
    instancePath: 'Device.WiFi.DataElements.Network.Device.2.',
    id: 'AA:BB:CC:DD:EE:02',
    manufacturerModel: 'MX5500',
    manufacturer: 'Linksys',
    serialNumber: 'SN67890',
    softwareVersion: '2.0.0',
    backhaulAlId: 'AA:BB:CC:DD:EE:01', // Has parent = slave node
    backhaulMacAddress: 'AA:BB:CC:DD:EE:02',
    backhaulMediaType: 'IEEE 802.11ax',
    backhaulPhyRate: 1200,
    multiApLastContactTime: '',
    multiApAssocIEEE1905DeviceRef: '',
    multiApEasyMeshAgentOperationMode: '',
    backhaulBackhaulDeviceId: 'AA:BB:CC:DD:EE:01',
    backhaulBackhaulMacAddress: 'AA:BB:CC:DD:EE:02',
    backhaulLinkType: 'Wi-Fi',
    backhaulMacAddressMultiAp: 'AA:BB:CC:DD:EE:01',
    backhaulStatsLastDataDownlinkRate: 600000,
    backhaulStatsPacketsSent: 1000,
    backhaulStatsPacketsReceived: 2000,
    backhaulStatsErrorsSent: 0,
    backhaulStatsErrorsReceived: 0,
    backhaulStatsTimeStamp: '2026-05-18T10:00:00Z',
    backhaulStatsLastDataUplinkRate: 500000,
    backhaulStatsSignalStrength: 180, // RCPI = 180 → RSSI = (180/2) - 110 = -20
    radios: [
      MeshRadio(
        instancePath: 'Device.WiFi.DataElements.Network.Device.2.Radio.1.',
        bssList: [
          MeshBss(
            instancePath:
                'Device.WiFi.DataElements.Network.Device.2.Radio.1.BSS.1.',
            bssid: 'AA:BB:CC:DD:EE:02',
            ssid: 'HomeNetwork',
            stations: [
              MeshStation(
                instancePath:
                    'Device.WiFi.DataElements.Network.Device.2.Radio.1.BSS.1.STA.1.',
                macAddress: '11:22:33:44:55:03',
                signalStrength: 140,
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // MeshTopologyBuilder.build
  // ---------------------------------------------------------------------------

  group('MeshTopologyBuilder.build', () {
    test('builds nodes from DataElementsNetwork', () {
      final network = DataElementsNetwork(items: [masterNode, slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      expect(result.nodes, hasLength(2));
      expect(result.nodes[0].deviceId, 'AA:BB:CC:DD:EE:01');
      expect(result.nodes[0].model, 'MR7500');
      expect(result.nodes[0].isMaster, isTrue);
      expect(result.nodes[1].deviceId, 'AA:BB:CC:DD:EE:02');
      expect(result.nodes[1].model, 'MX5500');
      expect(result.nodes[1].isMaster, isFalse);
    });

    test('builds client to node mapping from stations', () {
      final network = DataElementsNetwork(items: [masterNode, slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      expect(result.clientToNodeMap, hasLength(3));
      expect(result.clientToNodeMap['11:22:33:44:55:01'], 'AA:BB:CC:DD:EE:01');
      expect(result.clientToNodeMap['11:22:33:44:55:02'], 'AA:BB:CC:DD:EE:01');
      expect(result.clientToNodeMap['11:22:33:44:55:03'], 'AA:BB:CC:DD:EE:02');
    });

    test('converts RCPI to RSSI for backhaul signal strength', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      final slave = result.nodes[0] as SlaveNode;
      // RCPI = 180 → RSSI = (180/2) - 110 = -20 dBm
      expect(slave.backhaul.signalStrength, -20);
    });

    test('includes backhaul uplink rate when available', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      final slave = result.nodes[0] as SlaveNode;
      expect(slave.backhaul.uplinkRate, 500000);
    });

    test('excludes backhaul stats when includeBackhaulStats is false', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result =
          MeshTopologyBuilder.build(network, includeBackhaulStats: false);

      final slave = result.nodes[0] as SlaveNode;
      expect(slave.backhaul.signalStrength, isNull);
      expect(slave.backhaul.uplinkRate, isNull);
      // Other backhaul fields are still included
      expect(slave.backhaul.mediaType, 'IEEE 802.11ax');
      expect(slave.backhaul.phyRate, 1200);
    });

    test('normalizes MAC addresses to uppercase', () {
      final nodeWithLowercase = MeshNode(
        instancePath: 'Device.WiFi.DataElements.Network.Device.1.',
        id: 'aa:bb:cc:dd:ee:ff',
        manufacturerModel: 'MR7500',
        manufacturer: '',
        serialNumber: '',
        softwareVersion: '',
        backhaulAlId: '',
        backhaulMacAddress: '',
        backhaulMediaType: '',
        backhaulPhyRate: 0,
        multiApLastContactTime: '',
        multiApAssocIEEE1905DeviceRef: '',
        multiApEasyMeshAgentOperationMode: '',
        backhaulBackhaulDeviceId: '',
        backhaulBackhaulMacAddress: '',
        backhaulLinkType: '',
        backhaulMacAddressMultiAp: '',
        backhaulStatsLastDataDownlinkRate: 0,
        backhaulStatsPacketsSent: 0,
        backhaulStatsPacketsReceived: 0,
        backhaulStatsErrorsSent: 0,
        backhaulStatsErrorsReceived: 0,
        backhaulStatsTimeStamp: '',
        backhaulStatsLastDataUplinkRate: 0,
        backhaulStatsSignalStrength: 0,
        radios: [
          MeshRadio(
            instancePath: 'Device.WiFi.DataElements.Network.Device.1.Radio.1.',
            bssList: [
              MeshBss(
                instancePath:
                    'Device.WiFi.DataElements.Network.Device.1.Radio.1.BSS.1.',
                bssid: 'aa:bb:cc:dd:ee:ff',
                ssid: 'Test',
                stations: [
                  MeshStation(
                    instancePath: 'sta.1.',
                    macAddress: 'aa:bb:cc:11:22:33',
                    signalStrength: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final network = DataElementsNetwork(items: [nodeWithLowercase]);
      final result = MeshTopologyBuilder.build(network);

      expect(result.nodes[0].deviceId, 'AA:BB:CC:DD:EE:FF');
      expect(result.clientToNodeMap['AA:BB:CC:11:22:33'], 'AA:BB:CC:DD:EE:FF');
    });

    test('uses instancePath as deviceId when id is empty', () {
      final nodeWithEmptyId = MeshNode(
        instancePath: 'Device.WiFi.DataElements.Network.Device.1.',
        id: '',
        manufacturerModel: 'MR7500',
        manufacturer: '',
        serialNumber: '',
        softwareVersion: '',
        backhaulAlId: '',
        backhaulMacAddress: '',
        backhaulMediaType: '',
        backhaulPhyRate: 0,
        multiApLastContactTime: '',
        multiApAssocIEEE1905DeviceRef: '',
        multiApEasyMeshAgentOperationMode: '',
        backhaulBackhaulDeviceId: '',
        backhaulBackhaulMacAddress: '',
        backhaulLinkType: '',
        backhaulMacAddressMultiAp: '',
        backhaulStatsLastDataDownlinkRate: 0,
        backhaulStatsPacketsSent: 0,
        backhaulStatsPacketsReceived: 0,
        backhaulStatsErrorsSent: 0,
        backhaulStatsErrorsReceived: 0,
        backhaulStatsTimeStamp: '',
        backhaulStatsLastDataUplinkRate: 0,
        backhaulStatsSignalStrength: 0,
        radios: [],
      );

      final network = DataElementsNetwork(items: [nodeWithEmptyId]);
      final result = MeshTopologyBuilder.build(network);

      expect(result.nodes[0].deviceId,
          'Device.WiFi.DataElements.Network.Device.1.');
    });

    test('returns empty result for empty network', () {
      final network = DataElementsNetwork(items: []);

      final result = MeshTopologyBuilder.build(network);

      expect(result.isEmpty, isTrue);
      expect(result.nodes, isEmpty);
      expect(result.clientToNodeMap, isEmpty);
    });

    test('preserves DataElements enrichment fields', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      final slave = result.nodes[0] as SlaveNode;
      expect(slave.instancePath, 'Device.WiFi.DataElements.Network.Device.2.');
      expect(slave.backhaul.backhaulAlId, 'AA:BB:CC:DD:EE:01');
      expect(slave.backhaul.backhaulMacAddress, 'AA:BB:CC:DD:EE:02');
    });

    test('includes backhaulLinkType', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      final slave = result.nodes[0] as SlaveNode;
      expect(slave.backhaul.linkType, 'Wi-Fi');
    });

    test('includes backhaulDownlinkRate', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      final slave = result.nodes[0] as SlaveNode;
      expect(slave.backhaul.downlinkRate, 600000);
    });

    test('includes backhaulParentDeviceId', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      final slave = result.nodes[0] as SlaveNode;
      expect(slave.backhaul.parentNodeId, 'AA:BB:CC:DD:EE:01');
    });

    test('includes backhaulParentBssid', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      final slave = result.nodes[0] as SlaveNode;
      expect(slave.backhaul.parentBssid, 'AA:BB:CC:DD:EE:01');
    });

    test('excludes backhaulDownlinkRate when includeBackhaulStats is false',
        () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result =
          MeshTopologyBuilder.build(network, includeBackhaulStats: false);

      final slave = result.nodes[0] as SlaveNode;
      expect(slave.backhaul.downlinkRate, isNull);
      // Non-stats fields are still included
      expect(slave.backhaul.linkType, 'Wi-Fi');
      expect(slave.backhaul.parentNodeId, 'AA:BB:CC:DD:EE:01');
    });

    test('master node has no backhaul fields', () {
      final network = DataElementsNetwork(items: [masterNode]);

      final result = MeshTopologyBuilder.build(network);

      expect(result.nodes[0], isA<MasterNode>());
      expect(result.nodes[0].isMaster, isTrue);
    });

    test('populates clientBandSsidMap when bssidToBandMap is provided', () {
      final nodeWithClient = MeshNode(
        instancePath: 'Device.WiFi.DataElements.Network.Device.1.',
        id: 'AA:BB:CC:DD:EE:01',
        manufacturerModel: 'TestRouter',
        manufacturer: 'Test',
        serialNumber: 'SN123',
        softwareVersion: '1.0.0',
        backhaulAlId: '',
        backhaulMacAddress: '',
        backhaulMediaType: '',
        backhaulPhyRate: 0,
        multiApLastContactTime: '',
        multiApAssocIEEE1905DeviceRef: '',
        multiApEasyMeshAgentOperationMode: '',
        backhaulBackhaulDeviceId: '',
        backhaulBackhaulMacAddress: '',
        backhaulLinkType: '',
        backhaulMacAddressMultiAp: '',
        backhaulStatsLastDataDownlinkRate: 0,
        backhaulStatsPacketsSent: 0,
        backhaulStatsPacketsReceived: 0,
        backhaulStatsErrorsSent: 0,
        backhaulStatsErrorsReceived: 0,
        backhaulStatsTimeStamp: '',
        backhaulStatsLastDataUplinkRate: 0,
        backhaulStatsSignalStrength: 0,
        radios: [
          MeshRadio(
            instancePath: 'Device.WiFi.DataElements.Network.Device.1.Radio.1.',
            bssList: [
              MeshBss(
                instancePath:
                    'Device.WiFi.DataElements.Network.Device.1.Radio.1.BSS.1.',
                bssid: '11:22:33:44:55:01',
                ssid: 'TestNetwork',
                stations: [
                  MeshStation(
                    instancePath:
                        'Device.WiFi.DataElements.Network.Device.1.Radio.1.BSS.1.STA.1.',
                    macAddress: 'aa:bb:cc:dd:ee:ff',
                    signalStrength: 140,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final network = DataElementsNetwork(items: [nodeWithClient]);
      final bssidToBandMap = {'11:22:33:44:55:01': '5GHz'};

      final result = MeshTopologyBuilder.build(
        network,
        bssidToBandMap: bssidToBandMap,
      );

      expect(result.clientBandSsidMap, isNotEmpty);
      expect(result.clientBandSsidMap['AA:BB:CC:DD:EE:FF']?.band, '5GHz');
      expect(
          result.clientBandSsidMap['AA:BB:CC:DD:EE:FF']?.ssid, 'TestNetwork');
    });

    test('clientBandSsidMap has SSID but empty band without bssidToBandMap',
        () {
      final network = DataElementsNetwork(items: [masterNode]);

      final result = MeshTopologyBuilder.build(network);

      // Has SSID from BSS but no band since no bssidToBandMap provided
      expect(result.clientBandSsidMap, isNotEmpty);
      // Band should be empty string
      for (final entry in result.clientBandSsidMap.values) {
        expect(entry.band, isEmpty);
        expect(entry.ssid, 'HomeNetwork');
      }
    });
  });
}
