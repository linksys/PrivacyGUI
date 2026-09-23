import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
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
}
