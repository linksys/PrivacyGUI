import 'dart:io';

import 'package:http/http.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';

extension GuidansRemoteAssistanceService on LinksysHttpClient {
  Future<Response> getSessions({
    required String token,
  }) {
    final endPoint = combineUrl(kSessions);
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    return this.get(
      Uri.parse(endPoint),
      headers: header,
    );
  }

  Future<Response> getSessionInfo({
    required String token,
    required String sessionId,
  }) {
    final endPoint =
        combineUrl(kSessionInfo, args: {kVarRASessionId: sessionId});
    final header = defaultHeader
      ..[HttpHeaders.authorizationHeader] = wrapSessionToken(token);
    return this.get(
      Uri.parse(endPoint),
      headers: header,
    );
  }
}
