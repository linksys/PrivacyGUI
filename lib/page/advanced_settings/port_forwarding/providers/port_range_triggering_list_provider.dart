import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';

final portRangeTriggeringListProvider = NotifierProvider<
    PortRangeTriggeringListNotifier,
    PortRangeTriggeringListState>(() => PortRangeTriggeringListNotifier());

class PortRangeTriggeringListNotifier
    extends Notifier<PortRangeTriggeringListState> {
  @override
  PortRangeTriggeringListState build() => const PortRangeTriggeringListState();

  fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    repo
        .send(
      JNAPAction.getPortRangeTriggeringRules,
      fetchRemote: true,
      auth: true,
    )
        .then<JNAPSuccess?>((value) {
      final rules = List.from(value.output['rules'])
          .map((e) => PortRangeTriggeringRule.fromJson(e))
          .toList();
      final int maxRules = value.output['maxRules'] ?? 50;
      final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
      state = state.copyWith(
          rules: rules, maxRules: maxRules, maxDescriptionLength: maxDesc);
      return null;
    }).onError(
      (error, stackTrace) {
        return null;
      },
    );
  }

  bool isExceedMax() {
    return state.maxRules == state.rules.length;
  }
}
