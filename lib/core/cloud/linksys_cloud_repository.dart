import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/core/http/linksys_http_client.dart';
import 'package:linksys_moab/core/cloud/linksys_requests/authorization_service.dart';
import 'package:linksys_moab/core/cloud/linksys_requests/device_service.dart';
import 'package:linksys_moab/core/cloud/linksys_requests/user_service.dart';
import 'package:linksys_moab/core/cloud/model/cloud_account.dart';
import 'package:linksys_moab/core/cloud/model/cloud_communication_method.dart';
import 'package:linksys_moab/core/cloud/model/cloud_network_model.dart';
import 'package:linksys_moab/core/cloud/model/cloud_session_model.dart';

final cloudRepositoryProvider = Provider((ref) => LinksysCloudRepository(
      httpClient: LinksysHttpClient(),
    ));

class LinksysCloudRepository {
  final LinksysHttpClient _httpClient;

  LinksysCloudRepository({required LinksysHttpClient httpClient})
      : _httpClient = httpClient;

  Future<SessionToken> login({required username, required password}) async {
    return _httpClient
        .passwordLogin(username: username, password: password)
        .then((response) => SessionToken.fromJson(jsonDecode(response.body)));
  }

  Future<SessionToken> refreshToken(String refreshToken) {
    return _httpClient
        .refreshToken(token: refreshToken)
        .then((response) => SessionToken.fromJson(jsonDecode(response.body)));
  }

  Future<List<NetworkAccountAssociation>> getNetworks() async {
    return loadSessionToken().then((token) => _httpClient
        .getNetworks(token: token)
        .then((response) =>
            List.from(jsonDecode(response.body)['networkAccountAssociations'])
                .map((e) => e['networkAccountAssociation'])
                .map((e) => NetworkAccountAssociation.fromJson(e))
                .toList()));
  }

  Future<List<CommunicationMethod>> getMfaMaskedMethods(
      {required String username}) async {
    return _httpClient.getMaskedMfaMethods(username: username).then(
        (response) => List.from(jsonDecode(response.body))
            .map((e) => CommunicationMethod.fromJson(e))
            .toList());
  }

  Future mfaChallenge({
    required String verificationToken,
    required String method,
  }) {
    return _httpClient.mfaChallenge(
      verificationToken: verificationToken,
      method: method,
    );
  }

  // TODO is there any other response??
  Future<SessionToken> mfaValidate({
    required String otpCode,
    required String verificationToken,
    bool rememberUserAgent = false,
  }) {
    return _httpClient
        .mfaValidate(
          otpCode: otpCode,
          verificationToken: verificationToken,
          rememberUserAgent: rememberUserAgent,
        )
        .then((response) => SessionToken.fromJson(jsonDecode(response.body)));
  }

  Future<CAUserAccount> getAccount() async {
    return loadSessionToken()
        .then((token) => _httpClient.getAccount(token: token))
        .then(
          (response) => CAUserAccount.fromJson(
            jsonDecode(response.body)['account'],
          ),
        );
  }

  Future<List<CommunicationMethod>> getMfaMethod() async {
    return loadSessionToken()
        .then((token) => _httpClient.getMfaMethods(token: token))
        .then(
          (response) => List.from(jsonDecode(response.body))
              .map((e) => CommunicationMethod.fromJson(e))
              .toList(),
        );
  }

  Future<void> updateFriendlyName(String friendlyName, String networkId) async {
    return loadSessionToken().then((token) => _httpClient.updateNetwork(
          token: token,
          networkId: networkId,
          friendlyName: friendlyName,
        ));
  }

  Future<String> loadSessionToken() async {
    return const FlutterSecureStorage()
        .read(key: pSessionToken)
        .then((value) =>
            value != null ? SessionToken.fromJson(jsonDecode(value)) : null)
        .then((value) => value?.accessToken ?? '');
  }
}
