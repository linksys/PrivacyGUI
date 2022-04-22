import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';
import 'package:moab_poc/page/dashboard/cubit.dart';
import 'package:moab_poc/page/dashboard/state.dart';
import 'package:test/test.dart';

void main() {
  const device = Device(address: '192.168.100.1', port: '80');
  const identity = Identity(username: 'root', password: 'Belkin123');
  final repo = LocalDeviceRepository(OpenWRTClient(device, identity));
  group('test dashboard bloc', () {
    test('test dashboard', () async {
      DashboardCubit cubit = DashboardCubit();
      String result = await cubit.getSSID(repo);
      expect(cubit.state.runtimeType,
          const DashboardState.ssidFetched('').runtimeType);
      expect(result.isEmpty, false);
    });
  });
}
