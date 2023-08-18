import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_app/bloc/device/_device.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

part 'state.dart';

class MacFilteringCubit extends Cubit<MacFilteringState> {
  MacFilteringCubit(RouterRepository repository)
      : _repository = repository,
        super(MacFilteringState.init());

  final RouterRepository _repository;

  fetch() async {}

  setEnable(bool isEnabled) {
    emit(
      state.copyWith(
          status: isEnabled ? MacFilterStatus.allow : MacFilterStatus.off),
    );
  }

  setAccess(String value) {
    final status =
        MacFilterStatus.values.firstWhereOrNull((e) => e.name == value);
    if (status != null) {
      emit(state.copyWith(status: status));
    }
  }
}
