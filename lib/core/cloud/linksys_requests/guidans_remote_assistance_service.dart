import 'dart:io';

import 'package:http/http.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

extension GuidansRemoteAssistanceService on LinksysHttpClient {
  Future<Response> getSessions({
    required String token,
    required String serialNumber,
  }) {
    final endPoint = combineUrl(kSessions);
    final header = defaultHeader
      ..[kHeaderLinksysToken] = token
      ..[kHeaderSerialNumber] = serialNumber;
    return this.get(
      Uri.parse(endPoint),
      headers: header,
    );
  }

  Future<Response> getSessionInfo({
    required String token,
    required String sessionId,
    String? serialNumber,
  }) {
    final endPoint =
        combineUrl(kSessionInfo, args: {kVarRASessionId: sessionId});
    var header = defaultHeader
      ..[kHeaderLinksysToken] = token;

    if (serialNumber != null) {
      header[kHeaderSerialNumber] = serialNumber;
    } else {
      header[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    }
    return this.get(
      Uri.parse(endPoint),
      headers: header,
    );
  }

  Future<Response> deleteSession({
    required String token,
    required String sessionId,
    String? serialNumber,
  }) {
    final endPoint = combineUrl(kSessionInfo, args: {kVarRASessionId: sessionId});
    var header = defaultHeader
      ..[kHeaderLinksysToken] = token;

    if (serialNumber != null) {
      header[kHeaderSerialNumber] = serialNumber;
    } else {
      header[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    }
    return this.delete(
      Uri.parse(endPoint),
      headers: header,
    );
  }
  Future<Response> createPin({
    required String token,
    required String serialNumber,
  }) {
    final endPoint = combineUrl(kCreatePin);
    final header = defaultHeader
      ..[kHeaderLinksysToken] = token
      ..[kHeaderSerialNumber] = serialNumber;
    return this.post(Uri.parse(endPoint), headers: header);
  }
}
