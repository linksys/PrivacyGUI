/// **Cause 4 — whether the operator is standing next to the router.**
///
/// This is the cause that decides which disruptive operations are offered, and
/// it is the one most often mistaken for a UI flag. Local: the user can power
/// cycle, re-cable, or read a sticker, so a factory reset is recoverable. Remote
/// Assistance: the agent is not in the building, so an operation that destroys
/// the credential (factory reset) or the path (local firmware upload) ends the
/// session with no way back — while reboot and *cloud* OTA upgrade stay allowed,
/// because the box comes back on its own.
///
/// **Deliberately empty in phase 3 (#1493).** Its member is
/// `bool canRecoverFrom(DisruptionClass)`, filled by **#1496 (phase 6)**. The
/// measured blocker is that `DisruptionClass` does not exist yet: the
/// enumeration (`credentialLoss`, `transportLoss`, `transientReboot`) is the
/// substance of phase 6's own analysis, and declaring the member against a
/// placeholder enum would freeze that analysis before it happens.
///
/// See the empty-contract rationale in [SessionStrategy] and
/// `doc/mode_strategy/mode_strategy_guide.md` §"Why three contracts ship empty".
///
/// Naming note: "proximity", not "capability". A capability table is per-mode
/// *data*, which #1474 rejected after phase 8 deleted three such flags with zero
/// consumers each (see `GlobalConfig.remote`'s doc comment). Naming the cause
/// keeps the answer derivable — "can the operator physically recover?" has one
/// right answer per mode — where a flag named `allowFactoryReset` invites a
/// second, contradictory one.
abstract class ProximityStrategy {}
