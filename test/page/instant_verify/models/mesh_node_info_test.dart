import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';

void main() {
  group('MeshNodeInfo — hasWeakBackhaul', () {
    test('satellite with RSSI < -70 → weak', () {
      const node = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
        backhaulType: 'Wireless',
        backhaulRssi: -75,
      );
      expect(node.hasWeakBackhaul, isTrue);
    });

    test('satellite with RSSI = -70 → not weak (< not <=)', () {
      const node = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
        backhaulType: 'Wireless',
        backhaulRssi: -70,
      );
      expect(node.hasWeakBackhaul, isFalse);
    });

    test('satellite with RSSI = -50 → strong', () {
      const node = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
        backhaulType: 'Wireless',
        backhaulRssi: -50,
      );
      expect(node.hasWeakBackhaul, isFalse);
    });

    test('controller node never weak even with bad RSSI', () {
      const node = MeshNodeInfo(
        deviceId: 'router',
        name: 'Router',
        isController: true,
        backhaulRssi: -90,
      );
      expect(node.hasWeakBackhaul, isFalse);
    });

    test('null RSSI → not weak', () {
      const node = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
        backhaulType: 'Wireless',
      );
      expect(node.hasWeakBackhaul, isFalse);
    });
  });

  group('MeshNodeInfo — hasWiredBackhaul', () {
    test('Wired type → true', () {
      const node = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Office',
        isController: false,
        backhaulType: 'Wired',
      );
      expect(node.hasWiredBackhaul, isTrue);
    });

    test('Wireless type → false', () {
      const node = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Office',
        isController: false,
        backhaulType: 'Wireless',
      );
      expect(node.hasWiredBackhaul, isFalse);
    });
  });

  group('MeshNodeInfo — backhaulLabel', () {
    test('controller → "Main Router"', () {
      const node = MeshNodeInfo(
        deviceId: 'router',
        name: 'Router',
        isController: true,
      );
      expect(node.backhaulLabel, 'Main Router');
    });

    test('wired satellite → "Wired backhaul"', () {
      const node = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Office',
        isController: false,
        backhaulType: 'Wired',
      );
      expect(node.backhaulLabel, 'Wired backhaul');
    });

    test('wireless satellite with RSSI → shows dBm', () {
      const node = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
        backhaulType: 'Wireless',
        backhaulRssi: -55,
      );
      expect(node.backhaulLabel, 'Wireless -55 dBm');
    });

    test('wireless satellite without RSSI → just "Wireless"', () {
      const node = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
        backhaulType: 'Wireless',
      );
      expect(node.backhaulLabel, 'Wireless');
    });
  });

  group('MeshNodeInfo — Equatable', () {
    test('same props → equal', () {
      const a = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
        backhaulRssi: -55,
      );
      const b = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
        backhaulRssi: -55,
      );
      expect(a, equals(b));
    });

    test('different props → not equal', () {
      const a = MeshNodeInfo(
        deviceId: 'sat-1',
        name: 'Living Room',
        isController: false,
      );
      const b = MeshNodeInfo(
        deviceId: 'sat-2',
        name: 'Bedroom',
        isController: false,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
