import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/helpers/backhaul_parent_graph.dart';

/// The parent graph the topology builder hands to ui_kit (#1441).
///
/// ## Why this is its own module, and its own test
///
/// The builder used to resolve each slave's parent inline, in one expression:
/// `deviceIdToExtenderId[normalizedParentId] ?? gatewayId`. Two defects hid in
/// that `??`:
///
/// - **A cycle survives it.** Our side never walks the graph, so nothing here
///   loops — but ui_kit's layout does walk it (`concentric_layout.dart`'s
///   `_positionChildrenRecursively`, `topology_tree_view.dart`'s `buildSubtree`),
///   with no visited set and no depth cap, so A→B→A overflows the stack *there*.
///   We may not hand-roll around a ui_kit widget (constitution Article XV), so
///   the only defence available is not emitting the cycle.
/// - **A lookup failure is spelled exactly like success.** A node whose
///   `BackhaulDeviceID` names an agent absent from the tree lands on the gateway,
///   and so does a node genuinely parented by the gateway. A three-hop chain that
///   collapsed to a star was indistinguishable from a real star, in logs and on
///   screen.
///
/// Both are decisions about *data*, which is why they are a pure function with a
/// return value rather than a log line inside a loop: the outcome is asserted
/// here as a value, and the builder's only remaining job is to log it. A test
/// that could only read the global `logger` would pin neither.
void main() {
  const gatewayId = 'gateway';
  const gatewayMac = 'AA:BB:CC:DD:EE:00';

  /// [resolveBackhaulParents] with the two lookup tables derived from [slaves]
  /// the way the builder derives them, so a test states only what it is about.
  BackhaulParentGraph resolve(
    List<({String id, String? parent})> slaves, {
    String? gatewayMacOverride,
  }) =>
      resolveBackhaulParents(
        slaves: slaves
            .map((s) => (extenderId: s.id, parentDeviceId: s.parent))
            .toList(),
        extenderIdByNodeMac: {
          for (final s in slaves) normalizeNodeMac(s.id): s.id,
        },
        gatewayNodeMacs: {normalizeNodeMac(gatewayMacOverride ?? gatewayMac)},
        gatewayId: gatewayId,
      );

  BackhaulParent parentOf(BackhaulParentGraph graph, String extenderId) =>
      graph.parents.firstWhere((p) => p.extenderId == extenderId);

  group('outcomes that are not cycles', () {
    test('a slave whose firmware named no parent attaches to the gateway', () {
      final graph = resolve([(id: 'A', parent: null)]);

      expect(parentOf(graph, 'A').parentId, gatewayId);
      expect(parentOf(graph, 'A').outcome, BackhaulParentOutcome.noneReported);
      expect(graph.misses, isEmpty,
          reason: 'firmware reporting nothing is not a failed lookup');
    });

    test('a blank parent is no parent, not a miss', () {
      // `nonUnsetMac` already nulls these upstream; belt on the boundary,
      // because a `''` reaching the lookup would miss and be reported as one.
      for (final blank in ['', '   ']) {
        final graph = resolve([(id: 'A', parent: blank)]);
        expect(parentOf(graph, 'A').outcome, BackhaulParentOutcome.noneReported,
            reason: 'blank parent ${blank.length} chars');
      }
    });

    test('a slave that names the gateway is gateway-parented, not a miss', () {
      // The distinction AC2 is about. The gateway's own MAC is **not** in the
      // extender lookup, so before this it took the same `?? gatewayId` path a
      // failed lookup takes and the two were indistinguishable.
      final graph = resolve([(id: 'A', parent: gatewayMac)]);

      expect(parentOf(graph, 'A').parentId, gatewayId);
      expect(parentOf(graph, 'A').outcome, BackhaulParentOutcome.gateway);
      expect(graph.misses, isEmpty);
    });

    test('a slave that names another slave attaches to it', () {
      final graph = resolve([
        (id: 'A', parent: gatewayMac),
        (id: 'B', parent: 'A'),
      ]);

      expect(parentOf(graph, 'B').parentId, 'A');
      expect(parentOf(graph, 'B').outcome, BackhaulParentOutcome.extender);
      expect(graph.misses, isEmpty);
    });

    test(
        'a parent absent from the tree is a MISS, and still lands on the '
        'gateway', () {
      // AC2 + AC3. The attachment is unchanged — the gateway is the only place
      // to put a node whose parent we cannot find — and what changes is that it
      // now says so.
      final graph = resolve([(id: 'A', parent: '99:99:99:99:99:99')]);

      expect(parentOf(graph, 'A').parentId, gatewayId);
      expect(parentOf(graph, 'A').outcome, BackhaulParentOutcome.miss);
      expect(graph.misses.map((m) => m.extenderId), ['A']);
      expect(parentOf(graph, 'A').reportedParentDeviceId, '99:99:99:99:99:99',
          reason: 'the log needs the value firmware sent, not its normal form');
    });

    test('separators and case do not decide a miss', () {
      // `normalizeNodeMac` is the one normal form for both sides of the lookup.
      // A dashed or lower-case parent MAC used to miss and collapse a real hop.
      final graph = resolve([
        (id: 'AA:BB:CC:DD:EE:01', parent: gatewayMac),
        (id: 'AA:BB:CC:DD:EE:02', parent: 'aa-bb-cc-dd-ee-01'),
      ]);

      expect(
          parentOf(graph, 'AA:BB:CC:DD:EE:02').parentId, 'AA:BB:CC:DD:EE:01');
      expect(parentOf(graph, 'AA:BB:CC:DD:EE:02').outcome,
          BackhaulParentOutcome.extender);
    });

    test('a three-hop chain is left alone', () {
      // The false-positive guard: cycle detection that re-parents a legitimate
      // chain is worse than none, and a chain is the shape closest to a cycle.
      final graph = resolve([
        (id: 'A', parent: gatewayMac),
        (id: 'B', parent: 'A'),
        (id: 'C', parent: 'B'),
      ]);

      expect(graph.brokenCycles, isEmpty);
      expect(graph.parentIdByExtenderId, {
        'A': gatewayId,
        'B': 'A',
        'C': 'B',
      });
    });
  });

  group('cycles are broken before the graph is emitted', () {
    test('a 2-cycle loses exactly one edge, the earlier node\'s', () {
      // AC1 + AC3. Deterministic by input order: the earliest member of the
      // cycle is the one re-parented, so the same firmware state always produces
      // the same tree — a rule this test states rather than a side effect of
      // which node the walk happened to start from.
      final graph = resolve([
        (id: 'A', parent: 'B'),
        (id: 'B', parent: 'A'),
      ]);

      expect(parentOf(graph, 'A').parentId, gatewayId);
      expect(parentOf(graph, 'A').outcome, BackhaulParentOutcome.cycleBroken);
      expect(parentOf(graph, 'B').parentId, 'A',
          reason: 'only the edge that closes the cycle goes');
      expect(parentOf(graph, 'B').outcome, BackhaulParentOutcome.extender);
    });

    test('the broken cycle is reported once, with every member', () {
      final graph = resolve([
        (id: 'A', parent: 'B'),
        (id: 'B', parent: 'A'),
      ]);

      expect(graph.brokenCycles, hasLength(1),
          reason:
              'one cycle, one report — not one per node that walks into it');
      expect(graph.brokenCycles.single.cycle, containsAll(['A', 'B']));
      expect(graph.brokenCycles.single.cycle, hasLength(2));
    });

    test('a node pointing into a cycle does not report a second one', () {
      final graph = resolve([
        (id: 'A', parent: 'B'),
        (id: 'B', parent: 'A'),
        (id: 'C', parent: 'A'),
      ]);

      expect(graph.brokenCycles, hasLength(1));
      expect(parentOf(graph, 'C').parentId, 'A',
          reason: 'C is not in the cycle and keeps its real parent');
      expect(parentOf(graph, 'C').outcome, BackhaulParentOutcome.extender);
    });

    test('a 3-cycle is broken at its earliest member', () {
      final graph = resolve([
        (id: 'A', parent: 'C'),
        (id: 'B', parent: 'A'),
        (id: 'C', parent: 'B'),
      ]);

      expect(parentOf(graph, 'A').parentId, gatewayId);
      expect(parentOf(graph, 'A').outcome, BackhaulParentOutcome.cycleBroken);
      expect(graph.brokenCycles.single.cycle, hasLength(3));
      expect(parentOf(graph, 'B').parentId, 'A');
      expect(parentOf(graph, 'C').parentId, 'B');
    });

    test('the earliest member is broken, not the node the walk re-enters at',
        () {
      // The one shape where "earliest in input order" and "where the walk came
      // back to its own path" disagree, and therefore the only shape that pins
      // the rule. The cycle is {B, C}; A points into it at **C**, so the walk
      // A → C → B re-enters at C while the earliest member is B.
      //
      // Found by mutation: with the victim taken as the re-entry node instead,
      // every other cycle case here still passed. A determinism rule nothing can
      // fail is a comment, not a rule.
      final graph = resolve([
        (id: 'A', parent: 'C'),
        (id: 'B', parent: 'C'),
        (id: 'C', parent: 'B'),
      ]);

      expect(parentOf(graph, 'B').parentId, gatewayId,
          reason: 'B precedes C in the input');
      expect(parentOf(graph, 'C').parentId, 'B',
          reason: 'C keeps its edge; only the earliest member loses one');
      expect(parentOf(graph, 'A').parentId, 'C');
      expect(graph.brokenCycles.single.cycle, containsAll(['B', 'C']));
    });

    test('a node that is its own parent is a cycle of one', () {
      // Reachable without firmware misbehaving: any build where a node reports
      // its own MAC as `BackhaulDeviceID`, and the shape that overflows the
      // ui_kit walk fastest.
      final graph = resolve([(id: 'A', parent: 'A')]);

      expect(parentOf(graph, 'A').parentId, gatewayId);
      expect(parentOf(graph, 'A').outcome, BackhaulParentOutcome.cycleBroken);
      expect(graph.brokenCycles.single.cycle, ['A']);
    });

    test('two disjoint cycles are both broken and both reported', () {
      final graph = resolve([
        (id: 'A', parent: 'B'),
        (id: 'B', parent: 'A'),
        (id: 'C', parent: 'D'),
        (id: 'D', parent: 'C'),
      ]);

      expect(graph.brokenCycles, hasLength(2));
      expect(parentOf(graph, 'A').parentId, gatewayId);
      expect(parentOf(graph, 'C').parentId, gatewayId);
    });

    test('every slave reaches the gateway after resolution', () {
      // The property ui_kit's recursion actually needs, asserted over the output
      // rather than over the arms that produce it: from any node, following
      // parents terminates at the gateway.
      final graph = resolve([
        (id: 'A', parent: 'B'),
        (id: 'B', parent: 'C'),
        (id: 'C', parent: 'A'),
        (id: 'D', parent: 'C'),
        (id: 'E', parent: 'ZZ:ZZ:ZZ:ZZ:ZZ:ZZ'),
        (id: 'F', parent: null),
      ]);

      for (final start in ['A', 'B', 'C', 'D', 'E', 'F']) {
        var current = start;
        final seen = <String>{};
        while (current != gatewayId) {
          expect(seen.add(current), isTrue,
              reason: 'walking up from $start revisited $current');
          final next = graph.parentIdByExtenderId[current];
          expect(next, isNotNull, reason: '$current has no parent entry');
          current = next!;
        }
      }
    });
  });
}
