import 'dart:convert';

import 'package:http/http.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import '../../../constants/_constants.dart';
import '../http_client.dart';

extension MoabAccountsRequests on MoabHttpClient {
  Future<Response> getAccountSelf() async {
    final url = combineUrl(endpointGetAccountSelf);
    final header = defaultHeader..addAll({moabSiteIdKey: moabRetailSiteId});
    return this.get(Uri.parse(url), headers: header);
  }

  Future<Response> addCommunicationMethods(
      {required String accountId, required CommunicationMethod method}) async {
    final url = combineUrl(endpointPostCommunicationMethods,
        args: {varAccountId: accountId, varFlow: 'OTP'});
    final header = defaultHeader;
    return this.post(Uri.parse(url),
        headers: header, body: jsonEncode(method.toJson()));
  }

  Future<Response> deleteCommunicationMethods(
      {required String accountId,
      required String method,
      required String targetValue}) async {
    final url = combineUrl(endpointDeleteAuthCommunicationMethod, args: {
      varAccountId: accountId,
      varMethod: method,
      varTargetValue: Uri.encodeQueryComponent(targetValue)
    });
    final header = defaultHeader;
    return this.delete(
      Uri.parse(url),
      headers: header,
    );
  }

  Future<Response> verifyAccountPassword({
    required String accountId,
    required String password,
  }) {
    final url =
        combineUrl(endpointPostChangePassword, args: {varAccountId: accountId});
    final header = defaultHeader;
    return this.post(Uri.parse(url),
        headers: header,
        body: jsonEncode(
          {'password': password},
        ));
  }

  Future<Response> acceptNewPassword({
    required String accountId,
    required String password,
    required String token,
  }) {
    final url = combineUrl(endpointPutVerificationAccept,
        args: {varAccountId: accountId, varVerifyToken: token});
    final header = defaultHeader;
    return this.put(Uri.parse(url),
        headers: header,
        body: jsonEncode(
          {
            'arguments': [
              {
                'sequence': 1,
                'type': 'PLAIN',
                'value': password,
              }
            ]
          },
        ));
  }
}
