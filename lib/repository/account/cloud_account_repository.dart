import 'dart:convert';
import 'dart:io';

import 'package:linksys_moab/network/http/extension_requests/extension_requests.dart';
import 'package:linksys_moab/network/http/http_client.dart';
import 'package:linksys_moab/network/http/model/cloud_account_info.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/repository/security_context_loader_mixin.dart';

class CloudAccountRepository with SCLoader {
  Future<MoabHttpClient> get _instance async =>
      MoabHttpClient.withCert(await get());

  Future<CloudAccountInfo> getAccount() async {
    return _instance.then((client) => client.getAccountSelf()).then(
        (response) => CloudAccountInfo.fromJson(json.decode(response.body)));
  }

  Future<String> addCommunicationMethods(
      String accountId, CommunicationMethod method) async {
    return _instance.then((client) => client
        .addCommunicationMethods(accountId: accountId, method: method)
        .then((response) => json.decode(response.body)['token']));
  }

  Future<void> deleteCommunicationMethods(
      String accountId, String method, String targetValue) async {
    return _instance.then((client) => client.deleteCommunicationMethods(
        accountId: accountId, method: method, targetValue: targetValue));
  }

  Future<String> verifyPassword(String accountId, String password) async {
    return _instance
        .then((client) => client.verifyAccountPassword(
            accountId: accountId, password: password))
        .then((response) => json.decode(response.body)['token']);
  }

  Future<void> changePassword(String accountId, String password, String token) async {
    return _instance
        .then((client) => client.acceptNewPassword(
        accountId: accountId, password: password, token: token));
  }
}
