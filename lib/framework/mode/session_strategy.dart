import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';

/// **Cause 3 — what "the session ended" means.**
///
/// Local: the user's own router session ended; log out and show the login
/// screen, and they can log straight back in. Remote Assistance: the *support
/// engagement* ended; the temporary token is spent, there is no login screen to
/// return to, and the correct destination is a terminal "session ended" surface.
///
/// Declared empty in phase 3 (#1493) and filled here in **#1323 (phases 4-5)**.
/// The reason for the two-step is worth keeping: the composition roots' exhaustive
/// `switch` is the epic's load-bearing guard (constitution Article XVII, Rule 1)
/// and can only be written once against a complete set of causes, so the contract
/// had to exist before any member did. See
/// `doc/mode_strategy/mode_strategy_guide.md` §"Why three contracts ship empty".
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
