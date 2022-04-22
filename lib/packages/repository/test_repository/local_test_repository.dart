import '../../openwrt/openwrt.dart';
import 'base_test_repository.dart';

class LocalTestRepository extends BaseTesterRepository {
  LocalTestRepository(OpenWRTClient client) : super(client);

  @override
  Future<bool> test() async {
    try {
      await client.authenticate().then((value) => client.execute(value, [
            SystemBoardReply(ReplyStatus.unknown),
            SystemInfoReply(ReplyStatus.unknown)
          ]));
      return true;
    } catch (e) {
      return false;
    }
  }
}
