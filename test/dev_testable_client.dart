import 'package:linksys_moab/network/http/http_client.dart';

class DevTestableClient extends MoabHttpClient {

  @override
  String getHost() => 'https://dev-as1-api.moab.xvelop.com';

}