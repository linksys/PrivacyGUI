import 'package:bloc/bloc.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';

import 'state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState.unauthenticated());

  Future<void> login(
      {required String username, required String password}) async {
    DeviceRepository repository = LocalDeviceRepository(
        OpenWRTClient(Device(address: '192.168.100.1', port: '80')));
    bool result = await repository.login(username, password);
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
