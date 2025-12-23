import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/services/dmz_settings_service.dart';

// Mock class for DMZSettingsService
class MockDMZSettingsService extends Mock implements DMZSettingsService {}

// Mock class for Ref
class MockRef extends Mock implements Ref {}

// Fake for RouterRepository
class FakeRouterRepository extends Fake implements RouterRepository {}

void main() {
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(MockRef());
  });

  setUp(() {
    container = ProviderContainer();
  });

  group('DMZSettingsProvider', () {
    group('build', () {
      test('returns default state with DMZ disabled', () {
        // Act
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.settings.current.isDMZEnabled, false);
        expect(state.settings.current.sourceType, DMZSourceType.auto);
        expect(state.settings.current.destinationType, DMZDestinationType.ip);
        expect(state.settings.original, state.settings.current);
      });

      test('initializes with default status', () {
        // Act
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.status, isNotNull);
        expect(state.status.ipAddress, '192.168.1.1');
        expect(state.status.subnetMask, '255.255.0.0');
      });
    });

    group('notifier methods', () {
      test('notifier can be accessed from container', () {
        // Act
        final notifier = container.read(dmzSettingsProvider.notifier);

        // Assert
        expect(notifier, isNotNull);
        expect(notifier, isA<DMZSettingsNotifier>());
      });
    });

    group('state updates', () {
      test('setSettings updates current settings', () {
        // Arrange
        final newSettings = DMZUISettings(
          isDMZEnabled: true,
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        container.read(dmzSettingsProvider.notifier).setSettings(newSettings);
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.settings.current, newSettings);
        // Original should not change
        expect(state.settings.original.isDMZEnabled, false);
      });

      test('setSourceType updates sourceType and clears restriction on auto',
          () {
        // Arrange
        final initialSettings = DMZUISettings(
          isDMZEnabled: true,
          sourceRestriction: DMZSourceRestrictionUI(
            firstIPAddress: '192.168.1.10',
            lastIPAddress: '192.168.1.20',
          ),
          sourceType: DMZSourceType.range,
          destinationType: DMZDestinationType.ip,
        );
        container
            .read(dmzSettingsProvider.notifier)
            .setSettings(initialSettings);

        // Act
        container
            .read(dmzSettingsProvider.notifier)
            .setSourceType(DMZSourceType.auto);
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.settings.current.sourceType, DMZSourceType.auto);
        expect(state.settings.current.sourceRestriction, null);
      });

      test('setSourceType updates to range type', () {
        // Arrange
        final initialSettings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );
        container
            .read(dmzSettingsProvider.notifier)
            .setSettings(initialSettings);

        // Act
        container
            .read(dmzSettingsProvider.notifier)
            .setSourceType(DMZSourceType.range);
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.settings.current.sourceType, DMZSourceType.range);
        expect(state.settings.current.sourceRestriction, isNotNull);
      });

      test('setDestinationType updates to MAC type and clears IP', () {
        // Arrange
        final initialSettings = DMZUISettings(
          isDMZEnabled: true,
          destinationIPAddress: '192.168.1.100',
          destinationType: DMZDestinationType.ip,
          sourceType: DMZSourceType.auto,
        );
        container
            .read(dmzSettingsProvider.notifier)
            .setSettings(initialSettings);

        // Act
        container
            .read(dmzSettingsProvider.notifier)
            .setDestinationType(DMZDestinationType.mac);
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.settings.current.destinationType, DMZDestinationType.mac);
        expect(state.settings.current.destinationIPAddress, null);
        expect(state.settings.current.destinationMACAddress, isNotNull);
      });

      test('setDestinationType updates to IP type and clears MAC', () {
        // Arrange
        final initialSettings = DMZUISettings(
          isDMZEnabled: true,
          destinationMACAddress: '00:11:22:33:44:55',
          destinationType: DMZDestinationType.mac,
          sourceType: DMZSourceType.auto,
        );
        container
            .read(dmzSettingsProvider.notifier)
            .setSettings(initialSettings);

        // Act
        container
            .read(dmzSettingsProvider.notifier)
            .setDestinationType(DMZDestinationType.ip);
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.settings.current.destinationType, DMZDestinationType.ip);
        expect(state.settings.current.destinationMACAddress, null);
        expect(state.settings.current.destinationIPAddress, isNotNull);
      });
    });

    group('preservable functionality', () {
      test('preservable contract accessor returns notifier', () {
        // Act
        final preservable = container.read(preservableDMZSettingsProvider)
            as DMZSettingsNotifier;

        // Assert
        expect(preservable, isNotNull);
        expect(preservable, isA<DMZSettingsNotifier>());
      });

      test('preservable stores original values for reset', () {
        // Arrange
        final newSettings = DMZUISettings(
          isDMZEnabled: true,
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        container.read(dmzSettingsProvider.notifier).setSettings(newSettings);
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.settings.current.isDMZEnabled, true);
        expect(state.settings.original.isDMZEnabled, false);
      });
    });

    group('isDirty tracking', () {
      test('isDirty is true when current differs from original', () {
        // Arrange
        final newSettings = DMZUISettings(
          isDMZEnabled: true,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        // Act
        container.read(dmzSettingsProvider.notifier).setSettings(newSettings);
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.isDirty, true);
      });

      test('isDirty is false when current equals original', () {
        // Act
        final state = container.read(dmzSettingsProvider);

        // Assert
        expect(state.isDirty, false);
      });
    });
  });
}
