/// How a mode gets *into* a session, expressed as a kind of destination.
///
/// The entry-side counterpart of `session_end.dart`, and it lives here for the
/// same reason: `SessionStrategy` names it to state a signature, so it is not an
/// implementation detail (constitution Article XVII Rule 17.1.3).
///
/// **Deliberately not a route location, exactly like [SessionOutcome].**
/// `lib/core/` may not depend on `lib/route/`, and the two implementations of
/// `SessionStrategy` live in `lib/core/mode/impl/` because `AppModeProfile`
/// composes them. Naming a *kind* of entry and letting `router_provider.dart` map
/// it is what keeps that placement legal. The mapping is four lines and lives at
/// the one layer that already knows `RoutePath`.
library;

import 'package:privacy_gui/framework/mode/session_end.dart';

/// Where a mode's session comes from, as answered by
/// `SessionStrategy.entryPoint` and `SessionStrategy.guardEntry`.
///
/// **Sealed, and switched with data** — which is the shape Article XVII Rule 4
/// prescribes for exactly this: the router does not merely branch on which case
/// it got, it reads [SupportSessionEntry]'s three fields to build a URL. An enum
/// could not carry them and an `abstract class` would put the URL construction
/// behind a polymorphic call in `lib/core/`, where `RoutePath` is not visible.
///
/// Three cases, and which member can produce which is not symmetric:
///
///   - `guardEntry` returns any of the three. It is answering "the user asked for
///     a `/usp*` location — do they already have a session, and if not, where do
///     they get one?", and "yes" is a real answer there.
///   - `entryPoint` returns [OwnCredentialsEntry] or [SupportSessionEntry] only.
///     It runs on `/` and on the login location, *before* any session exists, so
///     [SessionAlreadyHeld] has nothing to mean. The router still switches over
///     all three, because a sealed switch that lists a case it never sees costs
///     one line and an `is` check costs the exhaustiveness.
sealed class SessionEntry {
  const SessionEntry();
}

/// The app is already in a session for this mode; leave the requested location
/// alone.
///
/// Local reads `authState.isLoggedIn`; remote reads
/// `authState.isRemoteAssistance`. Two different predicates over the same auth
/// state, and that asymmetry is the measured difference that earns `guardEntry` a
/// place on the contract: `isLoggedIn` is false throughout an RA session (there is
/// no local credential), so the local predicate applied to a remote build would
/// bounce the agent to the login page on every navigation.
final class SessionAlreadyHeld extends SessionEntry {
  const SessionAlreadyHeld();
}

/// The session starts from the user's own credentials.
///
/// Carries nothing, and answers "not here" rather than "the login page". The
/// route layer already owns where a credential-less app goes and it knows things
/// this class does not — whether PnP is pending, whether the build is cloud or
/// local, whether a first-time login is due. Returning `RoutePath.login` here
/// would be a second, worse copy of `authCheck`.
///
/// So the two consumers read it differently, and both readings are correct:
/// `autoConfigurationLogic` falls through to `authCheck(state)`, and the `/usp*`
/// guard — which is refusing a location, not choosing one — returns `_home()`.
final class OwnCredentialsEntry extends SessionEntry {
  const OwnCredentialsEntry();
}

/// The session is a Remote Assistance support engagement.
///
/// The three fields are the three shapes of confirm-route URL the router used to
/// build inline, and they are one class rather than three cases because the
/// consumer's mapping is a single `if`/ternary over them:
///
///   - [sessionId] + [token] both present — a resumable session, so the URL
///     carries them and the confirm view auto-validates. This is both the
///     `?session=` deep link and the page-refresh restore.
///   - neither present, [previousSessionEnded] true — a session existed in this
///     page lifetime and is over: `?ended=true`, which renders the terminal
///     surface [SessionOutcome.supportSessionEnded] names.
///   - neither present, [previousSessionEnded] false — a cold entry into a remote
///     build with no link parameters. The bare path, which the confirm view
///     answers with its "Missing Parameters" developer page.
///
/// [token] may be the empty string, and that is preserved rather than normalised
/// to null: the `?session=` translation has always emitted `&token=` with whatever
/// the URL carried, so the confirm view's `_hasRequiredParams` is what reports the
/// half-formed link. Turning it into an absence here would silently reroute a
/// malformed supporter link to the *ended* surface.
final class SupportSessionEntry extends SessionEntry {
  final String? sessionId;
  final String? token;

  /// Whether a Guardian session was activated in this page lifetime.
  ///
  /// Reads `remoteAssistanceProvider.isActive`, which nothing ever sets back to
  /// false (`deactivate()` was removed by #1323's acceptance 10), so it survives
  /// session teardown and is exactly the "there *was* a session" signal. A browser
  /// reload rebuilds the provider and answers false, which is correct: a reloaded
  /// tab really has no session to have lost.
  final bool previousSessionEnded;

  const SupportSessionEntry({
    this.sessionId,
    this.token,
    this.previousSessionEnded = false,
  });
}
