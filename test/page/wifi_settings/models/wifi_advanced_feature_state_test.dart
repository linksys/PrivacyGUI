import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_feature_state.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';

void main() {
  group('WifiAdvancedFeatureState', () {
    test('initial() returns loading state with empty settings', () {
      final state = WifiAdvancedFeatureState.initial();

      expect(state.status.isLoading, isTrue);
      expect(state.status.isSaving, isFalse);
      expect(state.status.errorMessage, isNull);
      expect(state.settings.current.ieee80211hByRadio, isEmpty);
      expect(state.settings.original.ieee80211hByRadio, isEmpty);
      expect(state.isDirty, isFalse);
    });

    test('isDirty true when current differs from original', () {
      final state = WifiAdvancedFeatureState(
        settings: Preservable(
          original: const WifiAdvancedSettings(
            ieee80211hByRadio: {'Device.WiFi.Radio.1.': false},
          ),
          current: const WifiAdvancedSettings(
            ieee80211hByRadio: {'Device.WiFi.Radio.1.': true},
          ),
        ),
        status: const WifiAdvancedStatus(),
      );

      expect(state.isDirty, isTrue);
    });

    test('isDirty false when current equals original', () {
      final state = WifiAdvancedFeatureState(
        settings: Preservable(
          original: const WifiAdvancedSettings(
            ieee80211hByRadio: {'Device.WiFi.Radio.1.': true},
          ),
          current: const WifiAdvancedSettings(
            ieee80211hByRadio: {'Device.WiFi.Radio.1.': true},
          ),
        ),
        status: const WifiAdvancedStatus(),
      );

      expect(state.isDirty, isFalse);
    });

    test('copyWith creates new instance with replaced fields', () {
      final state = WifiAdvancedFeatureState.initial();
      final newStatus = const WifiAdvancedStatus(isSaving: true);

      final updated = state.copyWith(status: newStatus);

      expect(updated.status.isSaving, isTrue);
      expect(updated.settings, state.settings);
    });
  });

  group('WifiAdvancedSettings', () {
    test('isDfsEnabled true when all radios enabled', () {
      const settings = WifiAdvancedSettings(
        ieee80211hByRadio: {
          'Device.WiFi.Radio.1.': true,
          'Device.WiFi.Radio.2.': true,
        },
      );

      expect(settings.isDfsEnabled, isTrue);
    });

    test('isDfsEnabled false when any radio disabled', () {
      const settings = WifiAdvancedSettings(
        ieee80211hByRadio: {
          'Device.WiFi.Radio.1.': true,
          'Device.WiFi.Radio.2.': false,
        },
      );

      expect(settings.isDfsEnabled, isFalse);
    });

    test('isDfsEnabled false when empty', () {
      const settings = WifiAdvancedSettings.empty();
      expect(settings.isDfsEnabled, isFalse);
    });

    test('copyWith replaces ieee80211hByRadio', () {
      const settings = WifiAdvancedSettings(
        ieee80211hByRadio: {'Device.WiFi.Radio.1.': false},
      );
      final updated = settings.copyWith(
        ieee80211hByRadio: {'Device.WiFi.Radio.1.': true},
      );

      expect(updated.ieee80211hByRadio['Device.WiFi.Radio.1.'], isTrue);
    });

    test('Equatable: same values are equal', () {
      const a = WifiAdvancedSettings(
        ieee80211hByRadio: {'Device.WiFi.Radio.1.': true},
      );
      const b = WifiAdvancedSettings(
        ieee80211hByRadio: {'Device.WiFi.Radio.1.': true},
      );

      expect(a, equals(b));
    });

    test('Equatable: different values are not equal', () {
      const a = WifiAdvancedSettings(
        ieee80211hByRadio: {'Device.WiFi.Radio.1.': true},
      );
      const b = WifiAdvancedSettings(
        ieee80211hByRadio: {'Device.WiFi.Radio.1.': false},
      );

      expect(a, isNot(equals(b)));
    });
  });
}
