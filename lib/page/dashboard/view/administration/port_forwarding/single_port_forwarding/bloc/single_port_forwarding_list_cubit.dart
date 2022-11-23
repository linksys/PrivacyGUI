import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/single_port_forwarding_rule.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/firewall_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

part 'single_port_forwarding_list_state.dart';

class SinglePortForwardingListCubit
    extends Cubit<SinglePortForwardingListState> {
  SinglePortForwardingListCubit({required RouterRepository repository})
      : _repository = repository,
        super(const SinglePortForwardingListState());

  final RouterRepository _repository;

  fetch() async {
    _repository
        .getSinglePortForwardingRules()
        .then<JnapSuccess?>((value) {
          final rules = List.from(value.output['rules']).map((e) => SinglePortForwardingRule.fromJson(e)).toList();
          final int maxRules = value.output['maxRules'] ?? 50;
          final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
          emit(state.copyWith(rules: rules, maxRules: maxRules, maxDescriptionLength: maxDesc));
    })
        .onError(
      (error, stackTrace) {
        addError(error as JnapError, stackTrace);
      },
    );
  }

  bool isExceedMax(){
    return state.maxRules == state.rules.length;
  }
}
