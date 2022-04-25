import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';

import '../../packages/repository/device_repository/device_repository.dart';
import 'state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required DeviceRepository repository})
      : _repository = repository,
        super(const LoginState.unauthenticated());

  final DeviceRepository _repository;

  Future<void> login() async {
    log('username: ${state.username}, ${state.password}');
    bool result = await _repository.login(state.username, state.password);
    if (result) {
      emit(const LoginState.authenticated());
    } else {
      emit(const LoginState.unauthenticated());
    }
  }

  onUsernameChanged(String username) {
    log('onUsernameChanged: $username');
    emit(LoginState.updateUsername(username));
  }

  onPasswordChanged(String password) {
    emit(LoginState.updatePassword(password));
  }

  @override
  void onChange(Change<LoginState> change) {
    super.onChange(change);
    print(change);
  }
}
