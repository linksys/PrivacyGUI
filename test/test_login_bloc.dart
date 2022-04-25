import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';
import 'package:moab_poc/page/login/cubit.dart';
import 'package:moab_poc/page/login/state.dart';
import 'package:test/test.dart';

void main() {
  const device = Device(address: '192.168.100.1', port: '80');
  const identity = Identity(username: 'root', password: 'Belkin123');
  group('test login bloc', () {
    test('test login', () async {
      LoginCubit cubit =
          LoginCubit(repository: LocalDeviceRepository(OpenWRTClient(device)));
      await cubit.login(username: 'root', password: 'Belkin123');
      expect(cubit.state, const LoginState.authenticated());
    });
  });
}
