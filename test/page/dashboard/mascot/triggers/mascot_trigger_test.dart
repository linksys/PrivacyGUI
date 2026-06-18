import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/mascot/triggers/mascot_trigger.dart';

void main() {
  group('MascotTrigger', () {
    test('creates with required fields', () {
      const trigger = MascotTrigger(
        id: 'test_trigger',
        message: 'Test message',
      );

      expect(trigger.id, 'test_trigger');
      expect(trigger.message, 'Test message');
      expect(trigger.priority, TriggerPriority.medium);
      expect(trigger.cooldown, const Duration(minutes: 5));
      expect(trigger.interruptCurrent, false);
    });

    test('creates with custom priority', () {
      const trigger = MascotTrigger(
        id: 'critical_trigger',
        message: 'Critical!',
        priority: TriggerPriority.critical,
        interruptCurrent: true,
      );

      expect(trigger.priority, TriggerPriority.critical);
      expect(trigger.interruptCurrent, true);
    });

    test('equality based on props', () {
      const trigger1 = MascotTrigger(id: 'test', message: 'Hello');
      const trigger2 = MascotTrigger(id: 'test', message: 'Hello');
      const trigger3 = MascotTrigger(id: 'other', message: 'Hello');

      expect(trigger1, trigger2);
      expect(trigger1, isNot(trigger3));
    });
  });

  group('TriggerCooldownState', () {
    test('initially not in cooldown', () {
      final cooldown = TriggerCooldownState();
      const trigger = MascotTrigger(id: 'test', message: 'Test');

      expect(cooldown.isInCooldown(trigger), false);
    });

    test('enters cooldown after recording', () {
      final cooldown = TriggerCooldownState();
      const trigger = MascotTrigger(
        id: 'test',
        message: 'Test',
        cooldown: Duration(minutes: 5),
      );

      cooldown.recordTrigger(trigger);
      expect(cooldown.isInCooldown(trigger), true);
    });

    test('different triggers have independent cooldowns', () {
      final cooldown = TriggerCooldownState();
      const trigger1 = MascotTrigger(id: 'test1', message: 'Test 1');
      const trigger2 = MascotTrigger(id: 'test2', message: 'Test 2');

      cooldown.recordTrigger(trigger1);

      expect(cooldown.isInCooldown(trigger1), true);
      expect(cooldown.isInCooldown(trigger2), false);
    });

    test('clearCooldown removes specific trigger', () {
      final cooldown = TriggerCooldownState();
      const trigger = MascotTrigger(id: 'test', message: 'Test');

      cooldown.recordTrigger(trigger);
      expect(cooldown.isInCooldown(trigger), true);

      cooldown.clearCooldown('test');
      expect(cooldown.isInCooldown(trigger), false);
    });

    test('clearAll removes all cooldowns', () {
      final cooldown = TriggerCooldownState();
      const trigger1 = MascotTrigger(id: 'test1', message: 'Test 1');
      const trigger2 = MascotTrigger(id: 'test2', message: 'Test 2');

      cooldown.recordTrigger(trigger1);
      cooldown.recordTrigger(trigger2);

      cooldown.clearAll();

      expect(cooldown.isInCooldown(trigger1), false);
      expect(cooldown.isInCooldown(trigger2), false);
    });

    test('cooldown expires after duration', () async {
      final cooldown = TriggerCooldownState();
      const trigger = MascotTrigger(
        id: 'test',
        message: 'Test',
        cooldown: Duration(milliseconds: 50),
      );

      cooldown.recordTrigger(trigger);
      expect(cooldown.isInCooldown(trigger), true);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(cooldown.isInCooldown(trigger), false);
    });
  });

  group('TriggerPriority', () {
    test('priority ordering', () {
      expect(TriggerPriority.critical, lessThan(TriggerPriority.high));
      expect(TriggerPriority.high, lessThan(TriggerPriority.medium));
      expect(TriggerPriority.medium, lessThan(TriggerPriority.low));
    });
  });
}
