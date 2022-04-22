import '../../openwrt/openwrt_client.dart';

abstract class BaseTesterRepository {
  const BaseTesterRepository(this.client);

  final OpenWRTClient client;

  Future<bool> test();
}
