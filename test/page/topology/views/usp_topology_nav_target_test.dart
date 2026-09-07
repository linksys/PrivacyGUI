import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

MeshNode _node({
  required MeshNodeType type,
  required MeshNodeStatus status,
  Map<String, dynamic>? metadata,
}) =>
    MeshNode(
      id: 'n1',
      name: 'n1',
      type: type,
      status: status,
      metadata: metadata,
    );

void main() {
  group('topologyNavTargetFor', () {
    test('offline client -> uspDeviceDetail with its mac', () {
      final target = topologyNavTargetFor(_node(
        type: MeshNodeType.client,
        status: MeshNodeStatus.offline,
        metadata: {'mac': 'AA:BB:CC:DD:EE:FF'},
      ));
      expect(target, isNotNull);
      expect(target!.route, RouteNamed.uspDeviceDetail);
      expect(target.queryParameters, {'mac': 'AA:BB:CC:DD:EE:FF'});
    });

    test('online client -> uspDeviceDetail with its mac', () {
      final target = topologyNavTargetFor(_node(
        type: MeshNodeType.client,
        status: MeshNodeStatus.online,
        metadata: {'mac': 'AA:BB:CC:DD:EE:FF'},
      ));
      expect(target, isNotNull);
      expect(target!.route, RouteNamed.uspDeviceDetail);
      expect(target.queryParameters, {'mac': 'AA:BB:CC:DD:EE:FF'});
    });

    test('offline extender -> null (gate kept until #1465)', () {
      final target = topologyNavTargetFor(_node(
        type: MeshNodeType.extender,
        status: MeshNodeStatus.offline,
        metadata: {'deviceId': 'dev-1'},
      ));
      expect(target, isNull);
    });

    test('offline gateway -> null (gate kept until #1465)', () {
      final target = topologyNavTargetFor(_node(
        type: MeshNodeType.gateway,
        status: MeshNodeStatus.offline,
        metadata: {'deviceId': 'dev-0'},
      ));
      expect(target, isNull);
    });

    test('online extender -> uspNodeDetail with its deviceId', () {
      final target = topologyNavTargetFor(_node(
        type: MeshNodeType.extender,
        status: MeshNodeStatus.online,
        metadata: {'deviceId': 'dev-1'},
      ));
      expect(target, isNotNull);
      expect(target!.route, RouteNamed.uspNodeDetail);
      expect(target.queryParameters, {'deviceId': 'dev-1'});
    });

    test('online gateway -> uspNodeDetail with its deviceId', () {
      final target = topologyNavTargetFor(_node(
        type: MeshNodeType.gateway,
        status: MeshNodeStatus.online,
        metadata: {'deviceId': 'dev-0'},
      ));
      expect(target, isNotNull);
      expect(target!.route, RouteNamed.uspNodeDetail);
      expect(target.queryParameters, {'deviceId': 'dev-0'});
    });

    test('client missing mac metadata -> null', () {
      expect(
        topologyNavTargetFor(_node(
          type: MeshNodeType.client,
          status: MeshNodeStatus.online,
          metadata: null,
        )),
        isNull,
      );
      expect(
        topologyNavTargetFor(_node(
          type: MeshNodeType.client,
          status: MeshNodeStatus.online,
          metadata: {'mac': ''},
        )),
        isNull,
      );
    });

    test('node missing deviceId metadata -> null', () {
      expect(
        topologyNavTargetFor(_node(
          type: MeshNodeType.extender,
          status: MeshNodeStatus.online,
          metadata: null,
        )),
        isNull,
      );
      expect(
        topologyNavTargetFor(_node(
          type: MeshNodeType.gateway,
          status: MeshNodeStatus.online,
          metadata: {'deviceId': ''},
        )),
        isNull,
      );
    });

    test('internet node -> null', () {
      expect(
        topologyNavTargetFor(_node(
          type: MeshNodeType.internet,
          status: MeshNodeStatus.online,
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
        type: MeshNodeType.extender,
        status: MeshNodeStatus.offline,
        metadata: {'deviceId': 'dev-1'},
      );
      // With the gate present this is null; without it, it would be a target.
      expect(topologyNavTargetFor(offlineExtender), isNull);
    });
  });
}
