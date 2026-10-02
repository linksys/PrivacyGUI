// The loop measured on QA Guardian, 2026-09-30, closed at the bridge — and the
// SSE bootstrap's best-effort health check, which reuses the same switch.
//
// THE DECISION GUARDED. A 401 means "the session is gone" everywhere except
// during teardown, where the credential has usually just been spent on purpose:
// the End Session DELETE answers 204 before the disconnect cleanup reads
// `/subscriptions`. Reporting that 401 through `onAuthFailed` asked for a logout
// from inside the logout that caused it, and the app tore down 770 times in four
// minutes. A teardown request's 401 is therefore thrown but not reported; every
// other request's is reported exactly as before.
//
// WHY THIS TEST TYPE. The real web client over `package:http`'s `MockClient`,
// because the decision is inside `_withAuthRetry` and a mocked bridge would be
// testing its own stub. Web-only (`usp_bridge_client_web.dart` imports
// `package:web`), so the file runs under `--platform chrome`:
//
//   fvm flutter test --platform chrome test/core/usp/services/web/
//
// **CI does not run it.** Both CI jobs run the VM suite, where this file reports
// "No tests ran" and passes; it is the first `@TestOn('browser')` file in the
// repo. What CI does hold is the two halves either side of it: the remote
// strategy's cleanup passing `teardown: true` (`sse_remote_strategy_test.dart`)
// and `logout()` joining a teardown already running
// (`auth_notifier_test.dart`), which alone breaks the loop. This file is the
// check that the bridge honours the flag, and it has to be run by hand when
// `_withAuthRetry` changes.
@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

import '../../mocks.dart';

void main() {
  late int authFailures;
  late UspBridgeClient bridge;

  setUp(() {
    authFailures = 0;
    final usp = MockUspClient();
    bridge = UspBridgeClient(
      usp,
      endpoints: BridgeEndpoints.remote('session-1'),
      baseUrl: 'https://guardian.test',
      authToken: 'spent',
      authBehavior: AuthBehavior.remote,
    )..onAuthFailed = () => authFailures++;
  });

  Future<T> with401<T>(Future<T> Function() call) => http.runWithClient(
        call,
        () => MockClient((_) async => http.Response('{"code":"401"}', 401)),
      );

  group('UspBridgeClient - a 401 during teardown', () {
    test('listSubscriptions(teardown: true) throws and reports nothing',
        () async {
      await expectLater(
        with401(() => bridge.listSubscriptions(teardown: true)),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(authFailures, 0);
    });

    test('unsubscribe(teardown: true) throws and reports nothing', () async {
      await expectLater(
        with401(() => bridge.unsubscribe(subscriptionId: 'x', teardown: true)),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(authFailures, 0);
    });

    test('the same read outside teardown still ends the session', () async {
      // The other half, and the one that must not regress: a 401 on an ordinary
      // request is still the only signal a remote session has that its token is
      // gone (#1627).
      await expectLater(
        with401(() => bridge.listSubscriptions()),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(authFailures, 1);
    });
  });

  group('UspBridgeClient - a 401 on the best-effort health check', () {
    test('health(reportAuthFailure: false) throws and reports nothing',
        () async {
      // The SSE bootstrap's check: its failure is ignored, so its 401 must not
      // end the session either (review of #1600).
      await expectLater(
        with401(() => bridge.health(reportAuthFailure: false)),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(authFailures, 0);
    });

    test('health() still ends the session by default', () async {
      // The recovery probe's call. A rejected token is not an outage to wait
      // out, so this one must keep reporting.
      await expectLater(
        with401(() => bridge.health()),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(authFailures, 1);
    });
  });
}
