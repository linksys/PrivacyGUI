import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/cloud/cloud_host.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/guardians_remote_assistance_service.dart';
import 'package:privacy_gui/core/cloud/linksys_requests/ping_service.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/core/jnap/providers/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/jnap/providers/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/ip_getter/web_get_local_ip.dart';

final cloudRepositoryProvider = Provider((ref) => LinksysCloudRepository(
      httpClient: LinksysHttpClient(
        getHost: () => cloudHost(
          force: BuildConfig.forceCommandType,
          routerType: () =>
              ref.read(connectivityProvider).connectivityInfo.routerType,
          localIp: () => getLocalIp(ref),
        ),
      ),
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

  Future<GRASessionInfo> getSessionInfo(
      {String? token, required String sessionId}) {
    return loadSessionToken(token).then((token) => _httpClient
            .getSessionInfo(token: token, sessionId: sessionId)
            .then((response) {
          final json = jsonDecode(response.body);
          return GRASessionInfo.fromMap(json);
        }));
  }

  Future deleteSession({
    required String sessionId,
  }) {
    return loadSessionToken().then((token) =>
        _httpClient.deleteSession(sessionId: sessionId, token: token));
  }
}
