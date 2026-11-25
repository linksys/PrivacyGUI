import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';

/// `GetFirmwareUpdateSettings` output as JSON text: install on its own,
/// between 02:00 and 05:00.
const _autoText = '''
{
  "updatePolicy": "AutomaticallyCheckAndInstall",
  "autoUpdateWindow": {"startMinute": 120, "durationMinutes": 180}
}
''';

void main() {
  group('FirmwareUpdateSettings', () {
    test('reads the policy and its window', () {
      final settings = FirmwareUpdateSettings.fromJson(_autoText);

      expect(settings.updatePolicy,
          FirmwareUpdateSettings.firmwareUpdatePolicyAuto);
      expect(settings.autoUpdateWindow.startMinute, 120);
      expect(settings.autoUpdateWindow.durationMinutes, 180);
    });

    test('writes back what it read', () {
      expect(FirmwareUpdateSettings.fromJson(_autoText).toMap(), {
        'updatePolicy': 'AutomaticallyCheckAndInstall',
        'autoUpdateWindow': {'startMinute': 120, 'durationMinutes': 180},
      });
    });

    test('survives a trip through JSON text', () {
      final settings = FirmwareUpdateSettings.fromJson(_autoText);

      expect(FirmwareUpdateSettings.fromJson(settings.toJson()), settings);
    });

    test('copyWith changes only what it names', () {
      final settings = FirmwareUpdateSettings.fromJson(_autoText);

      final manual = settings.copyWith(
          updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyManual);

      expect(manual.updatePolicy, 'Manual');
      expect(manual.autoUpdateWindow, settings.autoUpdateWindow);
      expect(manual, isNot(settings));
    });
  });

  group('FirmwareAutoUpdateWindow', () {
    test('the default window is the first four hours of the day', () {
      expect(FirmwareAutoUpdateWindow.simple().toMap(),
          {'startMinute': 0, 'durationMinutes': 240});
    });

    test('survives a trip through JSON text, and copies', () {
      final window =
          FirmwareUpdateSettings.fromJson(_autoText).autoUpdateWindow;

      expect(FirmwareAutoUpdateWindow.fromJson(window.toJson()), window);
      final later = window.copyWith(startMinute: 180);
      expect((later.startMinute, later.durationMinutes), (180, 180));
    });
  });
}
