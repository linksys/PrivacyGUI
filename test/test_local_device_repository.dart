import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';
import 'package:test/test.dart';

void main() {
  const device = Device(address: '192.168.100.1', port: '80');
  const identity = Identity(username: 'root', password: 'Belkin123');
  final repo = LocalDeviceRepository(OpenWRTClient(device, identity));

  group('test local device repository', () {
    test('test get wireless info', () async {
      final actual = await repo.getWirelessInfo();
      print('result: $actual');
    });

    test('test get system info', () async {
      final actual = await repo.getSystemInfo();
      print('result: $actual');
    });

    test('test get network info', () async {
      final actual = await repo.getNetworkInfo();
      expect(actual, isA<NetworkInfo>());
    });
  });
}
