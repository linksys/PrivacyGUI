import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';

void main() {
  test('bootstrap sends the router password only in the JSON request body',
      () async {
    late http.Request observed;
    final service = HttpAiSessionService(
      client: MockClient((request) async {
        observed = request;
        return http.Response('{"authenticated":true}', 200);
      }),
      baseUri: Uri.parse('https://192.168.1.1/'),
    );

    expect(await service.bootstrap('CandidateSecret!'), isTrue);
    expect(
        observed.url.toString(), 'https://192.168.1.1/cgi-bin/ai-session.cgi');
    expect(observed.method, 'POST');
    expect(
        observed.headers.values.join(' '), isNot(contains('CandidateSecret!')));
    expect(jsonDecode(observed.body), {
      'action': 'login',
      'admin_password': 'CandidateSecret!',
    });
  });

  test('bootstrap failure is reported without throwing router login away',
      () async {
    final service = HttpAiSessionService(
      client: MockClient((_) async => http.Response('{}', 404)),
      baseUri: Uri.parse('https://192.168.1.1/'),
    );
    expect(await service.bootstrap('CandidateSecret!'), isFalse);
  });

  test('logout revokes the server-side AI session', () async {
    late http.Request observed;
    final service = HttpAiSessionService(
      client: MockClient((request) async {
        observed = request;
        return http.Response('{"authenticated":false}', 200);
      }),
      baseUri: Uri.parse('https://192.168.1.1/'),
    );

    await service.logout();
    expect(jsonDecode(observed.body), {'action': 'logout'});
  });
}
