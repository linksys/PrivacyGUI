import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/framework/mode/session_entry.dart';
import 'package:privacy_gui/framework/mode/session_request.dart';

/// **Cause 3 — what a session *is*: where it comes from and what ending it means.**
///
/// Local: the user logs in with the router's own password and the session lasts
/// until they log out; when it ends, show the login screen and they can log
/// straight back in. Remote Assistance: a supporter's link carries a one-shot
/// Guardian engagement, and when the *engagement* ends the temporary token is
/// spent, there is no login screen to return to, and the correct destination is a
/// terminal "session ended" surface.
///
/// Declared empty in phase 3 (#1493), given its ending half in **#1323 (phases
/// 4-5)** and its entry half in **#1498 (phase 9)** — the last phase of the epic,
/// and the one that takes `lib/route/` to zero mode reads.
/// The reason for the multi-step is worth keeping: the composition roots' exhaustive
/// `switch` is the epic's load-bearing guard (constitution Article XVII, Rule 1)
/// and can only be written once against a complete set of causes, so the contract
/// had to exist before any member did. See
/// `doc/mode_strategy/mode_strategy_guide.md` §"Why three contracts ship empty".
///
/// **Why entry and ending are one contract and not two.** They are the same cause
/// read from both ends: what a session *is* in this mode. The evidence is that they
/// share state in both directions — [end]'s unconditional `clearSession()` is what
/// makes [guardEntry] stop rebuilding the confirm URL from stale parameters
/// (acceptance 3), and [guardEntry]'s `?ended=true` arm is the only consumer of
/// [SessionOutcome.supportSessionEnded] on an automatic ending. Splitting them
/// would put one fact — "the engagement is over" — behind two contracts that have
/// to agree.
///
/// **The single consumer of [end] is `AuthNotifier.logout`**, which is why phase 5
/// changed 11 call sites by editing 1. `logout()` was already this app's session
/// teardown funnel — it disconnects SSE, unregisters subscriptions, syncs the USP
/// logout, clears the fingerprint, clears credentials and even removes two
/// RA-related prefs under a "legacy cleanup" comment. The defect #1323 fixes is
/// that the *rest* of RA teardown lived in one button handler
/// (`remote_session_chip.dart`) instead, so the other ten paths into `logout()`
/// left `sessionInfo` and `sessionToken` populated and `router_provider.dart`'s
/// `/usp*` guard redirected straight back to the confirm page with the stale
/// parameters (acceptance 3).
///
/// Note the placement decision recorded in the guide: despite the design doc's
/// file tree, the implementations live under `lib/core/mode/impl/` like the other
/// core causes, because [SessionStrategy] is composed by `AppModeProfile` and
/// CLAUDE.md forbids a `lib/core/` → `lib/page/` dependency. Naming a
/// [SessionOutcome] rather than a route is what makes that placement legal.
abstract class SessionStrategy {
  /// Open a session for this mode.
  ///
  /// Local: USP login with the router password, then fetch device info and start
  /// the services that depend on it. Remote: build the Guardian transport config
  /// from the validated engagement, install it, and record the session so the
  /// countdown and the UI restrictions have something to read.
  ///
  /// **The mode-independent state machine stays in the caller, and does not
  /// navigate.** `AsyncValue.loading()`, the `guardError` flag and the
  /// `_mapToViewError` translation live in `AuthNotifier.localLogin`; the spinner
  /// and the "Connection failed" surface live in the confirm view. What moves here
  /// is only the part that differs — a member whose two implementations agree is a
  /// member Article XVII Rule 5 rejects.
  ///
  /// **`loginType` is the exception, and it is not symmetric.** The remote
  /// implementation *does* write `authProvider.state`, because `activate()` calls
  /// `setLoginType(LoginType.remote)` and always has; the local one leaves it to
  /// `localLogin`. So do not hoist `localLogin`'s loading/data wrapper into
  /// `AuthNotifier.openSession` as a tidy-up: it captures `previousState` *before*
  /// `start` runs, so the shared wrapper would overwrite the remote
  /// `loginType` with `none`, `isRemoteAssistance` would read false, and
  /// [guardEntry] would bounce the operator back to the confirm page on every
  /// `/usp*` navigation. An earlier revision of this paragraph stated the
  /// invariant as an unqualified "does not touch `authProvider.state`", which is
  /// exactly the false premise that tidy-up would have rested on.
  ///
  /// **May throw, unlike [end].** Callers already have error surfaces — a login
  /// form showing a mapped `ServiceError`, a confirm view showing "Connection
  /// failed" — and a session that silently fails to open is worse than one that
  /// reports why. This is the opposite of [end]'s contract for the opposite
  /// reason: nothing is half-torn-down if entry fails.
  ///
  /// Throws `ArgumentError` when handed the [SessionRequest] variant belonging to
  /// the other mode. See [SessionRequest] for why that is a refusal rather than a
  /// best-effort coercion.
  Future<void> start(Ref ref, SessionRequest request);

  /// Where this mode's session comes from, given the location the app was
  /// entered at.
  ///
  /// Runs on a *cold* entry — `/` and the login location — before any session
  /// exists, which is why it takes the [Uri] rather than reading a provider: the
  /// supporter's link is the input, and in local mode the answer ignores it.
  ///
  /// The local implementation answers [OwnCredentialsEntry] unconditionally and
  /// logs when it had to ignore a `?session=` parameter. That log line is the whole
  /// safety property of #1357 item 1: the likeliest cause of a `?session=` in a
  /// non-Remote build is an RA deployment whose `force` dart-define is unset or
  /// misspelled, which `ForceCommand.reslove` downgrades to `ForceCommand.none`
  /// without complaint — so it is the only evidence that every supporter's link is
  /// dead.
  ///
  /// Never returns [SessionAlreadyHeld]; see [SessionEntry].
  SessionEntry entryPoint(Ref ref, Uri location);

  /// Whether the app may enter a `/usp*` location, and where it goes if not.
  ///
  /// Separate from [entryPoint] because the question is different and the answer
  /// differs with it: this one runs on every in-session navigation, so "already
  /// held" is its common case, and it must not re-run entry logic — reading the
  /// URL here would let a stale `?session=` in the address bar re-drive a live
  /// session.
  ///
  /// The two modes disagree on all three of: which auth predicate means "held"
  /// (`isLoggedIn` versus `isRemoteAssistance`), whether a *restorable* session is
  /// a thing (only remote persists one, in `sessionStorage`), and where a refusal
  /// goes. That is three measured differences, which is what keeps this a member
  /// rather than a shared `isLoggedIn` check with a remote special case — the shape
  /// it had, as `if (GlobalConfig.remote.isActive)`.
  ///
  /// Reads auth with `ref.watch` in local mode and `ref.read` in remote, preserved
  /// exactly as the redirect had it: the local branch wants the router to rebuild
  /// when the login state changes, and the remote branch is consulted only on
  /// navigations that `RouterNotifier` already triggers.
  SessionEntry guardEntry(Ref ref);

  /// Where the app belongs once this mode's session is over.
  ///
  /// Pure, and cause-independent — which is the finding that keeps this a getter
  /// rather than a second return value from [end]. The two remote endings differ
  /// in their *copy* (`?ended=true` versus `?expired=true`), and that is derived
  /// from the [EndCause] by the page layer; they do not differ in destination.
  ///
  /// A pure query is required because the consumer is acceptance 1 — a recovery
  /// dialog deciding whether to offer "Return to login page" *before* anything has
  /// ended. Asking [end] would answer the question by doing the thing.
  SessionOutcome get destination;

  /// Tear down whatever this mode holds for the session.
  ///
  /// **Does not navigate, and does not clear app auth.** Both omissions are
  /// deliberate:
  ///
  ///   - *navigation*, because `lib/core/` cannot see `lib/route/` (see
  ///     [SessionOutcome]) — and because it is unnecessary: clearing the mode's
  ///     session state is exactly what makes the existing route redirect send the
  ///     app somewhere correct;
  ///   - *app auth*, because this runs from inside `logout()`. Clearing the app's
  ///     own credential is the mode-independent half and stays where it was. A
  ///     member whose two implementations agree is a member Article XVII Rule 5
  ///     rejects.
  ///
  /// **Must not throw.** `logout()` runs it inside an `AsyncValue.guard`, so a
  /// throw here would leave `authProvider` in an error state with the credential
  /// *not* cleared — a session that fails to end, which is strictly worse than one
  /// that ends untidily. Best-effort remote calls belong in a `try`/`catch` in the
  /// implementation.
  ///
  /// Runs *before* the rest of `logout()` on purpose: a Guardian call needs the
  /// token that `logout()` is about to invalidate.
  Future<void> end(Ref ref, EndCause cause);
}
