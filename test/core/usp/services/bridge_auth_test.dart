import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/usp/services/bridge_auth.dart';
import 'package:privacy_gui/core/usp/services/session_auth_gate.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';

void main() {
  late int ends;
  late int reauths;

  SessionAuthGate liveGate(AuthBehavior mode) {
    ends = 0;
    reauths = 0;
    return SessionAuthGate(authBehavior: mode, endSession: () => ends++)
      ..begin();
  }

  Future<void> okReauth() async => reauths++;
  Future<void> failedReauth() async {
    reauths++;
    throw StateError('restore unreachable');
  }

  // The bridge's ticket is taken where its token is read (#1666).
  group('BridgeCredential', () {
    test('a fixed token names the session that was live when it was given', () {
      final gate = liveGate(AuthBehavior.remote);
      final credential = BridgeCredential(
          fixedToken: 'guardian', sessionToken: () => null, gate: gate);
      final given = gate.ticket;

      gate.begin(); // a Remote Assistance re-activation: a new session

      final (:token, :ticket) = credential.read();
      expect(token, 'guardian');
      expect(ticket, given,
          reason: 'the old bridge, still disposing, must not speak for the '
              'session that replaced it (721939aa8)');
      expect(gate.decideOn401(ticket), AuthDecision.ignore);
    });

    test('the client\'s token names the session live when it is read', () {
      final gate = liveGate(AuthBehavior.local);
      var current = 'one';
      final credential =
          BridgeCredential(sessionToken: () => current, gate: gate);
      final first = credential.read();

      gate.begin(); // the user logged in again; a local bridge lives on
      current = 'two';

      final second = credential.read();
      expect(second.token, 'two');
      expect(second.ticket, gate.ticket);
      expect(second.ticket, isNot(first.ticket));
    });

    test('no fixed token and no session token is a StateError', () {
      final credential = BridgeCredential(
          sessionToken: () => null, gate: liveGate(AuthBehavior.local));

      expect(credential.read, throwsStateError);
    });
  });

  group('resendAfter401', () {
    test('local: reauth and send again', () async {
      final gate = liveGate(AuthBehavior.local);

      expect(
          await resendAfter401(
              gate: gate, ticket: gate.ticket, resent: false, reauth: okReauth),
          isTrue);
      expect(reauths, 1);
      expect(ends, 0);
    });

    test('local: a 401 on the request sent again ends the session', () async {
      final gate = liveGate(AuthBehavior.local);

      expect(
          await resendAfter401(
              gate: gate, ticket: gate.ticket, resent: true, reauth: okReauth),
          isFalse);
      expect(reauths, 0);
      expect(ends, 1);
    });

    // A failed reauth has been decided already (#1666 C1): `UspClient.reauth`
    // ended the session if the router refused the token, and a router it could
    // not reach says nothing about the credential.
    test('local: a reauth that fails ends nothing more', () async {
      final gate = liveGate(AuthBehavior.local);

      expect(
          await resendAfter401(
              gate: gate,
              ticket: gate.ticket,
              resent: false,
              reauth: failedReauth),
          isFalse);
      expect(ends, 0);
    });

    test('remote: the session ends, with no reauth', () async {
      final gate = liveGate(AuthBehavior.remote);

      expect(
          await resendAfter401(
              gate: gate, ticket: gate.ticket, resent: false, reauth: okReauth),
          isFalse);
      expect(reauths, 0);
      expect(ends, 1);
    });

    // bb7d394ae: the SSE bootstrap's health check.
    test('a best-effort request neither reauths nor ends', () async {
      for (final mode in [AuthBehavior.local, AuthBehavior.remote]) {
        final gate = liveGate(mode);

        expect(
            await resendAfter401(
                gate: gate,
                ticket: gate.ticket,
                resent: false,
                reauth: okReauth,
                kind: RequestKind.bestEffort),
            isFalse);
        expect(reauths, 0);
        expect(ends, 0);
      }
    });

    // 7734c2e4d and 721939aa8: End Session's own cleanup, and logout's
    // unsubscribe, run in the session logout() has already ended.
    test('an ended session neither reauths nor ends again', () async {
      final gate = liveGate(AuthBehavior.remote);
      final ticket = gate.ticket;
      gate.markEnded();

      expect(
          await resendAfter401(
              gate: gate, ticket: ticket, resent: false, reauth: okReauth),
          isFalse);
      expect(reauths, 0);
      expect(ends, 0);
    });

    test('a superseded session cannot end the one that replaced it', () async {
      final gate = liveGate(AuthBehavior.remote);
      final old = gate.ticket;
      gate.begin();

      expect(
          await resendAfter401(
              gate: gate, ticket: old, resent: false, reauth: okReauth),
          isFalse);
      expect(ends, 0);
      expect(gate.isLive, isTrue);
    });
  });

  // The remote bridge is rebuilt on a re-activation only because
  // `remote_transport_strategy.dart` selects `RemoteAssistanceConfig` and every
  // activation makes a new one that compares unequal. Value equality would keep
  // the old bridge — and its old ticket — for a re-activation with the same
  // link, and every 401 of the new session would then be ignored (#1666).
  test('two RemoteAssistanceConfigs with the same fields are not equal', () {
    // Not `const`: two const instances with the same fields are one object.
    final a = RemoteAssistanceConfig(
      guardianBaseUrl: 'https://guardian.example',
      sessionId: 's',
      temporaryAccessToken: 't',
    );
    final b = RemoteAssistanceConfig(
      guardianBaseUrl: 'https://guardian.example',
      sessionId: 's',
      temporaryAccessToken: 't',
    );

    expect(a == b, isFalse);
  });
}
