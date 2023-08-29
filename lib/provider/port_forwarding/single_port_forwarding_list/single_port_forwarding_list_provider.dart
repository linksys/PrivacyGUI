import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/port_forwarding/single_port_forwarding_list/single_port_forwarding_list_state.dart';

final singlePortForwardingListProvider = NotifierProvider<
    SinglePortForwardingListNotifier,
    SinglePortForwardingListState>(() => SinglePortForwardingListNotifier());

class SinglePortForwardingListNotifier
    extends Notifier<SinglePortForwardingListState> {
  @override
  SinglePortForwardingListState build() =>
      const SinglePortForwardingListState();

  fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    repo
        .send(
      JNAPAction.getSinglePortForwardingRules,
      auth: true,
    )
        .then<JNAPSuccess?>((value) {
      final rules = List.from(value.output['rules'])
          .map((e) => SinglePortForwardingRule.fromJson(e))
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
