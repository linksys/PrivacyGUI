/// **Cause 3 — what "the session ended" means.**
///
/// Local: the user's own router session ended; log out and show the login
/// screen, and they can log straight back in. Remote Assistance: the *support
/// engagement* ended; the temporary token is spent, there is no login screen to
/// return to, and the correct destination is a terminal "session ended" surface.
///
/// **Deliberately empty in phase 3 (#1493), and this is not an oversight.** The
/// contract is declared now because the composition roots' exhaustive `switch`
/// is the epic's load-bearing guard (constitution Article XVII, Rule 1) and it
/// can only be written once against a complete set of causes; adding a member to
/// an existing contract in phase 5 touches 3 files, whereas creating the
/// contract, its two implementations, both profile wirings and the roster test
/// later touches 6.
///
/// The member it will hold is `Future<SessionOutcome> end(Ref, EndCause)`,
/// filled by **#1323 (phases 4-5)**. It cannot move today for a measured reason:
/// the two mode-specific endings currently differ *by navigation target*, and
/// the design doc's §4.2 signature deliberately returns an outcome instead of
/// navigating — so the caller side has to be rewritten in the same change as the
/// member, which is precisely the scope #1493 excludes. See
/// `doc/mode_strategy/mode_strategy_guide.md` §"Why three contracts ship empty".
///
/// Note the placement decision recorded in that section: despite the design
/// doc's file tree, the implementations live under `lib/core/mode/impl/` like the
/// other core causes, because [SessionStrategy] is composed by `AppModeProfile`
/// and CLAUDE.md forbids a `lib/core/` → `lib/page/` dependency. Returning an
/// outcome rather than navigating is what makes that placement legal.
abstract class SessionStrategy {}
