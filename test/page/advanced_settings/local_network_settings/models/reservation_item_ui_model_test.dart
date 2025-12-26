import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/reservation_item_ui_model.dart';

void main() {
  group('ReservationItemUIModel -', () {
    const testMacAddress = '00:11:22:33:44:55';
    const testIpAddress = '192.168.1.100';
    const testDescription = 'Test Device';

    test('creates instance with required fields', () {
      const model = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      expect(model.macAddress, testMacAddress);
      expect(model.ipAddress, testIpAddress);
      expect(model.description, testDescription);
    });

    test('copyWith creates new instance with updated fields', () {
      const original = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      final updated = original.copyWith(
        description: 'Updated Device',
      );

      expect(updated.macAddress, testMacAddress);
      expect(updated.ipAddress, testIpAddress);
      expect(updated.description, 'Updated Device');
    });

    test('copyWith with no parameters returns same values', () {
      const original = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      final updated = original.copyWith();

      expect(updated.macAddress, original.macAddress);
      expect(updated.ipAddress, original.ipAddress);
      expect(updated.description, original.description);
    });

    test('toMap returns correct map', () {
      const model = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      final map = model.toMap();

      expect(map['macAddress'], testMacAddress);
      expect(map['ipAddress'], testIpAddress);
      expect(map['description'], testDescription);
    });

    test('fromMap creates correct instance', () {
      final map = {
        'macAddress': testMacAddress,
        'ipAddress': testIpAddress,
        'description': testDescription,
      };

      final model = DHCPReservationUIModel.fromMap(map);

      expect(model.macAddress, testMacAddress);
      expect(model.ipAddress, testIpAddress);
      expect(model.description, testDescription);
    });

    test('toJson returns valid JSON string', () {
      const model = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      final jsonString = model.toJson();
      final decoded = json.decode(jsonString);

      expect(decoded['macAddress'], testMacAddress);
      expect(decoded['ipAddress'], testIpAddress);
      expect(decoded['description'], testDescription);
    });

    test('fromJson creates correct instance', () {
      final jsonString = json.encode({
        'macAddress': testMacAddress,
        'ipAddress': testIpAddress,
        'description': testDescription,
      });

      final model = DHCPReservationUIModel.fromJson(jsonString);

      expect(model.macAddress, testMacAddress);
      expect(model.ipAddress, testIpAddress);
      expect(model.description, testDescription);
    });

    test('Equatable props returns correct list', () {
      const model = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      expect(model.props, [testMacAddress, testIpAddress, testDescription]);
    });

    test('equality works correctly with same values', () {
      const model1 = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      const model2 = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('equality works correctly with different values', () {
      const model1 = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      const model2 = DHCPReservationUIModel(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        ipAddress: testIpAddress,
        description: testDescription,
      );

      expect(model1, isNot(equals(model2)));
    });

    test('stringify returns true', () {
      const model = DHCPReservationUIModel(
        macAddress: testMacAddress,
        ipAddress: testIpAddress,
        description: testDescription,
      );

      expect(model.stringify, isTrue);
    });
  });
}
