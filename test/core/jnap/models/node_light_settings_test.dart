import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

void main() {
  group('NodeLightSettings - fromMap', () {
    test('parses all fields correctly', () {
      final map = {
        'Enable': true,
        'StartingTime': 20,
        'EndingTime': 8,
        'AllDayOff': false,
      };

      final settings = NodeLightSettings.fromMap(map);

      expect(settings.isNightModeEnable, true);
      expect(settings.startHour, 20);
      expect(settings.endHour, 8);
      expect(settings.allDayOff, false);
    });

    test('parses minimal fields (Enable only)', () {
      final map = {
        'Enable': false,
      };

      final settings = NodeLightSettings.fromMap(map);

      expect(settings.isNightModeEnable, false);
      expect(settings.startHour, isNull);
      expect(settings.endHour, isNull);
      expect(settings.allDayOff, isNull);
    });
  });

  group('NodeLightSettings - toMap', () {
    test('excludes null fields', () {
      const settings = NodeLightSettings(
        isNightModeEnable: false,
      );

      final map = settings.toMap();

      expect(map, {'Enable': false});
      expect(map.containsKey('StartingTime'), false);
      expect(map.containsKey('EndingTime'), false);
      expect(map.containsKey('AllDayOff'), false);
    });

    test('includes all non-null fields', () {
      const settings = NodeLightSettings(
        isNightModeEnable: true,
        startHour: 20,
        endHour: 8,
        allDayOff: false,
      );

      final map = settings.toMap();

      expect(map, {
        'Enable': true,
        'StartingTime': 20,
        'EndingTime': 8,
        'AllDayOff': false,
      });
    });
  });

  group('NodeLightSettings - factory constructors', () {
    test('on() produces LED always on settings', () {
      final settings = NodeLightSettings.on();

      expect(settings.isNightModeEnable, false);
      expect(settings.startHour, isNull);
      expect(settings.endHour, isNull);
    });

    test('off() produces LED always off settings', () {
      final settings = NodeLightSettings.off();

      expect(settings.isNightModeEnable, true);
      expect(settings.startHour, 0);
      expect(settings.endHour, 24);
    });

    test('night() produces night mode settings', () {
      final settings = NodeLightSettings.night();

      expect(settings.isNightModeEnable, true);
      expect(settings.startHour, 20);
      expect(settings.endHour, 8);
    });
  });

  group('NodeLightSettings - fromStatus', () {
    test('fromStatus(on) creates same as on() factory', () {
      final fromStatus = NodeLightSettings.fromStatus(NodeLightStatus.on);
      final fromFactory = NodeLightSettings.on();

      expect(fromStatus, fromFactory);
    });

    test('fromStatus(off) creates same as off() factory', () {
      final fromStatus = NodeLightSettings.fromStatus(NodeLightStatus.off);
      final fromFactory = NodeLightSettings.off();

      expect(fromStatus, fromFactory);
    });

    test('fromStatus(night) creates same as night() factory', () {
      final fromStatus = NodeLightSettings.fromStatus(NodeLightStatus.night);
      final fromFactory = NodeLightSettings.night();

      expect(fromStatus, fromFactory);
    });
  });

  group('NodeLightSettings - copyWith', () {
    test('partial update changes only specified fields', () {
      final original = NodeLightSettings.night();
      final updated = original.copyWith(startHour: 22);

      expect(updated.isNightModeEnable, true);
      expect(updated.startHour, 22);
      expect(updated.endHour, 8);
    });

    test('preserves all fields when no changes specified', () {
      const original = NodeLightSettings(
        isNightModeEnable: true,
        startHour: 20,
        endHour: 8,
        allDayOff: false,
      );
      final updated = original.copyWith();

      expect(updated, original);
    });
  });

  group('NodeLightSettings - equality', () {
    test('two identical settings are equal', () {
      const settings1 = NodeLightSettings(
        isNightModeEnable: true,
        startHour: 20,
        endHour: 8,
      );
      const settings2 = NodeLightSettings(
        isNightModeEnable: true,
        startHour: 20,
        endHour: 8,
      );

      expect(settings1, settings2);
      expect(settings1.hashCode, settings2.hashCode);
    });

    test('different settings are not equal', () {
      const settings1 = NodeLightSettings(isNightModeEnable: true);
      const settings2 = NodeLightSettings(isNightModeEnable: false);

      expect(settings1, isNot(settings2));
    });
  });

  group('NodeLightSettings - JSON roundtrip', () {
    test('toJson and fromJson preserve all data', () {
      const original = NodeLightSettings(
        isNightModeEnable: true,
        startHour: 20,
        endHour: 8,
        allDayOff: false,
      );

      final json = original.toJson();
      final restored = NodeLightSettings.fromJson(json);

      expect(restored, original);
    });

    test('roundtrip with minimal fields', () {
      const original = NodeLightSettings(isNightModeEnable: false);

      final json = original.toJson();
      final restored = NodeLightSettings.fromJson(json);

      expect(restored.isNightModeEnable, false);
    });
  });
}
