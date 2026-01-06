import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/asset_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/cloud2_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/event_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/guardians_remote_assistance_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/ping_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/remote_assistance_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/smart_device_service.dart';
import 'package:privacy_gui/core/cloud/model/cloud_event_action.dart';
import 'package:privacy_gui/core/cloud/model/cloud_event_subscription.dart';
import 'package:privacy_gui/core/cloud/model/cloud_linkup.dart';
import 'package:privacy_gui/core/cloud/model/cloud_remote_assistance_info.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/authorization_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/device_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/user_service.dart';
import 'package:privacy_gui/core/cloud/model/cloud_account.dart';
import 'package:privacy_gui/core/cloud/model/cloud_communication_method.dart';
import 'package:privacy_gui/core/cloud/model/cloud_network_model.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/core/utils/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/utils/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/utils/ip_getter/web_get_local_ip.dart';

final cloudRepositoryProvider = Provider((ref) => LinksysCloudRepository(
      httpClient: LinksysHttpClient(getHost: () {
        if (BuildConfig.forceCommandType == ForceCommand.local) {
          var localIP = getLocalIp(ref);
          localIP = localIP.startsWith('http') ? localIP : 'https://$localIP';
          return localIP;
        }
        final routerType =
            ref.read(connectivityProvider).connectivityInfo.routerType;
        if (routerType == RouterType.others) {
          return null;
        } else {
          var localIP = getLocalIp(ref);
          localIP = localIP.startsWith('http') ? localIP : 'https://$localIP';
          return localIP;
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

  Future<List<NetworkAccountAssociation>> getNetworks([String? token]) async {
    return loadSessionToken(token).then((token) => _httpClient
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

  Future<String> loadSessionToken([String? token]) async {
    if (token != null) {
      return token;
    }
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

  Future<void> associateSmartDevice({
    required String linksysToken,
    required String serialNumber,
    required String fcmToken,
  }) {
    return _httpClient.associateSmartDevice(
        linksysToken: linksysToken,
        serialNumber: serialNumber,
        fcmToken: fcmToken);
  }

  Future<bool> testPingPng() {
    return _httpClient
        .testPingPng()
        .then((response) =>
            response.statusCode == HttpStatus.ok &&
            response.headers['content-type'] == 'image/png')
        .onError((error, stackTrace) => false);
  }

  /// Remote assistance
  Future<(String, String)> raLogin({
    required String username,
    required String password,
    required String serialNumber,
  }) {
    return _httpClient
        .raLogin(
      username: username,
      password: password,
      serialNumber: serialNumber,
    )
        .then((response) {
      final json = jsonDecode(response.body);
      final raSession = json['remoteAssistanceSession'];
      return (
        raSession['remoteAssistanceSessionId'] as String,
        raSession['session']['token'] as String,
      );
    });
  }

  ///
  /// {
  /// "remoteAssistanceSessions": [
  ///   {
  ///     "remoteAssistanceSession": {
  ///       "remoteAssistanceSessionId": "8AD8DBC2-552D-4102-A76F-65DBA1867219"
  ///     }
  ///   }
  /// ]
  /// }
  Future<String> raGetSession({required String networkId}) {
    return loadSessionToken().then((token) => _httpClient
            .getRASession(token: token, networkId: networkId)
            .then((response) {
          final jsonArray =
              List.from(jsonDecode(response.body)['remoteAssistanceSessions']);
          final raSession = jsonArray.first['remoteAssistanceSession'];
          return raSession['remoteAssistanceSessionId'];
        }));
  }

  ///
  /// {
  ///     "remoteAssistanceSession": {
  ///         "remoteAssistanceSessionId": "727DEBA0-FE9C-41F3-A5A8-28A84B87E930",
  ///         "status": "PENDING",
  ///         "expiredIn": -1757,
  ///         "createdAt": 1722240538000,
  ///         "statusChangedAt": 1722240574000,
  ///         "currentTime": 1722240580739
  ///     }
  /// }
  ///
  Future<CloudRemoteAssistanceInfo> raGetSessionInfo(
      {required String networkId, required String sessionId}) {
    return loadSessionToken().then((token) => _httpClient
            .getRASessionInfo(
                token: token, networkId: networkId, sessionId: sessionId)
            .then((response) {
          final json = jsonDecode(response.body)['remoteAssistanceSession'];
          return CloudRemoteAssistanceInfo.fromMap(json);
        }));
  }

  Future<GRASessionInfo> getSessionInfo(
      {String? token, required String sessionId}) {
    return loadSessionToken(token).then((token) => _httpClient
            .getSessionInfo(token: token, sessionId: sessionId)
            .then((response) {
          final json = jsonDecode(response.body);
          return GRASessionInfo.fromMap(json);
        }));
  }

  ///
  ///{
  ///"remoteAssistanceSession": {
  ///  "remoteAssistanceSessionId": "8AD8DBC2-552D-4102-A76F-65DBA1867219",
  ///  "pin": "010794",
  ///  "status": "PENDING"
  ///}
  ///}
  ///
  Future<String> raGenPin({
    required String sessionId,
    required String networkId,
  }) {
    return loadSessionToken().then((token) => _httpClient
            .genRAPin(
          token: token,
          sessionId: sessionId,
          networkId: networkId,
        )
            .then((response) {
          final json = jsonDecode(response.body);
          final raSession = json['remoteAssistanceSession'];
          return raSession['pin'];
          // TODO expire handling
        }));
  }

  Future<(String, CAMobile?)> raGetInfo({
    required String sessionId,
    required String token,
  }) {
    return _httpClient
        .raGetInfo(sessionId: sessionId, token: token)
        .then((response) {
      final json = jsonDecode(response.body);
      final raSession = json['remoteAssistanceSession'];

      final accountInfo = raSession['accountInfo'];
      final email = accountInfo['emailAddress'] as String;
      final mobile = accountInfo['mobile'] != null
          ? CAMobile.fromMap(accountInfo['mobile'])
          : null;
      return (email, mobile);
    });
  }

  Future sendRAPin(
      {required String sessionId,
      required String token,
      required String method}) {
    return _httpClient.sendRAPin(
        token: token, sessionId: sessionId, method: method);
  }

  /// {
  /// "temporaryRAS": {
  ///   "networkId": "network-774AFF4CC419408EB8FEAD4F3028D3DB55E41185@ciscoconnectcloud.com",
  ///   "sessionToken": "AGENT540ADDDB4D7D45188EF89685BE0C408FA64B6A164BE340DF83203B2FB8B"
  /// }
  /// }
  Future<({String token, String networkId})> pinVerify(
      {required String sessionId, required String token, required String pin}) {
    return _httpClient
        .pinVerify(token: token, sessionId: sessionId, pin: pin)
        .then((response) {
      final json = jsonDecode(response.body);
      final temporaryRAS = json['temporaryRAS'];
      return (
        networkId: temporaryRAS['networkId'] as String,
        token: temporaryRAS['sessionToken'] as String
      );
    });
  }

  Future deleteSession({
    required String sessionId,
  }) {
    return loadSessionToken().then((token) =>
        _httpClient.deleteSession(sessionId: sessionId, token: token));
  }

  // Geolocation
  Future getGeolocation({
    required String linksysToken,
    required String serialNumber,
  }) {
    return _httpClient.geolocation(
        linksysToken: linksysToken, serialNumber: serialNumber);
  }
}
