import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository.dart';

class LocalDeviceRepository extends DeviceRepository {
  LocalDeviceRepository(OpenWRTClient client) : super(client);

  @override
  Future getSystemInfo() async {
    // TODO
    return await client.authenticate().then((value) => client.execute(value, [
          SystemBoardReply(ReplyStatus.unknown),
          SystemInfoReply(ReplyStatus.unknown)
        ]));
  }

  @override
  Future getWirelessInfo() async {
    return await client.authenticate().then((value) => client.execute(value, [
          WirelessStateReply(ReplyStatus.unknown),
        ]));
  }

  @override
  Future<bool> login(String username, String password) async {
    try {
      await client.authenticate();
      return true;
    } catch (_) {
      return false;
    }
  }
}
