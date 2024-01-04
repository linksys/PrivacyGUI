import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/cloud/linksys_requests/asset_service.dart';
import 'package:linksys_app/core/cloud/linksys_requests/event_service.dart';
import 'package:linksys_app/core/cloud/linksys_requests/smart_device_service.dart';
import 'package:linksys_app/core/cloud/model/cloud_event_action.dart';
import 'package:linksys_app/core/cloud/model/cloud_event_subscription.dart';
import 'package:linksys_app/core/cloud/model/cloud_linkup.dart';
import 'package:linksys_app/core/http/linksys_http_client.dart';
import 'package:linksys_app/core/cloud/linksys_requests/authorization_service.dart';
import 'package:linksys_app/core/cloud/linksys_requests/device_service.dart';
import 'package:linksys_app/core/cloud/linksys_requests/user_service.dart';
import 'package:linksys_app/core/cloud/model/cloud_account.dart';
import 'package:linksys_app/core/cloud/model/cloud_communication_method.dart';
import 'package:linksys_app/core/cloud/model/cloud_network_model.dart';
import 'package:linksys_app/core/cloud/model/cloud_session_model.dart';
import 'package:linksys_app/provider/connectivity/_connectivity.dart';

final cloudRepositoryProvider = Provider((ref) => LinksysCloudRepository(
      httpClient: LinksysHttpClient(getHost: () {
        final routerType =
            ref.read(connectivityProvider).connectivityInfo.routerType;
        if (routerType == RouterType.others) {
          return null;
        } else {
          return 'https://${ref.read(connectivityProvider).connectivityInfo.gatewayIp}';
        }
      }),
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

  Future<String> prepareAddMfa() {
    return loadSessionToken()
        .then((token) => _httpClient.prepareAddMfaMethod(token: token))
        .then((response) => jsonDecode(response.body)['verificationToken']);
  }

  Future<bool> deleteMfaMethod(String mfaID) {
    return loadSessionToken()
        .then(
            (token) => _httpClient.deleteMfaMethod(token: token, mfaID: mfaID))
        .then((response) => response.statusCode == HttpStatus.noContent);
  }

  Future<CommunicationMethod> mfaValidate({
    required String otpCode,
    required String verificationToken,
  }) {
    return loadSessionToken()
        .then((token) => _httpClient.mfaValidate(
            token: token, verificationToken: verificationToken, code: otpCode))
        .then((response) =>
            CommunicationMethod.fromJson(jsonDecode(response.body)));
  }

  // TODO is there any other response??
  Future<SessionToken> oAuthMfaValidate({
    required String otpCode,
    required String verificationToken,
    bool rememberUserAgent = false,
  }) {
    return _httpClient
        .oAuthMfaValidate(
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

  // User service
  Future<CAPreferences> getPreferences() {
    return loadSessionToken()
        .then((token) => _httpClient.getPreferences(token: token))
        .then((response) =>
            CAPreferences.fromJson(jsonDecode(response.body)['preferences']));
  }

  Future<bool> setPreferences(CAPreferences preferences) {
    return loadSessionToken()
        .then((token) =>
            _httpClient.setPreferences(token: token, preferences: preferences))
        .then((response) => response.statusCode == HttpStatus.ok);
  }

  // Smart device
  Future<(String?, String?)> registerSmartDevice(
    String deviceToken, {
    String? appType,
  }) async {
    return _httpClient
        .registerSmartDevice(deviceToken, appType: appType)
        .then((response) {
      final data = jsonDecode(response.body);
      final smartDevice = data['smartDevice'];
      return (
        smartDevice['smartDeviceId'] as String?,
        smartDevice['smartDeviceSecret'] as String?
      );
    });
  }

  Future<bool> verifySmartDevice(String verificationToken) {
    return _httpClient
        .verifySmartDevice(verificationToken)
        .then((response) => response.statusCode == HttpStatus.ok);
  }

  // event service
  Future<List<CloudEventSubscription>> queryNetworkEventSubscriptions(
      String networkId) {
    return loadSessionToken()
        .then((token) => _httpClient.queryEventSubscription(token, networkId))
        .then((response) => List.from(
                jsonDecode(response.body)['eventSubscriptions'])
            .map((e) => CloudEventSubscription.fromMap(e['eventSubscription']))
            .toList());
  }

  Future<String> createNetworkEventSubscription(
      String networkId, CloudEventSubscription cloudEventSubscription) {
    return loadSessionToken().then((token) => _httpClient
        .createNetworkEventSubscription(
            token, networkId, cloudEventSubscription)
        .then((response) => jsonDecode(response.body)['eventSubscription']
            ['eventSubscriptionId']));
  }

  Future<bool> createNetworkEventAction(
      String eventSubscriptionId, CloudEventAction cloudEventAction) {
    return loadSessionToken().then((token) => _httpClient
        .createNetworkEventAction(token, eventSubscriptionId, cloudEventAction)
        .then((response) => response.statusCode == HttpStatus.ok));
  }

  Future<List<CloudEventAction>> getNetworkEventAction(
      String eventSubscriptionId) {
    return loadSessionToken()
        .then((token) =>
            _httpClient.getNetworkEventAction(token, eventSubscriptionId))
        .then((response) {
      final json = jsonDecode(response.body);
      final actions = List.from(json['eventActions']['eventAction'])
          .map((e) => CloudEventAction.fromMap(e))
          .toList();
      return actions;
    });
  }

  Future<bool> deleteNetworkEventAction(String eventSubscriptionId) {
    return loadSessionToken()
        .then((token) =>
            _httpClient.deleteNetworkEventAction(token, eventSubscriptionId))
        .then((response) => response.statusCode == HttpStatus.ok);
  }

  // asset service
  Future<CloudLinkUpModel> fetchLinkUp() {
    return loadSessionToken()
        .then((token) => _httpClient.fetchLinkup(token: token))
        .then((response) => CloudLinkUpModel.fromJson(response.body));
  }
}
