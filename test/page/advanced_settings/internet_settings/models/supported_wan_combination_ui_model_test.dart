import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/supported_wan_combination_ui_model.dart';

void main() {
  group('SupportedWANCombinationUIModel', () {
    test('creates model with required fields', () {
      // Act
      const model = SupportedWANCombinationUIModel(
        wanType: 'DHCP',
        wanIPv6Type: 'Automatic',
      );

      // Assert
      expect(model.wanType, 'DHCP');
      expect(model.wanIPv6Type, 'Automatic');
    });

    test('copyWith creates new instance with updated values', () {
      // Arrange
      const original = SupportedWANCombinationUIModel(
        wanType: 'DHCP',
        wanIPv6Type: 'Automatic',
      );

      // Act
      final updated = original.copyWith(
        wanType: 'Static',
      );

      // Assert
      expect(updated.wanType, 'Static');
      expect(updated.wanIPv6Type, 'Automatic');
    });

    test('copyWith updates both fields', () {
      // Arrange
      const original = SupportedWANCombinationUIModel(
        wanType: 'DHCP',
        wanIPv6Type: 'Automatic',
      );

      // Act
      final updated = original.copyWith(
        wanType: 'PPPoE',
        wanIPv6Type: 'PPPoE',
      );

      // Assert
      expect(updated.wanType, 'PPPoE');
      expect(updated.wanIPv6Type, 'PPPoE');
    });

    test('toMap converts model to map', () {
      // Arrange
      const model = SupportedWANCombinationUIModel(
        wanType: 'DHCP',
        wanIPv6Type: 'Automatic',
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map['wanType'], 'DHCP');
      expect(map['wanIPv6Type'], 'Automatic');
      expect(map.length, 2);
    });

    test('fromMap creates model from map', () {
      // Arrange
      final map = {
        'wanType': 'Static',
        'wanIPv6Type': 'Pass-through',
      };

      // Act
      final model = SupportedWANCombinationUIModel.fromMap(map);

      // Assert
      expect(model.wanType, 'Static');
      expect(model.wanIPv6Type, 'Pass-through');
    });

    test('toJson and fromJson work correctly', () {
      // Arrange
      const original = SupportedWANCombinationUIModel(
        wanType: 'PPPoE',
        wanIPv6Type: 'Automatic',
      );

      // Act
      final json = original.toJson();
      final restored = SupportedWANCombinationUIModel.fromJson(json);

      // Assert
      expect(restored, original);
    });

    test('equality works correctly', () {
      // Arrange
      const model1 = SupportedWANCombinationUIModel(
        wanType: 'DHCP',
        wanIPv6Type: 'Automatic',
      );

      const model2 = SupportedWANCombinationUIModel(
        wanType: 'DHCP',
        wanIPv6Type: 'Automatic',
      );

      const model3 = SupportedWANCombinationUIModel(
        wanType: 'Static',
        wanIPv6Type: 'Automatic',
      );

      // Assert
      expect(model1, model2);
      expect(model1, isNot(model3));
    });

    test('equality considers both fields', () {
      // Arrange
      const model1 = SupportedWANCombinationUIModel(
        wanType: 'DHCP',
        wanIPv6Type: 'Automatic',
      );

      const model2 = SupportedWANCombinationUIModel(
        wanType: 'DHCP',
        wanIPv6Type: 'Pass-through',
      );

      // Assert
      expect(model1, isNot(model2));
    });

    test('stringify returns string representation', () {
      // Arrange
      const model = SupportedWANCombinationUIModel(
        wanType: 'DHCP',
        wanIPv6Type: 'Automatic',
      );

      // Act
      final stringValue = model.toString();

      // Assert
      expect(stringValue, contains('DHCP'));
      expect(stringValue, contains('Automatic'));
    });
  });
}
