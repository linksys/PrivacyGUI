import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_order.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The order siblings appear in on a tree row.
///
/// This was a private static on the page's `State`, where the only way to check it
/// was to pump the whole page and read rows off the screen. It decides what a
/// viewer sees first, so it is worth being able to ask directly.
///
/// Only the tree view reads it: `nodeComparator` is consumed in the kit's
/// `topology_tree_view.dart` and nowhere else, so the three call sites pinning
/// `viewMode: graph` would get nothing from passing one.
void main() {
  GraphNode node(
    String name, {
    String? slot,
    NodeState status = NodeState.active,
    bool external = false,
  }) =>
      GraphNode(
        id: name,
        name: name,
        styleSlot: slot,
        status: status,
        external: external,
      );

  /// What [nodes] look like once sorted — names, in order.
  List<String> sorted(List<GraphNode> nodes) {
    final copy = [...nodes]..sort(TopologyNodeOrder.compare);
    return copy.map((n) => n.name).toList();
  }

  group('status leads', () {
    test('an offline node sinks below an online one whatever its role', () {
      // The master is rank 0 and the device rank 2, so role would put the master
      // first. Status outranks role: an unreachable device is the one a viewer
      // came to find.
      expect(
        sorted([
          node('master', slot: 'primary', status: NodeState.inactive),
          node('laptop', slot: 'leaf'),
        ]),
        ['laptop', 'master'],
      );
    });

    test('two offline nodes still order by role between themselves', () {
      expect(
        sorted([
          node('laptop', slot: 'leaf', status: NodeState.inactive),
          node('study', slot: 'secondary', status: NodeState.inactive),
        ]),
        ['study', 'laptop'],
      );
    });

    test('alert counts as active, not as offline', () {
      // `isInactive` is the kit's predicate and only `inactive` satisfies it.
      // This app never produces `alert`, so the case is pinned rather than
      // relied on: if it ever does, this says what happens.
      expect(
        sorted([
          node('b-alert', slot: 'leaf', status: NodeState.alert),
          node('a-offline', slot: 'leaf', status: NodeState.inactive),
        ]),
        ['b-alert', 'a-offline'],
      );
    });
  });

  group('then role', () {
    test('master, slave, device, external', () {
      expect(
        sorted([
          node('internet', external: true),
          node('laptop', slot: 'leaf'),
          node('study', slot: 'secondary'),
          node('gateway', slot: 'primary'),
        ]),
        ['gateway', 'study', 'laptop', 'internet'],
      );
    });

    test('a node with no slot sorts with the devices, not above them', () {
      // An unassigned slot is the case the two readers in one file used to
      // disagree about. It ranks last among the non-external nodes rather than
      // being promoted past the ones this app did classify.
      expect(TopologyNodeOrder.priorityOf(node('mystery')),
          TopologyNodeOrder.priorityOf(node('laptop', slot: 'leaf')));
    });

    test('an external node ranks last even when it wears a slot', () {
      // The externality check sits before the switch, so a future slot
      // assignment on the upstream endpoint cannot promote it.
      expect(
        TopologyNodeOrder.priorityOf(
            node('internet', slot: 'primary', external: true)),
        greaterThan(TopologyNodeOrder.priorityOf(node('laptop', slot: 'leaf'))),
      );
    });
  });

  group('then name, which is what makes the order repeatable', () {
    test('two devices under one parent go alphabetically', () {
      expect(
        sorted([
          node('Zebra Printer', slot: 'leaf'),
          node('Apple TV', slot: 'leaf'),
        ]),
        ['Apple TV', 'Zebra Printer'],
      );
    });

    test('sorting twice gives the same order', () {
      // The input reaches the comparator from map- and Set-ordered collections,
      // which do not promise a stable order of their own. Without the name tie
      // -break, two runs over unchanged data could draw two different trees.
      final nodes = [
        node('Thermostat', slot: 'leaf'),
        node('Doorbell', slot: 'leaf'),
        node('Speaker', slot: 'leaf'),
      ];
      expect(sorted(nodes), sorted(nodes.reversed.toList()));
    });
  });

  group('the comparator is a valid ordering', () {
    final all = [
      node('gateway', slot: 'primary'),
      node('study', slot: 'secondary'),
      node('laptop', slot: 'leaf'),
      node('mystery'),
      node('internet', external: true),
      node('offline-laptop', slot: 'leaf', status: NodeState.inactive),
    ];

    test('is antisymmetric', () {
      for (final a in all) {
        for (final b in all) {
          expect(
            TopologyNodeOrder.compare(a, b).sign,
            -TopologyNodeOrder.compare(b, a).sign,
            reason: '${a.name} vs ${b.name}',
          );
        }
      }
    });

    test('a node equals itself', () {
      for (final a in all) {
        expect(TopologyNodeOrder.compare(a, a), 0, reason: a.name);
      }
    });

    test('is transitive', () {
      // `List.sort` is only meaningful if the comparator is a real ordering;
      // an inconsistent one can produce different results per input order,
      // which is the bug that would look like "the tree jumps around".
      for (final a in all) {
        for (final b in all) {
          for (final c in all) {
            if (TopologyNodeOrder.compare(a, b) <= 0 &&
                TopologyNodeOrder.compare(b, c) <= 0) {
              expect(TopologyNodeOrder.compare(a, c), lessThanOrEqualTo(0),
                  reason: '${a.name} <= ${b.name} <= ${c.name}');
            }
          }
        }
      }
    });
  });
}
