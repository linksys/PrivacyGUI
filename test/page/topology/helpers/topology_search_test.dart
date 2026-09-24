import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/helpers/topology_search.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Which nodes a query matches, and which it deliberately does not.
///
/// The topology page had no search at all before #1614 — `TopologyController` is
/// what made "type a device name, go to that device" expressible. The predicate
/// started life as a private method on the page's `State`, which is untestable, so
/// it lives here.
///
/// The field set is the same one the device list offers (`searchByNameMacIp`) plus
/// the subtitle, which carries a leaf's IP and a node's model.
void main() {
  final topology = GraphData(
    nodes: const [
      GraphNode(
        id: 'gateway',
        name: 'Living Room Router',
        styleSlot: 'primary',
        extra: 'MR7500 · Linksys',
        metadata: {'deviceId': 'AA:BB:CC:DD:EE:00'},
      ),
      GraphNode(
        id: 'extender-1',
        name: 'Study Extender',
        styleSlot: 'secondary',
        parentId: 'gateway',
        extra: 'MX2000 · Wi-Fi -55 dBm',
        metadata: {'deviceId': 'AA:BB:CC:DD:EE:01'},
      ),
      GraphNode(
        id: 'client-1',
        name: "Alex's MacBook",
        styleSlot: 'leaf',
        parentId: 'extender-1',
        extra: '192.168.1.50 · 5GHz',
        metadata: {'mac': '11:22:33:44:55:01'},
      ),
      GraphNode(
        id: 'client-2',
        name: 'Thermostat',
        styleSlot: 'leaf',
        parentId: 'gateway',
        // A device with no subtitle and no address is the sparse case: it must
        // still be findable by name, and must not throw.
        metadata: null,
      ),
    ],
    edges: const [],
  );

  group('what a query matches', () {
    test('a name, case-insensitively', () {
      expect(TopologySearch.match(topology, 'macbook'), {'client-1'});
      expect(TopologySearch.match(topology, 'MACBOOK'), {'client-1'});
    });

    test('a partial name', () {
      expect(TopologySearch.match(topology, 'room'), {'gateway'});
    });

    test("a leaf's IP, from the subtitle", () {
      expect(TopologySearch.match(topology, '192.168.1.50'), {'client-1'});
    });

    test("a node's model, from the subtitle", () {
      // The reason giving slaves a subtitle changed search as a side effect: the
      // predicate reads `extra`, so a model became searchable the moment it was
      // shown.
      expect(TopologySearch.match(topology, 'mx2000'), {'extender-1'});
    });

    test("a leaf's MAC", () {
      expect(TopologySearch.match(topology, '11:22:33:44:55:01'), {'client-1'});
    });

    test("a mesh node's deviceId", () {
      // Mesh nodes and leaves keep their address under different metadata keys,
      // which is why the predicate reads both.
      expect(
          TopologySearch.match(topology, 'AA:BB:CC:DD:EE:01'), {'extender-1'});
    });

    test('several nodes at once', () {
      // `AA:BB:CC:DD:EE:0` prefixes both mesh nodes' ids.
      expect(TopologySearch.match(topology, 'AA:BB:CC:DD:EE:0'),
          {'gateway', 'extender-1'});
    });

    test('a node with no metadata, by name', () {
      expect(TopologySearch.match(topology, 'thermostat'), {'client-2'});
    });
  });

  group('which match a viewer is taken to', () {
    test('the one nearest the anchor, not whichever the data listed first', () {
      // 'a' appears in the gateway's subtitle (Linksys), the extender's name
      // (Study) and the laptop's name (Alex's) — three matches at three depths.
      final matched = TopologySearch.match(topology, 'a');
      expect(matched.length, greaterThan(1),
          reason: 'the point of this case is a tie to break');

      // Depth wins: the gateway is depth 0.
      expect(TopologySearch.focusTarget(topology, 'a'), 'gateway');
    });

    test('ties at one depth break by name', () {
      // Two leaves under the same parent, so depth cannot separate them.
      final tied = GraphData(
        nodes: const [
          GraphNode(id: 'gw', name: 'Router', styleSlot: 'primary'),
          GraphNode(
              id: 'z',
              name: 'Zebra Printer',
              styleSlot: 'leaf',
              parentId: 'gw'),
          GraphNode(
              id: 'a', name: 'Apple TV', styleSlot: 'leaf', parentId: 'gw'),
        ],
        edges: const [],
      );

      // Both match 'r' (Printer, Router...) — assert the leaf pair specifically.
      expect(TopologySearch.focusTarget(tied, 'e'), 'gw',
          reason: 'Router is depth 0 and matches too');
      // Restricted to the two leaves: alphabetical, so Apple before Zebra.
      final leafOnly = GraphData(
        nodes: tied.nodes.where((n) => n.id != 'gw').toList(),
        edges: const [],
      );
      expect(TopologySearch.focusTarget(leafOnly, 'e'), 'a');
    });

    test('a miss has no target', () {
      expect(TopologySearch.focusTarget(topology, 'no such device'), isNull);
      expect(TopologySearch.focusTarget(topology, ''), isNull);
    });

    test('the target is always one of the matches', () {
      for (final q in ['a', 'e', 'router', '192.168']) {
        final target = TopologySearch.focusTarget(topology, q);
        if (target == null) continue;
        expect(TopologySearch.match(topology, q), contains(target), reason: q);
      }
    });
  });

  group('what a query does not match', () {
    test('an empty query matches nothing, not everything', () {
      // The caller's contract is "these are the matches to emphasise".
      // Emphasising every node reads the same as emphasising none, and costs a
      // relayout to say it.
      expect(TopologySearch.match(topology, ''), isEmpty);
    });

    test('a whitespace-only query matches nothing', () {
      expect(TopologySearch.match(topology, '   '), isEmpty);
    });

    test('a query is trimmed before matching', () {
      expect(TopologySearch.match(topology, '  thermostat  '), {'client-2'});
    });

    test('a miss is empty rather than an error', () {
      expect(TopologySearch.match(topology, 'no such device'), isEmpty);
    });

    test('an id is not a searchable field', () {
      // `extender-1` is the graph's internal identity, not something a viewer
      // knows the device by — matching on it would surface a node for a string
      // never shown anywhere.
      expect(TopologySearch.match(topology, 'extender-1'), isEmpty);
    });

    test('a non-String metadata value does not match or throw', () {
      final withNumbers = GraphData(
        nodes: const [
          GraphNode(
            id: 'n1',
            name: 'Node',
            styleSlot: 'leaf',
            metadata: {'mac': 42, 'deviceId': true},
          ),
        ],
        edges: const [],
      );

      // Metadata is `Map<String, dynamic>`, so a caller can put anything in it.
      expect(TopologySearch.match(withNumbers, '42'), isEmpty);
    });
  });
}
