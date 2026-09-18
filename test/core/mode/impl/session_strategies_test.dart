// Cause 3 — what a session *is*. `destination` and `end` arrived with #1323 phase
// 5; `start`, `entryPoint` and `guardEntry` with #1498 phase 9, which is the entry
// half of the same cause.
//
// WHY THE ENTRY HALF BELONGS IN THIS FILE AND NOT ITS OWN. The five members answer
// one question between them, and the interesting assertions are the ones that read
// across the halves. `guardEntry`'s third answer — `previousSessionEnded` — is only
// ever true because `end` cleared `remoteAccessProvider` first; the two are a
// protocol, and split across two files the `endedHere` flag looks like an
// unexplained boolean. `start` and `end` are likewise a pair: `start` may throw and
// `end` must not, which is a difference worth reading in one place.
//
// The one entry claim that is NOT here is `entryPoint`'s. It lives in
// `test/route/remote_assistance_entry_gate_test.dart`, because there the two answers
// are the gate that keeps the agent UI out of a local build (#1357 item 1) — the
// same member, asserted for a different reason, next to the route-table half of that
// same gate.
//
// One file for both modes, same reason as `recovery_strategies_test.dart`: every
// claim below is a *difference* between the two answers to one question, and split
// across two files each half reads as an arbitrary table. Article XVII's "a member
// needs a measured difference" is only checkable side by side.
//
// WHAT THE DIFFERENCE IS, CONCRETELY. Before this phase, RA teardown existed in
// exactly one place — `remote_session_chip.dart`'s Disconnect handler — and the
// other ten paths into `logout()` called it bare. Those paths are not exotic: an
// idle timeout, a 401 on the bridge, an SSE give-up, a serial mismatch, a factory
// reset, a relogin that failed after a password change. All of them left
// `remoteAccessProvider` holding `sessionInfo` and `sessionToken`, and
// `router_provider.dart`'s `/usp*` guard reads exactly those two:
//
//     if (raState.sessionInfo != null && raState.sessionToken != null) {
//       return '${RoutePath.remoteAssistanceConfirm}'
//           '?session=${raState.sessionInfo!.id}&token=${raState.sessionToken}';
//     }
//
// So a logged-out RA app was redirected to the confirm page *with the parameters
// of the session it had just left*, where Connect re-activated it. That is
// acceptance 3, and the `clearSession()` assertions below are what close it.
//
// `test/providers/auth/auth_notifier_test.dart` covers the other half — that
// `logout()` reaches this member at all, and in what order. This file covers each
// implementation alone.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/core/mode/impl/local_session_strategy.dart';
import 'package:privacy_gui/core/mode/impl/remote_session_strategy.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/framework/mode/session_entry.dart';
import 'package:privacy_gui/framework/mode/session_request.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_state.dart';

import '../../../mocks/provider_overrides/mock_login.dart';

class MockRemoteAssistanceService extends Mock
    implements RemoteAssistanceService {}

/// Records the two calls cause 3 makes into RA session state, without stubbing the
/// rest of the notifier.
///
/// A `Mock implements RemoteAccessNotifier` would work for the verification and
/// would then also have to answer `state`, which the strategy reads on the way in
/// — two mocks describing one object, where the second one silently decides what
/// the first one sees. Subclassing keeps the state real and spies on the calls.
class _SpyRemoteAccessNotifier extends RemoteAccessNotifier {
  _SpyRemoteAccessNotifier(this._seed, {List<String>? events})
      : events = events ?? [];

  final RemoteAccessState _seed;

  /// Shared with [_SpyRemoteAssistanceNotifier] when a test cares about order.
  final List<String> events;

  int clearSessionCalls = 0;
  final List<({GRASessionInfo? info, int? seconds, String? token})> updates =
      [];

  @override
  RemoteAccessState build() => _seed;

  @override
  void clearSession() {
    clearSessionCalls++;
    events.add('clearSession');
    // Deliberately does NOT call super: the real one cancels two timers and
    // touches `sessionStorage`, neither of which exists in a VM test, and the
    // claim being made here is "the strategy asks", not "the notifier delivers".
  }

  @override
  void updateSessionInfo(
    GRASessionInfo? info,
    int? remainingSeconds, {
    String? sessionToken,
  }) {
    updates.add((info: info, seconds: remainingSeconds, token: sessionToken));
    events.add('updateSessionInfo');
    // Not calling super for the same reason as above, and one more: the real one
    // starts a `Timer.periodic` countdown and a status poll, so a VM test that let
    // it through would leak two timers per case and fail in whatever test ran next.
  }
}

/// Records `activate()` — or fails it — without a wasm runtime.
///
/// The real one refuses off-web on its first line, so a test of what `start()` does
/// *around* it needs this. What is installed is not this file's claim:
/// `remote_assistance_provider_test.dart` owns the transport-installation and
/// handle-ownership rules.
class _SpyRemoteAssistanceNotifier extends RemoteAssistanceNotifier {
  _SpyRemoteAssistanceNotifier({
    this.seed = const RemoteAssistanceState(),
    this.failWith,
    List<String>? events,
  }) : events = events ?? [];

  final RemoteAssistanceState seed;

  /// When set, `activate()` throws it — standing in for a Guardian that rejected
  /// the token or a wasm client that would not build.
  final Object? failWith;

  final List<String> events;
  final List<RemoteAssistanceConfig> activations = [];

  @override
  RemoteAssistanceState build() => seed;

  @override
  Future<void> activate(RemoteAssistanceConfig config) async {
    activations.add(config);
    events.add('activate');
    if (failWith != null) {
      throw failWith!;
    }
  }
}

/// Seeds `authProvider` with a settled login type.
///
/// Reuses the shared `FixedAuthStateNotifier` rather than declaring another local
/// one: `guardEntry` reads nothing else off auth, so a bespoke stub here would be a
/// near-duplicate whose only difference is that a future reader has to check.
Override _authAs(LoginType loginType) => authProvider.overrideWith(
    () => FixedAuthStateNotifier(AuthState(loginType: loginType)));

GRASessionInfo _sessionInfo(String id) => GRASessionInfo(
      id: id,
      serialNumber: 'ABC123',
      modelNumber: 'M60TB',
      status: GRASessionStatus.active,
      expiredIn: 1800,
      createdAt: 0,
      statusChangedAt: 0,
      currentTime: 0,
    );

void main() {
  group('SessionStrategy.destination', () {
    test('local ends at a login page, remote at a terminal surface', () {
      // The whole reason cause 3 is a strategy. Both values are read by the two
      // recovery dialogs (acceptance 1): a bail-out button that offers "Return to
      // login page" is only honest where a login page is reachable, and in RA the
      // credential was a one-shot Guardian token — there is no password to type.
      //
      // Neither answer depends on the [EndCause], which is what keeps this a
      // getter rather than a second return value from `end()`, and there is no
      // test below asserting that: the getter takes no cause, so the claim is a
      // type, and a test that set up two causes and compared the same value twice
      // would be asserting that `==` works. The two *remote* endings do differ in
      // copy (`?ended=true` versus `?expired=true`) — the page layer derives that
      // from the cause; they do not differ in destination.
      expect(
          const LocalSessionStrategy().destination, SessionOutcome.loginPage);
      expect(const RemoteSessionStrategy().destination,
          SessionOutcome.supportSessionEnded);
    });
  });

  group('LocalSessionStrategy.end', () {
    test('does nothing, for either cause', () async {
      // Acceptance 8, in the only form it can take here. Local logout was already
      // complete before #1323 — `logout()` disconnects SSE, unregisters
      // subscriptions, syncs the USP logout, clears the fingerprint and clears
      // credentials — so a local `end()` that *added* a step would be the
      // regression.
      //
      // The overrides are the assertion, and a bare `ProviderContainer()` would
      // not have been one: with no overrides the real providers build happily in a
      // VM test, so `completes` would pass whether `end()` read them or not. These
      // two throw on first read instead, which makes "touches nothing RA-shaped"
      // the thing that is measured rather than the thing that is hoped.
      final container = ProviderContainer(overrides: [
        remoteAssistanceServiceProvider.overrideWith((_) =>
            throw StateError('LocalSessionStrategy.end read the RA service')),
        remoteAccessProvider.overrideWith(() =>
            throw StateError('LocalSessionStrategy.end read the RA state')),
      ]);
      addTearDown(container.dispose);

      for (final cause in EndCause.values) {
        await expectLater(
          const LocalSessionStrategy().end(_refOf(container), cause),
          completes,
        );
      }
    });
  });

  group('RemoteSessionStrategy.end', () {
    late MockRemoteAssistanceService mockService;
    late _SpyRemoteAccessNotifier spyNotifier;

    /// Disposal is registered here rather than in a group `tearDown` reading a
    /// `late` field: a test that failed before building its container would make
    /// the tear-down throw `LateInitializationError`, which is reported as the
    /// failure and buries the one that actually happened.
    ProviderContainer containerWith(RemoteAccessState seed) {
      spyNotifier = _SpyRemoteAccessNotifier(seed);
      final container = ProviderContainer(overrides: [
        remoteAssistanceServiceProvider.overrideWithValue(mockService),
        remoteAccessProvider.overrideWith(() => spyNotifier),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    setUp(() {
      mockService = MockRemoteAssistanceService();
      when(() => mockService.endSessionForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          )).thenAnswer((_) async {});
    });

    test('userRequested releases the Guardian session, then clears local state',
        () async {
      final container = containerWith(RemoteAccessState(
        sessionInfo: _sessionInfo('sess-1'),
        sessionToken: 'tok-1',
      ));

      await const RemoteSessionStrategy()
          .end(_refOf(container), EndCause.userRequested);

      verify(() => mockService.endSessionForCA(
            sessionToken: 'tok-1',
            sessionId: 'sess-1',
          )).called(1);
      expect(spyNotifier.clearSessionCalls, 1);
    });

    test('the API call happens before the state is cleared', () async {
      // Order, not just presence: `clearSession()` drops the very token
      // `endSessionForCA` authenticates with, so the reverse order is a call that
      // cannot succeed. It is the natural order to get wrong, because "tidy up
      // locally first, then tell the server" reads as the defensive one.
      final container = containerWith(RemoteAccessState(
        sessionInfo: _sessionInfo('sess-1'),
        sessionToken: 'tok-1',
      ));
      int? clearedAtCall;
      when(() => mockService.endSessionForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          )).thenAnswer((_) async {
        clearedAtCall = spyNotifier.clearSessionCalls;
      });

      await const RemoteSessionStrategy()
          .end(_refOf(container), EndCause.userRequested);

      expect(clearedAtCall, 0,
          reason:
              'clearSession() must not have run when the API call was made');
      expect(spyNotifier.clearSessionCalls, 1);
    });

    test('sessionLost skips the API call and still clears local state',
        () async {
      // Acceptances 2 and 3 together. The skip is not an optimisation: a rejected
      // token is the commonest way to reach this cause, so the call would
      // authenticate with the thing that just failed — a certain `ServiceError` on
      // a path documented as non-throwing. The clear is unconditional because it is
      // what stops the `/usp*` guard rebuilding the confirm URL.
      final container = containerWith(RemoteAccessState(
        sessionInfo: _sessionInfo('sess-1'),
        sessionToken: 'tok-1',
      ));

      await const RemoteSessionStrategy()
          .end(_refOf(container), EndCause.sessionLost);

      verifyNever(() => mockService.endSessionForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          ));
      expect(spyNotifier.clearSessionCalls, 1);
    });

    test('a failing API call does not throw and still clears local state',
        () async {
      // `SessionStrategy.end` is documented as non-throwing, and `logout()` runs
      // it inside an `AsyncValue.guard` — so a throw here would put authProvider
      // in an error state with the credential *not* cleared. A session that fails
      // to end is strictly worse than one that ends untidily.
      final container = containerWith(RemoteAccessState(
        sessionInfo: _sessionInfo('sess-1'),
        sessionToken: 'tok-1',
      ));
      when(() => mockService.endSessionForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          )).thenThrow(Exception('Guardian returned 502'));

      await expectLater(
        const RemoteSessionStrategy()
            .end(_refOf(container), EndCause.userRequested),
        completes,
      );
      expect(spyNotifier.clearSessionCalls, 1);
    });

    test('a Guardian call that never answers still clears local state', () {
      // The case `thenThrow` above cannot reach, and the reason `end()` has a
      // timeout at all. `GuardianApiClient._request` calls `http.delete` with no
      // timeout of its own, so an endpoint that accepts the connection and never
      // answers hangs the `await` forever — and a `try`/`catch` catches errors,
      // not hangs.
      //
      // What that costs is the whole logout, not a slow one: `end()` runs first
      // inside `logout()`'s `AsyncValue.guard`, so authProvider stays
      // `AsyncValue.loading()`, the credential is never cleared, and the
      // `clearSession()` below never runs — which leaves `sessionInfo` and
      // `sessionToken` in place for the `/usp*` guard to rebuild the confirm URL
      // from. Acceptance 3, failing on the one path that asked politely.
      //
      // Elapsed either side of the 5s ceiling rather than past it in one step, so
      // the test also fails if the timeout is deleted *and* if it is set so short
      // that a merely slow Guardian is abandoned.
      final container = containerWith(RemoteAccessState(
        sessionInfo: _sessionInfo('sess-1'),
        sessionToken: 'tok-1',
      ));
      when(() => mockService.endSessionForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          )).thenAnswer((_) => Completer<void>().future);

      fakeAsync((async) {
        const RemoteSessionStrategy()
            .end(_refOf(container), EndCause.userRequested);

        async.elapse(const Duration(seconds: 4));
        expect(spyNotifier.clearSessionCalls, 0,
            reason: 'still inside the ceiling — the request is a courtesy, but '
                'abandoning it early makes a slow Guardian leak a live session');

        async.elapse(const Duration(seconds: 2));
        expect(spyNotifier.clearSessionCalls, 1,
            reason: 'past the ceiling, teardown must have run anyway');
      });
    });

    test('no session to release still clears local state', () async {
      // Reachable two ways, and neither is `_forceSessionEnd()` — that one keeps
      // `sessionToken` and only rewrites `sessionInfo.status` to `invalid`, so it
      // arrives here with both fields populated. What actually gets here is a
      // logout during the confirm page's connect attempt, where no session exists
      // yet, and a *second* ending arriving after the first — an idle timeout
      // landing behind a Disconnect the operator already pressed, which is the
      // common one now that eleven paths reach `end()` instead of one.
      //
      // Before #1323 this arm was `sessionId != null && sessionToken != null`
      // guarding *the whole handler*, so nothing at all happened.
      final container = containerWith(const RemoteAccessState());

      await const RemoteSessionStrategy()
          .end(_refOf(container), EndCause.userRequested);

      verifyNever(() => mockService.endSessionForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          ));
      expect(spyNotifier.clearSessionCalls, 1);
    });

    test('the two modes differ on both members', () async {
      // The census, same intent as `recovery_strategies_test.dart`'s "the two
      // modes disagree on exactly one trigger": a member whose implementations
      // agree everywhere should not be on the contract at all.
      final container = containerWith(RemoteAccessState(
        sessionInfo: _sessionInfo('sess-1'),
        sessionToken: 'tok-1',
      ));
      final ref = _refOf(container);

      await const LocalSessionStrategy().end(ref, EndCause.userRequested);
      expect(spyNotifier.clearSessionCalls, 0,
          reason: 'a local session ending must not touch RA state — that state '
              'does not exist in a local build');
      verifyNever(() => mockService.endSessionForCA(
            sessionToken: any(named: 'sessionToken'),
            sessionId: any(named: 'sessionId'),
          ));

      await const RemoteSessionStrategy().end(ref, EndCause.userRequested);
      expect(spyNotifier.clearSessionCalls, 1);
      verify(() => mockService.endSessionForCA(
            sessionToken: 'tok-1',
            sessionId: 'sess-1',
          )).called(1);
    });
  });

  group('SessionStrategy.start', () {
    test('each mode refuses the other mode\'s request, and refuses it first',
        () {
      // The reason [SessionRequest] is sealed rather than one class with nullable
      // fields, and #1357 item 1 read structurally: the hybrid configuration that
      // bug produced — a Guardian transport installed while the app believed it was
      // local — needed a password and a session token to coexist in one object. They
      // cannot. There is no `if` guarding this; the type is the guard, and the
      // `switch` is exhaustive, so a third request kind would not compile.
      //
      // Every provider either strategy could reach throws on first read, so this
      // also pins *when*: a refusal that happened after `tryUspLogin` or after
      // `activate` would be a refusal arriving too late to prevent anything.
      final container = ProviderContainer(overrides: [
        uspAuthCoordinatorProvider.overrideWith(
            (_) => throw StateError('start() opened a local login')),
        sessionProvider.overrideWith(
            () => throw StateError('start() fetched device info')),
        remoteAssistanceProvider.overrideWith(
            () => throw StateError('start() installed a transport')),
        remoteAccessProvider
            .overrideWith(() => throw StateError('start() recorded a session')),
      ]);
      addTearDown(container.dispose);
      final ref = _refOf(container);

      expect(
        () => const LocalSessionStrategy()
            .start(ref, SupportSessionRequest(sessionId: 's', token: 't')),
        throwsArgumentError,
      );
      expect(
        () => const RemoteSessionStrategy()
            .start(ref, const OwnCredentialsRequest('hunter2')),
        throwsArgumentError,
      );
    });

    group('RemoteSessionStrategy', () {
      late List<String> events;
      late _SpyRemoteAssistanceNotifier spyRa;
      late _SpyRemoteAccessNotifier spyAccess;

      ProviderContainer containerWith({Object? activateFails}) {
        events = [];
        spyRa = _SpyRemoteAssistanceNotifier(
            failWith: activateFails, events: events);
        spyAccess =
            _SpyRemoteAccessNotifier(const RemoteAccessState(), events: events);
        final container = ProviderContainer(overrides: [
          remoteAssistanceProvider.overrideWith(() => spyRa),
          remoteAccessProvider.overrideWith(() => spyAccess),
        ]);
        addTearDown(container.dispose);
        return container;
      }

      SupportSessionRequest request() => SupportSessionRequest(
            sessionId: 'sess-1',
            token: 'tok-1',
            sessionInfo: _sessionInfo('sess-1'),
            remainingSeconds: 1800,
          );

      test('installs the transport before it records the engagement', () async {
        // Order, and the reverse is the plausible mistake: "record what we know,
        // then connect" reads as the careful one. It is not — `updateSessionInfo`
        // starts the expiry countdown and the status poll, and the RA chip appears
        // as soon as it lands, so recording first shows the operator a live session
        // over a connection that does not exist yet.
        final container = containerWith();

        await const RemoteSessionStrategy().start(_refOf(container), request());

        expect(events, ['activate', 'updateSessionInfo']);
      });

      test('the token reaches both the transport and the session record',
          () async {
        // Two consumers of one credential, and they are reached by different calls
        // — so a refactor can drop either without the other noticing. The transport
        // authenticates USP with it; the record is what the `/usp*` guard later
        // rebuilds a resumable confirm URL from (see `guardEntry` below), and a
        // record without a token cannot be resumed.
        final container = containerWith();

        await const RemoteSessionStrategy().start(_refOf(container), request());

        expect(spyRa.activations.single.temporaryAccessToken, 'tok-1');
        expect(spyRa.activations.single.sessionId, 'sess-1');
        expect(spyAccess.updates.single.token, 'tok-1');
        expect(spyAccess.updates.single.seconds, 1800);
        expect(spyAccess.updates.single.info?.id, 'sess-1');
      });

      test('the Guardian host comes from build config, not from the request',
          () async {
        // The whole reason `guardianBaseUrl` and `clientTypeId` are absent from
        // [SupportSessionRequest]: a caller that could name the Guardian could point
        // a session at the wrong one, and the request arrives from a URL. Asserted
        // against the same expression the config getter uses rather than a literal,
        // because the value is per-build — a literal would pin whichever environment
        // this test happened to run in.
        final container = containerWith();

        await const RemoteSessionStrategy().start(_refOf(container), request());

        expect(spyRa.activations.single.guardianBaseUrl,
            cloudEnvironmentConfig[kCloudBase]);
        expect(spyRa.activations.single.clientTypeId, kClientTypeId);
      });

      test('a failed activation records nothing and lets the error through',
          () async {
        // The difference from `end`, which is documented as non-throwing and is
        // tested above for exactly that. Entry must throw: the confirm view awaits
        // this and turns a throw into its "Connection failed" state, and a swallowed
        // failure would leave the operator on a page that says it connected.
        //
        // And the state must stay empty. A recorded session over a transport that
        // failed to install is worse than no session: `guardEntry` would read it back
        // as resumable and send a retry straight past the confirm form.
        final container =
            containerWith(activateFails: Exception('Guardian 401'));

        await expectLater(
          const RemoteSessionStrategy().start(_refOf(container), request()),
          throwsException,
        );
        expect(events, ['activate']);
        expect(spyAccess.updates, isEmpty);
      });
    });

    // No local `start()` case here, and the absence is deliberate rather than a gap.
    // Its two calls and their order are asserted in
    // `test/providers/auth/auth_notifier_test.dart` — "login does not call
    // fetchDeviceInfo if USP fails" — and that group runs the *real*
    // `LocalSessionStrategy` because it does not override `appModeProfileProvider`.
    // That is what makes it the proof phase 9 left local login alone; re-asserting it
    // here against spies would be a weaker copy of it.
  });

  group('SessionStrategy.guardEntry', () {
    // Runs on every in-session navigation to a `/usp*` location, which is why the
    // two implementations differ on something as basic as `watch` versus `read`.

    test('local: logged in holds the location, logged out goes to login',
        () async {
      for (final (loginType, expected) in [
        (LoginType.local, isA<SessionAlreadyHeld>()),
        (LoginType.none, isA<OwnCredentialsEntry>()),
      ]) {
        // Both RA providers throw on first read. A local build has no RA state to
        // consult, and the pre-#1498 redirect could not have made that mistake
        // because the local branch was on the other side of an `if` — so the guard
        // has to be here now that the branch is a strategy choice instead.
        final container = ProviderContainer(overrides: [
          _authAs(loginType),
          remoteAccessProvider.overrideWith(
              () => throw StateError('local guardEntry read RA state')),
          remoteAssistanceProvider.overrideWith(
              () => throw StateError('local guardEntry read RA activation')),
        ]);
        addTearDown(container.dispose);

        expect(
            const LocalSessionStrategy()
                .guardEntry(await _settledRef(container)),
            expected);
      }
    });

    group('remote', () {
      /// Also settles `authProvider` — see [_settledRef].
      Future<Ref> refWith({
        LoginType loginType = LoginType.none,
        RemoteAccessState access = const RemoteAccessState(),
        bool raActive = false,
      }) async {
        final container = ProviderContainer(overrides: [
          _authAs(loginType),
          remoteAccessProvider
              .overrideWith(() => _SpyRemoteAccessNotifier(access)),
          remoteAssistanceProvider.overrideWith(() =>
              _SpyRemoteAssistanceNotifier(
                  seed: RemoteAssistanceState(isActive: raActive))),
        ]);
        addTearDown(container.dispose);
        return _settledRef(container);
      }

      test('a live Guardian session holds the location', () async {
        // `isRemoteAssistance`, not `isLoggedIn`, and the difference is not cosmetic:
        // `loginType == remote` is the only value that means "this app is on a
        // Guardian transport". A local `loginType` in a remote build would be a bug,
        // and answering `SessionAlreadyHeld` to it would hide that bug behind a
        // working dashboard.
        final ref = await refWith(loginType: LoginType.remote);

        expect(const RemoteSessionStrategy().guardEntry(ref),
            isA<SessionAlreadyHeld>());
      });

      test('a local login in a remote build is not a held session', () async {
        final ref = await refWith(loginType: LoginType.local);

        expect(const RemoteSessionStrategy().guardEntry(ref),
            isA<SupportSessionEntry>());
      });

      test('a reload mid-session comes back resumable, with its parameters',
          () async {
        // The mode-specific arm. RA parameters survive a page reload in
        // `sessionStorage`, so a refresh can re-establish rather than start over —
        // and the id and token are what make that possible, because the confirm view
        // refuses to connect without both.
        final ref = await refWith(
          access: RemoteAccessState(
            sessionInfo: _sessionInfo('sess-9'),
            sessionToken: 'tok-9',
          ),
        );

        final entry = const RemoteSessionStrategy().guardEntry(ref);

        expect(entry, isA<SupportSessionEntry>());
        expect((entry as SupportSessionEntry).sessionId, 'sess-9');
        expect(entry.token, 'tok-9');
        expect(entry.previousSessionEnded, isFalse,
            reason:
                'a resumable session has not ended — the flag would send the '
                'operator to the terminal surface instead of letting them '
                'reconnect');
      });

      test('a half-populated record is not resumable', () async {
        // `sessionInfo != null && sessionToken != null`, both halves. Reachable:
        // `_forceSessionEnd()` rewrites `sessionInfo.status` to invalid and keeps the
        // token, and `clearSession()` drops both — but a partial write in between
        // would build a confirm URL with `token=null` in it, which the view rejects
        // as a missing parameter on a page the operator cannot get past.
        final ref = await refWith(
          access: RemoteAccessState(sessionInfo: _sessionInfo('sess-9')),
        );

        final entry = const RemoteSessionStrategy().guardEntry(ref)
            as SupportSessionEntry;

        expect(entry.sessionId, isNull);
      });

      test('an ended session is told apart from a cold load', () async {
        // #1323 phase 5's `?ended=true`, and the pair below is the whole claim: the
        // *same* empty `remoteAccessProvider` means two different things depending on
        // whether a Guardian session was ever activated in this page lifetime.
        //
        // It matters because phase 5 made the empty state the normal way to arrive.
        // All eight automatic RA endings — an idle timeout, a 401 on the bridge, an
        // SSE give-up, a serial mismatch, a factory reset, a failed relogin — now
        // clear the session on the way out and land here. Without this flag they
        // rendered the confirm view's `_buildMissingParamsView()`: a red developer
        // page reading "Missing Parameters", shown to an operator whose session had
        // simply expired.
        //
        // `remoteAssistanceProvider.isActive` is the discriminator because it is the
        // one piece of RA state `end()` does *not* clear — see the "NO deactivate()"
        // note on `RemoteAssistanceNotifier`, which is why that is true by design and
        // not by accident.
        final cold = await refWith();
        final afterEnding = await refWith(raActive: true);

        expect(
          (const RemoteSessionStrategy().guardEntry(cold)
                  as SupportSessionEntry)
              .previousSessionEnded,
          isFalse,
        );
        expect(
          (const RemoteSessionStrategy().guardEntry(afterEnding)
                  as SupportSessionEntry)
              .previousSessionEnded,
          isTrue,
        );
      });

      test('the two modes disagree on the same state', () async {
        // The census, same intent as the `end` group's version: a member whose
        // implementations agree everywhere does not belong on the contract. Not
        // logged in, no session — local sends the user to type a password, remote
        // sends them to the agent UI, because in a remote build there is no password
        // to type.
        final ref = await refWith();

        expect(const LocalSessionStrategy().guardEntry(ref),
            isA<OwnCredentialsEntry>());
        expect(const RemoteSessionStrategy().guardEntry(ref),
            isA<SupportSessionEntry>());
      });
    });
  });
}

/// Riverpod exposes no public `Ref` on a container, so a one-line adapter it is —
/// honest about the fact that these strategies use `Ref` as a service locator
/// rather than for lifecycle.
///
/// `LocalSessionStrategy.guardEntry` is the one member that `watch`es rather than
/// `read`s, and it works through this adapter too: in riverpod 2 a `Ref` obtained
/// from a built provider still resolves `watch` — it just has nothing left to
/// rebuild. Which is exactly the shape of the production call, where the router's
/// `redirect` runs outside any build and go_router re-runs it from the
/// `refreshListenable` instead.
Ref _refOf(ProviderContainer container) => container.read(_refExposerProvider);

/// [_refOf], after `authProvider` has resolved.
///
/// `AuthNotifier.build` returns a `Future`, so a freshly-overridden container sits
/// at `AsyncLoading` for one microtask — and both `guardEntry` implementations read
/// through `value.value?`, where loading and logged-out are the same answer. Without
/// this every case below would read as "no session" whatever it was seeded with, and
/// the two that expect a held session would fail while the four that expect an entry
/// point would pass for the wrong reason.
Future<Ref> _settledRef(ProviderContainer container) async {
  await container.read(authProvider.future);
  return _refOf(container);
}

final _refExposerProvider = Provider<Ref>((ref) => ref);
