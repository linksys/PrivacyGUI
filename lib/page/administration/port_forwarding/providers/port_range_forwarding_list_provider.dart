import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/page/administration/port_forwarding/_port_forwarding.dart';

final portRangeForwardingListProvider = NotifierProvider<
    PortRangeForwardingListNotifier,
    PortRangeForwardingListState>(() => PortRangeForwardingListNotifier());

class PortRangeForwardingListNotifier
    extends Notifier<PortRangeForwardingListState> {
  @override
  PortRangeForwardingListState build() => const PortRangeForwardingListState();

  Future fetch() async {
    ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getPortRangeForwardingRules,
            fetchRemote: true, auth: true)
        .then<JNAPSuccess?>((value) {
      final rules = List.from(value.output['rules'])
          .map((e) => PortRangeForwardingRule.fromJson(e))
          .toList();
      final int maxRules = value.output['maxRules'] ?? 50;
      final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
      state = state.copyWith(
          rules: rules, maxRules: maxRules, maxDescriptionLength: maxDesc);
    });
  }

  bool isExceedMax() {
    return state.maxRules == state.rules.length;
  }
}
