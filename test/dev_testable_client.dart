import 'package:moab_poc/network/http/http_client.dart';

class DevTestableClient extends MoabHttpClient {

  @override
  String getHost() => 'https://dev-as1-api.moab.xvelop.com';

}