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
    test('the shallowest, not whichever the data listed first', () {
      // The match set is pinned, not merely counted. An earlier version asserted
      // `length > 1`, which is a precondition rather than an assertion — and it was
      // wrong about the fixture besides: the comment said three matches at three
      // depths, and measuring it gives four. `Thermostat` contains an 'a' too.
      // Pinning the set is what made that visible.
      expect(TopologySearch.match(topology, 'a'),
          {'gateway', 'extender-1', 'client-1', 'client-2'});

      // Depth decides: the gateway is the only depth 0.
      expect(TopologySearch.focusTarget(topology, 'a'), 'gateway');
    });

    test('a deeper match loses to a shallower one whatever its name', () {
      // The case that isolates the depth rule, chosen by measuring which needles
      // land where rather than by reading the fixture and guessing. 'x' matches the
      // extender (depth 1, `Study Extender`) and the laptop (depth 2,
      // `Alex's MacBook`) and **not** the gateway.
      expect(TopologySearch.match(topology, 'x'), {'extender-1', 'client-1'});

      // Alphabetically `Alex's` wins; by depth `Study` does. So a target of
      // `extender-1` can only have come from consulting depth first.
      expect(TopologySearch.focusTarget(topology, 'x'), 'extender-1');
    });

    test('two matches at one depth in the real fixture break by name', () {
      // 'st' matches `Study Extender` and `Thermostat`, both depth 1 — the
      // tie-break on the same graph every other case here uses, rather than only on
      // the hand-made one below.
      expect(TopologySearch.match(topology, 'st'), {'extender-1', 'client-2'});
      expect(TopologySearch.focusTarget(topology, 'st'), 'extender-1',
          reason: 'Study Extender before Thermostat');
    });

    test('ties at one depth break by name', () {
      // Two leaves under one parent, so depth cannot separate them — and the parent
      // is **present**, which it needs to be for the depths to be real. An earlier
      // version of this case built the pair with their `gw` parent filtered out of
      // the node list; the kit answers a missing id with `NodeStructure.unknown`
      // (`depth: 0`), so both leaves were depth 0 and the case passed for the wrong
      // reason — it was exercising the orphan path, not the tie-break.
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

      // 'p' matches only the two leaves (Printer, Apple) — the router does not, so
      // depth 1 is a genuine tie and the name breaks it.
      expect(TopologySearch.match(tied, 'p'), {'z', 'a'});
      expect(TopologySearch.focusTarget(tied, 'p'), 'a',
          reason: 'Apple before Zebra');
    });

    test('an orphan sorts as a root rather than throwing', () {
      // The behaviour the case above used to depend on by accident, asserted here
      // on purpose. A node whose `parentId` names something absent gets
      // `NodeStructure.unknown` — the kit answers layout and paint harmlessly
      // rather than throwing mid-frame — so it reads as depth 0.
      final orphaned = GraphData(
        nodes: const [
          GraphNode(id: 'gw', name: 'Router', styleSlot: 'primary'),
          GraphNode(
              id: 'lost',
              name: 'Aaa Orphan',
              styleSlot: 'leaf',
              parentId: 'no-such-node'),
        ],
        edges: const [],
      );

      // Both read as depth 0, so the name decides: 'Aaa Orphan' before 'Router'.
      expect(TopologySearch.focusTarget(orphaned, 'r'), 'lost');
    });

    test('a miss has no target', () {
      expect(TopologySearch.focusTarget(topology, 'no such device'), isNull);
      expect(TopologySearch.focusTarget(topology, ''), isNull);
    });

    test('the target is always one of the matches', () {
      // Counted, not `continue`d past. The earlier version skipped a null target,
      // so a regression that returned null for everything would have passed this
      // silently while asserting nothing.
      var checked = 0;
      for (final q in ['a', 'e', 'router', '192.168']) {
        final matches = TopologySearch.match(topology, q);
        expect(matches, isNotEmpty, reason: 'fixture must match "$q"');

        final target = TopologySearch.focusTarget(topology, q);
        expect(target, isNotNull, reason: 'a non-empty match set has a target');
        expect(matches, contains(target), reason: q);
        checked++;
      }
      expect(checked, 4);
    });

    test('targetAmong is the same decision as focusTarget', () {
      // The view calls `targetAmong` with the set it already computed; every other
      // caller and all the cases above go through `focusTarget`. They must not be
      // able to drift apart.
      for (final q in [
        'a',
        'e',
        'router',
        'thermostat',
        'no such device',
        ''
      ]) {
        expect(
          TopologySearch.targetAmong(
              topology, TopologySearch.match(topology, q)),
          TopologySearch.focusTarget(topology, q),
          reason: q,
        );
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
