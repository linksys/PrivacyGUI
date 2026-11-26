import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';

void main() {
  group('AutoConfigurationSettings', () {
    test('reads a router set up in the factory, not yet acknowledged', () {
      final settings = AutoConfigurationSettings.fromJson(const {
        'isAutoConfigurationSupported': true,
        'autoConfigurationMethod': 'PreConfigured',
        'userAcknowledgedAutoConfiguration': false,
      });

      expect(settings.isAutoConfigurationSupported, isTrue);
      expect(settings.autoConfigurationMethod,
          AutoConfigurationMethod.preConfigured);
      expect(settings.userAcknowledgedAutoConfiguration, isFalse);
    });

    test('reads a router its parent configured', () {
      final settings = AutoConfigurationSettings.fromMap(const {
        'isAutoConfigurationSupported': true,
        'autoConfigurationMethod': 'AutoParent',
        'userAcknowledgedAutoConfiguration': true,
      });

      expect(
          settings.autoConfigurationMethod, AutoConfigurationMethod.autoParent);
    });

    test('reads no method from a router that names one it does not know', () {
      final settings = AutoConfigurationSettings.fromMap(const {
        'isAutoConfigurationSupported': false,
        'autoConfigurationMethod': 'Cloud',
      });

      expect(settings.autoConfigurationMethod, isNull);
      expect(settings.userAcknowledgedAutoConfiguration, isNull);
    });

    test('writes back what it read', () {
      const output = {
        'isAutoConfigurationSupported': true,
        'autoConfigurationMethod': 'AutoParent',
        'userAcknowledgedAutoConfiguration': false,
      };

      expect(AutoConfigurationSettings.fromJson(output).toJson(), output);
    });

    test('assumes a factory set-up when built without a method', () {
      const settings = AutoConfigurationSettings();

      expect(settings.autoConfigurationMethod,
          AutoConfigurationMethod.preConfigured);
      expect(settings.toString(), contains('preConfigured'));
    });

    test('copyWith can set and clear each field', () {
      final settings = AutoConfigurationSettings.fromMap(const {
        'isAutoConfigurationSupported': true,
        'autoConfigurationMethod': 'PreConfigured',
        'userAcknowledgedAutoConfiguration': false,
      });

      final acknowledged =
          settings.copyWith(userAcknowledgedAutoConfiguration: () => true);
      expect(acknowledged.userAcknowledgedAutoConfiguration, isTrue);
      expect(acknowledged.autoConfigurationMethod,
          AutoConfigurationMethod.preConfigured);
      expect(acknowledged, isNot(settings));

      final cleared = settings.copyWith(
        isAutoConfigurationSupported: () => null,
        autoConfigurationMethod: () => null,
      );
      expect(cleared.isAutoConfigurationSupported, isNull);
      expect(cleared.autoConfigurationMethod, isNull);
    });
  });
}
