import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';

void main() {
  group('BackhaulInfoUIModel', () {
    const testDeviceUUID = 'test-uuid-123';
    const testConnectionType = 'Wired';
    const testTimestamp = '2026-01-07T10:30:00Z';

    group('Equatable equality', () {
      test('two instances with same values are equal', () {
        const model1 = BackhaulInfoUIModel(
          deviceUUID: testDeviceUUID,
          connectionType: testConnectionType,
          timestamp: testTimestamp,
        );
        const model2 = BackhaulInfoUIModel(
          deviceUUID: testDeviceUUID,
          connectionType: testConnectionType,
          timestamp: testTimestamp,
        );

        expect(model1, equals(model2));
        expect(model1.hashCode, equals(model2.hashCode));
      });

      test('two instances with different values are not equal', () {
        const model1 = BackhaulInfoUIModel(
          deviceUUID: testDeviceUUID,
          connectionType: testConnectionType,
          timestamp: testTimestamp,
        );
        const model2 = BackhaulInfoUIModel(
          deviceUUID: 'different-uuid',
          connectionType: testConnectionType,
          timestamp: testTimestamp,
        );

        expect(model1, isNot(equals(model2)));
      });

      test('props returns all fields', () {
        const model = BackhaulInfoUIModel(
          deviceUUID: testDeviceUUID,
          connectionType: testConnectionType,
          timestamp: testTimestamp,
        );

        expect(
            model.props, [testDeviceUUID, testConnectionType, testTimestamp]);
      });
    });

    group('toMap/fromMap roundtrip', () {
      test('toMap returns correct map structure', () {
        const model = BackhaulInfoUIModel(
          deviceUUID: testDeviceUUID,
          connectionType: testConnectionType,
          timestamp: testTimestamp,
        );

        final map = model.toMap();

        expect(map['deviceUUID'], testDeviceUUID);
        expect(map['connectionType'], testConnectionType);
        expect(map['timestamp'], testTimestamp);
      });

      test('fromMap creates correct instance', () {
        final map = {
          'deviceUUID': testDeviceUUID,
          'connectionType': testConnectionType,
          'timestamp': testTimestamp,
        };

        final model = BackhaulInfoUIModel.fromMap(map);

        expect(model.deviceUUID, testDeviceUUID);
        expect(model.connectionType, testConnectionType);
        expect(model.timestamp, testTimestamp);
      });

      test('roundtrip preserves data', () {
        const original = BackhaulInfoUIModel(
          deviceUUID: testDeviceUUID,
          connectionType: testConnectionType,
          timestamp: testTimestamp,
        );

        final restored = BackhaulInfoUIModel.fromMap(original.toMap());

        expect(restored, equals(original));
      });

      test('fromMap handles missing fields with empty strings', () {
        final map = <String, dynamic>{};

        final model = BackhaulInfoUIModel.fromMap(map);

        expect(model.deviceUUID, '');
        expect(model.connectionType, '');
        expect(model.timestamp, '');
      });
    });

    group('toJson/fromJson roundtrip', () {
      test('toJson returns valid JSON string', () {
        const model = BackhaulInfoUIModel(
          deviceUUID: testDeviceUUID,
          connectionType: testConnectionType,
          timestamp: testTimestamp,
        );

        final json = model.toJson();

        expect(json, isA<String>());
        expect(json, contains(testDeviceUUID));
        expect(json, contains(testConnectionType));
        expect(json, contains(testTimestamp));
      });

      test('fromJson creates correct instance', () {
        const jsonString =
            '{"deviceUUID":"$testDeviceUUID","connectionType":"$testConnectionType","timestamp":"$testTimestamp"}';

        final model = BackhaulInfoUIModel.fromJson(jsonString);

        expect(model.deviceUUID, testDeviceUUID);
        expect(model.connectionType, testConnectionType);
        expect(model.timestamp, testTimestamp);
      });

      test('roundtrip preserves data', () {
        const original = BackhaulInfoUIModel(
          deviceUUID: testDeviceUUID,
          connectionType: testConnectionType,
          timestamp: testTimestamp,
        );

        final restored = BackhaulInfoUIModel.fromJson(original.toJson());

        expect(restored, equals(original));
      });
    });
  });
}
