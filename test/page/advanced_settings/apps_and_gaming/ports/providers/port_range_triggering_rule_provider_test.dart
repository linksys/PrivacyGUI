import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_rule_state.dart';

PortRangeTriggeringRule _trigger({
  String description = 'custom',
  int firstTrigger = 12000,
  int lastTrigger = 12050,
  int firstForwarded = 13000,
  int lastForwarded = 13050,
}) =>
    PortRangeTriggeringRule(
      isEnabled: true,
      firstTriggerPort: firstTrigger,
      lastTriggerPort: lastTrigger,
      firstForwardedPort: firstForwarded,
      lastForwardedPort: lastForwarded,
      description: description,
    );

void main() {
  late ProviderContainer container;
  late PortRangeTriggeringRuleNotifier notifier;

  PortRangeTriggeringRuleState rule() =>
      container.read(portRangeTriggeringRuleProvider);

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(portRangeTriggeringRuleProvider.notifier);
    // One rule: triggered by 12000-12050, forwarding 13000-13050.
    notifier.init([_trigger()], null, null);
  });

  tearDown(() => container.dispose());

  test('init holds the list, the rule being edited and its place', () {
    final rules = [_trigger()];

    notifier.init(rules, rules.first, 0);

    expect(
        rule(),
        PortRangeTriggeringRuleState(
            rules: rules, rule: rules.first, editIndex: 0));
  });

  group('the name and range rules', () {
    test('need a name', () {
      expect(notifier.isNameValid(''), isFalse);
      expect(notifier.isNameValid('IRC'), isTrue);
    });

    test('take a range of one port and a rising range, not a falling one', () {
      expect(notifier.isPortRangeValid(6667, 6667), isTrue);
      expect(notifier.isPortRangeValid(6660, 6669), isTrue);
      expect(notifier.isPortRangeValid(6669, 6660), isFalse);
    });
  });

  group('the triggered range overlap rule', () {
    test('flags a range that overlaps another rule\'s trigger range', () {
      expect(notifier.isTriggeredPortConflict(12040, 12060), isTrue);
      // Ranges share their ends.
      expect(notifier.isTriggeredPortConflict(12050, 12060), isTrue);
    });

    test('lets a range beside every trigger range through', () {
      expect(notifier.isTriggeredPortConflict(12051, 12060), isFalse);
      // Another rule's forwarded range is not a trigger range.
      expect(notifier.isTriggeredPortConflict(13000, 13050), isFalse);
    });

    test('does not hold the rule being edited against itself', () {
      notifier.init([_trigger()], _trigger(), 0);

      expect(notifier.isTriggeredPortConflict(12000, 12050), isFalse);
    });
  });

  group('the forwarded range overlap rule', () {
    test('flags a range that overlaps another rule\'s forwarded range', () {
      expect(notifier.isForwardedPortConflict(13040, 13060), isTrue);
      expect(notifier.isForwardedPortConflict(12990, 13000), isTrue);
    });

    test('lets a range beside every forwarded range through', () {
      expect(notifier.isForwardedPortConflict(13051, 13060), isFalse);
    });

    test('does not hold the rule being edited against itself', () {
      notifier.init([_trigger()], _trigger(), 0);

      expect(notifier.isForwardedPortConflict(13000, 13050), isFalse);
    });
  });

  group('isRuleValid', () {
    test('has nothing to check before a rule is open', () {
      expect(notifier.isRuleValid(), isFalse);
    });

    test('accepts a named rule whose ranges are clear of every other rule', () {
      notifier.updateRule(_trigger(
        description: 'IRC',
        firstTrigger: 6667,
        lastTrigger: 6667,
        firstForwarded: 113,
        lastForwarded: 113,
      ));

      expect(notifier.isRuleValid(), isTrue);
    });

    test('turns down a rule with no name or a falling range', () {
      final broken = <String, PortRangeTriggeringRule>{
        'no name': _trigger(
            description: '',
            firstTrigger: 6667,
            lastTrigger: 6667,
            firstForwarded: 113,
            lastForwarded: 113),
        'a falling trigger range': _trigger(
            firstTrigger: 6669,
            lastTrigger: 6667,
            firstForwarded: 113,
            lastForwarded: 113),
        'a falling forwarded range': _trigger(
            firstTrigger: 6667,
            lastTrigger: 6667,
            firstForwarded: 114,
            lastForwarded: 113),
      };

      for (final MapEntry(key: reason, value: candidate) in broken.entries) {
        notifier.updateRule(candidate);
        expect(notifier.isRuleValid(), isFalse, reason: reason);
      }
    });
  });
}
