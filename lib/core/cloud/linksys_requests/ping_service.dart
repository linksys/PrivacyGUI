import 'dart:io';

import 'package:http/http.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

extension PingService on LinksysHttpClient {
  Future<Response> testPingPng() {
    final endpoint = combineUrl(kTestPingPng);
    final header = defaultHeader
      ..addAll({
        HttpHeaders.contentTypeHeader: 'image/png',
        HttpHeaders.expiresHeader: 'Fri, 10 Oct 2015 14:19:41 GMT',
        HttpHeaders.cacheControlHeader: 'no-cache',
      });
    return this.get(Uri.parse(endpoint), headers: header);
  }
}
