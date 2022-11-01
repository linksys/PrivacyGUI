import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'change_auth_mode_state.dart';

class ChangeAuthModeCubit extends Cubit<ChangeAuthModeState> {
  ChangeAuthModeCubit() : super(ChangeAuthModeInitial());
  
  void changeAuthModeToPassword() {
    emit(ChangeAuthModeToPassword());
  }
  
  void changeAuthModeToPasswordless() {
    emit(ChangeAuthModeToPasswordless());
  }

  void reset() {
    emit(ChangeAuthModeInitial());
  }
}
