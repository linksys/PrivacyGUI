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

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
import 'package:privacy_gui/core/usp/services/session_auth_gate.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:web/web.dart' as web;

import '../../mocks.dart';

/// The page's `fetch`, which the notification stream calls directly (it needs
/// a `ReadableStream`, so it does not go through `package:http`).
@JS('fetch')
external JSFunction get _fetch;

@JS('fetch')
external set _fetch(JSFunction value);

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
    // A single handler's release in a live session (#1666's design, Q9): the
    // flag it used to pass is gone, and a rejected credential in a live session
    // is over.
    test('an unsubscribe ends the session, once', () async {
      await expectLater(
        with401(() => bridge.unsubscribe(subscriptionId: 'x')),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(sessionEnds, 1);
    });

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

  // The notification stream's 401 goes through the same rule as the REST
  // requests, from its own call site. Answered 401 every time, the local
  // stream reauths and reopens once, and the second 401 ends the session: a
  // stream that reopened on every 401 would reauth without end.
  group('UspBridgeClient - the notification stream answered 401', () {
    late int fetches;
    late JSFunction original;

    setUp(() {
      fetches = 0;
      original = _fetch;
      _fetch = ((JSAny? input, JSAny? init) {
        fetches++;
        return Future<web.Response>.value(
          web.Response(null, web.ResponseInit(status: 401)),
        ).toJS;
      }).toJS;
    });
    tearDown(() => _fetch = original);

    /// Listens to [stream] until it closes and returns the errors it carried.
    Future<List<Object>> errorsUntilClosed(Stream<SseEvent> stream) async {
      final errors = <Object>[];
      final done = Completer<void>();
      stream.listen((_) {}, onError: errors.add, onDone: done.complete);
      await done.future.timeout(const Duration(seconds: 5));
      return errors;
    }

    test('local: reauths and reopens once, then ends the session', () async {
      final localGate = SessionAuthGate(
        authBehavior: AuthBehavior.local,
        endSession: () => sessionEnds++,
      )..begin();
      final usp = MockUspClient();
      when(() => usp.sessionToken).thenReturn('token');
      when(() => usp.reauth()).thenAnswer((_) async {});
      final local = UspBridgeClient(
        usp,
        baseUrl: 'https://router.test',
        gate: localGate,
      );

      final errors = await errorsUntilClosed(local.notifications());

      expect(fetches, 2);
      verify(() => usp.reauth()).called(1);
      expect(sessionEnds, 1);
      expect(errors.single, isA<SessionExpiredException>());
    });

    test('remote: ends the session at once, with no reauth', () async {
      final errors = await errorsUntilClosed(bridge.notifications());

      expect(fetches, 1);
      expect(sessionEnds, 1);
      expect(errors.single, isA<SessionExpiredException>());
    });

    test('after logout() has ended the session, ends nothing', () async {
      gate.markEnded();

      final errors = await errorsUntilClosed(bridge.notifications());

      expect(fetches, 1);
      expect(sessionEnds, 0);
      expect(errors.single, isA<SessionExpiredException>());
    });
  });
}
