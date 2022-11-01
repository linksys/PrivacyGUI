part of 'change_auth_mode_cubit.dart';

abstract class ChangeAuthModeState extends Equatable {
  const ChangeAuthModeState();
}

class ChangeAuthModeInitial extends ChangeAuthModeState {
  @override
  List<Object> get props => [];
}

class ChangeAuthModeToPasswordless extends ChangeAuthModeState {
  @override
  List<Object> get props => [];
}

class ChangeAuthModeToPassword extends ChangeAuthModeState {
  @override
  List<Object> get props => [];
}
