import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/models/invalidation_domain.dart';
import 'package:privacy_gui/page/dashboard/mascot/triggers/mascot_trigger.dart';
import 'package:privacy_gui/page/dashboard/mascot/triggers/trigger_definitions.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  group('TriggerDefinitions', () {
    test('wanDown creates critical priority trigger', () {
      final trigger = TriggerDefinitions.wanDown();

      expect(trigger.id, 'wan_down');
      expect(trigger.priority, TriggerPriority.critical);
      expect(trigger.interruptCurrent, true);
      expect(trigger.animation, MascotAnimationKey.sad);
    });

    test('wanRestored creates high priority trigger', () {
      final trigger = TriggerDefinitions.wanRestored();

      expect(trigger.id, 'wan_restored');
      expect(trigger.priority, TriggerPriority.high);
      expect(trigger.interruptCurrent, false);
      expect(trigger.animation, MascotAnimationKey.celebrate);
    });

    test('newDeviceJoined includes device name', () {
      final trigger = TriggerDefinitions.newDeviceJoined('iPhone');

      expect(trigger.id, 'new_device_joined');
      expect(trigger.message, contains('iPhone'));
      expect(trigger.priority, TriggerPriority.medium);
    });

    test('cpuHigh includes percentage', () {
      final trigger = TriggerDefinitions.cpuHigh(95);

      expect(trigger.id, 'cpu_high');
      expect(trigger.message, contains('95%'));
      expect(trigger.priority, TriggerPriority.high);
    });

    test('memoryHigh includes percentage', () {
      final trigger = TriggerDefinitions.memoryHigh(90);

      expect(trigger.id, 'memory_high');
      expect(trigger.message, contains('90%'));
    });

    test('firmwareAvailable includes version', () {
      final trigger = TriggerDefinitions.firmwareAvailable('1.0.17');

      expect(trigger.id, 'firmware_available');
      expect(trigger.message, contains('1.0.17'));
      expect(trigger.priority, TriggerPriority.low);
    });

    test('wifiRadioDisabled includes band', () {
      final trigger = TriggerDefinitions.wifiRadioDisabled('5GHz');

      expect(trigger.id, 'wifi_radio_disabled_5GHz');
      expect(trigger.message, contains('5GHz'));
    });

    test('firewallDisabled is high priority', () {
      final trigger = TriggerDefinitions.firewallDisabled();

      expect(trigger.id, 'firewall_disabled');
      expect(trigger.priority, TriggerPriority.high);
      expect(trigger.interruptCurrent, true);
    });

    test('dmzEnabled includes device name', () {
      final trigger = TriggerDefinitions.dmzEnabled('Gaming PC');

      expect(trigger.id, 'dmz_enabled');
      expect(trigger.message, contains('Gaming PC'));
      expect(trigger.priority, TriggerPriority.medium);
    });
  });

  group('TriggerDomainMapping', () {
    test('healthCriticalDomains contains expected domains', () {
      expect(
        TriggerDomainMapping.healthCriticalDomains,
        contains(InvalidationDomain.wanStatus),
      );
      expect(
        TriggerDomainMapping.healthCriticalDomains,
        contains(InvalidationDomain.connectedDevices),
      );
      expect(
        TriggerDomainMapping.healthCriticalDomains,
        contains(InvalidationDomain.wifiRadios),
      );
    });

    test('isHealthCritical returns true for critical domains', () {
      expect(
        TriggerDomainMapping.isHealthCritical(InvalidationDomain.wanStatus),
        true,
      );
      expect(
        TriggerDomainMapping.isHealthCritical(InvalidationDomain.dhcpClients),
        false,
      );
    });

    test('canTriggerNotification returns true for notification domains', () {
      expect(
        TriggerDomainMapping.canTriggerNotification(
            InvalidationDomain.wanStatus),
        true,
      );
      expect(
        TriggerDomainMapping.canTriggerNotification(
            InvalidationDomain.connectedDevices),
        true,
      );
    });
  });
}
