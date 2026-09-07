import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
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
/// Both members are now filled. They answer *different* questions about the
/// same operation and are not derivable from one another: [planFor] asks what
/// happens to the operator's connection **after** a disruption that is going to
/// happen anyway, and [canRecoverFrom] asks whether the disruption may be
/// started at all. A reboot needs recovery remotely and is allowed; a Wi-Fi
/// change needs none and is allowed; a factory reset would need recovery and is
/// refused.
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

  /// Whether an operation that costs [disruption] may be started in this mode.
  ///
  /// **The single place the policy lives.** Every disruptive operation names its
  /// [DisruptionClass] at its own seam and asks `OperationGuard`, which asks
  /// this. There is no per-operation table and no `allowFactoryReset` flag,
  /// because a table is the second place a policy can live and the two copies
  /// then disagree about a case neither author was thinking of. See
  /// `lib/core/mode/operation_guard.dart` for the roster of seams.
  ///
  /// Implementations must `switch` over [DisruptionClass] exhaustively rather
  /// than defaulting. That is the *whole* compile-time property #1496 acceptance
  /// 6 can actually have: a new disruption class cannot be added without every
  /// mode stating an opinion about it. The converse — a new destructive
  /// operation being unable to compile without naming a class — is not
  /// expressible in Dart, and is guarded by the roster census in
  /// `test/core/mode/destructive_operation_roster_test.dart` instead.
  bool canRecoverFrom(DisruptionClass disruption);
}
