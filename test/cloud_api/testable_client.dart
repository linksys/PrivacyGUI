import 'package:linksys_moab/network/http/linksys_http_client.dart';

class TestableHttpClient extends LinksysHttpClient {

  final String host;
  TestableHttpClient(this.host);

  @override
  String getHost() => host;

}