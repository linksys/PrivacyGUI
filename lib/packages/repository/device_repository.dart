import '../openwrt/openwrt_client.dart';

abstract class DeviceRepository {
  const DeviceRepository(this.client);

  final OpenWRTClient client;

  Future<bool> login(String username, String password);
  Future<dynamic> getSystemInfo();
  Future<dynamic> getWirelessInfo();
}
