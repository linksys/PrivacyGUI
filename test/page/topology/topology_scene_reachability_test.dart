// Reachability guard for the topology scenes. Nothing is pumped here — this
// asserts that the composed states in `test/mocks/test_data/scenes/
// topology_scene_data.dart` describe trees the app can actually be in.
//
// #1472 was a scene that did not: `meshNetworkDevicesData` drew a live wired
// client hanging off an extender the renderer painted offline, on a solid green
// link. Not merely an odd picture — an impossible one. Measured on the M60TB-EU
// bench (FW `1.2.3.26072920`, two wireless slaves), a slave's liveness and its
// client list come out of the *same* match: `_findMatchingMeshNode` compares the
// last 12 hex of the Hosts `DeviceID` UUID against the DataElements node id, and
// that single result feeds both `dataElementsId` — all `SlaveNode.isOnline`
// reads — and the only key that can attach clients, since `clientToNodeMap` is
// keyed by the DataElements id (`mesh_topology_builder.dart`) while
// `Hosts.PhysAddress` is the node's Radio.1 BSSID, one above the AL-MAC
// (`80:69:1A:BB:46:95` vs `…:94`), so the `PhysAddress` lookup in
// `MeshNetworkBuilder` never hits on real hardware. No match therefore means
// offline **and** childless.
//
// The golden suite cannot be this guard. #1472's omission moved 4.2 % of the
// pixels at `phone480` but 1.4 % at `screen1080` and 0.9 % at `desktop1280`,
// both under `diffThreshold: 0.025` — the defect's footprint is laid out at a
// fixed size while the allowance grows with canvas area, so the wide widths are
// blind to it by construction (#1475). These assertions cost no pixels and hold
// at every width.
//
// One invariant is deliberately **not** asserted: `MeshNetworkBuilder` derives
// `livenessKnown: meshTopology.isNotEmpty` (`mesh_network_builder.dart:186`),
// and `meshNetworkDevicesData` pairs the default `livenessKnown: true` with the
// default empty `meshTopology`, which the builder would never emit. It is not
// asserted because no consumer behaves differently either way: with
// `livenessKnown` false the absent match says nothing and the slave is online,
// with it true the slave carries a `dataElementsId` and is online. Satisfying
// the assertion would mean building a `MeshTopologyInfo` fixture whose only
// effect is to satisfy the assertion.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';

import '../../mocks/test_data/scenes/topology_scene_data.dart';

/// Node-detail scenes that still pair an offline node with a client list, filed
/// as #1476. They are exempted rather than fixed here because the fix repaints
/// the liveness badge and one client list across 26 locales, i.e. a deliberate
/// baseline refresh in golden-ci — a coordinated action, where #1473 restores
/// 0.000 % and needs none.
///
/// Asserted by set equality below, so the list may only shrink: a new violator
/// and a name that no longer violates both fail the same test.
const _offlineWithClients = <String>{
  'slaveNodeWithDevices',
  'slaveNodeWithBackhaulTiming',
  'slaveNodeGlobalIpv6',
  'slaveNodeLinkLocalIpv6',
};

void main() {
  group('topology view scenes (DevicesData)', () {
    final scenes = <String, DevicesData>{
      'singleNodeDevicesData': singleNodeDevicesData,
      'meshNetworkDevicesData': meshNetworkDevicesData,
    };

    for (final scene in scenes.entries) {
      test('${scene.key}: no offline node carries clients', () {
        for (final NodeEntity node in scene.value.meshNetwork.allNodes) {
          if (node.connectedClients.isEmpty) continue;
          expect(
            node.isOnline,
            isTrue,
            reason: '${scene.key}: node ${node.deviceId} has '
                '${node.connectedClients.length} client(s) but reads offline. '
                'Liveness and client attribution come from one match, so the '
                'builder cannot produce this — give the node a '
                '`dataElementsId`, or take its clients away.',
          );
        }
      });
    }

    test('meshNetworkDevicesData draws the healthy mesh it documents', () {
      final mesh = meshNetworkDevicesData.meshNetwork;
      expect(
        mesh.slaves,
        isNotEmpty,
        reason: 'The scene exists to draw the widest tree in the suite, and is '
            'the layout gate\'s topology cell (`kTopologyPageCase`). Without a '
            'slave it is `singleNodeDevicesData` twice.',
      );
      for (final NodeEntity node in mesh.allNodes) {
        expect(
          node.isOnline,
          isTrue,
          reason: 'Node ${node.deviceId} reads offline, which sorts it below '
              'the gateway\'s clients (`_nodeComparator`, since #882), greys '
              'its image and dashes its links — a different tree from the '
              'healthy one this scene is the fixture for (#1472).',
        );
      }
    });
  });

  group('node detail scenes (UspNodeDetailState)', () {
    // Keyed by name because the exemption list names them; the page draws
    // `state.connectedClients`, so that is the list read here.
    final scenes = <String, UspNodeDetailState>{
      'masterNodeWithDevices': masterNodeWithDevices,
      'masterNodeEmptyDevices': masterNodeEmptyDevices,
      'slaveNodeWithDevices': slaveNodeWithDevices,
      'slaveNodeOnlineWithDevices': slaveNodeOnlineWithDevices,
      'slaveNodeWithBackhaulTiming': slaveNodeWithBackhaulTiming,
      'slaveNodeNoBackhaul': slaveNodeNoBackhaul,
      'slaveNodeGlobalIpv6': slaveNodeGlobalIpv6,
      'slaveNodeLinkLocalIpv6': slaveNodeLinkLocalIpv6,
      'nodeNotFoundState': nodeNotFoundState,
    };

    test('every scene is accounted for by the exemption list', () {
      expect(
        scenes.keys,
        containsAll(_offlineWithClients),
        reason: 'An exemption names a scene that no longer exists. Delete the '
            'entry (#1476).',
      );
    });

    test('offline-with-clients is confined to the scenes #1476 lists', () {
      final violating = scenes.entries
          .where((scene) {
            final node = scene.value.node;
            return node != null &&
                !node.isOnline &&
                scene.value.connectedClients.isNotEmpty;
          })
          .map((scene) => scene.key)
          .toSet();

      expect(
        violating,
        _offlineWithClients,
        reason: 'A node-detail scene pairs an offline node with a client list, '
            'which the builder cannot produce (see this file\'s header). If a '
            'new scene appears here, give it a `dataElementsId` or empty its '
            'clients. If a listed one is missing, #1476 fixed it — delete the '
            'entry rather than leaving a name that asserts nothing.',
      );
    });
  });
}
