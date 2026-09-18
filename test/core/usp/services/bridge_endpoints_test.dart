// Phase 3 of epic #1474 / #1493: the endpoint table that decides where every
// bridge request lands had zero tests.
//
// THE DECISION GUARDED. That the two tables are *disjoint* and that the remote
// one is session-scoped. `BridgeEndpoints` is interpolated at 8 request sites in
// `usp_bridge_client_web.dart` as `'$_baseUrl${_endpoints.X}'`, so the table and
// the host have to agree: on-router paths (`/api/v1/...`) only make sense against
// the router's own origin, Guardian paths only against the Guardian host. Phase 1
// of this epic fixed a live defect that was exactly this pair coming apart — a
// `?session=` URL in a local build registered a Guardian-proxied client while
// `BuildConfig.isRemote()` read false, producing local paths and no bearer token
// aimed at `qa.guardian.tools`.
//
// HOW IT COULD SILENTLY REVERT. Two ways, neither of which throws.
//
//   1. A path edited in one table and not the other, or a leading slash dropped:
//      the client string-concatenates, so `'https://host' + 'v1/...'` yields
//      `https://hostv1/...` and fails as a network error far from the cause.
//   2. `remote()` losing its session id — it is a factory, not a const, precisely
//      because all four paths embed the id. A refactor that hoisted it to a
//      `static const` would compile only by dropping the interpolation, and every
//      agent would then share one subscription namespace on the proxy.
//
// WHY THIS TEST TYPE. Plain unit assertions on a pure value class — no scan, no
// pump. The reason this file did not exist is that the table was only ever read
// through the VM stub of `UspBridgeClient`, which discards its `endpoints`
// argument and exposes no getter, so nothing downstream could observe it.
// Asserting the table directly is the cheapest place to see it.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';

/// All four fields, so a new one cannot be added without deciding what it means
/// in both modes. Used by the disjointness and shape sweeps below.
List<String> _paths(BridgeEndpoints e) =>
    [e.notifications, e.subscription, e.health, e.turboPrefix];

void main() {
  group('the local table addresses the on-router bridge', () {
    test('exact paths', () {
      const local = BridgeEndpoints.local;

      expect(local.notifications, '/api/v1/notifications');
      expect(local.subscription, '/api/v1/subscription');
      expect(local.health, '/api/v1/health');
      expect(local.turboPrefix, '/api/v1/turbo');
    });

    test('is a const singleton', () {
      expect(identical(BridgeEndpoints.local, BridgeEndpoints.local), isTrue,
          reason: 'LocalTransportStrategy hands this straight to '
              'BridgeConfig, and `_endpoints = endpoints ?? '
              'BridgeEndpoints.local` in the client means the omitted-argument '
              'case and the explicit case must be the same object');
    });
  });

  group('the remote table addresses the Guardian proxy', () {
    test('every path is scoped to the session', () {
      final remote = BridgeEndpoints.remote('sess-4711');

      for (final path in _paths(remote)) {
        expect(path, contains('sess-4711'),
            reason: 'Guardian scopes subscriptions to the session and rejects '
                'duplicate IDs across them. A path that lost its session id '
                'would put every agent in one namespace.');
      }
    });

    test('exact paths', () {
      final remote = BridgeEndpoints.remote('sess-4711');
      const base = '/v1/guardians/remote-assistances/sessions/sess-4711/usp';

      expect(remote.notifications, '$base/notifications');
      expect(remote.subscription, '$base/subscriptions',
          reason: 'plural remotely, singular locally (/api/v1/subscription) — '
              'the asymmetry is Guardian\'s, and it is the kind of detail a '
              'well-meaning "consistency" edit breaks');

      // **`health` is not a fabrication, and this comment used to say it was.**
      // Guardian's own OpenAPI spec serves `/usp/health` at exactly this path, so
      // #1576 deleted the remote-mode skip in `sseBootstrapProvider` and pointed
      // `RemoteTransportStrategy.isRouterReachable` at it. The expectation below is
      // now an ordinary contract assertion.
      //
      // `turboPrefix` is a different matter and is still unverified: nothing calls
      // it remotely and no spec has been seen for it. Left as a declared path
      // rather than deleted, because deleting a `required` field to express "we
      // have not checked" would be the mistake `health` just cost a release cycle.
      expect(remote.health, '$base/health');
      expect(remote.turboPrefix, '$base/turbo');
    });

    test('a different session yields a different table', () {
      final a = BridgeEndpoints.remote('sess-a');
      final b = BridgeEndpoints.remote('sess-b');

      expect(_paths(a), isNot(_paths(b)),
          reason:
              'remote() is a factory rather than a const for this reason; a '
              'refactor that made it const could only do so by dropping the '
              'interpolation');
    });
  });

  test('the two tables share no path', () {
    final local = _paths(BridgeEndpoints.local).toSet();
    final remote = _paths(BridgeEndpoints.remote('sess-4711')).toSet();

    expect(local.intersection(remote), isEmpty,
        reason: 'an overlapping path is a path that works against the wrong '
            'host, which is how the phase-1 defect stayed invisible: the request '
            'was well formed and simply went nowhere useful');
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RemoteReads — #1580 / epic #1575
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // THE DECISION GUARDED. That these paths are **optional**, not a fifth, sixth
  // and seventh `required` field on `BridgeEndpoints`. They are the first group
  // of endpoints that exists remotely and has no local counterpart at all — the
  // router keeps no notification store — so giving local a placeholder would
  // repeat exactly the mistake three docstrings spent a year repeating about
  // `health` (#1576). `BridgeConfig.remoteReads == null` is how a local build
  // says "these do not exist here", and the page reads that to render its
  // not-available state instead of a red developer page.
  group('the remote read table', () {
    test('exact paths', () {
      final reads = RemoteReads.forSession('sess-4711');
      const base = '/v1/guardians/remote-assistances/sessions/sess-4711/usp';

      expect(reads.state, '$base/state');
      expect(reads.notificationsHistory, '$base/notifications/history');
      expect(reads.notification('msg-9'), '$base/notifications/msg-9');
    });

    test('the per-entry path is the history path with the id swapped in', () {
      final reads = RemoteReads.forSession('sess-4711');

      expect(
        reads.notification('history'),
        reads.notificationsHistory,
        reason: 'not a bug to fix — the spec says the `history` route wins on '
            'the server, so a msgId of that literal can never address an '
            'entry. The equality is here so that a reader who wonders reaches '
            'this note rather than filing it.',
      );
    });

    test('every path is scoped to the session', () {
      final reads = RemoteReads.forSession('sess-4711');

      for (final path in [
        reads.state,
        reads.notificationsHistory,
        reads.notification('msg-9'),
        reads.results('key-abc'),
      ]) {
        expect(path, contains('sess-4711'));
      }
    });

    group('results — #1578', () {
      test('carries commandKey as a required query parameter', () {
        final reads = RemoteReads.forSession('sess-4711');
        const base = '/v1/guardians/remote-assistances/sessions/sess-4711/usp';

        expect(reads.results('key-abc'), '$base/results?commandKey=key-abc');
      });

      test('percent-encodes the key', () {
        // The UUIDs Guardian mints need no escaping, which is exactly why an
        // unescaped interpolation would survive review and break on the first key
        // that does. The value reaches us out of a JSON response and is echoed into
        // a query string.
        final reads = RemoteReads.forSession('sess-4711');

        expect(reads.results('a b&c=d'), endsWith('?commandKey=a+b%26c%3Dd'));
      });

      test('is not a path on its own', () {
        // There is no `results` field, deliberately: `commandKey` has no default and
        // the endpoint rejects a bare call, so a bare path would be a URL that can
        // only 400. The method is the whole API.
        final reads = RemoteReads.forSession('sess-4711');

        expect(reads.results('k'), contains('?commandKey='));
      });
    });

    test('a different session yields a different table', () {
      expect(
        RemoteReads.forSession('sess-a').notificationsHistory,
        isNot(RemoteReads.forSession('sess-b').notificationsHistory),
      );
    });

    test('shares no path with the local table', () {
      final reads = RemoteReads.forSession('sess-4711');
      final local = _paths(BridgeEndpoints.local).toSet();

      expect(
        local.intersection({reads.state, reads.notificationsHistory}),
        isEmpty,
      );
    });
  });

  test('every path is absolute', () {
    final reads = RemoteReads.forSession('sess-4711');
    final all = [
      ..._paths(BridgeEndpoints.local),
      ..._paths(BridgeEndpoints.remote('sess-4711')),
      reads.state,
      reads.notificationsHistory,
      reads.notification('msg-9'),
    ];

    for (final path in all) {
      expect(path, startsWith('/'),
          reason: 'the client builds URLs by concatenation '
              '(\'\$_baseUrl\${_endpoints.X}\'), so a dropped leading slash '
              'silently produces https://hostv1/... and surfaces as a network '
              'error nowhere near this table');
      expect(path, isNot(endsWith('/')),
          reason: 'turboPrefix is joined as \'\$turboPrefix/\$action\' — a '
              'trailing slash would double it');
    }
  });
}
