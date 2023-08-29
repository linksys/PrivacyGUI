import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/repository/router/extensions/firewall_extension.dart';
import 'package:linksys_app/provider/port_forwarding/port_range_forwarding_list/port_range_forwarding_list_state.dart';

final portRangeForwardingListProvider = NotifierProvider<
    PortRangeForwardingListNotifier,
    PortRangeForwardingListState>(() => PortRangeForwardingListNotifier());

class PortRangeForwardingListNotifier
    extends Notifier<PortRangeForwardingListState> {
  @override
  PortRangeForwardingListState build() => const PortRangeForwardingListState();

  fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    repo.getPortRangeForwardingRules().then<JNAPSuccess?>((value) {
      final rules = List.from(value.output['rules'])
          .map((e) => PortRangeForwardingRule.fromJson(e))
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
