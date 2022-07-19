import 'dart:convert';

import 'package:http/http.dart';
import 'package:moab_poc/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:moab_poc/network/http/model/cloud_communication_method.dart';
import 'package:moab_poc/network/http/model/cloud_create_account_verified.dart';
import '../constant.dart';
import '../http_client.dart';

extension MoabAuthRequests on MoabHttpClient {
  ///
  /// * 200 - {"token": "xxxxxx"}
  /// * 400 - {"code":"USERNAME_ALREADY_EXISTS","errorMessage":"Account austin.chang@linksys.com already exist","parameters":[{"name":"username","value":"austin.chang@linksys.com"}]}
  /// * 400 - {"code":"INVALID_PARAMETER","parameters":[{"name":"username","value":"must be a well-formed email address"}]}
  ///
  Future<Response> createAccountPreparation(String username) async {
    final url = combineUrl(endpointPostAccountPreparations);
    final header = defaultHeader;
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode({'username': username}));
  }

  ///
  ///  * 204 - success
  ///  * 400
  ///
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

  ///
  /// * 204 - success
  ///
  ///
  Future<Response> authChallenge(AuthChallengeMethod method,
      {required String id, required String secret}) async {
    final url = combineUrl(endpointPostAuthChallenges);

    final appId = id;
    final appSecret = secret;

    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode(method.toJson()));
  }

  ///
  ///  * 204 - success
  ///  * 400 - {"code":"INVALID_OTP","errorMessage":"Invalid OTP","parameters":[]}
  ///
  Future<Response> authChallengeVerify(
      {required String token, required String code}) async {
    final url =
        combineUrl(endpointPutAuthChallenges, args: {varVerifyToken: token});
    final header = defaultHeader;
    // TODO For the moment, the sequence and the type won't be changed
    return this.put(Uri.parse(url),
        headers: header,
        body: jsonEncode({
          'arguments': [
            {'sequence': 1, 'type': 'PLAIN', 'value': code}
          ]
        }));
  }

  ///
  /// * 200 - {"id":"82248d9d-50a7-4e35-822c-e07ed02d8063","username":"austin.chang@linksys.com","usernames":["austin.chang@linksys.com"],"status":"ACTIVE","type":"NORMAL","authenticationMode":"PASSWORD","createdAt":"2022-07-13T09:37:01.665063052Z","updatedAt":"2022-07-13T09:37:01.665063052Z"}
  ///
  Future<Response> createAccount(CreateAccountVerified accountVerified) async {
    final url = combineUrl(endpointPostCreateAccount);
    final header = defaultHeader;
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode(accountVerified.toJson()));
  }

  Future<Response> loginPrepare(CommunicationMethod method,
      {required String id, required String secret}) {
    final url = combineUrl(endpointPostLoginPrepare);
    final appId = id;
    final appSecret = secret;

    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode(method.toJson()));
  }

  Future<Response> loginPassword(String token, String password,
      {required String id, required String secret}) {
    final url = combineUrl(endpointPostLoginPassword);

    final appId = id;
    final appSecret = secret;

    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});
    return this.post(Uri.parse(url),
        headers: header, body: {'token': token, 'password': password});
  }

  Future<Response> login(String token, String? certToken,
      {required String id, required String secret}) {
    final url = combineUrl(endpointPostLogin);

    final appId = id;
    final appSecret = secret;

    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});

    final bodyPayload = {'token': token};
    if (certToken != null) {
      bodyPayload.addAll({'certToken': certToken});
    }
    return this.post(Uri.parse(url),
        headers: header, body: bodyPayload);
  }
}
