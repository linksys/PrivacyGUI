import 'package:moab_poc/packages/openwrt/openwrt.dart';

import 'base_device_repository.dart';
import 'model/model.dart';

class LocalDeviceRepository extends DeviceRepository {
  LocalDeviceRepository(OpenWRTClient client) : super(client);

  @override
  Future<SystemInfo> getSystemInfo() async {
    final result = await client.authenticate().then((value) => client.execute(
            value, [
          SystemBoardReply(ReplyStatus.unknown),
          SystemInfoReply(ReplyStatus.unknown)
        ]));
    return SystemInfo.fromJson(result[0].data);
  }

  @override
  Future<WirelessInfoList> getWirelessInfo() async {
    final result =
        await client.authenticate().then((value) => client.execute(value, [
              WirelessStateReply(ReplyStatus.unknown),
            ]));
    return WirelessInfoList.fromJson(result.first.data);
  }

  @override
  Future<NetworkInfo> getNetworkInfo() async {
    final result = await client.authenticate().then((value) =>
        client.execute(value, [NetworkStatusReply(ReplyStatus.unknown)]));
    return NetworkInfo.fromJson(result.first.data);
  }

  @override
  Future<bool> login(String username, String password) async {
    try {
      await client.authenticate(
          input: Identity(username: username, password: password));
      return true;
    } catch (_) {
      return false;
    }
  }
}
