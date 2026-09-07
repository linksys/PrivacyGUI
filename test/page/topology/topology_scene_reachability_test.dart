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
// #1476 closed the node-detail half: four scenes paired an offline slave with a
// client list, and they were exempted here by name because fixing them repaints
// a badge across 26 locales, which is a coordinated baseline refresh. Three took
// a `dataElementsId` and the fourth — the one that has to stay offline, since
// `offline` is the wider liveness label in every locale where the two differ —
// gave up its clients and was renamed `slaveNodeOffline` to say so. The
// exemption list is gone rather than empty: an empty set asserts the same thing
// as `isEmpty` and reads as though something is still pending.
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';

import '../../mocks/test_data/scenes/topology_scene_data.dart';

/// The scene file this guard is about. Read as text by [_declaredScenes], so the
/// path is load-bearing: a moved file makes the accounting test fail rather than
/// pass over an empty scan.
const _sceneFile = 'test/mocks/test_data/scenes/topology_scene_data.dart';

/// Every top-level scene of type [typeName] declared in [_sceneFile], by name.
///
/// Dart cannot enumerate a library's top-level finals, and the maps below are
/// hand-written — so without this the guard says nothing about a scene added
/// tomorrow. #1476's four violators were tracked by a hand-maintained exemption
/// list, which had exactly that property in reverse: it forced every scene to be
/// *named* somewhere. Emptying the list would have given that up, so the
/// accounting moved here, where it costs nothing to keep.
///
/// Two declaration shapes are recognised — `final <name> = <Type>(` and
/// `<Type> get <name> =>`, the two the file uses. A third shape is not silently
/// skipped: any top-level line that mentions the type and yields no name fails
/// the test, because a scan that cannot see a declaration is worse than no scan.
Set<String> _declaredScenes(String typeName) {
  final source = File(_sceneFile).readAsLinesSync();
  final declaration = RegExp('^(?:final|const|$typeName)\\b.*$typeName\\b');
  final assigned = RegExp(
      '^(?:final|const)\\s+(?:$typeName\\s+)?(\\w+)\\s*=\\s*$typeName\\b');
  final getter = RegExp('^$typeName\\s+get\\s+(\\w+)\\s*=>');

  final names = <String>{};
  for (final line in source) {
    if (!declaration.hasMatch(line)) continue;
    final match = assigned.firstMatch(line) ?? getter.firstMatch(line);
    expect(
      match,
      isNotNull,
      reason: 'This line declares a $typeName the scan cannot name, so the '
          'scene would escape every assertion below:\n  $line\n'
          'Either spell it as one of the two recognised shapes, or teach '
          '_declaredScenes the new one.',
    );
    names.add(match!.group(1)!);
  }
  return names;
}

void main() {
  // Keyed by name so a failure names the scene to edit, and so `scene
  // accounting` below can hold the maps up against the file they came from. The
  // node-detail page draws `state.connectedClients`, so that is the list read
  // for those.
  final viewScenes = <String, DevicesData>{
    'singleNodeDevicesData': singleNodeDevicesData,
    'meshNetworkDevicesData': meshNetworkDevicesData,
  };

  final detailScenes = <String, UspNodeDetailState>{
    'masterNodeWithDevices': masterNodeWithDevices,
    'masterNodeEmptyDevices': masterNodeEmptyDevices,
    'slaveNodeOffline': slaveNodeOffline,
    'slaveNodeOnlineWithDevices': slaveNodeOnlineWithDevices,
    'slaveNodeWithBackhaulTiming': slaveNodeWithBackhaulTiming,
    'slaveNodeNoBackhaul': slaveNodeNoBackhaul,
    'slaveNodeGlobalIpv6': slaveNodeGlobalIpv6,
    'slaveNodeLinkLocalIpv6': slaveNodeLinkLocalIpv6,
    'nodeNotFoundState': nodeNotFoundState,
  };

  group('topology view scenes (DevicesData)', () {
    for (final scene in viewScenes.entries) {
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
    test('no offline node-detail scene carries clients', () {
      final violating = detailScenes.entries
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
        isEmpty,
        reason: 'A node-detail scene pairs an offline node with a client list, '
            'which the builder cannot produce (see this file\'s header). Give '
            'the node a `dataElementsId`, or empty its clients — #1476 did the '
            'first to three scenes and the second to the one that has to stay '
            'offline.',
      );
    });
  });

  group('scene accounting', () {
    // The two maps are this guard's whole reach: a scene the file declares and
    // neither map holds is unasserted, and reads as green. Compared against the
    // file's text rather than a second hand-written list, so there is nothing
    // here to keep in sync — the maps are the list.
    test('every UspNodeDetailState in the scene file is asserted', () {
      expect(
        detailScenes.keys.toSet(),
        _declaredScenes('UspNodeDetailState'),
        reason: 'A node-detail scene was added, removed or renamed in '
            '$_sceneFile without reaching `detailScenes`, so nothing above '
            'asserts it.',
      );
    });

    test('every DevicesData in the scene file is asserted', () {
      expect(
        viewScenes.keys.toSet(),
        _declaredScenes('DevicesData'),
        reason: 'A topology-view scene was added, removed or renamed in '
            '$_sceneFile without reaching `viewScenes`.',
      );
    });
  });
}
