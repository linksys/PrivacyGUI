// Item 1 of #1357: both Remote Assistance entry points stay unreachable from a
// local build. Phase 1 of epic #1474 opened this file with two source scans;
// phase 7 converted the first into the structural assertion it was always waiting
// for, and phase 9 (#1498) converted the second into a behavioural one. No scan for
// a build flag is left, which is the epic's thesis reaching its own guard.
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
//      the confirm route. This one cannot become structural, for a reason phase 7
//      recorded and phase 9 does not change: a location returned *from* a redirect
//      is not filtered by the route table, and an unmatched one renders go_router's
//      error page. But it did not have to stay a scan. Since #1498 the translation
//      is `SessionStrategy.entryPoint`, so the gate is two implementations of one
//      member and both are assertable as values.
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
// WHY ENTRY 2 STOPPED BEING A SOURCE SCAN. The two constraints that forced the scan
// were both about the *gate*, not about the decision:
//
//   - the gate read `BuildConfig.isRemote()`, a mutable static, and #1474's
//     falsification criterion 2 forbids a test that assigns it. Gone: the gate is
//     now a method on a `const` strategy object, and a test names the mode by
//     picking which strategy to construct.
//   - pumping the local branch would have meant standing up the real
//     `routerProvider`, dragging in `authProvider`, `sessionProvider` and
//     `remoteAccessProvider`, and measuring the login redirect chain instead of the
//     gate. Gone for the same reason: the decision is no longer inside the redirect.
//
// What the scan could never do, and these tests do: exercise the **remote** side.
// A scan can only assert that a refusal is spelled somewhere; the pair below
// asserts that local refuses AND that remote accepts, which is what makes "absent
// locally" a gate rather than a feature nobody implemented.
//
// One scan remains and it is a different claim — that the router does not sniff the
// URL itself any more. See its own test.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/mode/impl/local_session_strategy.dart';
import 'package:privacy_gui/core/mode/impl/remote_session_strategy.dart';
import 'package:privacy_gui/framework/mode/session_entry.dart';
import 'package:privacy_gui/page/_shared/mode/local_surface.dart';
import 'package:privacy_gui/page/_shared/mode/remote_surface.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';

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

/// A real `Ref`, for the two members whose signature takes one.
///
/// `entryPoint` does not read a provider in either mode — the URL is its whole
/// input — so this exists to satisfy the signature rather than to configure
/// anything. No overrides, no `tearDown`, no global: #1474's criterion 1 and 2 in
/// one line each.
final _refExposerProvider = Provider<Ref>((ref) => ref);
Ref _refOf(ProviderContainer c) => c.read(_refExposerProvider);

void main() {
  final routerFile = File('lib/route/router_provider.dart');

  // Read lazily, so a moved file fails as the named test below rather than
  // throwing inside `main()` before any `test()` is registered — which the runner
  // reports as "failed to load" with a stack trace and none of the `reason:`
  // strings.
  late final String routerSource = routerFile.readAsStringSync();

  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('both Remote Assistance entry points are unreachable locally', () {
    test('the router file is where the remaining scan expects it', () {
      expect(
        routerFile.existsSync(),
        isTrue,
        reason:
            '${routerFile.path} moved or was split. Re-point the census and '
            'the no-sniffing scan below; the two entry gates do not read this '
            'file any more.',
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

    group('entry 2: a ?session= URL, resolved by cause 3', () {
      // The supporter's link, as it actually arrives: the token is what the
      // confirm view authenticates with, and both parameters ride the same URL.
      final supporterLink = Uri.parse('/?session=sess-42&token=tok-abc');

      test('a local build answers a supporter link with its own login flow',
          () {
        expect(
          const LocalSessionStrategy()
              .entryPoint(_refOf(container), supporterLink),
          isA<OwnCredentialsEntry>(),
          reason: 'a ?session= URL opened a support session in a local build. '
              'That does not merely show the wrong screen — it registers a '
              'Guardian-proxied UspClient behind a predicate reading false, '
              'producing the hybrid bridge of #1357 item 1: local endpoint paths '
              'and no bearer token against the Guardian origin. Deleting the '
              'route (what phase 7 did for entry 1) does NOT cover this one: a '
              'redirect return value bypasses the route table and an unmatched '
              "location renders go_router's error page.",
        );
      });

      test('the remote build is the one that reads it, parameters and all', () {
        final entry = const RemoteSessionStrategy()
            .entryPoint(_refOf(container), supporterLink);

        expect(entry, isA<SupportSessionEntry>(),
            reason:
                'no mode consumes a supporter link, so RA is unreachable by '
                'its own primary entry. This is the other half of the assertion '
                'above, and it is the half the source scan could not make: a '
                'refusal spelled somewhere is not a gate unless the acceptance '
                'exists too.');
        expect(
          (entry as SupportSessionEntry).sessionId,
          'sess-42',
          reason: 'the session id was dropped or renamed on the way through. '
              'The confirm view validates against it before it will connect, so '
              'losing it fails as "Missing Parameters" rather than as anything '
              'that names this seam.',
        );
        expect(entry.token, 'tok-abc',
            reason: 'the token was dropped. It is the credential — there is no '
                'password to fall back on in this mode.');
      });

      test('a link with no session is not a support session in local mode', () {
        // The ordinary case, and worth pinning: the same member runs on every cold
        // entry, not only on supporter links, so a local build reaching for RA when
        // the URL says nothing at all would break every normal launch.
        expect(
          const LocalSessionStrategy()
              .entryPoint(_refOf(container), Uri.parse('/')),
          isA<OwnCredentialsEntry>(),
        );
      });

      test('a remote build with no link parameters still lands on the agent UI',
          () {
        // The arm that used to read `if (BuildConfig.isRemote())` at the end of
        // `autoConfigurationLogic`: a remote build has no login page to fall back
        // to, so a bare entry belongs on the confirm route with nothing filled in.
        final entry = const RemoteSessionStrategy()
            .entryPoint(_refOf(container), Uri.parse('/'));

        expect(entry, isA<SupportSessionEntry>());
        expect((entry as SupportSessionEntry).sessionId, isNull);
        expect(entry.previousSessionEnded, isFalse,
            reason:
                'a cold entry claimed a session had ended here, which sends '
                'the operator to the terminal "session ended" surface instead of '
                'the one that tells them the link is malformed.');
      });

      test('an empty session parameter is not a session', () {
        // `?session=` with nothing after it is a truncated link, and the guard has
        // always been `isNotEmpty` rather than `!= null`. Pinned in both modes: the
        // local arm must not warn about it, and the remote arm must not build a URL
        // the confirm view then rejects with a red developer page.
        final truncated = Uri.parse('/?session=&token=tok-abc');

        expect(
          const LocalSessionStrategy().entryPoint(_refOf(container), truncated),
          isA<OwnCredentialsEntry>(),
        );
        expect(
          (const RemoteSessionStrategy().entryPoint(
                  _refOf(container), truncated) as SupportSessionEntry)
              .sessionId,
          isNull,
        );
      });
    });

    // The one scan left, and it is a different claim from the gates above: not
    // "which build refuses" but "the router does not decide this at all any more".
    //
    // Non-vacuous in the way the deleted scan was not. The old one asserted that a
    // string was present, which prose satisfied until the region filter learned to
    // drop comment lines. This one asserts an *absence* of URL sniffing, so no
    // comment can satisfy it and the only way to make it fail is to write the code
    // back.
    test('the router no longer reads the session parameters itself', () {
      final sniffing = routerSource
          .split('\n')
          .asMap()
          .entries
          .where((e) => !e.value.trimLeft().startsWith('//'))
          .where((e) => e.value.contains("queryParameters['session']"))
          .map((e) => e.key + 1)
          .toList();

      expect(
        sniffing,
        isEmpty,
        reason:
            'router_provider.dart is reading the RA session parameter again, '
            'at line(s) $sniffing. Whatever it does with it, the read itself is '
            'the regression: it means the router is deciding what a `?session=` '
            'means, in a file that cannot know which mode it is in without '
            'consulting the profile. Hand the whole `state.uri` to '
            '`SessionStrategy.entryPoint` and map the answer. Note that '
            '`route_remote_assistance.dart` reads both parameters legitimately — '
            'it is the confirm route\'s own builder, registered only by '
            '`RemoteSurface`, and it is a different file.',
      );
    });

    // A census, not a gate check. It exists so that a *new* way of reaching the
    // agent route has to be noticed, and it is scoped deliberately: it keeps a
    // future reader from "helpfully" gating the RA navigations inside
    // `remote_session_chip.dart` (mounted only by `RemoteSurface` since #1497) or
    // the confirm view's own self-redirect.
    //
    // Note which entries are absent. Entry 1 has no line here at all — it is an
    // absence in a list, not a redirect. Entry 2 has none either since #1498: the
    // `?session=` translation is now a `SupportSessionEntry` value, and this file
    // never names a route.
    test('nothing new sends the user to the agent route', () {
      final agentRouteRedirects = routerSource
          .split('\n')
          .asMap()
          .entries
          // Comment lines dropped, like the scan above. Without the filter the
          // count moves in *both* wrong directions: one doc comment naming the
          // route reds the suite while blaming a redirect that does not exist, and
          // — worse — deleting one of the three real destinations in the same edit
          // that adds such a comment keeps the count at 3 and hides it.
          .where((e) => !e.value.trimLeft().startsWith('//'))
          .where((e) => e.value.contains('RoutePath.remoteAssistanceConfirm'))
          .map((e) => e.key + 1)
          .toList();

      expect(
        agentRouteRedirects.length,
        3,
        reason:
            'router_provider.dart names the RA confirm route in 3 places, and '
            'all three are inside one function — `supportSessionLocation`, which '
            'turns a `SupportSessionEntry` into a location and is the only thing '
            'in this file that knows the agent route exists. The three are its '
            'three shapes: resumable (`?session=&token=`), ended (`?ended=true`) '
            'and bare. Found ${agentRouteRedirects.length} at lines '
            '$agentRouteRedirects — a fourth means someone chose a destination '
            'outside that function, and it needs its own case here and its own '
            'reason.\n\n'
            'The count has moved twice and both moves are worth knowing before you '
            'move it again. 4 -> 5 in #1323 phase 5: the no-session return became a '
            'ternary on `remoteAssistanceProvider.isActive`, appending '
            '`?ended=true` when a Guardian session was activated in this page '
            'lifetime, because cause 3 started clearing `remoteAccessProvider` on '
            'every exit and routed all eight automatic RA endings through a line '
            "whose bare path rendered the confirm view's "
            '`_buildMissingParamsView()`. 5 -> 3 in #1474 phase 9: the four '
            'decisions moved into `SessionStrategy`, and what is left is the '
            'mapping they all funnel through. Fewer lines, same three '
            'destinations.',
      );
    });

    // The scan above counts the three destinations; these assert what they *are*.
    // Both halves are needed and neither implies the other — the count stayed at 3
    // through every mutation of the strings below, which is what made this group a
    // review finding rather than an optional extra.
    group('the three locations a SupportSessionEntry maps to', () {
      test('a resumable session carries both parameters', () {
        expect(
          supportSessionLocation('sess-42', 'tok-abc', false),
          '${RoutePath.remoteAssistanceConfirm}?session=sess-42&token=tok-abc',
        );
      });

      test('a session id with no token still carries the id', () {
        // `SupportSessionEntry`'s two fields are independently nullable, so this is
        // a value the sealed type invites. Requiring both would discard the id and
        // fall through to the bare path, where `_hasRequiredParams` renders the red
        // `_buildMissingParamsView()` for a session that was resumable.
        expect(
          supportSessionLocation('sess-42', null, false),
          '${RoutePath.remoteAssistanceConfirm}?session=sess-42&token=',
          reason:
              'an empty token must be spelled out, not omitted: the confirm '
              'view has to see a half-formed supporter link and report it, rather '
              'than be told the session ended',
        );
      });

      test('an ended session is told apart from a cold load', () {
        // The `?ended=true` arm is the destination of all eight automatic RA
        // endings, and `route_remote_assistance.dart` reads it as the literal
        // `'true'`. Inverting this ternary — or spelling it `?ended=1` — sends every
        // one of them to `_buildMissingParamsView()`, which is the exact regression
        // #1323 phase 5 shipped a fix for.
        expect(
          supportSessionLocation(null, null, true),
          '${RoutePath.remoteAssistanceConfirm}?ended=true',
        );
        expect(
          supportSessionLocation(null, null, false),
          RoutePath.remoteAssistanceConfirm,
          reason:
              'a cold load of a bookmarked /usp URL never had a session, so '
              'telling it one ended is a lie the confirm view will render',
        );
      });
    });
  });
}
