import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_util_mixin.dart';

final portRangeTriggeringRuleProvider = NotifierProvider<
    PortRangeTriggeringRuleNotifier,
    PortRangeTriggeringRuleState>(() => PortRangeTriggeringRuleNotifier());

class PortRangeTriggeringRuleNotifier
    extends Notifier<PortRangeTriggeringRuleState> with PortUtilMixin {
  @override
  PortRangeTriggeringRuleState build() => const PortRangeTriggeringRuleState();

  void init(
    List<PortRangeTriggeringRule> rules,
    PortRangeTriggeringRule? rule,
    int? index,
  ) {
    state = state.copyWith(
      rules: rules,
      rule: () => rule,
      editIndex: () => index,
    );
  }

  void updateRule(PortRangeTriggeringRule? rule) {
    state = state.copyWith(rule: () => rule);
  }

  bool isRuleValid() {
    final rule = state.rule;
    if (rule == null) {
      return false;
    }
    return isNameValid(rule.description) &&
        isPortRangeValid(rule.firstForwardedPort, rule.lastForwardedPort) &&
        isPortRangeValid(rule.firstTriggerPort, rule.lastTriggerPort) &&
        !isForwardedPortConflict(rule.firstTriggerPort, rule.lastTriggerPort);
  }

  bool isNameValid(String name) {
    return name.isNotEmpty;
  }

  bool isTriggeredPortConflict(int firstPort, int lastPort) {
    return state.rules
        .whereIndexed((index, rule) => index != state.editIndex)
        .any((rule) => doesRangeOverlap(
              rule.firstTriggerPort,
              rule.lastTriggerPort,
              firstPort,
              lastPort,
            ));
  }

  bool isPortRangeValid(int firstPort, int lastPort) {
    return lastPort - firstPort >= 0;
  }

  bool isForwardedPortConflict(int firstPort, int lastPort) {
    return state.rules
        .whereIndexed((index, rule) => index != state.editIndex)
        .any((rule) => doesRangeOverlap(
              rule.firstForwardedPort,
              rule.lastForwardedPort,
              firstPort,
              lastPort,
            ));
  }
}
