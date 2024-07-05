import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';

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
    await repo
        .send(
      JNAPAction.getSinglePortForwardingRules,
      fetchRemote: true,
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
