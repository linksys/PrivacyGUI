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
import 'package:privacy_gui/core/cloud/linksys_requests/smart_device_service.dart';
import 'package:privacy_gui/core/cloud/model/cloud_event_action.dart';
import 'package:privacy_gui/core/cloud/model/cloud_event_subscription.dart';
import 'package:privacy_gui/core/cloud/model/cloud_linkup.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/http/linksys_http_client.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/authorization_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/device_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/user_service.dart';
import 'package:privacy_gui/core/cloud/model/cloud_account.dart';
import 'package:privacy_gui/core/cloud/model/cloud_communication_method.dart';
import 'package:privacy_gui/core/cloud/model/cloud_network_model.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/utils/ip_getter/ip_getter.dart';
import 'package:privacy_gui/core/utils/logger.dart';

final cloudRepositoryProvider = Provider((ref) => LinksysCloudRepository(
      httpClient: LinksysHttpClient(getHost: () {
        var localIP = getLocalIp(ref.read);
        if (localIP.isEmpty) return null;
        return localIP.startsWith('http') ? localIP : 'https://$localIP';
      }),
    ));

/// Cloud-only repository that always uses the cloud base URL.
/// Use this for APIs that must go to cloud (e.g., Remote Assistance).
final cloudOnlyRepositoryProvider = Provider((ref) => LinksysCloudRepository(
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

  // Geolocation
  Future getGeolocation({
    required String linksysToken,
    required String serialNumber,
  }) {
    return _httpClient.geolocation(
        linksysToken: linksysToken, serialNumber: serialNumber);
  }

  // =========================================================================
  // Remote Assistance (Guardian API)
  // =========================================================================

  /// Fetch device token from Guardian API.
  ///
  /// The device token is cached in secure storage with a 1-hour TTL.
  Future<String> fetchDeviceToken({
    required String serialNumber,
    required String macAddress,
    required String deviceUUID,
  }) async {
    // Check cached token
    const storage = FlutterSecureStorage();
    final cachedToken = await storage.read(key: pLinksysToken);
    final cachedTs = await storage.read(key: pLinksysTokenTs);

    if (cachedToken != null && cachedTs != null) {
      final ts = int.tryParse(cachedTs) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      // Token valid for 1 hour
      if (age < 3600000) {
        logger.d('[Cloud]: Using cached device token');
        return cachedToken;
      }
    }

    // Fetch new token
    logger.d('[Cloud]: Fetching new device token');
    final response = await _httpClient.getDeviceToken(
      serialNumber: serialNumber,
      macAddress: macAddress,
      deviceUUID: deviceUUID,
    );
    final data = jsonDecode(response.body);
    final token = data['linksysToken'] as String;

    // Cache the token
    await storage.write(key: pLinksysToken, value: token);
    await storage.write(
      key: pLinksysTokenTs,
      value: '${DateTime.now().millisecondsSinceEpoch}',
    );

    return token;
  }

  /// Get all Remote Assistance sessions for a device.
  Future<List<GRASessionInfo>> getRemoteAssistanceSessions({
    required String linksysToken,
    required String serialNumber,
  }) async {
    final response = await _httpClient.getSessions(
      linksysToken: linksysToken,
      serialNumber: serialNumber,
    );
    final data = jsonDecode(response.body);
    final content = data['content'] as List? ?? [];
    return content.map((e) => GRASessionInfo.fromMap(e)).toList();
  }

  /// Get info for a specific Remote Assistance session.
  Future<GRASessionInfo> getRemoteAssistanceSessionInfo({
    required String linksysToken,
    required String sessionId,
    required String serialNumber,
  }) async {
    final response = await _httpClient.getSessionInfo(
      linksysToken: linksysToken,
      sessionId: sessionId,
      serialNumber: serialNumber,
    );
    return GRASessionInfo.fromMap(jsonDecode(response.body));
  }

  /// Create a PIN for Remote Assistance.
  Future<String> createRemoteAssistancePin({
    required String linksysToken,
    required String serialNumber,
  }) async {
    final response = await _httpClient.createPin(
      linksysToken: linksysToken,
      serialNumber: serialNumber,
    );
    final data = jsonDecode(response.body);
    return data['pin'] as String;
  }

  /// Delete/terminate a Remote Assistance session.
  Future<void> deleteRemoteAssistanceSession({
    required String linksysToken,
    required String sessionId,
    required String serialNumber,
  }) async {
    await _httpClient.deleteSession(
      linksysToken: linksysToken,
      sessionId: sessionId,
      serialNumber: serialNumber,
    );
  }

  // =========================================================================
  // Remote Assistance - CA (Support Agent) Side
  // =========================================================================

  /// Get session info for CA side using session token.
  ///
  /// CA uses Authorization header with the temporary session token,
  /// not device token + serial number like the client side.
  Future<GRASessionInfo> getRemoteAssistanceSessionInfoForCA({
    required String sessionToken,
    required String sessionId,
  }) async {
    final response = await _httpClient.getSessionInfoForCA(
      sessionToken: sessionToken,
      sessionId: sessionId,
    );
    return GRASessionInfo.fromMap(jsonDecode(response.body));
  }

  /// Delete/terminate session for CA side.
  Future<void> deleteRemoteAssistanceSessionForCA({
    required String sessionToken,
    required String sessionId,
  }) async {
    await _httpClient.deleteSessionForCA(
      sessionToken: sessionToken,
      sessionId: sessionId,
    );
  }
}
