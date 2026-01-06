import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';
import 'package:privacy_gui/providers/empty_status.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('FirewallUISettings', () {
    group('construction & defaults', () {
      test('creates instance with all required fields', () {
        // Act
        const settings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: true,
          blockNATRedirection: false,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );

        // Assert
        expect(settings.blockAnonymousRequests, true);
        expect(settings.blockIDENT, true);
        expect(settings.blockIPSec, false);
        expect(settings.blockL2TP, false);
        expect(settings.blockMulticast, true);
        expect(settings.blockNATRedirection, false);
        expect(settings.blockPPTP, true);
        expect(settings.isIPv4FirewallEnabled, true);
        expect(settings.isIPv6FirewallEnabled, false);
      });

      test('creates instance with all fields disabled', () {
        // Act
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Assert
        expect(settings.blockAnonymousRequests, false);
        expect(settings.blockIDENT, false);
        expect(settings.blockIPSec, false);
        expect(settings.blockL2TP, false);
        expect(settings.blockMulticast, false);
        expect(settings.blockNATRedirection, false);
        expect(settings.blockPPTP, false);
        expect(settings.isIPv4FirewallEnabled, false);
        expect(settings.isIPv6FirewallEnabled, false);
      });

      test('creates instance with all fields enabled', () {
        // Act
        const settings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Assert
        expect(settings.blockAnonymousRequests, true);
        expect(settings.blockIDENT, true);
        expect(settings.blockIPSec, true);
        expect(settings.blockL2TP, true);
        expect(settings.blockMulticast, true);
        expect(settings.blockNATRedirection, true);
        expect(settings.blockPPTP, true);
        expect(settings.isIPv4FirewallEnabled, true);
        expect(settings.isIPv6FirewallEnabled, true);
      });
    });

    group('copyWith', () {
      test('creates new instance (not same reference)', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final copied = settings.copyWith(blockAnonymousRequests: true);

        // Assert
        expect(identical(copied, settings), false);
        expect(copied.blockAnonymousRequests, true);
        expect(settings.blockAnonymousRequests, false);
      });

      test('preserves unmodified fields', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Act
        final copied = settings.copyWith(blockAnonymousRequests: false);

        // Assert
        expect(copied.blockAnonymousRequests, false);
        expect(copied.blockIDENT, true);
        expect(copied.blockIPSec, true);
        expect(copied.blockL2TP, true);
        expect(copied.blockMulticast, true);
        expect(copied.blockNATRedirection, true);
        expect(copied.blockPPTP, true);
        expect(copied.isIPv4FirewallEnabled, true);
        expect(copied.isIPv6FirewallEnabled, true);
      });

      test('updates blockIDENT', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final updated = settings.copyWith(blockIDENT: true);

        // Assert
        expect(updated.blockIDENT, true);
        expect(settings.blockIDENT, false);
      });

      test('updates blockIPSec', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final updated = settings.copyWith(blockIPSec: true);

        // Assert
        expect(updated.blockIPSec, true);
      });

      test('updates blockL2TP', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final updated = settings.copyWith(blockL2TP: true);

        // Assert
        expect(updated.blockL2TP, true);
      });

      test('updates blockMulticast', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final updated = settings.copyWith(blockMulticast: true);

        // Assert
        expect(updated.blockMulticast, true);
      });

      test('updates blockNATRedirection', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final updated = settings.copyWith(blockNATRedirection: true);

        // Assert
        expect(updated.blockNATRedirection, true);
      });

      test('updates blockPPTP', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final updated = settings.copyWith(blockPPTP: true);

        // Assert
        expect(updated.blockPPTP, true);
      });

      test('updates isIPv4FirewallEnabled', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final updated = settings.copyWith(isIPv4FirewallEnabled: true);

        // Assert
        expect(updated.isIPv4FirewallEnabled, true);
      });

      test('updates isIPv6FirewallEnabled', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final updated = settings.copyWith(isIPv6FirewallEnabled: true);

        // Assert
        expect(updated.isIPv6FirewallEnabled, true);
      });

      test('updates multiple fields at once', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final updated = settings.copyWith(
          blockAnonymousRequests: true,
          blockIDENT: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Assert
        expect(updated.blockAnonymousRequests, true);
        expect(updated.blockIDENT, true);
        expect(updated.isIPv4FirewallEnabled, true);
        expect(updated.isIPv6FirewallEnabled, true);
        expect(updated.blockIPSec, false);
        expect(updated.blockL2TP, false);
      });

      test('copyWith no parameters returns equal instance', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: true,
          blockL2TP: false,
          blockMulticast: true,
          blockNATRedirection: false,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final copied = settings.copyWith();

        // Assert
        expect(copied, settings);
      });
    });

    group('equality (Equatable)', () {
      test('identical settings are equal', () {
        // Arrange
        const settings1 = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );
        const settings2 = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Assert
        expect(settings1, settings2);
        expect(settings1.hashCode, settings2.hashCode);
      });

      test('different settings are not equal', () {
        // Arrange
        const settings1 = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );
        const settings2 = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Assert
        expect(settings1, isNot(settings2));
      });

      test('different blockIDENT makes settings unequal', () {
        // Arrange
        const settings1 = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: true,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );
        const settings2 = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Assert
        expect(settings1, isNot(settings2));
      });

      test('different isIPv4FirewallEnabled makes settings unequal', () {
        // Arrange
        const settings1 = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );
        const settings2 = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Assert
        expect(settings1, isNot(settings2));
      });
    });

    group('serialization', () {
      test('toMap includes all fields', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Act
        final map = settings.toMap();

        // Assert
        expect(map['blockAnonymousRequests'], true);
        expect(map['blockIDENT'], true);
        expect(map['blockIPSec'], true);
        expect(map['blockL2TP'], true);
        expect(map['blockMulticast'], true);
        expect(map['blockNATRedirection'], true);
        expect(map['blockPPTP'], true);
        expect(map['isIPv4FirewallEnabled'], true);
        expect(map['isIPv6FirewallEnabled'], true);
        expect(map.length, 9);
      });

      test('fromMap restores all fields correctly', () {
        // Arrange
        const originalSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: true,
          blockL2TP: false,
          blockMulticast: true,
          blockNATRedirection: false,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );
        final map = originalSettings.toMap();

        // Act
        final restored = FirewallUISettings.fromMap(map);

        // Assert
        expect(restored, originalSettings);
        expect(restored.blockAnonymousRequests, true);
        expect(restored.blockIDENT, false);
        expect(restored.blockIPSec, true);
        expect(restored.blockL2TP, false);
        expect(restored.blockMulticast, true);
        expect(restored.blockNATRedirection, false);
        expect(restored.blockPPTP, true);
        expect(restored.isIPv4FirewallEnabled, true);
        expect(restored.isIPv6FirewallEnabled, false);
      });

      test('round-trip: object → toMap() → fromMap() → equals(original)', () {
        // Arrange
        const original = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: false,
          blockL2TP: true,
          blockMulticast: false,
          blockNATRedirection: true,
          blockPPTP: false,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Act
        final map = original.toMap();
        final restored = FirewallUISettings.fromMap(map);

        // Assert
        expect(restored, original);
        expect(
            restored.blockAnonymousRequests, original.blockAnonymousRequests);
        expect(restored.blockIDENT, original.blockIDENT);
        expect(restored.blockIPSec, original.blockIPSec);
        expect(restored.blockL2TP, original.blockL2TP);
        expect(restored.blockMulticast, original.blockMulticast);
        expect(restored.blockNATRedirection, original.blockNATRedirection);
        expect(restored.blockPPTP, original.blockPPTP);
        expect(restored.isIPv4FirewallEnabled, original.isIPv4FirewallEnabled);
        expect(restored.isIPv6FirewallEnabled, original.isIPv6FirewallEnabled);
      });

      test('toJson returns valid JSON string', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: true,
          blockL2TP: false,
          blockMulticast: true,
          blockNATRedirection: false,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );

        // Act
        final json = settings.toJson();

        // Assert
        expect(json, isNotNull);
        expect(json, isA<String>());
        final decoded = jsonDecode(json);
        expect(decoded, isA<Map>());
        expect(decoded['blockAnonymousRequests'], true);
        expect(decoded['isIPv4FirewallEnabled'], true);
      });

      test('fromJson correctly parses JSON string', () {
        // Arrange
        const originalSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );
        final json = originalSettings.toJson();

        // Act
        final restored = FirewallUISettings.fromJson(json);

        // Assert
        expect(restored, originalSettings);
      });

      test('round-trip: object → toJson() → fromJson() → equals(original)', () {
        // Arrange
        const original = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: true,
          blockIPSec: false,
          blockL2TP: true,
          blockMulticast: false,
          blockNATRedirection: true,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: true,
        );

        // Act
        final json = original.toJson();
        final restored = FirewallUISettings.fromJson(json);

        // Assert
        expect(restored, original);
      });
    });
  });

  group('FirewallState', () {
    group('construction', () {
      test('creates state with required fields', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const status = EmptyStatus();

        // Act
        const state = FirewallState(
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
        const originalSettings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );
        const preservableSettings = Preservable(
          original: originalSettings,
          current: originalSettings,
        );
        const state = FirewallState(
          settings: preservableSettings,
          status: EmptyStatus(),
        );

        const newSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
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
        const settings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const state = FirewallState(
          settings: preservableSettings,
          status: EmptyStatus(),
        );

        const newStatus = EmptyStatus();

        // Act
        final updated = state.copyWith(status: newStatus);

        // Assert
        expect(updated.status, newStatus);
        expect(updated.settings, state.settings);
      });

      test('preserves unmodified fields', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: true,
          blockL2TP: false,
          blockMulticast: true,
          blockNATRedirection: false,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const state = FirewallState(
          settings: preservableSettings,
          status: EmptyStatus(),
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
        const settings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const state = FirewallState(
          settings: preservableSettings,
          status: EmptyStatus(),
        );

        // Act
        final map = state.toMap();

        // Assert
        expect(map['settings'], isNotNull);
        expect(map['status'], isNotNull);
      });

      test('fromMap restores all fields correctly', () {
        // Arrange
        const originalSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: true,
          blockL2TP: false,
          blockMulticast: true,
          blockNATRedirection: false,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );
        const preservableSettings = Preservable(
          original: originalSettings,
          current: originalSettings,
        );
        const originalState = FirewallState(
          settings: preservableSettings,
          status: EmptyStatus(),
        );
        final map = originalState.toMap();

        // Act
        final restored = FirewallState.fromMap(map);

        // Assert
        expect(restored.settings.current, originalSettings);
        expect(restored.status, const EmptyStatus());
      });

      test('round-trip: object → toMap() → fromMap() → equals(original)', () {
        // Arrange
        const originalSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: false,
          blockL2TP: true,
          blockMulticast: false,
          blockNATRedirection: true,
          blockPPTP: false,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );
        const preservableSettings = Preservable(
          original: originalSettings,
          current: originalSettings,
        );
        const originalState = FirewallState(
          settings: preservableSettings,
          status: EmptyStatus(),
        );

        // Act
        final map = originalState.toMap();
        final restored = FirewallState.fromMap(map);

        // Assert
        expect(restored.settings.current, originalSettings);
        expect(restored.settings.original, originalSettings);
      });

      test('fromJson parses JSON correctly', () {
        // Arrange
        const settings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: true,
          blockL2TP: false,
          blockMulticast: true,
          blockNATRedirection: false,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );
        const preservableSettings = Preservable(
          original: settings,
          current: settings,
        );
        const originalState = FirewallState(
          settings: preservableSettings,
          status: EmptyStatus(),
        );
        final map = originalState.toMap();
        final json = jsonEncode(map);

        // Act
        final restored = FirewallState.fromJson(json);

        // Assert
        expect(restored.settings.current, settings);
      });
    });
  });
}
