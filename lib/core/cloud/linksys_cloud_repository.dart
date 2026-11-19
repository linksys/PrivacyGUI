import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/guardians_remote_assistance_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/ping_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/remote_assistance_service.dart';
import 'package:privacy_gui/core/cloud/model/cloud_remote_assistance_info.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/core/jnap/providers/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/jnap/providers/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/ip_getter/web_get_local_ip.dart';

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

  Future<bool> testPingPng() {
    return _httpClient
        .testPingPng()
        .then((response) =>
            response.statusCode == HttpStatus.ok &&
            response.headers['content-type'] == 'image/png')
        .onError((error, stackTrace) => false);
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

  Future deleteSession({
    required String sessionId,
  }) {
    return loadSessionToken().then((token) =>
        _httpClient.deleteSession(sessionId: sessionId, token: token));
  }
}
