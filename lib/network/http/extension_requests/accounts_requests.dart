import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import '../../../constants/constants.dart';
import '../http_client.dart';
import '../model/cloud_app.dart';

extension MoabAccountsRequests on MoabHttpClient {
  Future<Response> getAccountSelf() async {
    final url = combineUrl(endpointGetAccountSelf);
    final header = defaultHeader
      ..addAll({moabSiteIdKey: moabRetailSiteId});
    return this.get(Uri.parse(url), headers: header);
  }
}
