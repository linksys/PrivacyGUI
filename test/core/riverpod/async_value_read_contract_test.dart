import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
// AuthState and LoginType come via auth_provider.dart's re-exports.
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// Characterization tests for what the provider layer hands the UI when an
/// `AsyncNotifierProvider` is in the error state.
///
/// These pin CURRENT behaviour, not desired behaviour. They exist because a
/// population of call sites reads `authProvider` through `AsyncValue.value`, and
/// `value` is the one accessor whose contract differs between riverpod versions:
/// only `AsyncError.value` throws, and only when `hasValue` is false
/// (`riverpod-2.6.1/lib/src/common.dart:493`; `AsyncLoading.value` returns null,
/// as does `valueOrNull` everywhere).
///
/// Census re-measured at `4f4fe089`. **This corrects the "seven sites" figure**
/// this file and #1501 previously carried: that came from a one-line grep for
/// `authProvider` and `.value` on the same line, which is blind to every
/// `ref.listen(authProvider, (prev, next) {…})` body and every `.select(` that
/// wraps. Measured by shape instead of by name, `authProvider` is read through
/// `.value` at **16 lines in 10 files outside the notifier, 15 of them
/// unguarded**, plus 6 lines inside `AuthNotifier` itself:
///
///   Unguarded, plain read + `?? false`:
///     lib/app.dart:254
///     lib/components/layouts/root_container.dart:60
///     lib/page/remote_assistance/views/remote_assistance_session_guard.dart:65
///     lib/page/dashboard/orchestrator/dashboard_orchestrator.dart:133
///   Unguarded, inside `.select` — the worst place for a throw, because it
///   surfaces at the reader (for :145/:164/:212/:223, inside go_router):
///     lib/page/shell/usp_top_bar.dart:87
///     lib/route/router_provider.dart:145, :164, :212, :223
///     lib/components/styled/general_settings_widget/general_settings_widget.dart:30
///   Inside a `ref.listen` body, guarded only by `if (next.isLoading) return;`
///   — which does not cover an `AsyncError`, so still exposed:
///     lib/page/dashboard/orchestrator/dashboard_orchestrator.dart:96, :97
///     lib/route/router_provider.dart:182, :183
///     lib/core/connection/providers/app_connection_state_provider.dart:66
///   Actually safe, and the only one — guards on `hasValue && !hasError`:
///     lib/page/login/views/login_local_view.dart:110
///   Inside `AuthNotifier`, reading its own `state`:
///     auth_provider.dart:78, :79   safe — an `AsyncError` pattern-match
///                                  returns early at :74
///     auth_provider.dart:65        contained — throws inside the enclosing
///                                  `AsyncValue.guard`, so it degrades to
///                                  "init failed" rather than crashing
///     auth_provider.dart:93, :165, :175   exposed, and :93 is the most
///                                  consequential site found: it is the first
///                                  line of `localLogin()`, so after a failed
///                                  `init()` the user's login attempt throws
///                                  the STALE error instead of starting from
///                                  `AuthState.empty()` as the `??` implies
///
/// So the exposure is 19 lines, and it is confined to `authProvider`: every
/// other `.value` read on an `AsyncValue` in `lib/` is guarded
/// (`dhcp_data_provider.dart:65` and `usp_apps_notifier.dart:84` both check
/// `hasValue` first; `demo/providers/demo_overrides.dart:113` reads a
/// `guard`ed closure that cannot throw).
///
/// The `?? false` / `?? AuthState.empty()` in almost every one of them reads as
/// "default to logged out on failure". That is not what happens — see the tests
/// below. See #1501.
///
/// To be explicit about what these tests are: the behaviour below is a KNOWN
/// DEFECT, not intended behaviour. It is pinned here rather than fixed because
/// the fix is a `lib/` behaviour change — swapping `.value` for `.valueOrNull`
/// at every site makes the first-build-failure case actually take the
/// logged-out branch it already claims to take, which changes app routing — and
/// #1501 is a characterization ticket. No `TODO(#nnnn)` is left here on purpose:
/// #1501 closes with these tests, and a marker pointing at a closed ticket is
/// worse than none. The migration is a prerequisite for the riverpod 3 upgrade,
/// where `.value` stops throwing and these sites silently flip to the
/// logged-out branch instead — at which point these tests go red, which is
/// exactly the signal they exist to give.

/// An [AuthNotifier] whose `build()` follows a caller-supplied script, so a
/// single provider can succeed and then fail across an invalidate.
///
/// A step that is an [AuthState] is returned; anything else is thrown. The
/// script lives in the test (not the notifier) because riverpod constructs a
/// fresh notifier on every rebuild.
class _ScriptedAuthNotifier extends AuthNotifier {
  _ScriptedAuthNotifier(this._next);

  final Object Function() _next;

  @override
  Future<AuthState> build() async {
    final step = _next();
    if (step is AuthState) return step;
    throw step;
  }
}

void main() {
  /// Builds a container whose `authProvider` walks [steps], one per build.
  /// The last step repeats if the provider rebuilds more times than there are
  /// steps.
  ProviderContainer scriptedContainer(List<Object> steps) {
    var i = 0;
    Object next() => steps[i < steps.length ? i++ : steps.length - 1];
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _ScriptedAuthNotifier(next)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  /// Drives the provider to its settled state, swallowing a build failure.
  ///
  /// Awaiting `.future` is the whole synchronization: riverpod has already
  /// published the `AsyncData`/`AsyncError` by the time it completes or rejects,
  /// so no extra microtask hop is needed here. (Measured — a trailing
  /// `Future.delayed(Duration.zero)` was inert, all 8 tests pass without it.
  /// The SSE listener tests DO need extra hops, because there the chain
  /// continues past the state into `ref.listen` -> `invalidateSelf()`.)
  Future<void> settle(ProviderContainer container) async {
    try {
      await container.read(authProvider.future);
    } catch (_) {
      // Expected for the failing scripts; the state is what we assert on.
    }
  }

  const failure = InvalidCredentialsError();
  const loggedIn = AuthState(loginType: LoginType.local);

  group('failure on the FIRST build (no previous value)', () {
    test('state is AsyncError with hasValue false', () async {
      final container = scriptedContainer([failure]);
      await settle(container);

      final state = container.read(authProvider);
      expect(state, isA<AsyncError<AuthState>>());
      expect(state.hasValue, isFalse);
      expect(state.error, isA<InvalidCredentialsError>());
    });

    test('`.value` THROWS rather than returning null', () async {
      final container = scriptedContainer([failure]);
      await settle(container);

      expect(
        () => container.read(authProvider).value,
        throwsA(isA<InvalidCredentialsError>()),
        reason: 'riverpod 2.6.1 rethrows from `value` when hasValue is false',
      );
    });

    test('the production `.value?.isLoggedIn ?? false` shape throws', () async {
      final container = scriptedContainer([failure]);
      await settle(container);

      // Literally the expression at lib/app.dart:254 and three sibling sites.
      // The `?? false` never runs: the throw happens before the null check, so
      // these sites do NOT degrade to "logged out" — they propagate an auth
      // error into whatever called them.
      expect(
        () => container.read(authProvider).value?.isLoggedIn ?? false,
        throwsA(isA<InvalidCredentialsError>()),
      );
    });

    test('`.valueOrNull` returns null for the same state', () async {
      final container = scriptedContainer([failure]);
      await settle(container);

      expect(container.read(authProvider).valueOrNull, isNull,
          reason:
              'valueOrNull is the accessor whose behaviour matches what the '
              '`?? false` sites appear to assume');
    });

    test('`.requireValue` throws the raw ServiceError, unwrapped', () async {
      final container = scriptedContainer([failure]);
      await settle(container);

      // 23 requireValue sites depend on catching typed ServiceError subtypes.
      expect(
        () => container.read(authProvider).requireValue,
        throwsA(isA<InvalidCredentialsError>()),
      );
    });

    test('a `.select` reading `.value` propagates the throw to the reader',
        () async {
      final container = scriptedContainer([failure]);
      await settle(container);

      // The shape at lib/route/router_provider.dart:164 and :223. A selector
      // that throws surfaces at the read/watch site, i.e. inside go_router's
      // redirect callback rather than at the provider.
      expect(
        () => container
            .read(authProvider.select((v) => v.value?.isLoggedIn ?? false)),
        throwsA(isA<InvalidCredentialsError>()),
      );
    });

    test('the `.value?.loginType` selector throws too — no `?? false` to reach',
        () async {
      final container = scriptedContainer([failure]);
      await settle(container);

      // lib/route/router_provider.dart:223 is the one site whose selector
      // returns a nullable enum rather than a bool, so it is the only one where
      // "null means logged out" is the *documented* contract: `redirectLogic`
      // sends the user home when `loginType == null`. It still never gets that
      // null — the throw is in `.value`, before `?.` runs — so the redirect
      // fails instead of bouncing to Home. Asserted separately because this is
      // the shape that changes on riverpod 3, where `.value` returns null and
      // this site starts silently taking its logged-out branch.
      expect(
        () => container.read(authProvider.select((v) => v.value?.loginType)),
        throwsA(isA<InvalidCredentialsError>()),
      );
    });
  });

  group('failure AFTER a successful build (previous value retained)', () {
    test('state keeps the stale value, so `.value` does NOT throw', () async {
      final container = scriptedContainer([loggedIn, failure]);
      await settle(container);
      expect(container.read(authProvider).value?.isLoggedIn, isTrue);

      container.invalidate(authProvider);
      await settle(container);

      final state = container.read(authProvider);
      expect(state, isA<AsyncError<AuthState>>());
      expect(state.hasValue, isTrue,
          reason: 'riverpod carries the previous value forward on a failed '
              'rebuild (copyWithPrevious)');
      // Consequence: every one of the 19 exposed read sites sees the STALE
      // logged-in state after a failed re-auth, not an error and not `false`.
      expect(state.value?.isLoggedIn, isTrue);
      expect(state.error, isA<InvalidCredentialsError>());
    });

    test('`.select` on the stale value also does not throw', () async {
      final container = scriptedContainer([loggedIn, failure]);
      await settle(container);
      container.invalidate(authProvider);
      await settle(container);

      expect(
        container
            .read(authProvider.select((v) => v.value?.isLoggedIn ?? false)),
        isTrue,
        reason:
            'the redirect keeps routing as logged-in after a failed rebuild',
      );
      // Same for router_provider.dart:223's shape: the stale login TYPE is
      // carried forward, so a failed re-auth out of remote assistance keeps
      // routing as remote assistance rather than falling to the null branch.
      expect(
        container.read(authProvider.select((v) => v.value?.loginType)),
        LoginType.local,
      );
    });
  });
}
