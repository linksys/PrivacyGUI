import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('InstantSafetySettings', () {
    test('Equatable: same values are equal', () {
      const settings1 = InstantSafetySettings(
        safeBrowsingType: InstantSafetyType.fortinet,
      );
      const settings2 = InstantSafetySettings(
        safeBrowsingType: InstantSafetyType.fortinet,
      );
      expect(settings1, equals(settings2));
    });

    test('Equatable: different values are not equal', () {
      const settings1 = InstantSafetySettings(
        safeBrowsingType: InstantSafetyType.fortinet,
      );
      const settings2 = InstantSafetySettings(
        safeBrowsingType: InstantSafetyType.openDNS,
      );
      expect(settings1, isNot(equals(settings2)));
    });

    test('copyWith updates specified fields only', () {
      const original = InstantSafetySettings(
        safeBrowsingType: InstantSafetyType.off,
      );
      final updated = original.copyWith(
        safeBrowsingType: InstantSafetyType.fortinet,
      );

      expect(updated.safeBrowsingType, InstantSafetyType.fortinet);
    });

    test('copyWith with no arguments returns equivalent object', () {
      const original = InstantSafetySettings(
        safeBrowsingType: InstantSafetyType.openDNS,
      );
      final copied = original.copyWith();

      expect(copied, equals(original));
    });

    test('toMap contains expected keys and values', () {
      const settings = InstantSafetySettings(
        safeBrowsingType: InstantSafetyType.fortinet,
      );
      final map = settings.toMap();

      expect(map.containsKey('safeBrowsingType'), true);
      expect(map['safeBrowsingType'], 'fortinet');
    });

    test('toMap returns correct values for all enum types', () {
      expect(
        const InstantSafetySettings(safeBrowsingType: InstantSafetyType.off)
            .toMap()['safeBrowsingType'],
        'off',
      );
      expect(
        const InstantSafetySettings(
                safeBrowsingType: InstantSafetyType.fortinet)
            .toMap()['safeBrowsingType'],
        'fortinet',
      );
      expect(
        const InstantSafetySettings(safeBrowsingType: InstantSafetyType.openDNS)
            .toMap()['safeBrowsingType'],
        'openDNS',
      );
    });

    test('default constructor creates off type', () {
      const settings = InstantSafetySettings();
      expect(settings.safeBrowsingType, InstantSafetyType.off);
    });
  });

  group('InstantSafetyType', () {
    test('reslove returns correct type for valid string', () {
      expect(InstantSafetyType.reslove('off'), InstantSafetyType.off);
      expect(InstantSafetyType.reslove('fortinet'), InstantSafetyType.fortinet);
      expect(InstantSafetyType.reslove('openDNS'), InstantSafetyType.openDNS);
    });

    test('reslove returns off for unknown string', () {
      expect(InstantSafetyType.reslove('unknown'), InstantSafetyType.off);
      expect(InstantSafetyType.reslove(''), InstantSafetyType.off);
      expect(InstantSafetyType.reslove('FORTINET'), InstantSafetyType.off);
    });
  });

  group('InstantSafetyStatus', () {
    test('Equatable: same values are equal', () {
      const status1 = InstantSafetyStatus(hasFortinet: true);
      const status2 = InstantSafetyStatus(hasFortinet: true);
      expect(status1, equals(status2));
    });

    test('Equatable: different values are not equal', () {
      const status1 = InstantSafetyStatus(hasFortinet: true);
      const status2 = InstantSafetyStatus(hasFortinet: false);
      expect(status1, isNot(equals(status2)));
    });

    test('copyWith updates specified fields only', () {
      const original = InstantSafetyStatus(hasFortinet: false);
      final updated = original.copyWith(hasFortinet: true);

      expect(updated.hasFortinet, true);
    });

    test('copyWith with no arguments returns equivalent object', () {
      const original = InstantSafetyStatus(hasFortinet: true);
      final copied = original.copyWith();

      expect(copied, equals(original));
    });

    test('toMap contains expected keys and values', () {
      const status = InstantSafetyStatus(hasFortinet: true);
      final map = status.toMap();

      expect(map.containsKey('hasFortinet'), true);
      expect(map['hasFortinet'], true);
    });

    test('default constructor creates hasFortinet false', () {
      const status = InstantSafetyStatus();
      expect(status.hasFortinet, false);
    });
  });

  group('InstantSafetyState', () {
    test('initial creates default state', () {
      final state = InstantSafetyState.initial();

      expect(state.settings, isNotNull);
      expect(state.status, isNotNull);
      expect(state.settings.current.safeBrowsingType, InstantSafetyType.off);
      expect(state.status.hasFortinet, false);
    });

    test('initial creates state with original equals current', () {
      final state = InstantSafetyState.initial();

      expect(state.settings.original, equals(state.settings.current));
    });

    test('Equatable: same values are equal', () {
      final state1 = InstantSafetyState.initial();
      final state2 = InstantSafetyState.initial();

      expect(state1, equals(state2));
    });

    test('copyWith updates settings', () {
      final original = InstantSafetyState.initial();
      final newSettings = original.settings.copyWith(
        current: const InstantSafetySettings(
          safeBrowsingType: InstantSafetyType.fortinet,
        ),
      );
      final updated = original.copyWith(settings: newSettings);

      expect(updated.settings.current.safeBrowsingType,
          InstantSafetyType.fortinet);
      expect(updated.status, equals(original.status));
    });

    test('copyWith updates status', () {
      final original = InstantSafetyState.initial();
      const newStatus = InstantSafetyStatus(hasFortinet: true);
      final updated = original.copyWith(status: newStatus);

      expect(updated.status.hasFortinet, true);
      expect(updated.settings, equals(original.settings));
    });

    test('fromMap creates state correctly', () {
      final map = {
        'safeBrowsingType': 'fortinet',
        'hasFortinet': true,
      };
      final state = InstantSafetyState.fromMap(map);

      expect(
          state.settings.current.safeBrowsingType, InstantSafetyType.fortinet);
      expect(
          state.settings.original.safeBrowsingType, InstantSafetyType.fortinet);
      expect(state.status.hasFortinet, true);
    });

    test('fromMap handles null safeBrowsingType', () {
      final map = {
        'safeBrowsingType': null,
        'hasFortinet': false,
      };
      final state = InstantSafetyState.fromMap(map);

      expect(state.settings.current.safeBrowsingType, InstantSafetyType.off);
    });

    test('fromMap handles null hasFortinet', () {
      final map = {
        'safeBrowsingType': 'openDNS',
        'hasFortinet': null,
      };
      final state = InstantSafetyState.fromMap(map);

      expect(state.status.hasFortinet, false);
    });

    test('toMap and fromMap roundtrip', () {
      final original = InstantSafetyState(
        settings: const Preservable(
          original: InstantSafetySettings(
            safeBrowsingType: InstantSafetyType.fortinet,
          ),
          current: InstantSafetySettings(
            safeBrowsingType: InstantSafetyType.fortinet,
          ),
        ),
        status: const InstantSafetyStatus(hasFortinet: true),
      );
      final map = original.toMap();
      final restored = InstantSafetyState.fromMap(map);

      expect(
        restored.settings.current.safeBrowsingType,
        original.settings.current.safeBrowsingType,
      );
      expect(restored.status.hasFortinet, original.status.hasFortinet);
    });

    test('toJson and fromJson roundtrip', () {
      final original = InstantSafetyState.initial();
      final jsonString = original.toJson();
      final restored = InstantSafetyState.fromJson(jsonString);

      expect(restored.settings.current, equals(original.settings.current));
      expect(restored.status, equals(original.status));
    });

    test('toMap contains expected keys', () {
      final state = InstantSafetyState.initial();
      final map = state.toMap();

      expect(map.containsKey('safeBrowsingType'), true);
      expect(map.containsKey('hasFortinet'), true);
    });

    test('isDirty returns false when original equals current', () {
      final state = InstantSafetyState.initial();
      expect(state.settings.isDirty, false);
    });

    test('isDirty returns true when original differs from current', () {
      final state = InstantSafetyState.initial();
      final modifiedState = state.copyWith(
        settings: state.settings.update(
          const InstantSafetySettings(
            safeBrowsingType: InstantSafetyType.fortinet,
          ),
        ),
      );
      expect(modifiedState.settings.isDirty, true);
    });
  });
}
