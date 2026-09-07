// Phase 3 of epic #1474 / acceptance 3 of #1493: one override puts the whole
// stack in a different mode.
//
// THE DECISION GUARDED. That a mode is selected through a *provider* and not
// through `BuildConfig.forceCommandType`. The whole point of the epic's
// composition root is that `appModeProfileProvider.overrideWithValue(const
// RemoteModeProfile())` moves transport, credentials, session ending and
// proximity together, in one line, with the build flag untouched — so a
// remote-mode test needs no static mutation and no `tearDown` to restore one.
// The last expectation in the "switches the whole stack" test states that
// literally: the stack answered as remote while `forceCommandType` still read
// `none`.
//
// HOW IT COULD SILENTLY REVERT. By a new strategy reading
// `GlobalConfig.remote.isActive` directly instead of taking the answer from its
// profile. Nothing breaks when that happens — the app still works, because in a
// real build the static and the profile agree. It only shows up in tests, as a
// strategy that ignores the override, which reads like a broken test rather than
// like a broken strategy. That is why the assertions below are about *transport
// output* (endpoints, host, token, auth behaviour) rather than about
// `profile.mode`: a strategy that consulted the global would pass a `mode` check
// and fail these.
//
// WHY THIS TEST TYPE. Behavioural, deliberately, and it is the test that was not
// possible before this phase. The VM stub of `UspBridgeClient` accepts all five
// transport arguments and discards every one, exposing no getter — so the
// pre-#1474 `if` inside `uspBridgeClientProvider` could not be observed at all
// from a VM test. `bridgeConfigProvider` is the seam that made it observable, and
// reading it is how this file checks the mode reached the transport.
//
// The only `tearDown` here is `container.dispose`, which is Riverpod hygiene, not
// state restoration. Nothing in this file writes to anything global.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/mode/app_mode.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
import 'package:privacy_gui/core/usp/services/sse_local_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_remote_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/page/_shared/mode/local_surface.dart';
import 'package:privacy_gui/page/_shared/mode/remote_surface.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';

import '../usp/mocks.dart';

/// A Guardian session that exists. Remote transport is null without one — see
/// the "null until the session arrives" test — so every remote assertion about
/// endpoints or tokens needs this.
const _session = RemoteAssistanceConfig(
  guardianBaseUrl: 'qa.guardian.tools',
  sessionId: 'sess-4711',
  temporaryAccessToken: 'tat-abc',
  clientTypeId: 'agent-web',
);

/// Pins `remoteAssistanceProvider` to a given state without running
/// `activate()`, which is web-only (`kIsWeb`) and would throw here.
class _StubRemoteAssistanceNotifier extends RemoteAssistanceNotifier {
  _StubRemoteAssistanceNotifier(this._initial);

  final RemoteAssistanceState _initial;

  @override
  RemoteAssistanceState build() => _initial;
}

void main() {
  ProviderContainer containerWith({
    AppModeProfile? profile,
    AppMode? mode,
    RemoteAssistanceConfig? session,
  }) {
    final container = ProviderContainer(overrides: [
      if (profile != null) appModeProfileProvider.overrideWithValue(profile),
      if (mode != null) appModeProvider.overrideWithValue(mode),
      remoteAssistanceProvider.overrideWith(() => _StubRemoteAssistanceNotifier(
            RemoteAssistanceState(isActive: session != null, config: session),
          )),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('the default build composes the local strategies, end to end', () {
    test('the profile is cloud-labelled and the transport is on-router', () {
      final container = containerWith();

      final profile = container.read(appModeProfileProvider);
      expect(profile.mode, AppMode.cloud,
          reason: 'a test process has no --dart-define, so '
              'BuildConfig.forceCommandType is ForceCommand.none, which '
              'AppMode.resolve() maps to cloud. Cloud composes the local '
              'strategies (LocalModeProfile.aliasedAs) — hence the on-router '
              'transport asserted below — but reports its own label.');

      final config = container.read(bridgeConfigProvider);
      expect(config, isNotNull,
          reason: 'a local build always knows its transport — there is no '
              'session handshake to wait for');
      expect(config!.endpoints, same(BridgeEndpoints.local));
      expect(config.baseUrl, isNull,
          reason: 'null means same-origin: the app is served by the router it '
              'configures. UspBridgeClient reads it as `_usp.baseUrl`.');
      expect(config.authToken, isNull);
      expect(config.clientTypeId, isNull);
      expect(config.authBehavior, same(AuthBehavior.local));
      expect(config.authBehavior.shouldRetryOnFailure, isTrue,
          reason: 'locally a 401 is transient — the router session can be '
              'refreshed');
    });

    test('the SSE discipline comes through the transport', () {
      final container = containerWith();
      final transport = container.read(appModeProfileProvider).transport;

      expect(transport.sseStrategy(MockUspBridgeClient()),
          isA<LocalSseStrategy>());
    });

    test('the page root yields the local surfaces', () {
      final container = containerWith();
      expect(container.read(surfaceStrategyProvider), isA<LocalSurface>());
    });
  });

  group('one override switches the whole stack to remote', () {
    test('transport, credential and SSE discipline all move together', () {
      final container = containerWith(
        profile: const RemoteModeProfile(),
        session: _session,
      );

      final config = container.read(bridgeConfigProvider);
      expect(config, isNotNull);

      // Cause 1 — all four transport differences.
      expect(config!.endpoints.subscription,
          '/v1/guardians/remote-assistances/sessions/sess-4711/usp/subscriptions',
          reason:
              'session-scoped Guardian paths, not the on-router /api/v1 set');
      expect(config.baseUrl, 'https://qa.guardian.tools',
          reason: 'the Guardian API host, NOT the origin the app was served '
              'from. Pairing local paths with this host — or these paths with '
              'the local host — is the defect phase 1 of #1474 fixed.');
      expect(config.authToken, 'tat-abc');
      expect(config.clientTypeId, 'agent-web');

      // Cause 2 — reached the transport from the credential strategy, not from
      // a literal inside it.
      expect(config.authBehavior, same(AuthBehavior.remote));
      expect(config.authBehavior.shouldRetryOnFailure, isFalse,
          reason: 'a Guardian 401 means the support session is over; retrying '
              're-asks a question whose answer is now permanent');

      // The SSE discipline follows the transport.
      expect(
        container
            .read(appModeProfileProvider)
            .transport
            .sseStrategy(MockUspBridgeClient()),
        isA<RemoteSseStrategy>(),
      );

      // Acceptance 3, stated as an assertion: none of the above touched the
      // build flag. This is #1474's falsification criterion 2 — `test/di_test.dart`
      // is the one place in the repo allowed to assign this static, and every
      // mode test written after this phase overrides a provider instead.
      expect(BuildConfig.forceCommandType, ForceCommand.none,
          reason: 'the whole stack answered as Remote Assistance while the '
              'build flag still read none. If this fails, something in the mode '
              'subsystem is mutating a global — or a previous test did and left '
              'no tearDown, which is exactly what this design removes.');
    });

    test('overriding the mode instead of the profile works too', () {
      final container = containerWith(mode: AppMode.remote, session: _session);

      expect(container.read(appModeProfileProvider), isA<RemoteModeProfile>(),
          reason: 'appModeProvider is the coarse lever: the profile is derived '
              'from it, so overriding the mode moves both composition roots. '
              'Overriding appModeProfileProvider is the fine lever, for a test '
              'that wants one strategy swapped and the rest real.');
      expect(container.read(surfaceStrategyProvider), isA<RemoteSurface>(),
          reason:
              'the page root switches on the same appModeProvider, which is '
              'what keeps two roots from drifting');
    });

    test('the transport is null until the Guardian session arrives', () {
      final container = containerWith(profile: const RemoteModeProfile());

      expect(container.read(bridgeConfigProvider), isNull,
          reason:
              'the mode is known at build time but the session only arrives '
              'with the agent\'s ?session=&token= link. Null is that window, and '
              'uspBridgeClientProvider returns null for it — exactly what the '
              'pre-#1474 `if (config == null) return null;` did.');
    });
  });

  group('cloud and demo alias local without lying about their label', () {
    test('same strategy instances, different mode', () {
      for (final aliased in [AppMode.cloud, AppMode.demo]) {
        final container = containerWith(mode: aliased);
        final profile = container.read(appModeProfileProvider);

        expect(profile.mode, aliased,
            reason: '$aliased must report itself, not local: `mode` is what a '
                'diagnostic log shows, and a profile that claimed local would '
                'send a reader hunting a local bug in a $aliased session');

        const local = LocalModeProfile();
        expect(identical(profile.transport, local.transport), isTrue,
            reason:
                '$aliased must share the local strategy instance, not carry '
                'a copy — a copy is the thing that drifts');
        expect(identical(profile.credential, local.credential), isTrue);
        expect(identical(profile.session, local.session), isTrue);
        expect(identical(profile.proximity, local.proximity), isTrue);
      }
    });

    test('remote cannot be aliased onto the local profile', () {
      expect(
        () => LocalModeProfile.aliasedAs(AppMode.remote),
        throwsA(isA<AssertionError>()),
        reason: 'aliasing remote onto the local strategies pairs '
            'Guardian-proxied requests with on-router endpoint paths and no '
            'bearer token — the exact hybrid phase 1 of #1474 fixed. Worth '
            'failing loudly rather than trusting nobody types it.',
      );
    });
  });
}
