import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_status.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('DMZSourceRestrictionUI', () {
    group('construction & defaults', () {
      test('creates instance with provided values', () {
        // Act
        const restriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );

        // Assert
        expect(restriction.firstIPAddress, '192.168.1.10');
        expect(restriction.lastIPAddress, '192.168.1.20');
      });

      test('equality works for identical values', () {
        // Arrange
        const restriction1 = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );
        const restriction2 = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );

        // Assert
        expect(restriction1, restriction2);
      });

      test('inequality works for different values', () {
        // Arrange
        const restriction1 = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );
        const restriction2 = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.30',
          lastIPAddress: '192.168.1.40',
        );

        // Assert
        expect(restriction1, isNot(restriction2));
      });
    });

    group('copyWith', () {
      test('creates new instance with updated firstIPAddress', () {
        // Arrange
        const restriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );

        // Act
        final updated = restriction.copyWith(firstIPAddress: '192.168.1.15');

        // Assert
        expect(updated.firstIPAddress, '192.168.1.15');
        expect(updated.lastIPAddress, '192.168.1.20');
        // Original unchanged
        expect(restriction.firstIPAddress, '192.168.1.10');
      });

      test('creates new instance with updated lastIPAddress', () {
        // Arrange
        const restriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );

        // Act
        final updated = restriction.copyWith(lastIPAddress: '192.168.1.25');

        // Assert
        expect(updated.lastIPAddress, '192.168.1.25');
        expect(updated.firstIPAddress, '192.168.1.10');
      });

      test('preserves unmodified fields', () {
        // Arrange
        const restriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );

        // Act
        final updated = restriction.copyWith();

        // Assert
        expect(updated, restriction);
      });
    });

    group('serialization', () {
      test('toMap includes all fields', () {
        // Arrange
        const restriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );

        // Act
        final map = restriction.toMap();

        // Assert
        expect(map['firstIPAddress'], '192.168.1.10');
        expect(map['lastIPAddress'], '192.168.1.20');
        expect(map.length, 2);
      });

      test('fromMap restores all fields correctly', () {
        // Arrange
        const originalRestriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );
        final map = originalRestriction.toMap();

        // Act
        final restored = DMZSourceRestrictionUI.fromMap(map);

        // Assert
        expect(restored, originalRestriction);
      });

      test('round-trip: object → map → object results in equality', () {
        // Arrange
        const original = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.50',
          lastIPAddress: '192.168.1.99',
        );

        // Act
        final map = original.toMap();
        final restored = DMZSourceRestrictionUI.fromMap(map);

        // Assert
        expect(restored, original);
        expect(restored.firstIPAddress, original.firstIPAddress);
        expect(restored.lastIPAddress, original.lastIPAddress);
      });
    });

    group('boundary cases', () {
      test('handles empty IP addresses', () {
        // Act
        const restriction = DMZSourceRestrictionUI(
          firstIPAddress: '',
          lastIPAddress: '',
        );

        // Assert
        expect(restriction.firstIPAddress, '');
        expect(restriction.lastIPAddress, '');
      });

      test('handles special IP formats', () {
        // Act
        const restriction = DMZSourceRestrictionUI(
          firstIPAddress: '0.0.0.0',
          lastIPAddress: '255.255.255.255',
        );

        // Assert
        expect(restriction.firstIPAddress, '0.0.0.0');
        expect(restriction.lastIPAddress, '255.255.255.255');
      });
    });
  });

  group('DMZUISettings', () {
    group('construction & defaults', () {
      test('creates instance with required fields', () {
        // Act
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Assert
        expect(settings.isDMZEnabled, true);
        expect(settings.sourceType, DMZSourceType.auto);
        expect(settings.destinationType, DMZDestinationType.ip);
        expect(settings.sourceRestriction, null);
        expect(settings.destinationIPAddress, null);
        expect(settings.destinationMACAddress, null);
      });

      test('creates instance with all optional fields', () {
        // Arrange
        const sourceRestriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );

        // Act
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceRestriction: sourceRestriction,
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.range,
          destinationType: DMZDestinationType.ip,
        );

        // Assert
        expect(settings.isDMZEnabled, true);
        expect(settings.sourceRestriction, sourceRestriction);
        expect(settings.destinationIPAddress, '192.168.1.100');
        expect(settings.sourceType, DMZSourceType.range);
        expect(settings.destinationType, DMZDestinationType.ip);
      });

      test('equality works for identical values', () {
        // Arrange
        const settings1 = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const settings2 = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Assert
        expect(settings1, settings2);
      });

      test('inequality works for different isDMZEnabled', () {
        // Arrange
        const settings1 = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const settings2 = DMZUISettings(
          isDMZEnabled: false,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Assert
        expect(settings1, isNot(settings2));
      });
    });

    group('copyWith', () {
      test('updates isDMZEnabled', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: false,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final updated = settings.copyWith(isDMZEnabled: true);

        // Assert
        expect(updated.isDMZEnabled, true);
        expect(updated.sourceType, DMZSourceType.auto);
      });

      test('updates sourceRestriction using ValueGetter', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const newRestriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );

        // Act
        final updated =
            settings.copyWith(sourceRestriction: () => newRestriction);

        // Assert
        expect(updated.sourceRestriction, newRestriction);
      });

      test('updates sourceRestriction to null using ValueGetter', () {
        // Arrange
        const sourceRestriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceRestriction: sourceRestriction,
          sourceType: DMZSourceType.range,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final updated = settings.copyWith(sourceRestriction: () => null);

        // Assert
        expect(updated.sourceRestriction, null);
      });

      test('updates destinationIPAddress using ValueGetter', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final updated = settings.copyWith(
          destinationIPAddress: () => '192.168.1.200',
        );

        // Assert
        expect(updated.destinationIPAddress, '192.168.1.200');
      });

      test('updates destinationMACAddress using ValueGetter', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          destinationMACAddress: '00:11:22:33:44:55',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.mac,
        );

        // Act
        final updated = settings.copyWith(
          destinationMACAddress: () => 'AA:BB:CC:DD:EE:FF',
        );

        // Assert
        expect(updated.destinationMACAddress, 'AA:BB:CC:DD:EE:FF');
      });

      test('updates sourceType', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final updated = settings.copyWith(sourceType: DMZSourceType.range);

        // Assert
        expect(updated.sourceType, DMZSourceType.range);
      });

      test('updates destinationType', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final updated =
            settings.copyWith(destinationType: DMZDestinationType.mac);

        // Assert
        expect(updated.destinationType, DMZDestinationType.mac);
      });

      test('preserves unmodified fields', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final updated = settings.copyWith();

        // Assert
        expect(updated, settings);
      });

      test('updates multiple fields at once', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: false,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final updated = settings.copyWith(
          isDMZEnabled: true,
          destinationIPAddress: () => '192.168.1.100',
          sourceType: DMZSourceType.range,
        );

        // Assert
        expect(updated.isDMZEnabled, true);
        expect(updated.destinationIPAddress, '192.168.1.100');
        expect(updated.sourceType, DMZSourceType.range);
      });
    });

    group('serialization', () {
      test('toMap includes all fields', () {
        // Arrange
        const sourceRestriction = DMZSourceRestrictionUI(
          firstIPAddress: '192.168.1.10',
          lastIPAddress: '192.168.1.20',
        );
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceRestriction: sourceRestriction,
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.range,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final map = settings.toMap();

        // Assert
        expect(map['isDMZEnabled'], true);
        expect(map['sourceRestriction'], isNotNull);
        expect(map['destinationIPAddress'], '192.168.1.100');
        expect(map['sourceType'], 'range');
        expect(map['destinationType'], 'ip');
      });

      test('toMap with null optional fields', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: false,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final map = settings.toMap();

        // Assert
        expect(map['isDMZEnabled'], false);
        expect(map['sourceRestriction'], null);
        expect(map['destinationIPAddress'], null);
        expect(map['destinationMACAddress'], null);
        expect(map['sourceType'], 'auto');
        expect(map['destinationType'], 'ip');
      });

      test('fromMap restores all fields correctly', () {
        // Arrange
        const originalSettings = DMZUISettings(
          isDMZEnabled: true,
          sourceRestriction: DMZSourceRestrictionUI(
            firstIPAddress: '192.168.1.10',
            lastIPAddress: '192.168.1.20',
          ),
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.range,
          destinationType: DMZDestinationType.ip,
        );
        final map = originalSettings.toMap();

        // Act
        final restored = DMZUISettings.fromMap(map);

        // Assert
        expect(restored, originalSettings);
      });

      test('round-trip: object → map → object results in equality', () {
        // Arrange
        const original = DMZUISettings(
          isDMZEnabled: true,
          sourceRestriction: DMZSourceRestrictionUI(
            firstIPAddress: '192.168.1.50',
            lastIPAddress: '192.168.1.99',
          ),
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.range,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        final map = original.toMap();
        final restored = DMZUISettings.fromMap(map);

        // Assert
        expect(restored, original);
      });
    });

    group('boundary cases', () {
      test('handles null sourceRestriction', () {
        // Act
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceRestriction: null,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Assert
        expect(settings.sourceRestriction, null);
      });

      test('handles empty IP addresses', () {
        // Act
        const settings = DMZUISettings(
          isDMZEnabled: true,
          destinationIPAddress: '',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Assert
        expect(settings.destinationIPAddress, '');
      });

      test('handles empty MAC addresses', () {
        // Act
        const settings = DMZUISettings(
          isDMZEnabled: true,
          destinationMACAddress: '',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.mac,
        );

        // Assert
        expect(settings.destinationMACAddress, '');
      });

      test('handles special characters in addresses', () {
        // Act
        const settings = DMZUISettings(
          isDMZEnabled: true,
          destinationMACAddress: 'ff:ff:ff:ff:ff:ff',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.mac,
        );

        // Assert
        expect(settings.destinationMACAddress, 'ff:ff:ff:ff:ff:ff');
      });
    });
  });

  group('DMZSettingsState', () {
    group('construction', () {
      test('creates state with required fields', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: false,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const status = DMZStatus();

        // Act
        const state = DMZSettingsState(
          settings: preservableSettings,
          status: status,
        );

        // Assert
        expect(state.settings, preservableSettings);
        expect(state.status, status);
      });
    });

    group('copyWith', () {
      test('updates settings', () {
        // Arrange
        const originalSettings = DMZUISettings(
          isDMZEnabled: false,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: originalSettings,
          current: originalSettings,
        );
        const state = DMZSettingsState(
          settings: preservableSettings,
          status: DMZStatus(),
        );

        const newSettings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const newPreservableSettings = Preservable(
          original: newSettings,
          current: newSettings,
        );

        // Act
        final updated = state.copyWith(settings: newPreservableSettings);

        // Assert
        expect(updated.settings, newPreservableSettings);
        expect(updated.status, state.status);
      });

      test('updates status', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: false,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const state = DMZSettingsState(
          settings: preservableSettings,
          status: DMZStatus(),
        );

        const newStatus = DMZStatus(
          ipAddress: '192.168.1.0',
          subnetMask: '255.255.255.0',
        );

        // Act
        final updated = state.copyWith(status: newStatus);

        // Assert
        expect(updated.status, newStatus);
        expect(updated.settings, state.settings);
      });

      test('preserves unmodified fields', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: false,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const state = DMZSettingsState(
          settings: preservableSettings,
          status: DMZStatus(),
        );

        // Act
        final updated = state.copyWith();

        // Assert
        expect(updated, state);
      });
    });

    group('serialization', () {
      test('toMap includes all fields', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const status = DMZStatus(
          ipAddress: '192.168.1.0',
          subnetMask: '255.255.255.0',
        );
        const state = DMZSettingsState(
          settings: preservableSettings,
          status: status,
        );

        // Act
        final map = state.toMap();

        // Assert
        expect(map['settings'], isNotNull);
        expect(map['status'], isNotNull);
      });

      test('fromMap restores all fields correctly', () {
        // Arrange
        const originalSettings = DMZUISettings(
          isDMZEnabled: true,
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: originalSettings,
          current: originalSettings,
        );
        const originalStatus = DMZStatus(
          ipAddress: '192.168.1.0',
          subnetMask: '255.255.255.0',
        );
        const originalState = DMZSettingsState(
          settings: preservableSettings,
          status: originalStatus,
        );
        final map = originalState.toMap();

        // Act
        final restored = DMZSettingsState.fromMap(map);

        // Assert
        expect(restored.settings.current, originalSettings);
        expect(restored.status, originalStatus);
      });

      test('toJson produces valid JSON string', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const state = DMZSettingsState(
          settings: preservableSettings,
          status: DMZStatus(),
        );

        // Act
        final json = state.toJson();

        // Assert
        expect(json, isNotNull);
        expect(json, isA<String>());
        // Should be parseable
        final decoded = jsonDecode(json);
        expect(decoded, isA<Map>());
      });

      test('fromJson parses JSON correctly', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const originalState = DMZSettingsState(
          settings: preservableSettings,
          status: DMZStatus(),
        );
        final json = originalState.toJson();

        // Act
        final restored = DMZSettingsState.fromJson(json);

        // Assert
        expect(restored.settings.current, settings);
      });

      test('round-trip: object → JSON → object results in equality', () {
        // Arrange
        const originalSettings = DMZUISettings(
          isDMZEnabled: true,
          sourceRestriction: DMZSourceRestrictionUI(
            firstIPAddress: '192.168.1.50',
            lastIPAddress: '192.168.1.99',
          ),
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.range,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: originalSettings,
          current: originalSettings,
        );
        const originalStatus = DMZStatus(
          ipAddress: '192.168.1.0',
          subnetMask: '255.255.255.0',
        );
        const originalState = DMZSettingsState(
          settings: preservableSettings,
          status: originalStatus,
        );

        // Act
        final json = originalState.toJson();
        final restored = DMZSettingsState.fromJson(json);

        // Assert
        expect(restored.settings.current, originalSettings);
        expect(restored.status, originalStatus);
      });
    });

    group('equality', () {
      test('equal states have same props', () {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const state1 = DMZSettingsState(
          settings: preservableSettings,
          status: DMZStatus(),
        );
        const state2 = DMZSettingsState(
          settings: preservableSettings,
          status: DMZStatus(),
        );

        // Assert
        expect(state1.props, state2.props);
        expect(state1, state2);
      });
    });
  });

  group('Enum conversions', () {
    test('DMZSourceType.resolve works for valid values', () {
      // Act & Assert
      expect(DMZSourceType.resolve('auto'), DMZSourceType.auto);
      expect(DMZSourceType.resolve('range'), DMZSourceType.range);
    });

    test('DMZDestinationType.resolve works for valid values', () {
      // Act & Assert
      expect(DMZDestinationType.resolve('ip'), DMZDestinationType.ip);
      expect(DMZDestinationType.resolve('mac'), DMZDestinationType.mac);
    });
  });
}
