import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/network/http/linksys_http_client.dart';
import 'package:linksys_moab/network/http/linksys_requests/authorization_service.dart';
import 'package:linksys_moab/network/http/linksys_requests/device_service.dart';
import 'package:linksys_moab/repository/model/cloud_network_model.dart';
import 'package:linksys_moab/repository/model/cloud_session_model.dart';

class LinksysCloudRepository {
  final LinksysHttpClient _httpClient;

  LinksysCloudRepository({required LinksysHttpClient httpClient})
      : _httpClient = httpClient;

  Future login({required username, required password}) async {
    return _httpClient
        .passwordLogin(username: username, password: password)
        .then((response) => SessionToken.fromJson(jsonDecode(response.body)));
  }

  Future refreshToken(String refreshToken) {
    return _httpClient
        .refreshToken(token: refreshToken)
        .then((response) => SessionToken.fromJson(jsonDecode(response.body)));
  }

  Future<List<NetworkAccountAssociation>> getNetworks() async {
    final sessionToken = await const FlutterSecureStorage()
        .read(key: pSessionToken)
        .then((value) =>
            value != null ? SessionToken.fromJson(jsonDecode(value)) : null);

    return _httpClient.getNetworks(token: sessionToken?.accessToken ?? '').then(
        (response) =>
            List.from(jsonDecode(response.body)['networkAccountAssociations'])
                .map((e) => e['networkAccountAssociation'])
                .map((e) => NetworkAccountAssociation.fromJson(e))
                .toList());
  }
}
