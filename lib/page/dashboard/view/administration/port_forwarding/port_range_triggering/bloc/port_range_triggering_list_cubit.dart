import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/port_range_triggering_rule.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

part 'port_range_triggering_list_state.dart';

class PortRangeTriggeringListCubit
    extends Cubit<PortRangeTriggeringListState> {
  PortRangeTriggeringListCubit({required RouterRepository repository})
      : _repository = repository,
        super(const PortRangeTriggeringListState());

  final RouterRepository _repository;

  fetch() async {
    _repository
        .getPortRangeTriggeringRules()
        .then<JNAPSuccess?>((value) {
          final rules = List.from(value.output['rules']).map((e) => PortRangeTriggeringRule.fromJson(e)).toList();
          final int maxRules = value.output['maxRules'] ?? 50;
          final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
          emit(state.copyWith(rules: rules, maxRules: maxRules, maxDescriptionLength: maxDesc));
          return null;
    })
        .onError(
      (error, stackTrace) {
        addError(error as JNAPError, stackTrace);
        return null;
      },
    );
  }

  bool isExceedMax(){
    return state.maxRules == state.rules.length;
  }
}
