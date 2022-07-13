import 'dart:convert';

import 'package:http/http.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'http_client.dart';
import 'model/cloud_app.dart';

extension MoabRequests on MoabHttpClient {
  Future<Response> fetchCloudConfig() async {
    final url = cloudConfigUrl;
    return this.get(Uri.parse(url));
  }

  Future<Response> fetchAllCloudConfig() async {
    final url = allCloudConfigUrl;
    return this.get(Uri.parse(url));
  }

  Future<Response> createApp(DeviceInfo deviceInfo) async {
    final url = combineUrl(endpointCreateApps);
    final header = defaultHeader;
    return this.post(Uri.parse(url), headers: header, body: jsonEncode(deviceInfo.toJson()));
  }

  Future<Response> createAccountPreparation(String username) async {
    final url = combineUrl(endpointPostAccountPreparations);
    final header = defaultHeader;
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode({'username': username}));
  }

  Future<Response> createAccountVerifyPreparation(
      String verifyToken, CommunicationMethod method) async {
    final url = combineUrl(endpointPutAccountPreparations,
        args: {varVerifyToken: verifyToken});
    final header = defaultHeader;
    return this.put(Uri.parse(url),
        headers: header,
        body: jsonEncode({
          'communicationMethods': [method.toJson()]
        }));
  }

  Future<Response> authChallenge(AuthChallengeMethod method, {required String id, required String secret}) async {
    final url = combineUrl(endpointPostAuthChallenges);

    final appId = id;
    final appSecret = secret;

    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode(method.toJson()));
  }

  Future<Response> authChallengeVerify({required String token, required String code}) async {
    final url =
        combineUrl(endpointPutAuthChallenges, args: {varVerifyToken: token});
    final header = defaultHeader;
    // For the moment, the sequence and the type won't be changed
    return this.put(Uri.parse(url),
        headers: header,
        body: jsonEncode({'arguments': [{'sequence': 1, 'type': 'PLAIN', 'value': code}]}));
  }

  Future<Response> createAccount(CreateAccountVerified accountVerified) {
    final url = combineUrl(endpointPostCreateAccount);
    final header = defaultHeader;
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode(accountVerified.toJson()));
  }
}
