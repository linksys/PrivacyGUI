import 'dart:developer';

import '../../openwrt/openwrt.dart';
import 'base_test_repository.dart';

class LocalTestRepository extends BaseTesterRepository {
  LocalTestRepository(OpenWRTClient client) : super(client);

  @override
  Future<bool> test() async {
    try {
      await client.authenticate(
          input: const Identity(username: 'username', password: 'password'));
      return true;
    } on Exception catch (e) {
      log("test repo: ${e}");
      return false;
    }
  }
}
