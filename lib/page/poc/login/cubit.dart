import 'package:bloc/bloc.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';

import '../../../packages/repository/device_repository/device_repository.dart';
import 'state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required DeviceRepository repository})
      : _repository = repository,
        super(const LoginState.unauthenticated());

  final DeviceRepository _repository;

  Future<void> login(String username, String password) async {
    bool result = await _repository.login(username, password);
    if (result) {
      emit(const LoginState.authenticated());
    } else {
      emit(const LoginState.unauthenticated());
    }
  }

  @override
  void onChange(Change<LoginState> change) {
    super.onChange(change);
    print(change);
  }
}
