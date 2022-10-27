import 'dart:convert';

import 'package:http/http.dart';
import 'package:linksys_moab/network/http/model/cloud_auth_clallenge_method.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_create_account_verified.dart';
import '../../../constants/_constants.dart';
import '../http_client.dart';

extension MoabAuthRequests on MoabHttpClient {
  ///
  /// * 200 - {"token": "xxxxxx"}
  /// * 400 - {"code":"USERNAME_ALREADY_EXISTS","errorMessage":"Account austin.chang@linksys.com already exist","parameters":[{"name":"username","value":"austin.chang@linksys.com"}]}
  /// * 400 - {"code":"INVALID_PARAMETER","parameters":[{"name":"username","value":"must be a well-formed email address"}]}
  ///
  Future<Response> createAccountPreparation(String username) async {
    final url = await combineUrl(endpointPostAccountPreparations);
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
    final url = await combineUrl(endpointPutAccountPreparations,
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
  Future<Response> authChallenge(BaseAuthChallenge method,
      {required String id, required String secret}) async {
    final url = await combineUrl(endpointPostAuthChallenges);

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
    final url = await combineUrl(endpointPutAuthChallenges,
        args: {varVerifyToken: token});
    final header = defaultHeader;
    // TODO For the moment, the sequence and the type won't be changed
    return this
        .put(Uri.parse(url), headers: header, body: jsonEncode({'otp': code}));
  }

  Future<Response> authChallengeVerifyAccepted(
      {required String token, required String code}) async {
    final url = await combineUrl(endpointPutVerificationAccept,
        args: {varVerifyToken: token});
    final header = defaultHeader;
    // TODO For the moment, the sequence and the type won't be changed
    return this
        .put(Uri.parse(url), headers: header, body: jsonEncode({'otp': code}));
  }

  ///
  /// * 200 - {"id":"82248d9d-50a7-4e35-822c-e07ed02d8063","username":"austin.chang@linksys.com","usernames":["austin.chang@linksys.com"],"status":"ACTIVE","type":"NORMAL","authenticationMode":"PASSWORD","createdAt":"2022-07-13T09:37:01.665063052Z","updatedAt":"2022-07-13T09:37:01.665063052Z"}
  ///
  Future<Response> createAccount(CreateAccountVerified accountVerified) async {
    final url = await combineUrl(endpointPostCreateAccount);
    final header = defaultHeader;
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode(accountVerified.toJson()));
  }

  Future<Response> loginPrepare(String username,
      {required String id, required String secret}) async {
    final url = await combineUrl(endpointPostLoginPrepare);
    final appId = id;
    final appSecret = secret;

    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode({'username': username}));
  }

  Future<Response> loginPassword(String token, String password,
      {required String id, required String secret}) async {
    final url = await combineUrl(endpointPostLoginPassword);

    final appId = id;
    final appSecret = secret;

    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});
    return this.post(Uri.parse(url),
        headers: header,
        body: jsonEncode({'token': token, 'password': password}));
  }

  Future<Response> login(String token,
      {required String id, required String secret}) async {
    final url = await combineUrl(endpointPostLogin);

    final appId = id;
    final appSecret = secret;

    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});

    final bodyPayload = {'token': token};

    return this
        .post(Uri.parse(url), headers: header, body: jsonEncode(bodyPayload));
  }

  Future<Response> downloadCloudCerts(
      {required String taskId, required String secret}) async {
    final url =
        await combineUrl(endPointGetPrimaryTasks, args: {varTaskId: taskId});
    final header = defaultHeader..addAll({moabTaskSecretKey: secret});

    return this.get(Uri.parse(url), headers: header);
  }

  Future<Response> extendCertificates(
      String certId, String appId, String appSecret) async {
    final url = await combineUrl(endpointPostCertExtensions,
        args: {varCertificateId: certId});
    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});

    return this.post(
      Uri.parse(url),
      headers: header,
    );
  }

  Future<Response> requestAuthSession(
      String certId, String appId, String appSecret) async {
    final url = await combineUrl(endpointPostCertSessions,
        args: {varCertificateId: certId});
    final header = defaultHeader
      ..addAll({moabAppIdKey: appId, moabAppSecretKey: appSecret});

    return this.post(
      Uri.parse(url),
      headers: header,
    );
  }

  Future<Response> fetchRegionCodes() {
    final url = countryCodeUrl;
    return this.get(Uri.parse(url));
  }

  Future<Response> changeAuthenticationModePrepare(
      String accountId, String? password, String authenticationMode) async {
    final url = await combineUrl(endpointAuthenticationModePrepare,
        args: {varAccountId: accountId});
    final header = defaultHeader;
    final bodyPayload = password == null
        ? {
            'authenticationMode': authenticationMode,
          }
        : {
            'authenticationMode': authenticationMode,
            'password': password,
          };
    return this
        .post(Uri.parse(url), headers: header, body: jsonEncode(bodyPayload));
  }

  Future<Response> changeAuthenticationMode(
      String accountId, String token, String? password) async {
    final url = await combineUrl(endpointAuthenticationModeChange,
        args: {varAccountId: accountId});
    final header = defaultHeader;
    final bodyPayload = password == null
        ? {'token': token}
        : {'token': token, 'password': password};
    return this
        .put(Uri.parse(url), headers: header, body: jsonEncode(bodyPayload));
  }
}
