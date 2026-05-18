import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
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

      // RCPI = 180 → RSSI = (180/2) - 110 = -20 dBm
      expect(result.nodes[0].backhaulSignalStrength, -20);
    });

    test('includes backhaul uplink rate when available', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result = MeshTopologyBuilder.build(network);

      expect(result.nodes[0].backhaulUplinkRate, 500000);
    });

    test('excludes backhaul stats when includeBackhaulStats is false', () {
      final network = DataElementsNetwork(items: [slaveNode]);

      final result =
          MeshTopologyBuilder.build(network, includeBackhaulStats: false);

      expect(result.nodes[0].backhaulSignalStrength, isNull);
      expect(result.nodes[0].backhaulUplinkRate, isNull);
      // Other backhaul fields are still included
      expect(result.nodes[0].backhaulMediaType, 'IEEE 802.11ax');
      expect(result.nodes[0].backhaulPhyRate, 1200);
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

      expect(
          result.nodes[0].deviceId, 'Device.WiFi.DataElements.Network.Device.1.');
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

      expect(result.nodes[0].instancePath,
          'Device.WiFi.DataElements.Network.Device.2.');
      expect(result.nodes[0].backhaulAlId, 'AA:BB:CC:DD:EE:01');
      expect(result.nodes[0].backhaulMacAddress, 'AA:BB:CC:DD:EE:02');
    });
  });
}
