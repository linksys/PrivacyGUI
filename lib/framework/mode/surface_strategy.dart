/// **Cause 5 — which surfaces the mode has a concept for.**
///
/// The narrow one, and the only cause whose implementations live under
/// `lib/page/`. Remote Assistance has no concept of a mascot, of a dashboard
/// *preset picker* (its preset is fixed), or of dashboard edit mode — not
/// because a flag forbids them, but because a support session has nothing to
/// personalise. The discipline #1474 sets is that a mode expresses this by *its
/// strategy not using a surface*, never by a bool that hides UI.
///
/// **Deliberately empty in phase 3 (#1493).** Its members are the seven bare
/// `GlobalConfig.remote.isActive` reads under `lib/page/` + `lib/components/`,
/// folded in by **#1497 (phase 7)**. The measured blocker is a construction
/// site, not a signature: the first member would be `forcedPreset()`, and
/// `lib/page/dashboard/providers/usp_layout_controller.dart:19` builds its
/// notifier without a `Ref`, so the read cannot reach a provider until that
/// constructor changes — a behavioural edit, which #1493 excludes.
///
/// Rule 3 with the sign flipped: because these implementations must live at
/// `lib/page/_shared/mode/`, they are **not** reachable from `AppModeProfile`
/// (CLAUDE.md forbids `lib/core/` → `lib/page/`). [SurfaceStrategy] therefore
/// has its own composition root — a second exhaustive `switch` over the same
/// `AppMode` — at `lib/page/_shared/mode/surface_strategy_provider.dart`. Two
/// roots is the intended shape, and constitution Article XVII Rule 2 names both
/// so a third cannot appear unnoticed.
///
/// See `doc/mode_strategy/mode_strategy_guide.md` §"Why three contracts ship
/// empty".
abstract class SurfaceStrategy {}
