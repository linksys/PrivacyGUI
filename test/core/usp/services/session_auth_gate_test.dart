import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/session_auth_gate.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';

/// Where the session is when the 401 arrives.
enum _Epoch { none, live, ended }

String _modeName(AuthBehavior mode) =>
    mode == AuthBehavior.remote ? 'remote' : 'local';

void main() {
  late int ends;

  /// A gate in [mode], with the current session in [state]. With [superseded],
  /// the returned ticket belongs to the session before the current one.
  ({SessionAuthGate gate, SessionTicket ticket}) arrange(
    AuthBehavior mode,
    _Epoch state, {
    bool superseded = false,
  }) {
    ends = 0;
    final gate = SessionAuthGate(authBehavior: mode, endSession: () => ends++);
    var ticket = gate.ticket;
    if (state != _Epoch.none) {
      gate.begin();
      ticket = gate.ticket;
      if (superseded) gate.begin();
    }
    if (state == _Epoch.ended) gate.markEnded();
    return (gate: gate, ticket: ticket);
  }

  // The whole decision, one row per combination (AC5). "None yet" has no
  // earlier session for a ticket to belong to, so it has no superseded row.
  group('decideOn401: mode × kind × epoch × ticket', () {
    const r = AuthDecision.retry, e = AuthDecision.end, i = AuthDecision.ignore;
    const local = AuthBehavior.local, remote = AuthBehavior.remote;
    const normal = RequestKind.normal, best = RequestKind.bestEffort;
    final rows = <(AuthBehavior, RequestKind, _Epoch, bool, AuthDecision)>[
      (local, normal, _Epoch.none, false, r),
      (local, normal, _Epoch.live, false, r),
      (local, normal, _Epoch.live, true, i),
      (local, normal, _Epoch.ended, false, i),
      (local, normal, _Epoch.ended, true, i),
      (remote, normal, _Epoch.none, false, i),
      (remote, normal, _Epoch.live, false, e),
      (remote, normal, _Epoch.live, true, i),
      (remote, normal, _Epoch.ended, false, i),
      (remote, normal, _Epoch.ended, true, i),
      for (final mode in [local, remote]) ...[
        (mode, best, _Epoch.none, false, i),
        (mode, best, _Epoch.live, false, i),
        (mode, best, _Epoch.live, true, i),
        (mode, best, _Epoch.ended, false, i),
        (mode, best, _Epoch.ended, true, i),
      ],
    ];

    for (final (mode, kind, state, superseded, expected) in rows) {
      final ticketLabel =
          superseded ? 'a superseded ticket' : 'the current one';
      test(
          '${_modeName(mode)}, ${kind.name}, ${state.name}, $ticketLabel → '
          '${expected.name}', () {
        final (:gate, :ticket) = arrange(mode, state, superseded: superseded);

        expect(gate.decideOn401(ticket, kind: kind), expected);
        expect(ends, 0, reason: 'deciding never ends the session by itself');
      });
    }
  });

  group('end', () {
    test('ends the live session once, whoever asks again', () {
      final (:gate, :ticket) = arrange(AuthBehavior.remote, _Epoch.live);

      gate.end(ticket);
      gate.end(ticket);

      expect(ends, 1);
      expect(gate.hasEnded, isTrue);
    });

    test('a superseded ticket cannot end the session that replaced it', () {
      final (:gate, :ticket) =
          arrange(AuthBehavior.remote, _Epoch.live, superseded: true);

      gate.end(ticket);

      expect(ends, 0);
      expect(gate.isLive, isTrue);
    });

    test('with no session yet there is nothing to end', () {
      final (:gate, :ticket) = arrange(AuthBehavior.local, _Epoch.none);

      gate.end(ticket);

      expect(ends, 0);
      expect(gate.hasEnded, isFalse);
    });

    test('a session logout() already ended is not ended again', () {
      final (:gate, :ticket) = arrange(AuthBehavior.local, _Epoch.ended);

      gate.end(ticket);

      expect(ends, 0);
    });

    test('a throwing endSession is swallowed, and the session still ends', () {
      final gate = SessionAuthGate(
        authBehavior: AuthBehavior.remote,
        endSession: () => throw StateError('logout failed'),
      )..begin();

      expect(() => gate.end(gate.ticket), returnsNormally);
      expect(gate.hasEnded, isTrue);
    });

    // The latch the gate replaces: `sseManagerProvider`'s `logoutTriggered`
    // lived as long as the provider build, and locally that is the whole tab,
    // so every forced logout after the first did nothing.
    test('a session begun after an ended one can end too', () {
      final (:gate, :ticket) = arrange(AuthBehavior.local, _Epoch.live);

      gate.end(ticket);
      gate.begin();
      gate.end(gate.ticket);

      expect(ends, 2);
    });
  });

  group('begin and markEnded', () {
    test('markEnded with no session live changes nothing', () {
      final (:gate, ticket: _) = arrange(AuthBehavior.local, _Epoch.none);

      gate.markEnded();

      expect(gate.hasEnded, isFalse);
      expect(gate.isLive, isFalse);
    });

    test('begin during a live session supersedes it', () {
      final (:gate, :ticket) = arrange(AuthBehavior.remote, _Epoch.live);

      gate.begin();

      expect(gate.decideOn401(ticket), AuthDecision.ignore);
      expect(gate.isLive, isTrue);
    });
  });

  // One row per fix in #1666's history table (AC6), stated in the terms that
  // keep each one fixed now.
  group('the four fixes the gate now carries', () {
    test(
        'f02b00422 (#1627): under Remote Assistance a command\'s 401 ends the '
        'session, once', () {
      final (:gate, :ticket) = arrange(AuthBehavior.remote, _Epoch.live);

      expect(gate.decideOn401(ticket), AuthDecision.end);
      gate.end(ticket);
      expect(gate.decideOn401(ticket), AuthDecision.ignore);
      gate.end(ticket);

      expect(ends, 1);
    });

    test(
        'f02b00422 (#1627): a 401 from a connection that has been replaced does '
        'not end the new session', () {
      final (:gate, :ticket) =
          arrange(AuthBehavior.remote, _Epoch.live, superseded: true);

      expect(gate.decideOn401(ticket), AuthDecision.ignore);
      gate.end(ticket);

      expect(ends, 0);
    });

    test(
        '7734c2e4d: End Session\'s own cleanup, answered 401 during or after '
        'the teardown, asks for no second one', () {
      final (:gate, :ticket) = arrange(AuthBehavior.remote, _Epoch.live);

      gate.markEnded(); // logout(), before SessionStrategy.end spends the token
      // the teardown's requests, and a fire-and-forget one that outlives it
      for (var i = 0; i < 3; i++) {
        expect(gate.decideOn401(ticket), AuthDecision.ignore);
        gate.end(ticket);
      }

      expect(ends, 0);
    });

    test(
        'bb7d394ae: the SSE bootstrap\'s health check neither retries nor ends '
        'the session', () {
      for (final mode in [AuthBehavior.local, AuthBehavior.remote]) {
        final (:gate, :ticket) = arrange(mode, _Epoch.live);

        expect(gate.decideOn401(ticket, kind: RequestKind.bestEffort),
            AuthDecision.ignore,
            reason: _modeName(mode));
      }
    });

    test(
        '721939aa8: logout\'s unsubscribe, and a re-activation\'s dispose on the '
        'old bridge, end nothing', () {
      // Logout: the unsubscribe runs in the ended session.
      final logout = arrange(AuthBehavior.remote, _Epoch.ended);
      expect(logout.gate.decideOn401(logout.ticket), AuthDecision.ignore);

      // Re-activation: the old bridge's dispose runs with its own, older ticket.
      final (:gate, :ticket) = arrange(AuthBehavior.remote, _Epoch.live);
      gate.begin(); // the transport swap
      expect(gate.decideOn401(ticket), AuthDecision.ignore);
      gate.end(ticket);

      expect(ends, 0);
      expect(gate.isLive, isTrue);
    });
  });
}
