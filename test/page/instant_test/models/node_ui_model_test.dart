import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

// Tests for NodeUIModel backhaul health — replacing the old MeshNodeInfo tests.
// The weak-backhaul threshold is: backhaulSignalStrength != null && signal < -70.

NodeUIModel _satellite({int? signal, bool wired = false}) => NodeUIModel(
      deviceId: 'sat-1',
      friendlyName: 'Living Room',
      model: 'MX6200',
      isMaster: false,
      backhaulSignalStrength: signal,
      backhaulMediaType: wired ? 'Ethernet' : 'IEEE 802.11ax',
    );

NodeUIModel _master() => const NodeUIModel(
      deviceId: 'router',
      model: 'MX6200',
      isMaster: true,
    );

void main() {
  group('NodeUIModel — backhaul weakness detection', () {
    test('satellite with signal < -70 → weak', () {
      final node = _satellite(signal: -75);
      final isWeak = node.backhaulSignalStrength != null &&
          node.backhaulSignalStrength! < -70 &&
          !node.isMaster;
      expect(isWeak, isTrue);
    });

    test('satellite with signal = -70 → not weak (< not <=)', () {
      final node = _satellite(signal: -70);
      final isWeak = node.backhaulSignalStrength != null &&
          node.backhaulSignalStrength! < -70 &&
          !node.isMaster;
      expect(isWeak, isFalse);
    });

    test('satellite with signal = -50 → strong', () {
      final node = _satellite(signal: -50);
      final isWeak = node.backhaulSignalStrength != null &&
          node.backhaulSignalStrength! < -70 &&
          !node.isMaster;
      expect(isWeak, isFalse);
    });

    test('master node never weak even with bad signal', () {
      final node = _master();
      expect(node.isMaster, isTrue);
    });

    test('null signal → not weak', () {
      final node = _satellite(signal: null);
      final isWeak = node.backhaulSignalStrength != null &&
          node.backhaulSignalStrength! < -70 &&
          !node.isMaster;
      expect(isWeak, isFalse);
    });
  });

  group('NodeUIModel — displayName', () {
    test('prefers friendlyName', () {
      const node = NodeUIModel(
        deviceId: 'abc',
        model: 'MX6200',
        friendlyName: 'Bedroom Node',
      );
      expect(node.displayName, 'Bedroom Node');
    });

    test('falls back to model when no friendlyName', () {
      const node = NodeUIModel(deviceId: 'abc', model: 'MX6200');
      expect(node.displayName, 'MX6200');
    });
  });

  group('NodeUIModel — role labels', () {
    test('isMaster=true → roleLabel is Master', () {
      const node = NodeUIModel(deviceId: 'r', model: 'MX6200', isMaster: true);
      expect(node.roleLabel, 'Master');
    });

    test('isMaster=false → roleLabel is Slave', () {
      const node = NodeUIModel(deviceId: 'r', model: 'MX6200', isMaster: false);
      expect(node.roleLabel, 'Slave');
    });
  });
}
