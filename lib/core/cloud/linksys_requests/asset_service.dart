import 'dart:io';

import 'package:http/http.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

import '../../../constants/_constants.dart';

extension AssetService on LinksysHttpClient {
  Future<Response> fetchLinkup({
    required String token,
  }) async {
    final endpoint = combineUrl(kFetchLinkup);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    ;

    return this.get(Uri.parse(endpoint), headers: header);
  }
}
