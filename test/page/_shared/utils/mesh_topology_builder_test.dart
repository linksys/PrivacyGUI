import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_topology_builder.dart';

import '../../../mocks/test_data/data_elements_test_data.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Test data
  // ---------------------------------------------------------------------------

  // No `linkType` and no parent — which is how the builder now recognises the
  // controller (`hasMeshBackhaulLink`). It used to be an empty `BackhaulALID`, a
  // field prplMesh does not have (#1555).
  final masterNode = DataElementsTestData.node(
    instance: '1',
    id: 'AA:BB:CC:DD:EE:01',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'SN12345',
    softwareVersion: '2.0.0',
    bssList: [
      DataElementsTestData.bss(
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

  final slaveNode = DataElementsTestData.node(
    instance: '2',
    id: 'AA:BB:CC:DD:EE:02',
    model: 'MX5500',
    manufacturer: 'Linksys',
    serialNumber: 'SN67890',
    softwareVersion: '2.0.0',
    linkType: 'Wi-Fi',
    parentDeviceId: 'AA:BB:CC:DD:EE:01',
    backhaulStaMac: 'AA:BB:CC:DD:EE:02',
    rcpi: 180, // RCPI = 180 → RSSI = (180/2) - 110 = -20
    uplinkRate: 500000,
    downlinkRate: 600000,
    statsTimeStamp: DateTime.parse('2026-05-18T10:00:00Z'),
    bssList: [
      DataElementsTestData.bss(
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

    test('a zero rate is no rate, not a rate of zero (#1442 AC3)', () {
      // The shape every bench read has so far: `Backhaul.Stats` members default
      // to `= 0` in prplMesh's ODL and the controller row reports exactly that,
      // with `Stats.TimeStamp` at the epoch. So this is not an edge case, it is
      // the common case — and without the `> 0` guard the node-detail card
      // renders `0 Mbps` beside a qualifier explaining what the 0 means.
      //
      // The guard was already there and had no test. #1442 AC3 says not to
      // regress it, which nothing could have caught: the view's `!= null` check
      // is the second half of the same rule and would happily print a 0.
      final network = DataElementsNetwork(items: [
        DataElementsTestData.node(
          instance: '2',
          id: 'AA:BB:CC:DD:EE:02',
          linkType: 'Wi-Fi',
          parentDeviceId: 'AA:BB:CC:DD:EE:01',
          uplinkRate: 0,
          downlinkRate: 0,
        ),
      ]);

      final slave = MeshTopologyBuilder.build(network).nodes[0] as SlaveNode;
      expect(slave.backhaul.uplinkRate, isNull);
      expect(slave.backhaul.downlinkRate, isNull);
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
      final nodeWithLowercase = DataElementsTestData.node(
        instance: '1',
        id: 'aa:bb:cc:dd:ee:ff',
        model: 'MR7500',
        bssList: [
          DataElementsTestData.bss(
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
      final nodeWithEmptyId = DataElementsTestData.node(
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
        DataElementsTestData.node(
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
        DataElementsTestData.node(
          instance: '2',
          id: 'AA:BB:CC:DD:EE:02',
          linkType: 'Wi-Fi',
          parentDeviceId: '   ',
        ),
      ]);

      final slave = MeshTopologyBuilder.build(network).nodes[0] as SlaveNode;
      expect(slave.backhaul.parentNodeId, isNull);
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
        DataElementsTestData.node(
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

    test('an all-zero parent ID on a genuine agent is no parent (#1555)', () {
      // The sibling of the row above, on a node that really is an agent: there
      // the sentinel must not make the controller a slave, here it must not give
      // an agent a parent nothing can resolve — `usp_topology_builder` renders
      // that node attached to the gateway and logs the lost hop (#1441).
      //
      // This test used to assert a `parentBssid` beside it, read from
      // `Backhaul.MACAddress`. That field is the node's **own** station MAC, not
      // its parent's BSSID (prplMesh's `device.odl` documents `ServingBSSID` as
      // the parent's), and it had no consumer on either side, so #1441 AC4
      // deleted it. The parent-ID half is what the sentinel guard is for and it
      // stays.
      final network = DataElementsNetwork(items: [
        DataElementsTestData.node(
          instance: '2',
          id: 'AA:BB:CC:DD:EE:02',
          linkType: 'Wi-Fi',
          parentDeviceId: '00:00:00:00:00:00',
        ),
      ]);

      final slave = MeshTopologyBuilder.build(network).nodes[0] as SlaveNode;
      expect(slave.backhaul.parentNodeId, isNull);
      expect(slave.isMaster, isFalse, reason: 'still an agent, by LinkType');
    });

    test('padded identity fields arrive trimmed (#1555)', () {
      // `_identity` is `nonEmpty(...) ?? ''` since #1555, and `nonEmpty` trims.
      // That matters one layer up: `MeshNetworkBuilder` merges these against
      // `system_info` with `??`, where a whitespace-only value is non-empty and
      // would *win* over the real one from the other source.
      final network = DataElementsNetwork(items: [
        DataElementsTestData.node(
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
      final nodeWithClient = DataElementsTestData.node(
        instance: '1',
        id: 'AA:BB:CC:DD:EE:01',
        model: 'TestRouter',
        manufacturer: 'Test',
        serialNumber: 'SN123',
        softwareVersion: '1.0.0',
        bssList: [
          DataElementsTestData.bss(
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

  // ---------------------------------------------------------------------------
  // Wired-client attribution from Interface.{j}.Neighbor.{k} (#1688 item 2)
  // ---------------------------------------------------------------------------
  //
  // A non-1905 neighbor is a MAC in the node's bridge forwarding table — "seen
  // through this port", not "plugged into this node". The rules are those of
  // linksys/usp_framework's data_elements_interfaces.yaml and FWDEV#208 rule 2.

  group('MeshTopologyBuilder.wiredClientAttribution', () {
    const controller = '74:12:13:21:56:3a';
    const agent = 'aa:bb:cc:dd:ee:02';
    const wiredMac = '00:e0:4c:68:08:2d'; // a Mac on a cable, as measured
    const phoneMac = 'dc:52:85:5d:d0:7c'; // a Wi-Fi STA, as measured

    final p1 = DataElementsTestData.nodePath('1');
    final p2 = DataElementsTestData.nodePath('2');

    final network = DataElementsTestData.network([
      DataElementsTestData.node(instance: '1', id: controller),
      DataElementsTestData.node(
        instance: '2',
        id: agent,
        linkType: 'Wi-Fi',
        parentDeviceId: controller,
        backhaulStaMac: 'aa:bb:cc:dd:ee:12',
        backhaulMac: 'aa:bb:cc:dd:ee:22',
        backhaulMultiApMac: 'aa:bb:cc:dd:ee:32',
        bssList: [
          DataElementsTestData.bss(p2, bssid: 'aa:bb:cc:dd:ee:42'),
        ],
      ),
    ]);

    ({Map<String, String> byNode, Set<String> ambiguous}) attribute(
      List<({String id, bool? isIeee1905})> controllerNeighbors, {
      List<({String id, bool? isIeee1905})> agentNeighbors = const [],
      Set<String> wifiStations = const {},
    }) =>
        MeshTopologyBuilder.wiredClientAttribution(
          network: network,
          interfaces: DataElementsTestData.interfaces([
            DataElementsTestData.nodeInterfaces(
              instance: '1',
              id: controller,
              interfaces: [
                DataElementsTestData.interface(p1,
                    index: 4,
                    macAddress: controller,
                    mediaType: 'IEEE_802_3AB_GIGABIT_ETHERNET',
                    neighbors: controllerNeighbors),
              ],
            ),
            DataElementsTestData.nodeInterfaces(
              instance: '2',
              id: agent,
              interfaces: [
                DataElementsTestData.interface(p2,
                    index: 1,
                    macAddress: 'aa:bb:cc:dd:ee:52',
                    mediaType: 'IEEE_802_3AB_GIGABIT_ETHERNET',
                    neighbors: agentNeighbors),
              ],
            ),
          ]),
          wifiStations: wifiStations,
        );

    test('a wired client one node lists goes under that node', () {
      final result = attribute([(id: wiredMac, isIeee1905: false)]);

      expect(result.byNode, {
        wiredMac.toUpperCase(): controller.toUpperCase(),
      });
      expect(result.ambiguous, isEmpty);
    });

    // FWDEV#208 rule 2: a client behind a switch both nodes reach is seen
    // through both uplinks, and the app cannot pick one.
    test('a MAC two nodes list is ambiguous, not attributed', () {
      final result = attribute(
        [(id: wiredMac, isIeee1905: false)],
        agentNeighbors: [(id: wiredMac, isIeee1905: false)],
      );

      expect(result.byNode, isEmpty);
      expect(result.ambiguous, {wiredMac.toUpperCase()});
    });

    // prplMesh removes only the AL MAC. On the bench 4 of 5 non-1905
    // neighbors were the nodes' own bridges, backhaul STAs and BSSes.
    test('drops every MAC a mesh node owns', () {
      final result = attribute([
        (id: agent, isIeee1905: false), // AL MAC / Device.{i}.ID
        (id: 'aa:bb:cc:dd:ee:12', isIeee1905: false), // bSTA
        (id: 'aa:bb:cc:dd:ee:22', isIeee1905: false), // BackhaulMACAddress
        (id: 'aa:bb:cc:dd:ee:32', isIeee1905: false), // Backhaul.MACAddress
        (id: 'aa:bb:cc:dd:ee:42', isIeee1905: false), // a BSSID
        (id: 'aa:bb:cc:dd:ee:52', isIeee1905: false), // Interface.MACAddress
        (id: wiredMac, isIeee1905: false),
      ]);

      expect(result.byNode.keys, [wiredMac.toUpperCase()]);
    });

    // Measured on 2.0.3.26101482: the controller's Wi-Fi Interface lists the
    // iPhone as a non-1905 neighbor. It is a BSS.STA entry too, and the
    // station entry wins.
    test('a Wi-Fi station is not a wired client', () {
      final result = attribute(
        [(id: phoneMac, isIeee1905: false)],
        wifiStations: {phoneMac.toUpperCase()},
      );

      expect(result.byNode, isEmpty);
      expect(result.ambiguous, isEmpty);
    });

    test('a 1905 neighbor or an unknown row attributes nothing', () {
      final result = attribute([
        (id: '11:22:33:44:55:01', isIeee1905: true),
        (id: '11:22:33:44:55:02', isIeee1905: null),
      ]);

      expect(result.byNode, isEmpty);
      expect(result.ambiguous, isEmpty);
    });

    test('the all-zero and empty neighbor IDs are not clients', () {
      final result = attribute([
        (id: '00:00:00:00:00:00', isIeee1905: false),
        (id: '', isIeee1905: false),
      ]);

      expect(result.byNode, isEmpty);
    });

    // The Interface subtree is a separate Get. An agent that left between the
    // two reads is not built, so a client only it lists has no node to go to:
    // it is no evidence, and stays on the master rather than becoming an
    // orphan pointing at a missing node.
    test('a client listed only by a node the network read lacks is dropped',
        () {
      final result = MeshTopologyBuilder.wiredClientAttribution(
        network: DataElementsTestData.network([
          DataElementsTestData.node(instance: '1', id: controller),
        ]),
        interfaces: DataElementsTestData.interfaces([
          DataElementsTestData.nodeInterfaces(
            instance: '2',
            id: agent,
            interfaces: [
              DataElementsTestData.interface(p2,
                  index: 1,
                  macAddress: 'aa:bb:cc:dd:ee:52',
                  neighbors: [(id: wiredMac, isIeee1905: false)]),
            ],
          ),
        ]),
        wifiStations: const {},
      );

      expect(result.byNode, isEmpty);
      expect(result.ambiguous, isEmpty);
    });

    test('build() carries the attribution onto MeshTopologyInfo', () {
      final info = MeshTopologyBuilder.build(
        network,
        interfaces: DataElementsTestData.interfaces([
          DataElementsTestData.nodeInterfaces(
            instance: '1',
            id: controller,
            interfaces: [
              DataElementsTestData.interface(p1,
                  index: 4,
                  macAddress: controller,
                  neighbors: [(id: wiredMac, isIeee1905: false)]),
            ],
          ),
        ]),
      );

      expect(info.wiredClientToNodeMap,
          {wiredMac.toUpperCase(): controller.toUpperCase()});
    });

    // A controller without the Interface object, or a failed read: no wired
    // client is attributed, and the topology is otherwise unchanged.
    test('build() without interfaces attributes no wired client', () {
      final info = MeshTopologyBuilder.build(network);

      expect(info.wiredClientToNodeMap, isEmpty);
      expect(info.ambiguousWiredClients, isEmpty);
      expect(info.nodes, hasLength(2));
    });
  });

  // #1688 review (W2). The master is the node with no backhaul link unless
  // ControllerID says otherwise. An agent whose backhaul is not filled in yet
  // also has no link, so without ControllerID it was a second master and,
  // since #1688, dropped from the topology.
  group('MeshTopologyBuilder.build — the controller (ControllerID)', () {
    const controller = '74:12:13:21:56:3a';
    const agent = 'aa:bb:cc:dd:ee:02';

    // The agent has no BackhaulDeviceID and no LinkType: the shape an agent
    // has while it is still joining.
    final network = DataElementsTestData.network([
      DataElementsTestData.node(instance: '1', id: controller),
      DataElementsTestData.node(instance: '2', id: agent),
    ]);

    test('without ControllerID an agent with no backhaul is a second master',
        () {
      final info = MeshTopologyBuilder.build(network);

      expect(info.nodes.whereType<MasterNode>(), hasLength(2));
      expect(info.nodes.slaves, isEmpty);
    });

    test('with ControllerID every other node is a slave', () {
      final info = MeshTopologyBuilder.build(network, controllerId: controller);

      expect(info.nodes.whereType<MasterNode>().single.deviceId,
          controller.toUpperCase());
      expect(info.nodes.slaves.map((s) => s.deviceId), [agent.toUpperCase()]);
    });

    // ControllerID and Device.{i}.ID are separate leaves.
    test('ControllerID matches regardless of MAC spelling', () {
      final info =
          MeshTopologyBuilder.build(network, controllerId: '74-12-13-21-56-3A');

      expect(info.nodes.slaves, hasLength(1));
    });

    // A ControllerID that names no node in this read must not demote the real
    // controller: the backhaul rule decides instead.
    test('a ControllerID naming no listed node is ignored', () {
      final info =
          MeshTopologyBuilder.build(network, controllerId: '11:22:33:44:55:66');

      expect(info.nodes.whereType<MasterNode>(), hasLength(2));
    });

    test('a blank or all-zero ControllerID is ignored', () {
      for (final id in ['', '  ', '00:00:00:00:00:00']) {
        final info = MeshTopologyBuilder.build(network, controllerId: id);
        expect(info.nodes.whereType<MasterNode>(), hasLength(2),
            reason: '"$id" is not a controller');
      }
    });
  });
}
