// The loop measured on QA Guardian, 2026-09-30, closed at the bridge. The same
// file covers the SSE bootstrap's best-effort health check and, since #1666, the
// old bridge left over from a Remote Assistance re-activation.
//
// THE DECISION GUARDED. A 401 means "the session is gone" everywhere except in a
// session that is already over:
// - During teardown the credential has usually just been spent on purpose. The
//   End Session DELETE answers 204 before the disconnect cleanup reads
//   `/subscriptions`. Reporting that 401 asked for a logout from inside the
//   logout that caused it, and the app tore down 770 times in four minutes.
// - A `teardown: true` flag used to say so per request. Since #1666 the bridge
//   asks `SessionAuthGate`. logout() ends the session first, and every 401 for
//   an ended session is ignored, including one that outlives the teardown.
//
// WHY THIS TEST TYPE. The real web client over `package:http`'s `MockClient`.
// The decision is inside its `_withAuthRetry`, and a mocked bridge would only
// test its own stub. The client is web-only (`usp_bridge_client_web.dart`
// imports `package:web`), so the file runs under `--platform chrome`:
//
//   fvm flutter test --platform chrome test/core/usp/services/web/
//
// **CI does not run it.** Both CI jobs run the VM suite, where this file reports
// "No tests ran" and passes. CI does hold the rule this client applies:
// - `bridge_auth_test.dart`: `resendAfter401` and `BridgeCredential`;
// - `session_auth_gate_test.dart`: the gate's table.
// This file checks that the bridge applies the rule, and has to be run by hand
// when `_withAuthRetry` changes.
@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
import 'package:privacy_gui/core/usp/services/session_auth_gate.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

import '../../mocks.dart';

void main() {
  late int sessionEnds;
  late SessionAuthGate gate;
  late UspBridgeClient bridge;

  setUp(() {
    sessionEnds = 0;
    gate = SessionAuthGate(
      authBehavior: AuthBehavior.remote,
      endSession: () => sessionEnds++,
    )..begin();
    bridge = UspBridgeClient(
      MockUspClient(),
      endpoints: BridgeEndpoints.remote('session-1'),
      baseUrl: 'https://guardian.test',
      authToken: 'spent',
      gate: gate,
    );
  });

  Future<T> with401<T>(Future<T> Function() call) => http.runWithClient(
        call,
        () => MockClient((_) async => http.Response('{"code":"401"}', 401)),
      );

  group('UspBridgeClient - a 401 after logout() has ended the session', () {
    setUp(() => gate.markEnded());

    test('listSubscriptions throws and ends nothing', () async {
      await expectLater(
        with401(() => bridge.listSubscriptions()),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(sessionEnds, 0);
    });

    test('unsubscribe throws and ends nothing', () async {
      await expectLater(
        with401(() => bridge.unsubscribe(subscriptionId: 'x')),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(sessionEnds, 0);
    });
  });

  group('UspBridgeClient - a 401 in a live session', () {
    test('ends the session, once', () async {
      // The one that must not regress: a 401 on an ordinary request is the only
      // signal a remote session has that its token is gone (#1627).
      await expectLater(
        with401(() => bridge.listSubscriptions()),
        throwsA(isA<SessionExpiredException>()),
      );
      await expectLater(
        with401(() => bridge.listSubscriptions()),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(sessionEnds, 1);
    });

    // 721939aa8: a re-activation disposes the old bridge after the new session
    // has begun. Its token, and so its ticket, are the old session's.
    test('from a bridge built for a session since replaced, ends nothing',
        () async {
      gate.begin(); // the re-activation's transport swap

      await expectLater(
        with401(() => bridge.unsubscribe(subscriptionId: 'x')),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(sessionEnds, 0);
      expect(gate.isLive, isTrue);
    });
  });

  group('UspBridgeClient - a 401 on the health check', () {
    test('kind: bestEffort throws and ends nothing', () async {
      // The SSE bootstrap's check: its failure is ignored, so its 401 must not
      // end the session either (bb7d394ae).
      await expectLater(
        with401(() => bridge.health(kind: RequestKind.bestEffort)),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(sessionEnds, 0);
    });

    test('health() still ends the session by default', () async {
      // The recovery probe's call. A rejected token is not an outage to wait
      // out, so this one must keep ending the session.
      await expectLater(
        with401(() => bridge.health()),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(sessionEnds, 1);
    });
  });
}
