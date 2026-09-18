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

      // These two are documented fabrications, and the expectations exist to
      // record that rather than to bless it: Guardian has no health or turbo
      // endpoint, which is why `sseBootstrapProvider` skips its `health()` call
      // in remote mode instead of calling a 404. #1474 phase 3 deliberately left
      // that `if` in place — see the comment there — because wrapping a
      // fabricated path in a strategy member would freeze it into a contract.
      // When the transport layer deletes these two fields, delete these two
      // lines with them.
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

  test('every path is absolute', () {
    final all = [
      ..._paths(BridgeEndpoints.local),
      ..._paths(BridgeEndpoints.remote('sess-4711')),
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
