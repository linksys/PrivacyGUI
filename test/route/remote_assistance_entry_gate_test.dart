// Phase 1 of epic #1474 / item 1 of #1357: both Remote Assistance entry points
// stay gated on the build mode.
//
// THE DECISION GUARDED. The agent UI must be unreachable in a local build. RA
// has two entries into `lib/route/router_provider.dart` and only one of them was
// ever build-gated:
//
//   1. `/remoteAssistance*` — the top-level `redirect` passed it straight
//      through in any build flavour.
//   2. `?session=` on any location — `autoConfigurationLogic` translated it into
//      the confirm route in any build flavour.
//
// Entry 2 is the one that cost. It does not merely show the wrong screen: the
// confirm view calls `activate(config)`, which registers a Guardian-proxied
// `UspClient`, while `BuildConfig.isRemote()` stays false — so
// `sse_providers.dart` takes its *local* branch and builds a bridge with
// `BridgeEndpoints.local` paths and `AuthBehavior.local` pointed at the Guardian
// origin. On-router paths, no bearer token, wrong host, across the 8 request
// sites in `usp_bridge_client_web.dart` that interpolate `_baseUrl`. "Is this
// RA?" had two different answers in one session.
//
// HOW IT COULD SILENTLY REVERT. Both gates are a negated one-line condition
// wrapped around code that reads perfectly well without it. Deleting either
// restores a working RA flow in a local build — nothing throws, nothing renders
// an error, and the damage is a *misconfigured transport* that surfaces later as
// network timeouts. There is no user-visible symptom at the seam, so review is
// the only thing standing between the deletion and a shipped hole.
//
// WHY THIS TEST TYPE. Two constraints, and together they leave a source scan.
//
//   - The gate reads `BuildConfig.isRemote()`, backed by the mutable static
//     `BuildConfig.forceCommandType`. Falsification criterion 2 of #1474 (the
//     no-global criterion) forbids a new test that assigns it: `test/di_test.dart`
//     is the one place that pays that price, for a pure function, and the epic's
//     whole point is to stop the price rising. So the remote branch cannot be
//     exercised behaviourally at this layer.
//   - The local branch *could* be pumped — the default flavour in tests is
//     `ForceCommand.none`, so `isRemote()` is already false — but only by
//     standing up the real `routerProvider`, which needs `authProvider`,
//     `sessionProvider` and `remoteAccessProvider`, and whose refusal path then
//     runs the entire local login redirect chain. That test would be measuring
//     the login flow, and would go green again the moment the gate is replaced
//     by any other reason the agent view fails to render.
//
// This is temporary by design. #1474 phase 7 deletes both `if`s and leaves
// `remoteAssistanceRoute` out of a local build's route table altogether, at
// which point the invariant becomes "the route is absent" — structural, and
// assertable without reading source. Delete this file then.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The build-mode predicate both gates must consult. Deliberately the *build*
/// axis and not the runtime one (`authState.isRemoteAssistance`): the defect is
/// precisely that the two disagreed, and it is the build flag that decides which
/// bridge `sse_providers.dart` constructs.
const _buildGate = 'BuildConfig.isRemote()';

void main() {
  final routerFile = File('lib/route/router_provider.dart');

  // Read lazily. Phase 7 is expected to move this file, and a top-level
  // `readAsStringSync` would then throw during `main()` — before any `test()` is
  // registered — so the runner reports "failed to load" with a stack trace and
  // none of the `reason:` strings below. Lazy plus the existence test keeps a
  // moved file reported as a named failure that says what to do.
  late final String routerSource = routerFile.readAsStringSync();

  /// Lines of [routerSource] from the first line containing [from] up to and
  /// including the first later line containing [to], **with comment lines
  /// removed**. Returns null if either anchor is missing, so a moved anchor fails
  /// as "region not found" rather than as a silently empty search.
  ///
  /// Dropping `//` lines is not tidiness, it is the whole correctness of this
  /// file. The first version of this test kept them, and the comment above entry
  /// 1's gate explains the gate by quoting `BuildConfig.isRemote()` — so
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

  group('both Remote Assistance entry points are build-gated', () {
    test('the router file is where this scan expects it', () {
      expect(
        routerFile.existsSync(),
        isTrue,
        reason:
            '${routerFile.path} moved or was split. Re-point this scan, or — '
            'if this is #1474 phase 7 removing both gates in favour of leaving '
            '`remoteAssistanceRoute` out of a local build\'s route table — '
            'delete this file.',
      );
    });

    test('entry 1: the /remoteAssistance pass-through', () {
      final block = region(
        from: "startsWith('/remoteAssistance')",
        to: 'return state.uri.toString();',
      );

      expect(block, isNotNull,
          reason: 'the /remoteAssistance branch of the top-level redirect '
              'moved or was renamed — re-anchor this test on it');
      expect(
        block,
        contains(_buildGate),
        reason: 'the /remoteAssistance branch passes through in ANY build '
            'flavour, so a local build can reach the agent UI (#1357 item 1). '
            'Restore the $_buildGate gate, or — if this is #1474 phase 7 — '
            'delete this whole file along with the two `if`s it guards.',
      );
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
            'Guardian origin (#1357 item 1). Restore the $_buildGate gate.',
      );
    });

    // A census, not a gate check. It exists so that a *new* way of reaching the
    // agent route has to be noticed, and it is scoped deliberately: it keeps a
    // future reader from "helpfully" gating the RA navigations inside
    // `remote_session_chip.dart` (already unreachable locally — it self-gates in
    // `build`) or the confirm view's own self-redirect.
    //
    // Note which entry is absent. Entry 1 redirects by *declining* — it returns
    // `RoutePath.home` and never names the confirm route — so it contributes
    // none of these lines and this census cannot see it. That is what the two
    // region tests above are for; the count below is the other half.
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
        4,
        reason: 'router_provider.dart names the RA confirm route in 4 places, '
            'all of them already gated on the build or on `isActive`: the two '
            '/usp* refresh redirects inside `if (GlobalConfig.remote.isActive)`, '
            'entry 2 (the `?session=` translation, gated by this file), and the '
            '`force=remote` build-mode redirect in `autoConfigurationLogic`, '
            'which is itself an `if (BuildConfig.isRemote())` and so cannot fire '
            'in a local build. Found ${agentRouteRedirects.length} at lines '
            '$agentRouteRedirects — a fifth needs its own gate and its own case '
            'here.',
      );
    });
  });
}
