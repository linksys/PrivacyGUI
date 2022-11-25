import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/advanced_routing_rule.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

part 'advanced_routing_list_state.dart';

class AdvancedRoutingListCubit
    extends Cubit<AdvancedRoutingListState> {
  AdvancedRoutingListCubit({required RouterRepository repository})
      : _repository = repository,
        super(const AdvancedRoutingListState());

  final RouterRepository _repository;

  fetch() async {
    // TODO
    // _repository
    //     .getAdvancedRoutingRules()
    //     .then<JnapSuccess?>((value) {
    //       final rules = List.from(value.output['rules']).map((e) => AdvancedRoutingRule.fromJson(e)).toList();
    //       final int maxRules = value.output['maxRules'] ?? 50;
    //       final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
    //       emit(state.copyWith(rules: rules, maxRules: maxRules, maxDescriptionLength: maxDesc));
    // })
    //     .onError(
    //   (error, stackTrace) {
    //     addError(error as JnapError, stackTrace);
    //   },
    // );
  }

  bool isExceedMax(){
    return state.maxRules == state.rules.length;
  }
}
