import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  // ===========================================================================
  // MacFilterMode Tests
  // ===========================================================================

  group('MacFilterMode', () {
    group('reslove', () {
      test('resolves "disabled" to MacFilterMode.disabled', () {
        expect(MacFilterMode.reslove('disabled'), MacFilterMode.disabled);
      });

      test('resolves "allow" to MacFilterMode.allow', () {
        expect(MacFilterMode.reslove('allow'), MacFilterMode.allow);
      });

      test('resolves "deny" to MacFilterMode.deny', () {
        expect(MacFilterMode.reslove('deny'), MacFilterMode.deny);
      });

      test('resolves case-insensitively', () {
        expect(MacFilterMode.reslove('DISABLED'), MacFilterMode.disabled);
        expect(MacFilterMode.reslove('Allow'), MacFilterMode.allow);
        expect(MacFilterMode.reslove('DENY'), MacFilterMode.deny);
        expect(MacFilterMode.reslove('DiSaBlEd'), MacFilterMode.disabled);
      });

      test('returns disabled for unknown values', () {
        expect(MacFilterMode.reslove('unknown'), MacFilterMode.disabled);
        expect(MacFilterMode.reslove(''), MacFilterMode.disabled);
        expect(MacFilterMode.reslove('invalid'), MacFilterMode.disabled);
      });
    });

    group('isEnabled', () {
      test('returns false for disabled mode', () {
        expect(MacFilterMode.disabled.isEnabled, isFalse);
      });

      test('returns true for allow mode', () {
        expect(MacFilterMode.allow.isEnabled, isTrue);
      });

      test('returns true for deny mode', () {
        expect(MacFilterMode.deny.isEnabled, isTrue);
      });
    });
  });

  // ===========================================================================
  // InstantPrivacyStatus Tests
  // ===========================================================================

  group('InstantPrivacyStatus', () {
    test('init() creates status with disabled mode', () {
      final status = InstantPrivacyStatus.init();

      expect(status.mode, MacFilterMode.disabled);
    });

    test('copyWith creates new instance with updated mode', () {
      const original = InstantPrivacyStatus(mode: MacFilterMode.disabled);
      final copied = original.copyWith(mode: MacFilterMode.allow);

      expect(copied.mode, MacFilterMode.allow);
      expect(original.mode, MacFilterMode.disabled);
    });

    test('copyWith retains original value when not specified', () {
      const original = InstantPrivacyStatus(mode: MacFilterMode.allow);
      final copied = original.copyWith();

      expect(copied.mode, MacFilterMode.allow);
    });

    group('serialization', () {
      test('toMap converts to correct map structure', () {
        const status = InstantPrivacyStatus(mode: MacFilterMode.allow);
        final map = status.toMap();

        expect(map, {'mode': 'allow'});
      });

      test('fromMap creates instance from map', () {
        final map = {'mode': 'deny'};
        final status = InstantPrivacyStatus.fromMap(map);

        expect(status.mode, MacFilterMode.deny);
      });

      test('toJson and fromJson round-trip', () {
        const original = InstantPrivacyStatus(mode: MacFilterMode.allow);
        final json = original.toJson();
        final restored = InstantPrivacyStatus.fromJson(json);

        expect(restored, original);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const status1 = InstantPrivacyStatus(mode: MacFilterMode.allow);
        const status2 = InstantPrivacyStatus(mode: MacFilterMode.allow);

        expect(status1, status2);
      });

      test('different modes are not equal', () {
        const status1 = InstantPrivacyStatus(mode: MacFilterMode.allow);
        const status2 = InstantPrivacyStatus(mode: MacFilterMode.deny);

        expect(status1, isNot(status2));
      });
    });
  });

  // ===========================================================================
  // InstantPrivacySettings Tests
  // ===========================================================================

  group('InstantPrivacySettings', () {
    test('init() creates default settings', () {
      final settings = InstantPrivacySettings.init();

      expect(settings.mode, MacFilterMode.disabled);
      expect(settings.macAddresses, isEmpty);
      expect(settings.denyMacAddresses, isEmpty);
      expect(settings.maxMacAddresses, 32);
      expect(settings.bssids, isEmpty);
      expect(settings.myMac, isNull);
    });

    test('constructor accepts all parameters', () {
      const settings = InstantPrivacySettings(
        mode: MacFilterMode.allow,
        macAddresses: ['AA:BB:CC:DD:EE:FF'],
        denyMacAddresses: ['11:22:33:44:55:66'],
        maxMacAddresses: 64,
        bssids: ['77:88:99:AA:BB:CC'],
        myMac: 'MY:MA:CA:DD:RE:SS',
      );

      expect(settings.mode, MacFilterMode.allow);
      expect(settings.macAddresses, ['AA:BB:CC:DD:EE:FF']);
      expect(settings.denyMacAddresses, ['11:22:33:44:55:66']);
      expect(settings.maxMacAddresses, 64);
      expect(settings.bssids, ['77:88:99:AA:BB:CC']);
      expect(settings.myMac, 'MY:MA:CA:DD:RE:SS');
    });

    group('copyWith', () {
      test('creates new instance with updated values', () {
        final original = InstantPrivacySettings.init();
        final copied = original.copyWith(
          mode: MacFilterMode.allow,
          macAddresses: ['AA:BB:CC:DD:EE:FF'],
        );

        expect(copied.mode, MacFilterMode.allow);
        expect(copied.macAddresses, ['AA:BB:CC:DD:EE:FF']);
        expect(copied.denyMacAddresses, original.denyMacAddresses);
        expect(copied.maxMacAddresses, original.maxMacAddresses);
      });

      test('retains original values when not specified', () {
        const original = InstantPrivacySettings(
          mode: MacFilterMode.deny,
          macAddresses: ['AA:BB:CC:DD:EE:FF'],
          denyMacAddresses: ['11:22:33:44:55:66'],
          maxMacAddresses: 64,
          bssids: ['77:88:99:AA:BB:CC'],
          myMac: 'MY:MA:CA:DD:RE:SS',
        );
        final copied = original.copyWith();

        expect(copied, original);
      });

      test('can update all fields', () {
        final original = InstantPrivacySettings.init();
        final copied = original.copyWith(
          mode: MacFilterMode.deny,
          macAddresses: ['AA:BB:CC:DD:EE:FF'],
          denyMacAddresses: ['11:22:33:44:55:66'],
          maxMacAddresses: 64,
          bssids: ['77:88:99:AA:BB:CC'],
          myMac: 'MY:MA:CA:DD:RE:SS',
        );

        expect(copied.mode, MacFilterMode.deny);
        expect(copied.macAddresses, ['AA:BB:CC:DD:EE:FF']);
        expect(copied.denyMacAddresses, ['11:22:33:44:55:66']);
        expect(copied.maxMacAddresses, 64);
        expect(copied.bssids, ['77:88:99:AA:BB:CC']);
        expect(copied.myMac, 'MY:MA:CA:DD:RE:SS');
      });
    });

    group('serialization', () {
      test('toMap converts to correct map structure', () {
        const settings = InstantPrivacySettings(
          mode: MacFilterMode.allow,
          macAddresses: ['AA:BB:CC:DD:EE:FF'],
          denyMacAddresses: [],
          maxMacAddresses: 32,
          bssids: ['11:22:33:44:55:66'],
          myMac: 'MY:MA:CA:DD:RE:SS',
        );
        final map = settings.toMap();

        expect(map['mode'], 'allow');
        expect(map['macAddresses'], ['AA:BB:CC:DD:EE:FF']);
        expect(map['denyMacAddresses'], isEmpty);
        expect(map['maxMacAddresses'], 32);
        expect(map['bssids'], ['11:22:33:44:55:66']);
        expect(map['myMac'], 'MY:MA:CA:DD:RE:SS');
      });

      test('toMap removes null myMac', () {
        const settings = InstantPrivacySettings(
          mode: MacFilterMode.allow,
          macAddresses: [],
          denyMacAddresses: [],
          maxMacAddresses: 32,
          bssids: [],
          myMac: null,
        );
        final map = settings.toMap();

        expect(map.containsKey('myMac'), isFalse);
      });

      test('fromMap creates instance from map', () {
        final map = {
          'mode': 'deny',
          'macAddresses': ['AA:BB:CC:DD:EE:FF'],
          'denyMacAddresses': ['11:22:33:44:55:66'],
          'maxMacAddresses': 64,
          'bssids': ['77:88:99:AA:BB:CC'],
          'myMac': 'MY:MA:CA:DD:RE:SS',
        };
        final settings = InstantPrivacySettings.fromMap(map);

        expect(settings.mode, MacFilterMode.deny);
        expect(settings.macAddresses, ['AA:BB:CC:DD:EE:FF']);
        expect(settings.denyMacAddresses, ['11:22:33:44:55:66']);
        expect(settings.maxMacAddresses, 64);
        expect(settings.bssids, ['77:88:99:AA:BB:CC']);
        expect(settings.myMac, 'MY:MA:CA:DD:RE:SS');
      });

      test('fromMap handles null bssids', () {
        final map = {
          'mode': 'allow',
          'macAddresses': [],
          'denyMacAddresses': [],
          'maxMacAddresses': 32,
          'bssids': null,
          'myMac': null,
        };
        final settings = InstantPrivacySettings.fromMap(map);

        expect(settings.bssids, isEmpty);
      });

      test('toJson and fromJson round-trip', () {
        const original = InstantPrivacySettings(
          mode: MacFilterMode.allow,
          macAddresses: ['AA:BB:CC:DD:EE:FF'],
          denyMacAddresses: ['11:22:33:44:55:66'],
          maxMacAddresses: 64,
          bssids: ['77:88:99:AA:BB:CC'],
          myMac: 'MY:MA:CA:DD:RE:SS',
        );
        final json = original.toJson();
        final restored = InstantPrivacySettings.fromJson(json);

        expect(restored, original);
      });

      test('toJson and fromJson round-trip with null myMac', () {
        const original = InstantPrivacySettings(
          mode: MacFilterMode.deny,
          macAddresses: [],
          denyMacAddresses: [],
          maxMacAddresses: 32,
          bssids: [],
          myMac: null,
        );
        final json = original.toJson();
        final restored = InstantPrivacySettings.fromJson(json);

        expect(restored, original);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const settings1 = InstantPrivacySettings(
          mode: MacFilterMode.allow,
          macAddresses: ['AA:BB:CC:DD:EE:FF'],
          denyMacAddresses: [],
          maxMacAddresses: 32,
          bssids: [],
        );
        const settings2 = InstantPrivacySettings(
          mode: MacFilterMode.allow,
          macAddresses: ['AA:BB:CC:DD:EE:FF'],
          denyMacAddresses: [],
          maxMacAddresses: 32,
          bssids: [],
        );

        expect(settings1, settings2);
      });

      test('different modes are not equal', () {
        const settings1 = InstantPrivacySettings(
          mode: MacFilterMode.allow,
          macAddresses: [],
          denyMacAddresses: [],
          maxMacAddresses: 32,
        );
        const settings2 = InstantPrivacySettings(
          mode: MacFilterMode.deny,
          macAddresses: [],
          denyMacAddresses: [],
          maxMacAddresses: 32,
        );

        expect(settings1, isNot(settings2));
      });

      test('different macAddresses are not equal', () {
        const settings1 = InstantPrivacySettings(
          mode: MacFilterMode.allow,
          macAddresses: ['AA:BB:CC:DD:EE:FF'],
          denyMacAddresses: [],
          maxMacAddresses: 32,
        );
        const settings2 = InstantPrivacySettings(
          mode: MacFilterMode.allow,
          macAddresses: ['11:22:33:44:55:66'],
          denyMacAddresses: [],
          maxMacAddresses: 32,
        );

        expect(settings1, isNot(settings2));
      });
    });
  });

  // ===========================================================================
  // InstantPrivacyState Tests
  // ===========================================================================

  group('InstantPrivacyState', () {
    test('init() creates default state', () {
      final state = InstantPrivacyState.init();

      expect(state.status.mode, MacFilterMode.disabled);
      expect(state.settings.original.mode, MacFilterMode.disabled);
      expect(state.settings.current.mode, MacFilterMode.disabled);
    });

    group('copyWith', () {
      test('creates new instance with updated status', () {
        final original = InstantPrivacyState.init();
        final copied = original.copyWith(
          status: const InstantPrivacyStatus(mode: MacFilterMode.allow),
        );

        expect(copied.status.mode, MacFilterMode.allow);
        expect(original.status.mode, MacFilterMode.disabled);
      });

      test('creates new instance with updated settings', () {
        final original = InstantPrivacyState.init();
        final newSettings = Preservable(
          original: const InstantPrivacySettings(
            mode: MacFilterMode.allow,
            macAddresses: ['AA:BB:CC:DD:EE:FF'],
            denyMacAddresses: [],
            maxMacAddresses: 32,
          ),
          current: const InstantPrivacySettings(
            mode: MacFilterMode.allow,
            macAddresses: ['AA:BB:CC:DD:EE:FF'],
            denyMacAddresses: [],
            maxMacAddresses: 32,
          ),
        );
        final copied = original.copyWith(settings: newSettings);

        expect(copied.settings.current.mode, MacFilterMode.allow);
        expect(copied.settings.current.macAddresses, ['AA:BB:CC:DD:EE:FF']);
      });

      test('retains original values when not specified', () {
        final original = InstantPrivacyState.init();
        final copied = original.copyWith();

        expect(copied.status.mode, original.status.mode);
        expect(copied.settings.current.mode, original.settings.current.mode);
      });
    });

    group('serialization', () {
      test('toMap converts to correct map structure', () {
        final state = InstantPrivacyState.init();
        final map = state.toMap();

        expect(map.containsKey('status'), isTrue);
        expect(map.containsKey('settings'), isTrue);
        expect(map['status'], 'disabled');
      });

      test('toJson produces valid JSON string', () {
        final state = InstantPrivacyState.init();
        final json = state.toJson();

        expect(json, isA<String>());
        expect(json.contains('status'), isTrue);
        expect(json.contains('settings'), isTrue);
      });
    });
  });
}
