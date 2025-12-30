import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/ipv4_settings_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/ipv6_settings_ui_model.dart';

void main() {
  group('InternetSettingsUIModel', () {
    test('init creates model with default values', () {
      // Act
      final model = InternetSettingsUIModel.init();

      // Assert
      expect(model.ipv4Setting.ipv4ConnectionType, '');
      expect(model.ipv4Setting.mtu, 0);
      expect(model.ipv6Setting.ipv6ConnectionType, '');
      expect(model.ipv6Setting.isIPv6AutomaticEnabled, true);
      expect(model.macClone, false);
      expect(model.macCloneAddress, '');
    });

    test('copyWith creates new instance with updated values', () {
      // Arrange
      final original = InternetSettingsUIModel.init();

      // Act
      final updated = original.copyWith(
        macClone: true,
        macCloneAddress: () => 'AA:BB:CC:DD:EE:FF',
      );

      // Assert
      expect(updated.macClone, true);
      expect(updated.macCloneAddress, 'AA:BB:CC:DD:EE:FF');
      expect(updated.ipv4Setting, original.ipv4Setting);
      expect(updated.ipv6Setting, original.ipv6Setting);
    });

    test('copyWith with null value removes macCloneAddress', () {
      // Arrange
      final original = InternetSettingsUIModel.init().copyWith(
        macCloneAddress: () => 'AA:BB:CC:DD:EE:FF',
      );

      // Act
      final updated = original.copyWith(
        macCloneAddress: () => null,
      );

      // Assert
      expect(updated.macCloneAddress, null);
    });

    test('toMap converts model to map', () {
      // Arrange
      final model = InternetSettingsUIModel(
        ipv4Setting: const Ipv4SettingsUIModel(
          ipv4ConnectionType: 'DHCP',
          mtu: 1500,
        ),
        ipv6Setting: const Ipv6SettingsUIModel(
          ipv6ConnectionType: 'Automatic',
          isIPv6AutomaticEnabled: true,
        ),
        macClone: true,
        macCloneAddress: 'AA:BB:CC:DD:EE:FF',
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map['macClone'], true);
      expect(map['macCloneAddress'], 'AA:BB:CC:DD:EE:FF');
      expect(map['ipv4Setting'], isA<Map<String, dynamic>>());
      expect(map['ipv6Setting'], isA<Map<String, dynamic>>());
    });

    test('toMap removes null values', () {
      // Arrange
      final model = InternetSettingsUIModel(
        ipv4Setting: const Ipv4SettingsUIModel(
          ipv4ConnectionType: 'DHCP',
          mtu: 1500,
        ),
        ipv6Setting: const Ipv6SettingsUIModel(
          ipv6ConnectionType: 'Automatic',
          isIPv6AutomaticEnabled: true,
        ),
        macClone: false,
        macCloneAddress: null,
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map.containsKey('macCloneAddress'), false);
    });

    test('fromMap creates model from map', () {
      // Arrange
      final map = {
        'ipv4Setting': {
          'ipv4ConnectionType': 'DHCP',
          'mtu': 1500,
        },
        'ipv6Setting': {
          'ipv6ConnectionType': 'Automatic',
          'isIPv6AutomaticEnabled': true,
        },
        'macClone': true,
        'macCloneAddress': 'AA:BB:CC:DD:EE:FF',
      };

      // Act
      final model = InternetSettingsUIModel.fromMap(map);

      // Assert
      expect(model.macClone, true);
      expect(model.macCloneAddress, 'AA:BB:CC:DD:EE:FF');
      expect(model.ipv4Setting.ipv4ConnectionType, 'DHCP');
      expect(model.ipv4Setting.mtu, 1500);
    });

    test('toJson and fromJson work correctly', () {
      // Arrange
      final original = InternetSettingsUIModel(
        ipv4Setting: const Ipv4SettingsUIModel(
          ipv4ConnectionType: 'PPPoE',
          mtu: 1400,
        ),
        ipv6Setting: const Ipv6SettingsUIModel(
          ipv6ConnectionType: 'Automatic',
          isIPv6AutomaticEnabled: false,
        ),
        macClone: true,
        macCloneAddress: 'AA:BB:CC:DD:EE:FF',
      );

      // Act
      final json = original.toJson();
      final restored = InternetSettingsUIModel.fromJson(json);

      // Assert
      expect(restored, original);
    });

    test('equality works correctly', () {
      // Arrange
      final model1 = InternetSettingsUIModel(
        ipv4Setting: const Ipv4SettingsUIModel(
          ipv4ConnectionType: 'DHCP',
          mtu: 1500,
        ),
        ipv6Setting: const Ipv6SettingsUIModel(
          ipv6ConnectionType: 'Automatic',
          isIPv6AutomaticEnabled: true,
        ),
        macClone: true,
        macCloneAddress: 'AA:BB:CC:DD:EE:FF',
      );

      final model2 = InternetSettingsUIModel(
        ipv4Setting: const Ipv4SettingsUIModel(
          ipv4ConnectionType: 'DHCP',
          mtu: 1500,
        ),
        ipv6Setting: const Ipv6SettingsUIModel(
          ipv6ConnectionType: 'Automatic',
          isIPv6AutomaticEnabled: true,
        ),
        macClone: true,
        macCloneAddress: 'AA:BB:CC:DD:EE:FF',
      );

      final model3 = model1.copyWith(macClone: false);

      // Assert
      expect(model1, model2);
      expect(model1, isNot(model3));
    });
  });

  group('InternetSettingsStatusUIModel', () {
    test('init creates model with default values', () {
      // Act
      final model = InternetSettingsStatusUIModel.init();

      // Assert
      expect(model.supportedIPv4ConnectionType, isEmpty);
      expect(model.supportedWANCombinations, isEmpty);
      expect(model.supportedIPv6ConnectionType, isEmpty);
      expect(model.duid, '');
      expect(model.hostname, null);
      expect(model.redirection, null);
    });

    test('copyWith creates new instance with updated values', () {
      // Arrange
      final original = InternetSettingsStatusUIModel.init();

      // Act
      final updated = original.copyWith(
        duid: 'test-duid',
        hostname: () => 'test-router',
      );

      // Assert
      expect(updated.duid, 'test-duid');
      expect(updated.hostname, 'test-router');
      expect(updated.supportedIPv4ConnectionType,
          original.supportedIPv4ConnectionType);
    });

    test('toMap and fromMap work correctly', () {
      // Arrange
      final original = const InternetSettingsStatusUIModel(
        supportedIPv4ConnectionType: ['DHCP', 'PPPoE'],
        supportedWANCombinations: [],
        supportedIPv6ConnectionType: ['Automatic'],
        duid: 'test-duid',
        hostname: 'test-router',
        redirection: null,
      );

      // Act
      final map = original.toMap();
      final restored = InternetSettingsStatusUIModel.fromMap(map);

      // Assert
      expect(restored, original);
      expect(restored.supportedIPv4ConnectionType, ['DHCP', 'PPPoE']);
      expect(restored.duid, 'test-duid');
    });

    test('toJson and fromJson work correctly', () {
      // Arrange
      final original = const InternetSettingsStatusUIModel(
        supportedIPv4ConnectionType: ['Static'],
        supportedWANCombinations: [],
        supportedIPv6ConnectionType: ['PPPoE'],
        duid: 'duid-123',
        hostname: 'router',
        redirection: null,
      );

      // Act
      final json = original.toJson();
      final restored = InternetSettingsStatusUIModel.fromJson(json);

      // Assert
      expect(restored, original);
    });

    test('equality works correctly', () {
      // Arrange
      final model1 = const InternetSettingsStatusUIModel(
        supportedIPv4ConnectionType: ['DHCP'],
        supportedWANCombinations: [],
        supportedIPv6ConnectionType: ['Automatic'],
        duid: 'duid',
        hostname: 'router',
        redirection: null,
      );

      final model2 = const InternetSettingsStatusUIModel(
        supportedIPv4ConnectionType: ['DHCP'],
        supportedWANCombinations: [],
        supportedIPv6ConnectionType: ['Automatic'],
        duid: 'duid',
        hostname: 'router',
        redirection: null,
      );

      final model3 = model1.copyWith(duid: 'different-duid');

      // Assert
      expect(model1, model2);
      expect(model1, isNot(model3));
    });
  });
}
