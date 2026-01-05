
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';

void main() {
  group('TimezoneSettings', () {
    test('Equatable: same values are equal', () {
      const settings1 = TimezoneSettings(
        timezoneId: 'PST8',
        isDaylightSaving: true,
      );
      const settings2 = TimezoneSettings(
        timezoneId: 'PST8',
        isDaylightSaving: true,
      );
      expect(settings1, equals(settings2));
    });

    test('Equatable: different values are not equal', () {
      const settings1 = TimezoneSettings(
        timezoneId: 'PST8',
        isDaylightSaving: true,
      );
      const settings2 = TimezoneSettings(
        timezoneId: 'JST-9',
        isDaylightSaving: false,
      );
      expect(settings1, isNot(equals(settings2)));
    });

    test('copyWith updates specified fields only', () {
      const original = TimezoneSettings(
        timezoneId: 'PST8',
        isDaylightSaving: true,
      );
      final updated = original.copyWith(isDaylightSaving: false);

      expect(updated.timezoneId, 'PST8'); // unchanged
      expect(updated.isDaylightSaving, false); // updated
    });

    test('copyWith with no arguments returns equivalent object', () {
      const original = TimezoneSettings(
        timezoneId: 'PST8',
        isDaylightSaving: true,
      );
      final copied = original.copyWith();

      expect(copied, equals(original));
    });

    test('toMap and fromMap roundtrip', () {
      const original = TimezoneSettings(
        timezoneId: 'PST8',
        isDaylightSaving: true,
      );
      final map = original.toMap();
      final restored = TimezoneSettings.fromMap(map);

      expect(restored, equals(original));
    });

    test('toJson and fromJson roundtrip', () {
      const original = TimezoneSettings(
        timezoneId: 'JST-9',
        isDaylightSaving: false,
      );
      final jsonString = original.toJson();
      final restored = TimezoneSettings.fromJson(jsonString);

      expect(restored, equals(original));
    });

    test('toMap contains expected keys', () {
      const settings = TimezoneSettings(
        timezoneId: 'PST8',
        isDaylightSaving: true,
      );
      final map = settings.toMap();

      expect(map.containsKey('timezoneId'), true);
      expect(map.containsKey('isDaylightSaving'), true);
      expect(map['timezoneId'], 'PST8');
      expect(map['isDaylightSaving'], true);
    });
  });

  group('TimezoneStatus', () {
    test('Equatable: same values are equal', () {
      const status1 = TimezoneStatus(
        supportedTimezones: [],
        error: null,
      );
      const status2 = TimezoneStatus(
        supportedTimezones: [],
        error: null,
      );
      expect(status1, equals(status2));
    });

    test('Equatable: different values are not equal', () {
      const status1 = TimezoneStatus(
        supportedTimezones: [],
        error: null,
      );
      const status2 = TimezoneStatus(
        supportedTimezones: [],
        error: 'Some error',
      );
      expect(status1, isNot(equals(status2)));
    });

    test('copyWith updates specified fields only', () {
      const original = TimezoneStatus(
        supportedTimezones: [],
        error: null,
      );
      final updated = original.copyWith(error: 'Network error');

      expect(updated.supportedTimezones, isEmpty);
      expect(updated.error, 'Network error');
    });

    test('copyWith with supportedTimezones', () {
      const original = TimezoneStatus(
        supportedTimezones: [],
        error: null,
      );
      const newTimezone = SupportedTimezone(
        observesDST: true,
        timeZoneID: 'PST8',
        description: 'Pacific Time',
        utcOffsetMinutes: -480,
      );
      final updated = original.copyWith(supportedTimezones: [newTimezone]);

      expect(updated.supportedTimezones.length, 1);
      expect(updated.supportedTimezones.first.timeZoneID, 'PST8');
    });

    test('toMap and fromMap roundtrip', () {
      const original = TimezoneStatus(
        supportedTimezones: [
          SupportedTimezone(
            observesDST: true,
            timeZoneID: 'PST8',
            description: 'Pacific Time',
            utcOffsetMinutes: -480,
          ),
        ],
        error: null,
      );
      final map = original.toMap();
      final restored = TimezoneStatus.fromMap(map);

      expect(restored.supportedTimezones.length, 1);
      expect(restored.supportedTimezones.first.timeZoneID, 'PST8');
    });

    test('toJson and fromJson roundtrip', () {
      const original = TimezoneStatus(
        supportedTimezones: [
          SupportedTimezone(
            observesDST: false,
            timeZoneID: 'JST-9',
            description: 'Japan Standard Time',
            utcOffsetMinutes: 540,
          ),
        ],
        error: 'test error',
      );
      final jsonString = original.toJson();
      final restored = TimezoneStatus.fromJson(jsonString);

      expect(restored.supportedTimezones.first.timeZoneID, 'JST-9');
      expect(restored.error, 'test error');
    });
  });

  group('TimezoneState', () {
    test('init creates default state', () {
      final state = TimezoneState.init();

      expect(state.settings, isNotNull);
      expect(state.status, isNotNull);
      expect(state.settings.current.timezoneId, 'PST8');
      expect(state.settings.current.isDaylightSaving, true);
      expect(state.status.supportedTimezones, isEmpty);
      expect(state.status.error, isNull);
    });

    test('init creates state with original equals current', () {
      final state = TimezoneState.init();

      expect(state.settings.original, equals(state.settings.current));
    });

    test('Equatable: same values are equal', () {
      final state1 = TimezoneState.init();
      final state2 = TimezoneState.init();

      expect(state1, equals(state2));
    });

    test('copyWith updates settings', () {
      final original = TimezoneState.init();
      final newSettings = original.settings.copyWith(
        current: const TimezoneSettings(
          timezoneId: 'JST-9',
          isDaylightSaving: false,
        ),
      );
      final updated = original.copyWith(settings: newSettings);

      expect(updated.settings.current.timezoneId, 'JST-9');
      expect(updated.status, equals(original.status));
    });

    test('copyWith updates status', () {
      final original = TimezoneState.init();
      const newStatus = TimezoneStatus(
        supportedTimezones: [
          SupportedTimezone(
            observesDST: true,
            timeZoneID: 'EST5EDT',
            description: 'Eastern Time',
            utcOffsetMinutes: -300,
          ),
        ],
        error: null,
      );
      final updated = original.copyWith(status: newStatus);

      expect(updated.status.supportedTimezones.length, 1);
      expect(updated.settings, equals(original.settings));
    });

    test('toMap and fromMap roundtrip', () {
      final original = TimezoneState.init();
      final map = original.toMap();
      final restored = TimezoneState.fromMap(map);

      expect(restored.settings.current.timezoneId,
          original.settings.current.timezoneId);
      expect(restored.settings.current.isDaylightSaving,
          original.settings.current.isDaylightSaving);
    });

    test('toJson and fromJson roundtrip', () {
      final original = TimezoneState.init();
      final jsonString = original.toJson();
      final restored = TimezoneState.fromJson(jsonString);

      expect(restored.settings.current, equals(original.settings.current));
    });

    test('toMap contains expected keys', () {
      final state = TimezoneState.init();
      final map = state.toMap();

      expect(map.containsKey('settings'), true);
      expect(map.containsKey('status'), true);
    });
  });
}
