import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_status.dart';

void main() {
  group('DMZStatus', () {
    test('creates instance with default values', () {
      const status = DMZStatus();
      expect(status.ipAddress, '192.168.1.1');
      expect(status.subnetMask, '255.255.0.0');
    });

    test('creates instance with custom values', () {
      const status =
          DMZStatus(ipAddress: '10.0.0.1', subnetMask: '255.255.255.0');
      expect(status.ipAddress, '10.0.0.1');
      expect(status.subnetMask, '255.255.255.0');
    });

    test('copyWith updates specified fields', () {
      const original =
          DMZStatus(ipAddress: '192.168.1.1', subnetMask: '255.255.255.0');
      final copied = original.copyWith(ipAddress: '10.0.0.1');
      expect(copied.ipAddress, '10.0.0.1');
      expect(copied.subnetMask, '255.255.255.0');
    });

    test('toMap converts to map correctly', () {
      const status =
          DMZStatus(ipAddress: '10.0.0.1', subnetMask: '255.255.255.0');
      final map = status.toMap();
      expect(map['ipAddress'], '10.0.0.1');
      expect(map['subnetMask'], '255.255.255.0');
    });

    test('fromMap creates instance from map', () {
      final map = {'ipAddress': '10.0.0.1', 'subnetMask': '255.255.255.0'};
      final status = DMZStatus.fromMap(map);
      expect(status.ipAddress, '10.0.0.1');
      expect(status.subnetMask, '255.255.255.0');
    });

    test('fromMap uses defaults for missing values', () {
      final status = DMZStatus.fromMap(<String, dynamic>{});
      expect(status.ipAddress, '192.168.1.1');
      expect(status.subnetMask, '255.255.0.0');
    });

    test('equality comparison works correctly', () {
      const status1 =
          DMZStatus(ipAddress: '192.168.1.1', subnetMask: '255.255.255.0');
      const status2 =
          DMZStatus(ipAddress: '192.168.1.1', subnetMask: '255.255.255.0');
      const status3 =
          DMZStatus(ipAddress: '10.0.0.1', subnetMask: '255.255.255.0');
      expect(status1, status2);
      expect(status1, isNot(status3));
    });

    test('props returns correct list', () {
      const status =
          DMZStatus(ipAddress: '192.168.1.1', subnetMask: '255.255.255.0');
      expect(status.props, [status.ipAddress, status.subnetMask]);
    });
  });
}
