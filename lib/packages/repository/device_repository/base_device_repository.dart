import 'package:moab_poc/packages/repository/device_repository/model/wan_staus.dart';

import '../../openwrt/openwrt_client.dart';
import 'model/model.dart';

abstract class DeviceRepository {
  const DeviceRepository(this.client);

  final OpenWRTClient client;

  Future<bool> login(String username, String password);
  Future<SystemInfo> getSystemInfo();
  Future<WirelessInfoList> getWirelessInfo();
  Future<NetworkInfo> getNetworkInfo();
  Future<bool> sendBootstrap(String bootstrap);
  Future<WanStatus> getWanStatus();
}
