// #1627: a 401 on a credential that cannot be refreshed ends the session.
//
// THE DEFECT. `_withAuthRetry` answered every 401 the same way: `reauth()`, then
// retry. Locally that is right — the router's own session token refreshes. Under
// Remote Assistance the credential is Guardian's `temporaryAccessToken`, minted
// for one support session, and a 401 means that session is over. So a rejected
// remote command ran the *local* recovery: a WASM `refreshToken()` against a token
// that cannot be refreshed, then `restoreSession()`, whose "network error — might
// recover" branch returns without logging out. The request failed, the session
// stayed on screen, and nothing told the operator it had ended.
//
// THE MEASUREMENT (2026-09-24, Guardian QA and dev, `POST /actions/usp`, status
// only): no auth, a garbage bearer and a fake expired JWT all answer `401`, and
// auth is checked before the session lookup — an all-zero session id is still a
// 401, not a 404. `_isAuthError` matches on `HTTP 401`, so it already recognises
// the real response and needed no widening.
//
// THE FIX THESE TESTS PIN. The decision keys on the existing [AuthBehavior], the
// same value `UspBridgeClient` has always used for its own REST 401s. Remote:
// no reauth, [UspClient.onForceLogout], rethrow. Local: unchanged.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

import '../mocks.dart';

const _path = 'Device.DeviceInfo.SerialNumber';

/// One call per verb that goes through `_withAuthRetry`, so a gate added to one
/// verb's private helper instead of the shared wrapper cannot pass.
final _commands = <String, Future<Object?> Function(UspClient)>{
  'get': (c) => c.get([_path]),
  'set': (c) => c.set({'Device.X.Enable': 'true'}),
  'set (batch)': (c) => c.set({'Device.X.Enable': 'true', 'Device.Y': '1'}),
  'setOrdered': (c) => c.setOrdered([
        [
          {'Device.X.Enable': 'true'}
        ]
      ]),
  'add': (c) => c.add([
        {'path': 'Device.NAT.PortMapping.'}
      ]),
  'delete': (c) => c.delete(['Device.NAT.PortMapping.1.']),
  'operate': (c) => c.operate('Device.Reboot()'),
  'listSubscriptions': (c) => c.listSubscriptions(),
};

void main() {
  group('UspClient - remote: a 401 ends the session without a reauth (#1627)',
      () {
    for (final MapEntry(key: verb, value: send) in _commands.entries) {
      test(verb, () async {
        final transport = UnauthenticatedTransport();
        final client = UspClient.withTransport(transport)
          ..authBehavior = AuthBehavior.remote;

        var relogins = 0;
        var forcedLogouts = 0;
        client.onReauthRequired = () async => relogins++;
        client.onForceLogout = () => forcedLogouts++;

        await expectLater(send(client), throwsA(isA<Exception>()),
            reason: 'the caller must still see the request fail');

        expect(transport.refreshCalls, 0,
            reason:
                'reauth Stage 1 refreshes a token Guardian will not refresh');
        expect(relogins, 0,
            reason: 'reauth Stage 2 is `restoreSession()`, whose network-error '
                'branch returns without logging out — the silent failure');
        expect(forcedLogouts, 1, reason: 'the session is over; say so');
        expect(transport.requests, 1, reason: 'no retry');
        expect(client.isReauthInProgress, isFalse);
      });
    }

    test('a failure that is not a 401 does not end the session', () async {
      final transport = UnauthenticatedTransport()
        ..failWith = Exception('Transport error: HTTP error: HTTP 503');
      final client = UspClient.withTransport(transport)
        ..authBehavior = AuthBehavior.remote;

      var forcedLogouts = 0;
      client.onForceLogout = () => forcedLogouts++;

      await expectLater(client.get([_path]), throwsA(isA<Exception>()));

      expect(forcedLogouts, 0,
          reason: 'a Guardian or agent outage is the recovery probe\'s job, '
              'not a verdict on the credential');
    });

    test('a 401 from a connection that was since replaced ends nothing',
        () async {
      // The mirror of `reauth()`'s supersession rule. Remote Assistance rebinds
      // the façade when a new support session starts; a request still in flight
      // on the old one comes back 401 because *that* token is dead, and signing
      // the operator out of the new session over it would end a session that is
      // fine.
      final old = UnauthenticatedTransport()..requestGate = Completer<void>();
      final client = UspClient.withTransport(old)
        ..authBehavior = AuthBehavior.remote;

      var forcedLogouts = 0;
      client.onForceLogout = () => forcedLogouts++;

      final inFlight = client.get([_path]);
      client.rebindTransport(UnauthenticatedTransport(rejections: 0),
          baseUrl: 'https://two');
      old.requestGate!.complete();

      await expectLater(inFlight, throwsA(isA<Exception>()));
      expect(forcedLogouts, 0);
    });

    test('an onForceLogout that throws does not replace the 401', () async {
      final client = UspClient.withTransport(UnauthenticatedTransport())
        ..authBehavior = AuthBehavior.remote;
      client.onForceLogout = () => throw StateError('navigation failed');

      await expectLater(
        client.get([_path]),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'message', contains('HTTP 401'))),
      );
    });
  });

  group('UspClient - local: a 401 still refreshes and retries', () {
    test('the default is local', () {
      expect(UspClient.withTransport(UnauthenticatedTransport()).authBehavior,
          same(AuthBehavior.local));
    });

    for (final MapEntry(key: verb, value: send) in _commands.entries) {
      test(verb, () async {
        final transport = UnauthenticatedTransport();
        final client = UspClient.withTransport(transport);

        var forcedLogouts = 0;
        client.onForceLogout = () => forcedLogouts++;

        await send(client);

        expect(transport.refreshCalls, 1, reason: 'reauth Stage 1 ran');
        expect(transport.requests, 2, reason: 'the retry reached the router');
        expect(forcedLogouts, 0);
      });
    }
  });
}
