// #1323 phase 5: cause 3's two members — `SessionStrategy.destination` and
// `SessionStrategy.end`.
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
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/core/mode/impl/local_session_strategy.dart';
import 'package:privacy_gui/core/mode/impl/remote_session_strategy.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_state.dart';

class MockRemoteAssistanceService extends Mock
    implements RemoteAssistanceService {}

/// Records `clearSession()` without stubbing the rest of the notifier.
///
/// A `Mock implements RemoteAccessNotifier` would work for the verification and
/// would then also have to answer `state`, which the strategy reads on the way in
/// — two mocks describing one object, where the second one silently decides what
/// the first one sees. Subclassing keeps the state real and spies on the one call.
class _SpyRemoteAccessNotifier extends RemoteAccessNotifier {
  _SpyRemoteAccessNotifier(this._seed);

  final RemoteAccessState _seed;
  int clearSessionCalls = 0;

  @override
  RemoteAccessState build() => _seed;

  @override
  void clearSession() {
    clearSessionCalls++;
    // Deliberately does NOT call super: the real one cancels two timers and
    // touches `sessionStorage`, neither of which exists in a VM test, and the
    // claim being made here is "the strategy asks", not "the notifier delivers".
  }
}

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
}

/// Riverpod exposes no public `Ref` on a container, and these strategies only ever
/// `read` — so a one-line adapter is enough, and is honest about the fact that the
/// strategies use `Ref` as a service locator rather than for lifecycle.
Ref _refOf(ProviderContainer container) => container.read(_refExposerProvider);

final _refExposerProvider = Provider<Ref>((ref) => ref);
