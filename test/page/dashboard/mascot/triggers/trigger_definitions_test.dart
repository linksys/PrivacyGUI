import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/mascot/triggers/mascot_trigger.dart';
import 'package:privacy_gui/page/dashboard/mascot/triggers/trigger_definitions.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  group('TriggerDefinitions', () {
    test('wanDown creates critical priority trigger', () {
      final trigger = TriggerDefinitions.wanDown(en);

      expect(trigger.id, 'wan_down');
      expect(trigger.message,
          'Internet connection lost. Check your WAN cable or contact your ISP.');
      expect(trigger.priority, TriggerPriority.critical);
      expect(trigger.interruptCurrent, true);
      expect(trigger.animation, MascotAnimationKey.sad);
    });

    test('wanRestored creates high priority trigger', () {
      final trigger = TriggerDefinitions.wanRestored(en);

      expect(trigger.id, 'wan_restored');
      expect(trigger.priority, TriggerPriority.high);
      expect(trigger.interruptCurrent, false);
      expect(trigger.animation, MascotAnimationKey.celebrate);
    });

    test('newDeviceJoined includes device name', () {
      final trigger = TriggerDefinitions.newDeviceJoined(en, 'iPhone');

      expect(trigger.id, 'new_device_joined');
      expect(trigger.message, 'New device "iPhone" joined the network.');
      expect(trigger.priority, TriggerPriority.medium);
    });

    test('wifiRadioDisabled includes band', () {
      final trigger = TriggerDefinitions.wifiRadioDisabled(en, '5GHz');

      expect(trigger.id, 'wifi_radio_disabled_5GHz');
      expect(trigger.message, contains('5GHz'));
    });

    test('firewallDisabled is high priority', () {
      final trigger = TriggerDefinitions.firewallDisabled(en);

      expect(trigger.id, 'firewall_disabled');
      expect(trigger.priority, TriggerPriority.high);
      expect(trigger.interruptCurrent, true);
    });
  });
}
