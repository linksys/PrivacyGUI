import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privacy_gui/core/ai_session/ai_session_service.dart';

class _TrackedClient extends MockClient {
  _TrackedClient(super.fn);

  int closes = 0;

  @override
  void close() {
    closes++;
    super.close();
  }
}

void main() {
  test('bootstrap sends the router password only in the JSON request body',
      () async {
    late http.Request observed;
    final service = HttpAiSessionService(
      clientFactory: () => MockClient((request) async {
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
      clientFactory: () => MockClient((_) async => http.Response('{}', 404)),
      baseUri: Uri.parse('https://192.168.1.1/'),
    );
    expect(await service.bootstrap('CandidateSecret!'), isFalse);
  });

  test('logout revokes the server-side AI session', () async {
    late http.Request observed;
    final service = HttpAiSessionService(
      clientFactory: () => MockClient((request) async {
        observed = request;
        return http.Response('{"authenticated":false}', 200);
      }),
      baseUri: Uri.parse('https://192.168.1.1/'),
    );

    await service.logout();
    expect(jsonDecode(observed.body), {'action': 'logout'});
  });

  test('logout notifies the browser before server revocation can fail',
      () async {
    var notifications = 0;
    final service = HttpAiSessionService(
      clientFactory: () =>
          MockClient((_) async => throw StateError('router unavailable')),
      baseUri: Uri.parse('https://192.168.1.1/'),
      onLogout: () => notifications++,
    );

    await expectLater(service.logout(), throwsStateError);
    expect(notifications, 1);
  });

  testWidgets('timeout closes a stalled transport and permits a fresh login',
      (tester) async {
    final held = Completer<http.Response>();
    final stalled = _TrackedClient((_) => held.future);
    final fresh = _TrackedClient((_) async => http.Response('{}', 200));
    final clients = [stalled, fresh];
    final service = HttpAiSessionService(
      clientFactory: () => clients.removeAt(0),
      baseUri: Uri.parse('https://router.invalid/'),
    );
    addTearDown(service.close);

    final timeout = expectLater(
        service.bootstrap('FixtureOnly'), throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(milliseconds: 4999));
    expect(stalled.closes, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await timeout;
    expect(stalled.closes, 1);

    expect(await service.bootstrap('FixtureOnly'), isTrue);
    expect(fresh.closes, 1);
    held.complete(http.Response('{}', 200));
    await tester.pump();
    expect(stalled.closes, 1);
  });

  test('logout cancels pending login without closing its own transport',
      () async {
    final held = Completer<http.Response>();
    final loginClient = _TrackedClient((_) => held.future);
    final logoutClient = _TrackedClient((request) async {
      expect(jsonDecode(request.body), {'action': 'logout'});
      return http.Response('{}', 200);
    });
    final clients = [loginClient, logoutClient];
    final service = HttpAiSessionService(
      clientFactory: () => clients.removeAt(0),
      baseUri: Uri.parse('https://router.invalid/'),
    );
    addTearDown(service.close);
    final cancelled =
        expectLater(service.bootstrap('FixtureOnly'), throwsStateError);
    await service.logout();
    await cancelled;
    expect(loginClient.closes, 1);
    expect(logoutClient.closes, 1);
    held.complete(http.Response('{}', 200));
  });

  test('disposing cancels outstanding requests and rejects new work', () async {
    final held = Completer<http.Response>();
    final client = _TrackedClient((_) => held.future);
    final service = HttpAiSessionService(
      clientFactory: () => client,
      baseUri: Uri.parse('https://router.invalid/'),
    );
    final cancelled =
        expectLater(service.bootstrap('FixtureOnly'), throwsStateError);
    service.close();
    await cancelled;
    expect(client.closes, 1);
    await expectLater(service.bootstrap('FixtureOnly'), throwsStateError);
    held.complete(http.Response('{}', 200));
  });
}
