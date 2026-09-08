// Item 1 of #1357: both Remote Assistance entry points stay unreachable from a
// local build. Phase 1 of epic #1474 opened this file with two source scans;
// phase 7 converted the first of them into the structural assertion it was
// always waiting for.
//
// THE DECISION GUARDED. The agent UI must be unreachable in a local build. RA has
// two entries into `lib/route/router_provider.dart`, and they are now guarded by
// two different *kinds* of thing:
//
//   1. `/remoteAssistance*` — the top-level `redirect` used to pass it through in
//      any build flavour, and phase 1 wrapped a `BuildConfig.isRemote()` gate
//      around it. Phase 7 deleted that gate and deleted the route instead: only
//      `RemoteSurface.routes()` registers `remoteAssistanceRoute`, so in a local
//      build the location does not exist and go_router answers it with its own
//      404. Asserted structurally below, over the two route tables.
//   2. `?session=` on any location — `autoConfigurationLogic` translates it into
//      the confirm route, and this one CANNOT become structural. A location
//      returned *from* a redirect is not filtered by the route table; an unmatched
//      one renders go_router's error page. So the gate stays, and so does its
//      source scan.
//
// Entry 2 is also the one that cost. It does not merely show the wrong screen:
// the confirm view calls `activate(config)`, which registers a Guardian-proxied
// `UspClient`, while `BuildConfig.isRemote()` stays false — so
// `sse_providers.dart` takes its *local* branch and builds a bridge with
// `BridgeEndpoints.local` paths and `AuthBehavior.local` pointed at the Guardian
// origin. On-router paths, no bearer token, wrong host, across the 8 request
// sites in `usp_bridge_client_web.dart` that interpolate `_baseUrl`. "Is this
// RA?" had two different answers in one session.
//
// WHY ENTRY 2 IS STILL A SOURCE SCAN. Two constraints, and together they leave
// no behavioural option at this layer.
//
//   - The gate reads `BuildConfig.isRemote()`, backed by the mutable static
//     `BuildConfig.forceCommandType`. Falsification criterion 2 of #1474 (the
//     no-global criterion) forbids a new test that assigns it: `test/di_test.dart`
//     is the one place that pays that price, for a pure function, and the epic's
//     whole point is to stop the price rising.
//   - The local branch *could* be pumped, but only by standing up the real
//     `routerProvider`, which needs `authProvider`, `sessionProvider` and
//     `remoteAccessProvider`, and whose refusal path then runs the entire local
//     login redirect chain. That test would be measuring the login flow, and would
//     go green again the moment the gate is replaced by any other reason the agent
//     view fails to render.
//
// Note what entry 1 gained by going structural: it no longer reads source at all,
// and it exercises the *remote* side too — which the scan could not, for the
// criterion-2 reason above. A route table is a value, so both modes are assertable
// without touching a global.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/_shared/mode/local_surface.dart';
import 'package:privacy_gui/page/_shared/mode/remote_surface.dart';
import 'package:privacy_gui/route/constants.dart';

/// The build-mode predicate entry 2 must consult. Deliberately the *build* axis
/// and not the runtime one (`authState.isRemoteAssistance`): the defect is
/// precisely that the two disagreed, and it is the build flag that decides which
/// bridge `sse_providers.dart` constructs.
const _buildGate = 'BuildConfig.isRemote()';

/// Every path a route table can match, including nested children, in the order
/// they are declared.
///
/// Recursive because `remoteAssistanceRoute` is top-level today and a later
/// refactor could park it under a shell — at which point a check over the top
/// level only would read green while the location still resolved.
List<String> _allPaths(List<RouteBase> routes) => [
      for (final route in routes)
        ...switch (route) {
          GoRoute() => [route.path, ..._allPaths(route.routes)],
          _ => _allPaths(route.routes),
        },
    ];

void main() {
  final routerFile = File('lib/route/router_provider.dart');

  // Read lazily, so a moved file fails as the named test below rather than
  // throwing inside `main()` before any `test()` is registered — which the runner
  // reports as "failed to load" with a stack trace and none of the `reason:`
  // strings.
  late final String routerSource = routerFile.readAsStringSync();

  /// Lines of [routerSource] from the first line containing [from] up to and
  /// including the first later line containing [to], **with comment lines
  /// removed**. Returns null if either anchor is missing, so a moved anchor fails
  /// as "region not found" rather than as a silently empty search.
  ///
  /// Dropping `//` lines is not tidiness, it is the whole correctness of this
  /// file. The first version of this test kept them, and the comment above the
  /// gate explains the gate by quoting `BuildConfig.isRemote()` — so
  /// `contains(_buildGate)` was satisfied by prose, and deleting the four lines
  /// of `if` left the test green. Verified by doing exactly that.
  ///
  /// Anchors are chosen to be the code that *does the thing*, not line numbers
  /// or comment text: an edit that keeps the anchors and drops the gate is the
  /// exact regression this file exists for, and an edit that removes an anchor
  /// cannot help but be deliberate.
  String? region({required String from, required String to}) {
    final lines = routerSource.split('\n');
    final start = lines.indexWhere((l) => l.contains(from));
    if (start < 0) return null;
    final end = lines.indexWhere((l) => l.contains(to), start);
    if (end < 0) return null;
    return lines
        .sublist(start, end + 1)
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
  }

  group('both Remote Assistance entry points are unreachable locally', () {
    test('the router file is where this scan expects it', () {
      expect(
        routerFile.existsSync(),
        isTrue,
        reason: '${routerFile.path} moved or was split. Re-point the entry-2 '
            'scan below; entry 1 does not read this file any more.',
      );
    });

    group('entry 1: the /remoteAssistance route itself', () {
      test('a local build registers no route to the agent UI', () {
        expect(
          _allPaths(const LocalSurface().routes()),
          isNot(contains(RoutePath.remoteAssistanceConfirm)),
          reason: 'the agent UI is reachable in a local build. #1474 phase 7 '
              'replaced the `BuildConfig.isRemote()` gate in the top-level '
              'redirect with this absence, so putting `remoteAssistanceRoute` '
              'back into `sharedAppRoutes` re-opens #1357 item 1 with nothing '
              'left to refuse it — the redirect branch for /remoteAssistance is '
              'now an unconditional pass-through.',
        );
      });

      test('the remote build is the one that registers it', () {
        expect(
          _allPaths(const RemoteSurface().routes()),
          contains(RoutePath.remoteAssistanceConfirm),
          reason: 'no surface registers the confirm route, so RA is now '
              'unreachable in every mode including its own. This is the other '
              'half of the assertion above: "absent locally" is only a gate if '
              'it is present somewhere.',
        );
      });

      test('the tables differ by exactly that one route', () {
        final local = _allPaths(const LocalSurface().routes()).toSet();
        final remote = _allPaths(const RemoteSurface().routes()).toSet();

        expect(
          remote.difference(local),
          {RoutePath.remoteAssistanceConfirm},
          reason: 'the remote surface has grown a second mode-only route. That '
              'may well be correct, but it is a decision — RA composes the '
              'shared table plus the agent entry, and anything else the agent '
              'can reach that the owner cannot needs its own line here.',
        );
        expect(
          local.difference(remote),
          isEmpty,
          reason: 'a route the local surface registers is missing from the '
              'remote table. RA is a *superset* by construction '
              '(`[...sharedAppRoutes, remoteAssistanceRoute]`), so this means '
              'someone stopped composing and started listing.',
        );
      });
    });

    test('entry 2: the ?session= redirect in autoConfigurationLogic', () {
      final block = region(
        from: "queryParameters['session']",
        to: r"?session=$raSession&token=$raToken",
      );

      expect(block, isNotNull,
          reason: 'the ?session= branch of autoConfigurationLogic moved or was '
              'renamed — re-anchor this test on it');
      expect(
        block,
        contains(_buildGate),
        reason: 'a ?session= URL translates into the RA confirm route in ANY '
            'build flavour. In a local build that registers a Guardian-proxied '
            'UspClient behind a predicate that reads false, producing a hybrid '
            'bridge: local endpoint paths and no bearer token against the '
            'Guardian origin (#1357 item 1). Restore the $_buildGate gate. '
            'Deleting the route (what phase 7 did for entry 1) does NOT cover '
            'this one: a redirect return value bypasses the route table and an '
            "unmatched location renders go_router's error page.",
      );
    });

    // A census, not a gate check. It exists so that a *new* way of reaching the
    // agent route has to be noticed, and it is scoped deliberately: it keeps a
    // future reader from "helpfully" gating the RA navigations inside
    // `remote_session_chip.dart` (mounted only by `RemoteSurface` since #1497) or
    // the confirm view's own self-redirect.
    //
    // Note which entry is absent. Entry 1 has no line here at all any more — it
    // is an absence in a list, not a redirect — so the structural tests above are
    // the whole of it and this count is about everything else.
    test('nothing new sends the user to the agent route', () {
      final agentRouteRedirects = routerSource
          .split('\n')
          .asMap()
          .entries
          .where((e) => e.value.contains('RoutePath.remoteAssistanceConfirm'))
          .map((e) => e.key + 1)
          .toList();

      expect(
        agentRouteRedirects.length,
        5,
        reason: 'router_provider.dart names the RA confirm route in 5 places, '
            'all of them already gated on the build or on `isActive`: three '
            'inside the /usp* `if (GlobalConfig.remote.isActive)` block — the '
            'session-refresh redirect, and the two arms of the no-session '
            'ternary — plus entry 2 (the `?session=` translation, gated by this '
            'file) and the `force=remote` build-mode redirect in '
            '`autoConfigurationLogic`, which is itself an '
            '`if (BuildConfig.isRemote())` and so cannot fire in a local build. '
            'Found ${agentRouteRedirects.length} at lines $agentRouteRedirects '
            '— a sixth needs its own gate and its own case here.\n\n'
            'The count moved 4 -> 5 in #1323 phase 5, and the reason is worth '
            'knowing before you move it again: the no-session return used to be '
            'one bare path and is now a ternary on '
            '`remoteAssistanceProvider.isActive`, appending `?ended=true` when a '
            'Guardian session was activated in this page lifetime. Both arms are '
            'inside the same block as before, so nothing about the gating story '
            'changed — only the line count. Cause: cause 3 now clears '
            '`remoteAccessProvider` on every exit, which routed all eight '
            'automatic RA endings through this line, where the bare path renders '
            "the confirm view's `_buildMissingParamsView()`.\n\n"
            'Phase 7 did NOT move it: the /usp* block belongs to phase 9, and '
            'entry 1 never named the confirm route (it refused by returning '
            '`RoutePath.home`), so deleting that gate left this count alone.',
      );
    });
  });
}
