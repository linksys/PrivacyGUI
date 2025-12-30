import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/ipv6_settings_ui_model.dart';

void main() {
  group('Ipv6SettingsUIModel', () {
    test('creates model with required fields', () {
      // Act
      const model = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
      );

      // Assert
      expect(model.ipv6ConnectionType, 'Automatic');
      expect(model.isIPv6AutomaticEnabled, true);
      expect(model.ipv6rdTunnelMode, null);
      expect(model.ipv6Prefix, null);
      expect(model.ipv6PrefixLength, null);
      expect(model.ipv6BorderRelay, null);
      expect(model.ipv6BorderRelayPrefixLength, null);
    });

    test('creates model with all fields', () {
      // Act
      const model = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
        ipv6rdTunnelMode: IPv6rdTunnelMode.manual,
        ipv6Prefix: '2001:0db8:85a3::',
        ipv6PrefixLength: 48,
        ipv6BorderRelay: '192.168.1.1',
        ipv6BorderRelayPrefixLength: 16,
      );

      // Assert
      expect(model.ipv6ConnectionType, 'Automatic');
      expect(model.isIPv6AutomaticEnabled, true);
      expect(model.ipv6rdTunnelMode, IPv6rdTunnelMode.manual);
      expect(model.ipv6Prefix, '2001:0db8:85a3::');
      expect(model.ipv6PrefixLength, 48);
      expect(model.ipv6BorderRelay, '192.168.1.1');
      expect(model.ipv6BorderRelayPrefixLength, 16);
    });

    test('copyWith creates new instance with updated values', () {
      // Arrange
      const original = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
      );

      // Act
      final updated = original.copyWith(
        isIPv6AutomaticEnabled: false,
        ipv6rdTunnelMode: () => IPv6rdTunnelMode.manual,
        ipv6Prefix: () => '2001:0db8::',
        ipv6PrefixLength: () => 64,
      );

      // Assert
      expect(updated.ipv6ConnectionType, 'Automatic');
      expect(updated.isIPv6AutomaticEnabled, false);
      expect(updated.ipv6rdTunnelMode, IPv6rdTunnelMode.manual);
      expect(updated.ipv6Prefix, '2001:0db8::');
      expect(updated.ipv6PrefixLength, 64);
    });

    test('copyWith with null value removes optional fields', () {
      // Arrange
      const original = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
        ipv6rdTunnelMode: IPv6rdTunnelMode.manual,
        ipv6Prefix: '2001:0db8::',
      );

      // Act
      final updated = original.copyWith(
        ipv6rdTunnelMode: () => null,
        ipv6Prefix: () => null,
      );

      // Assert
      expect(updated.ipv6rdTunnelMode, null);
      expect(updated.ipv6Prefix, null);
      expect(updated.ipv6ConnectionType, 'Automatic');
    });

    test('toMap converts model to map', () {
      // Arrange
      const model = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
        ipv6rdTunnelMode: IPv6rdTunnelMode.manual,
        ipv6Prefix: '2001:0db8::',
        ipv6PrefixLength: 48,
        ipv6BorderRelay: '192.168.1.1',
        ipv6BorderRelayPrefixLength: 16,
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map['ipv6ConnectionType'], 'Automatic');
      expect(map['isIPv6AutomaticEnabled'], true);
      expect(map['ipv6rdTunnelMode'], 'Manual');
      expect(map['ipv6Prefix'], '2001:0db8::');
      expect(map['ipv6PrefixLength'], 48);
      expect(map['ipv6BorderRelay'], '192.168.1.1');
      expect(map['ipv6BorderRelayPrefixLength'], 16);
    });

    test('toMap removes null values', () {
      // Arrange
      const model = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map.containsKey('ipv6rdTunnelMode'), false);
      expect(map.containsKey('ipv6Prefix'), false);
      expect(map.containsKey('ipv6PrefixLength'), false);
    });

    test('toMap converts tunnel mode enum to value', () {
      // Arrange
      const model = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
        ipv6rdTunnelMode: IPv6rdTunnelMode.automatic,
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map['ipv6rdTunnelMode'], 'Automatic');
    });

    test('fromMap creates model from map', () {
      // Arrange
      final map = {
        'ipv6ConnectionType': 'Automatic',
        'isIPv6AutomaticEnabled': true,
        'ipv6Prefix': '2001:0db8::',
        'ipv6PrefixLength': 48,
      };

      // Act
      final model = Ipv6SettingsUIModel.fromMap(map);

      // Assert
      expect(model.ipv6ConnectionType, 'Automatic');
      expect(model.isIPv6AutomaticEnabled, true);
      expect(model.ipv6Prefix, '2001:0db8::');
      expect(model.ipv6PrefixLength, 48);
    });

    test('fromMap with tunnel mode resolves enum', () {
      // Arrange
      final map = {
        'ipv6ConnectionType': 'Automatic',
        'isIPv6AutomaticEnabled': true,
        'ipv6rdTunnelMode': 'Manual',
        'ipv6Prefix': '2001:0db8::',
      };

      // Act
      final model = Ipv6SettingsUIModel.fromMap(map);

      // Assert
      expect(model.ipv6rdTunnelMode, IPv6rdTunnelMode.manual);
      expect(model.ipv6Prefix, '2001:0db8::');
    });

    test('toJson and fromJson work correctly', () {
      // Arrange
      const original = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
        ipv6rdTunnelMode: IPv6rdTunnelMode.manual,
        ipv6Prefix: '2001:0db8:85a3::',
        ipv6PrefixLength: 48,
        ipv6BorderRelay: '192.168.1.1',
        ipv6BorderRelayPrefixLength: 16,
      );

      // Act
      final json = original.toJson();
      final restored = Ipv6SettingsUIModel.fromJson(json);

      // Assert
      expect(restored, original);
    });

    test('equality works correctly', () {
      // Arrange
      const model1 = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
      );

      const model2 = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
      );

      const model3 = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: false,
      );

      // Assert
      expect(model1, model2);
      expect(model1, isNot(model3));
    });

    test('equality includes all optional fields', () {
      // Arrange
      const model1 = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
        ipv6Prefix: '2001:0db8::',
      );

      const model2 = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
        ipv6Prefix: '2001:0db8::',
      );

      const model3 = Ipv6SettingsUIModel(
        ipv6ConnectionType: 'Automatic',
        isIPv6AutomaticEnabled: true,
        ipv6Prefix: '2001:0db9::',
      );

      // Assert
      expect(model1, model2);
      expect(model1, isNot(model3));
    });
  });
}
