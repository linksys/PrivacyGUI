import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/framework/mode/recovery_plan.dart';

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
/// Its second member, `bool canRecoverFrom(DisruptionClass)`, is filled by
/// **#1496 (phase 6)**. The measured blocker is that `DisruptionClass` does not
/// exist yet: the enumeration (`credentialLoss`, `transportLoss`,
/// `transientReboot`) is the substance of phase 6's own analysis, and declaring
/// the member against a placeholder enum would freeze that analysis before it
/// happens.
///
/// See `doc/mode_strategy/mode_strategy_guide.md`. Rule 3: this contract lives
/// in `lib/framework/mode/`, its implementations in `lib/core/mode/impl/`.
///
/// Naming note: "proximity", not "capability". A capability table is per-mode
/// *data*, which #1474 rejected after phase 8 deleted three such flags with zero
/// consumers each (see `GlobalConfig.remote`'s doc comment). Naming the cause
/// keeps the answer derivable — "can the operator physically recover?" has one
/// right answer per mode — where a flag named `allowFactoryReset` invites a
/// second, contradictory one.
abstract class ProximityStrategy {
  /// How this mode recovers from [trigger], or that it has nothing to recover
  /// from.
  ///
  /// **Why proximity and not transport.** The interesting answer is
  /// `RecoveryPlan.notNeeded()`, and it is not "my transport is fine" — it is
  /// "the thing that broke is not on my path". Restarting the Wi-Fi radios
  /// disconnects the *operator's own browser* when the operator is on that
  /// Wi-Fi, which is exactly the local case; a Guardian-proxied session reaches
  /// the router over its WAN uplink, so the same mutation is invisible to it.
  /// Whether the operator's own connection is the one being torn down is a
  /// question about where the operator is, which is this cause.
  ///
  /// Implementations must `switch` over [RecoveryTrigger] exhaustively rather
  /// than defaulting, so that a new trigger is a compile error at every mode
  /// that has to have an opinion about it — the same mechanism Rule 1 applies to
  /// `AppMode`.
  RecoveryPlan planFor(RecoveryTrigger trigger);
}
