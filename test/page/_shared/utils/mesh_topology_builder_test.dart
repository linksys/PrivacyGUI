import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_topology_builder.dart';

/// One radio, optionally carrying the bSTA MAC and a fronthaul BSS.
///
/// [backhaulStaMac] is where the node's own backhaul MAC lives since #1555. It
/// used to be the node-level `BackhaulMACAddress`, which FL-WRT 2.0 does not
/// define at all.
MeshRadio _radio(
  String nodeInstance, {
  String? backhaulStaMac,
  List<MeshBss> bssList = const [],
}) =>
    MeshRadio(
      instancePath: '${nodeInstance}Radio.1.',
      backhaulStaMacAddress: backhaulStaMac,
      currentOperatingClassProfiles: const [],
      bssList: bssList,
    );

/// One fronthaul BSS with [stations] attached, keyed off the node's path.
MeshBss _bss(
  String nodeInstance, {
  required String bssid,
  required String ssid,
  List<({String mac, int rcpi})> stations = const [],
}) =>
    MeshBss(
      instancePath: '${nodeInstance}Radio.1.BSS.1.',
      bssid: bssid,
      ssid: ssid,
      stations: [
        for (var i = 0; i < stations.length; i++)
          MeshStation(
            instancePath: '${nodeInstance}Radio.1.BSS.1.STA.${i + 1}.',
            macAddress: stations[i].mac,
            signalStrengthRcpi: stations[i].rcpi,
          ),
      ],
    );

/// A [MeshNode] with only the fields a test actually names.
///
/// This file used to spell the whole field list out five times. #1555 removed
/// five of those fields and renamed a sixth, which turned a one-line behaviour
/// change into 42 compile errors here — so the schema is tracked in one place
/// now, and a test that does not care about backhaul says so by omission.
///
/// **File-local on purpose, for now.** Constitution Article I §1.6.2 wants
/// codegen fixtures centralised in `test/mocks/test_data/`, and there has never
/// been a DataElements builder there to import. Two other files carry their own
/// copy of this helper — `usp_instant_privacy_service_test.dart` (`_meshNode`)
/// and `mesh_backhaul_link_test.dart` (`_node`) — each trimmed to the fields its
/// own subject reads. Promote the three into one
/// `test/mocks/test_data/data_elements_test_data.dart` when a **fourth** file
/// needs a `MeshNode`, not before: a shared builder written for three known
/// callers is guesswork about the fourth, and the version that survives is the
/// one an actual fourth caller shapes.
MeshNode _node({
  required String instance,
  required String id,
  String? model,
  String? manufacturer,
  String? serialNumber,
  String? softwareVersion,
  String? linkType,
  String? parentDeviceId,
  String? parentBssid,
  String? backhaulStaMac,
  int? rcpi,
  int? uplinkRate,
  int? downlinkRate,
  DateTime? lastContactTime,
  DateTime? statsTimeStamp,
  List<MeshBss> bssList = const [],
}) {
  final path = 'Device.WiFi.DataElements.Network.Device.$instance.';
  return MeshNode(
    instancePath: path,
    id: id,
    manufacturerModel: model,
    manufacturer: manufacturer,
    serialNumber: serialNumber,
    softwareVersion: softwareVersion,
    multiApLastContactTime: lastContactTime,
    multiApEasyMeshAgentOperationMode: '',
    backhaulLinkType: linkType,
    backhaulBackhaulDeviceId: parentDeviceId,
    backhaulBackhaulMacAddress: backhaulStaMac,
    backhaulMacAddressMultiAp: parentBssid,
    backhaulStatsLastDataDownlinkRate: downlinkRate,
    backhaulStatsLastDataUplinkRate: uplinkRate,
    backhaulStatsSignalStrengthRcpi: rcpi,
    backhaulStatsPacketsSent: 0,
    backhaulStatsPacketsReceived: 0,
    backhaulStatsErrorsSent: 0,
    backhaulStatsErrorsReceived: 0,
    backhaulStatsTimeStamp: statsTimeStamp,
    radios: [_radio(path, backhaulStaMac: backhaulStaMac, bssList: bssList)],
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Test data
  // ---------------------------------------------------------------------------

  // No `linkType` and no parent — which is how the builder now recognises the
  // controller (`hasMeshBackhaulLink`). It used to be an empty `BackhaulALID`, a
  // field prplMesh does not have (#1555).
  final masterNode = _node(
    instance: '1',
    id: 'AA:BB:CC:DD:EE:01',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'SN12345',
    softwareVersion: '2.0.0',
    bssList: [
      _bss(
        'Device.WiFi.DataElements.Network.Device.1.',
        bssid: 'AA:BB:CC:DD:EE:01',
        ssid: 'HomeNetwork',
        stations: const [
          (mac: '11:22:33:44:55:01', rcpi: 180),
          (mac: '11:22:33:44:55:02', rcpi: 160),
        ],
      ),
    ],
  );

  final slaveNode = _node(
    instance: '2',
    id: 'AA:BB:CC:DD:EE:02',
    model: 'MX5500',
    manufacturer: 'Linksys',
    serialNumber: 'SN67890',
    softwareVersion: '2.0.0',
    linkType: 'Wi-Fi',
    parentDeviceId: 'AA:BB:CC:DD:EE:01',
    parentBssid: 'AA:BB:CC:DD:EE:01',
    backhaulStaMac: 'AA:BB:CC:DD:EE:02',
    rcpi: 180, // RCPI = 180 → RSSI = (180/2) - 110 = -20
    uplinkRate: 500000,
    downlinkRate: 600000,
    statsTimeStamp: DateTime.parse('2026-05-18T10:00:00Z'),
    bssList: [
      _bss(
        'Device.WiFi.DataElements.Network.Device.2.',
        bssid: 'AA:BB:CC:DD:EE:02',
        ssid: 'HomeNetwork',
        stations: const [(mac: '11:22:33:44:55:03', rcpi: 140)],
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
      expect(slave.backhaul.linkType, 'Wi-Fi');
      expect(slave.backhaul.backhaulMacAddress, 'AA:BB:CC:DD:EE:02');
    });

    test('normalizes MAC addresses to uppercase', () {
      final nodeWithLowercase = _node(
        instance: '1',
        id: 'aa:bb:cc:dd:ee:ff',
        model: 'MR7500',
        bssList: [
          _bss(
            'Device.WiFi.DataElements.Network.Device.1.',
            bssid: 'aa:bb:cc:dd:ee:ff',
            ssid: 'Test',
            stations: const [(mac: 'aa:bb:cc:11:22:33', rcpi: 0)],
          ),
        ],
      );

      final network = DataElementsNetwork(items: [nodeWithLowercase]);
      final result = MeshTopologyBuilder.build(network);

      expect(result.nodes[0].deviceId, 'AA:BB:CC:DD:EE:FF');
      expect(result.clientToNodeMap['AA:BB:CC:11:22:33'], 'AA:BB:CC:DD:EE:FF');
    });

    test('uses instancePath as deviceId when id is empty', () {
      final nodeWithEmptyId = _node(
        instance: '1',
        id: '',
        model: 'MR7500',
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
      // `backhaulMacAddress` is the bSTA's own MAC, read off
      // `Radio.{i}.BackhaulSta.MACAddress` since #1555 — the node-level
      // `BackhaulMACAddress` and `BackhaulALID` it used to come from are not in
      // the prplMesh schema. The Wi-Fi performance card filters mesh bSTAs out
      // of the client list with this, and the field surviving its source is what
      // made that a silent break rather than a compile error.
      expect(slave.backhaul.backhaulMacAddress, 'AA:BB:CC:DD:EE:02');
    });

    test('an all-zero bSTA MAC is no MAC, not an address (#1555)', () {
      // What a radio with no backhaul station reports — measured, and the state
      // every radio of an Ethernet-backhauled node is in. Taking it at face value
      // hands the Wi-Fi performance card a filter MAC that matches nothing, and
      // `UspInstantPrivacyService` an allow-list entry that matches nothing; both
      // call `isUnsetMac` so they cannot diverge on it.
      final network = DataElementsNetwork(items: [
        _node(
          instance: '2',
          id: 'AA:BB:CC:DD:EE:02',
          linkType: 'Ethernet',
          parentDeviceId: 'AA:BB:CC:DD:EE:01',
          backhaulStaMac: '00:00:00:00:00:00',
        ),
      ]);

      final slave = MeshTopologyBuilder.build(network).nodes[0] as SlaveNode;
      expect(slave.backhaul.backhaulMacAddress, isNull);
    });

    test('a blank parent ID is no parent, not an empty one (#1555)', () {
      // Reachable: the node qualifies as an agent on its `LinkType` alone, so a
      // `BackhaulDeviceID` firmware left blank still reaches `BackhaulInfo`.
      // Passing `''` through instead of null gives the node a parent it can
      // never resolve, which `usp_topology_builder` then renders as an orphan.
      // `nonEmpty` is what prevents it, shared with `UnifiedDiagnosticsService`
      // so the two graders cannot disagree about whether this node has a parent.
      final network = DataElementsNetwork(items: [
        _node(
          instance: '2',
          id: 'AA:BB:CC:DD:EE:02',
          linkType: 'Wi-Fi',
          parentDeviceId: '   ',
          parentBssid: '',
        ),
      ]);

      final slave = MeshTopologyBuilder.build(network).nodes[0] as SlaveNode;
      expect(slave.backhaul.parentNodeId, isNull);
      expect(slave.backhaul.parentBssid, isNull);
      expect(slave.isMaster, isFalse, reason: 'still an agent, by LinkType');
    });

    test(
        'an all-zero parent ID does not turn the controller into an agent '
        '(#1555)', () {
      // The same sentinel as the bSTA MAC above, on a sibling field of the same
      // `MultiAPDevice.Backhaul` object — and this one is the field the
      // controller/agent decision keys on. Read raw it builds the gateway as a
      // `SlaveNode` whose parent is an address nothing resolves, leaving the
      // topology with no root at all.
      final network = DataElementsNetwork(items: [
        _node(
          instance: '1',
          id: 'AA:BB:CC:DD:EE:01',
          model: 'MR7500',
          parentDeviceId: '00:00:00:00:00:00',
        ),
      ]);

      final node = MeshTopologyBuilder.build(network).nodes[0];
      expect(node, isA<MasterNode>());
      expect(node.isMaster, isTrue);
    });

    test('an all-zero parent BSSID is no BSSID (#1555)', () {
      // A genuine agent whose parent fields firmware filled with the sentinel.
      // It stays an agent — `LinkType` decides that — but neither MAC may reach
      // the model, or the backhaul card prints `00:00:00:00:00:00` as the AP it
      // is attached to.
      final network = DataElementsNetwork(items: [
        _node(
          instance: '2',
          id: 'AA:BB:CC:DD:EE:02',
          linkType: 'Wi-Fi',
          parentDeviceId: '00:00:00:00:00:00',
          parentBssid: '00:00:00:00:00:00',
        ),
      ]);

      final slave = MeshTopologyBuilder.build(network).nodes[0] as SlaveNode;
      expect(slave.backhaul.parentNodeId, isNull);
      expect(slave.backhaul.parentBssid, isNull);
      expect(slave.isMaster, isFalse, reason: 'still an agent, by LinkType');
    });

    test('padded identity fields arrive trimmed (#1555)', () {
      // `_identity` is `nonEmpty(...) ?? ''` since #1555, and `nonEmpty` trims.
      // That matters one layer up: `MeshNetworkBuilder` merges these against
      // `system_info` with `??`, where a whitespace-only value is non-empty and
      // would *win* over the real one from the other source.
      final network = DataElementsNetwork(items: [
        _node(
          instance: '1',
          id: 'AA:BB:CC:DD:EE:01',
          model: '  MR7500 ',
          manufacturer: ' Linksys',
          serialNumber: '   ',
          softwareVersion: '\t2.0.0\n',
        ),
      ]);

      final node = MeshTopologyBuilder.build(network).nodes[0];
      expect(node.model, 'MR7500');
      expect(node.manufacturer, 'Linksys');
      expect(node.softwareVersion, '2.0.0');
      expect(node.serialNumber, isEmpty,
          reason: 'whitespace is absence, and absence has to arrive as `` '
              'because the identity fields are non-nullable');
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
      final nodeWithClient = _node(
        instance: '1',
        id: 'AA:BB:CC:DD:EE:01',
        model: 'TestRouter',
        manufacturer: 'Test',
        serialNumber: 'SN123',
        softwareVersion: '1.0.0',
        bssList: [
          _bss(
            'Device.WiFi.DataElements.Network.Device.1.',
            bssid: '11:22:33:44:55:01',
            ssid: 'TestNetwork',
            stations: const [(mac: 'aa:bb:cc:dd:ee:ff', rcpi: 140)],
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
