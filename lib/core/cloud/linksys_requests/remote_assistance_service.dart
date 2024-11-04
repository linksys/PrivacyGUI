import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

extension RemoteAssistanceService on LinksysHttpClient {
  Future<Response> raLogin({
    required String username,
    required String password,
    required String serialNumber,
  }) {
    final endpoint = combineUrl(kRASessions);
    final header = defaultHeader;
    return this.post(Uri.parse(endpoint),
        headers: header,
        body: jsonEncode({
          "remoteassistancesession": {
            "session": {
              "account": {"username": username, "password": password}
            },
            "serialNumber": serialNumber,
            "forceCreate": true
          }
        }));
  }

  Future<Response> raGetInfo({
    required String sessionId,
    required String token,
  }) {
    final endPoint =
        combineUrl(kRAAccountInfo, args: {kVarRASessionId: sessionId});
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    return this.get(Uri.parse(endPoint), headers: header);
  }

  Future<Response> sendRAPin({
    required String token,
    required String sessionId,
    required String method,
  }) {
    final endPoint = combineUrl(kRASendPin);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    return this.post(Uri.parse(endPoint),
        headers: header,
        body: jsonEncode({
          "remoteAssistanceSession": {
            "remoteAssistanceSessionId": sessionId,
            "communicationMethod": method,
          }
        }));
  }

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

  Future<Response> pinVerify({
    required String token,
    required String sessionId,
    required String pin,
  }) {
    final endPoint = combineUrl(kRATemporaryRAS);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    return this.post(Uri.parse(endPoint),
        headers: header,
        body: jsonEncode({
          "remoteAssistanceSession": {
            "remoteAssistanceSessionId": sessionId,
            "pin": pin,
          }
        }));
  }

  Future<Response> deleteSession(
      {required String token, required String sessionId}) {
    final endPoint = combineUrl(kRASessions);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    return this.delete(Uri.parse(endPoint),
        headers: header,
        body: jsonEncode({
          "remoteAssistanceSession": {
            "remoteAssistanceSessionId": sessionId,
          }
        }));
  }
}
