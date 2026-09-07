/// Why a session is ending, and what the app should land on afterwards.
///
/// Both types are named by `SessionStrategy`'s signature, so they live beside the
/// contract rather than under `impl/` — the same rule that moved `BridgeConfig`
/// here (constitution Article XVII Rule 17.1.3, second half: if the framework has
/// to name a type to state a signature, that type is not an implementation
/// detail).
library;

/// Why the session is ending.
///
/// **Two values, because two is what the implementations measurably consume.**
/// The eleven `logout()` call sites #1323 unified fall into more *situations* than
/// this — an idle timeout, a 401 on the bridge, a factory reset, a serial
/// mismatch, a password change whose relogin failed, three flavours of a user
/// pressing a button — and it is tempting to enumerate them, because they read
/// like distinct causes and an exhaustive `switch` over them looks rigorous.
///
/// Nothing would consume the distinction. Locally all eleven end identically:
/// `logout()` clears the credential and the route redirect sends a
/// credential-less app to the login page. Remotely they split exactly once, on
/// whether the *user* chose to end it:
///
///   - the Guardian API call. `endSessionForCA` is worth making when the operator
///     pressed Disconnect and actively wrong when the session is already gone —
///     a rejected token is the most common way to get here, so the call would
///     authenticate with the very thing that just failed;
///   - the copy on the terminal surface: "the session ended" versus "the session
///     expired", which is the `?ended=true` / `?expired=true` query parameter.
///
/// Those are the same axis, so they are one enum with two values. A third value
/// earns its place when something reads it — see the guide's "shape follows use".
///
/// The split is 3 [userRequested] to 8 [sessionLost], which is why
/// `AuthNotifier.logout` defaults to [sessionLost] and the three button handlers
/// opt in. Defaulting the other way would put a doomed API call on every
/// automatic path.
enum EndCause {
  /// The user deliberately ended it: the RA Disconnect button, a Logout button.
  userRequested,

  /// It ended under them: an idle timeout, an expired or rejected credential, a
  /// factory reset that wiped the credential, a different router answering, a
  /// relogin that failed after a password change.
  ///
  /// Note that "the app decided" counts as this and not as [userRequested], even
  /// when a user action triggered it. A factory reset is a user action; losing the
  /// session is not what they asked for.
  sessionLost,
}

/// Where the app belongs once the session is over.
///
/// Deliberately **not** a route location. `lib/core/` may not depend on
/// `lib/route/` — `router_provider.dart` imports most of `lib/page/`, so a
/// `RoutePath` constant in a core strategy would drag the page layer into core
/// transitively. So the strategy names the *kind* of destination and the page
/// layer maps it, which is the same division that keeps `SessionStrategy`'s
/// implementations legal in `lib/core/mode/impl/` at all.
enum SessionOutcome {
  /// There is a login page, and the user can log straight back in.
  ///
  /// Read as a *fact about the mode*, not as an instruction: nothing navigates on
  /// account of this value. The route redirect already knows where a
  /// credential-less app goes, and it knows things this enum does not — whether
  /// PnP is pending, whether the build is cloud or local — so returning a concrete
  /// destination here would be a second, worse copy of that logic.
  ///
  /// What does read it is acceptance 1: a recovery dialog offers "Return to login
  /// page" exactly when this is the mode's outcome.
  loginPage,

  /// The session was a one-shot engagement and is spent; the destination is a
  /// terminal "session ended" surface.
  ///
  /// There is no login page to return to: the credential was a
  /// `temporaryAccessToken` minted for one support engagement. This is the surface
  /// local mode has no equivalent of, and the reason cause 3 needs a strategy
  /// rather than a shared `logout()`.
  supportSessionEnded,
}
