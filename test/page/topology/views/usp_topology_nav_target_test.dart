import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/helpers/topology_nav_target.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

GraphNode _node({
  String? slot,
  bool external = false,
  required NodeState status,
  Map<String, dynamic>? metadata,
}) =>
    GraphNode(
      id: 'n1',
      name: 'n1',
      styleSlot: slot,
      external: external,
      status: status,
      metadata: metadata,
    );

void main() {
  group('topologyNavTargetFor', () {
    test('offline client -> uspDeviceDetail with its mac', () {
      final target = topologyNavTargetFor(_node(
        slot: 'leaf',
        status: NodeState.inactive,
        metadata: {'mac': 'AA:BB:CC:DD:EE:FF'},
      ));
      expect(target, isNotNull);
      expect(target!.route, RouteNamed.uspDeviceDetail);
      expect(target.queryParameters, {'mac': 'AA:BB:CC:DD:EE:FF'});
    });

    test('online client -> uspDeviceDetail with its mac', () {
      final target = topologyNavTargetFor(_node(
        slot: 'leaf',
        status: NodeState.active,
        metadata: {'mac': 'AA:BB:CC:DD:EE:FF'},
      ));
      expect(target, isNotNull);
      expect(target!.route, RouteNamed.uspDeviceDetail);
      expect(target.queryParameters, {'mac': 'AA:BB:CC:DD:EE:FF'});
    });

    test('offline extender -> null (gate kept until #1465)', () {
      final target = topologyNavTargetFor(_node(
        slot: 'secondary',
        status: NodeState.inactive,
        metadata: {'deviceId': 'dev-1'},
      ));
      expect(target, isNull);
    });

    test('offline gateway -> null (gate kept until #1465)', () {
      final target = topologyNavTargetFor(_node(
        slot: 'primary',
        status: NodeState.inactive,
        metadata: {'deviceId': 'dev-0'},
      ));
      expect(target, isNull);
    });

    test('online extender -> uspNodeDetail with its deviceId', () {
      final target = topologyNavTargetFor(_node(
        slot: 'secondary',
        status: NodeState.active,
        metadata: {'deviceId': 'dev-1'},
      ));
      expect(target, isNotNull);
      expect(target!.route, RouteNamed.uspNodeDetail);
      expect(target.queryParameters, {'deviceId': 'dev-1'});
    });

    test('online gateway -> uspNodeDetail with its deviceId', () {
      final target = topologyNavTargetFor(_node(
        slot: 'primary',
        status: NodeState.active,
        metadata: {'deviceId': 'dev-0'},
      ));
      expect(target, isNotNull);
      expect(target!.route, RouteNamed.uspNodeDetail);
      expect(target.queryParameters, {'deviceId': 'dev-0'});
    });

    test('client missing mac metadata -> null', () {
      expect(
        topologyNavTargetFor(_node(
          slot: 'leaf',
          status: NodeState.active,
          metadata: null,
        )),
        isNull,
      );
      expect(
        topologyNavTargetFor(_node(
          slot: 'leaf',
          status: NodeState.active,
          metadata: {'mac': ''},
        )),
        isNull,
      );
    });

    test('node missing deviceId metadata -> null', () {
      expect(
        topologyNavTargetFor(_node(
          slot: 'secondary',
          status: NodeState.active,
          metadata: null,
        )),
        isNull,
      );
      expect(
        topologyNavTargetFor(_node(
          slot: 'primary',
          status: NodeState.active,
          metadata: {'deviceId': ''},
        )),
        isNull,
      );
    });

    test('internet node -> null', () {
      expect(
        topologyNavTargetFor(_node(
          external: true,
          status: NodeState.active,
        )),
        isNull,
      );
    });

    // Mutation guard: the offline arm for infra nodes must be exercised.
    // If the `if (status == offline) return null` line is deleted, an offline
    // extender WITH a deviceId would resolve to uspNodeDetail and this test
    // would fail.
    test('mutation guard: deleting the offline gate breaks the extender case',
        () {
      final offlineExtender = _node(
        slot: 'secondary',
        status: NodeState.inactive,
        metadata: {'deviceId': 'dev-1'},
      );
      // With the gate present this is null; without it, it would be a target.
      expect(topologyNavTargetFor(offlineExtender), isNull);
    });
  });

  group('TopologyNavTarget is a value', () {
    test('two targets with the same destination are equal', () {
      // `Equatable` for the reason the tests need rather than the one Article XI
      // names: identity `==` meant every assertion about a destination had to be two
      // field comparisons, which is how a test checks the route and forgets the
      // parameters.
      final a = TopologyNavTarget('r', {'mac': 'AA'});
      final b = TopologyNavTarget('r', {'mac': 'AA'});

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('the map is compared by value, not by identity', () {
      // Not a given: `props` holding a `Map` only works because Equatable compares
      // collections deeply. Measured, because the whole point of adding it was to be
      // able to assert a destination in one line.
      expect(TopologyNavTarget('r', {'mac': 'AA'}),
          isNot(TopologyNavTarget('r', {'mac': 'BB'})));
      expect(TopologyNavTarget('r', {'mac': 'AA'}),
          isNot(TopologyNavTarget('other', {'mac': 'AA'})));
    });

    test('a caller mutating its own map cannot change a target', () {
      // The invariant `Map.unmodifiable` makes enforced rather than documented: this
      // class is `@immutable` and its `hashCode` derives from the map, so an aliased
      // one would let an object change identity after construction.
      final source = {'mac': 'AA'};
      final target = TopologyNavTarget('r', source);

      source['mac'] = 'ZZ';

      expect(target.queryParameters['mac'], 'AA');
    });

    test('the exposed map rejects writes', () {
      final target = TopologyNavTarget('r', {'mac': 'AA'});

      expect(
          () => target.queryParameters['mac'] = 'ZZ', throwsUnsupportedError);
    });
  });
}
