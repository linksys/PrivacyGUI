import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

extension RemoteAssistanceService on LinksysHttpClient {
  Future<Response> genRAPin({
    required String token,
    required String sessionId,
    required String networkId,
  }) {
    final endPoint = combineUrl(kRAPin);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token)
      ..[kHeaderNetworkId] = networkId;
    return this.post(Uri.parse(endPoint),
        headers: header,
        body: jsonEncode({
          "remoteAssistanceSession": {
            "remoteAssistanceSessionId": sessionId,
          }
        }));
  }

  Future<Response> getRASession({
    required String token,
    required String networkId,
  }) {
    final endPoint = combineUrl(kRASessions);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token)
      ..[kHeaderNetworkId] = networkId;
    return this.get(
      Uri.parse(endPoint),
      headers: header,
    );
  }

  Future<Response> getRASessionInfo({
    required String token,
    required String sessionId,
    required String networkId,
  }) {
    final endPoint =
        combineUrl(kRASessionInfo, args: {kVarRASessionId: sessionId});
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token)
      ..[kHeaderNetworkId] = networkId;
    return this.get(
      Uri.parse(endPoint),
      headers: header,
    );
  }
}
