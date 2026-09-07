/// What recovery looks like for one disruption, in one mode.
///
/// Returned by `ProximityStrategy.planFor`, and the reason it exists as a value
/// type rather than as two strategy getters: the two fields are only meaningful
/// *together*. `needsRecovery: false` makes [probeInterval] unreadable, and a
/// caller that read the interval without the flag would start a probe loop for a
/// disruption that never interrupted anything.
///
/// Rule 3 (constitution Article XVII): a type a contract needs to state its own
/// signature lives beside the contract in `lib/framework/mode/`, not with the
/// implementations that build it. This is the lesson `BridgeConfig` taught in
/// phase 3 — it was filed under `lib/core/mode/impl/` first, because the two
/// transport strategies build it, and that made `transport_strategy.dart` import
/// the implementation directory to name its own return type.
class RecoveryPlan {
  const RecoveryPlan({
    required this.needsRecovery,
    required this.probeInterval,
  });

  /// This disruption does not interrupt this mode's path to the router.
  ///
  /// Not "recovery is disabled" — recovery is *not applicable*. The router is
  /// still answering, so there is nothing to wait for, nothing to probe and no
  /// waiting surface to show. See `RemoteProximityStrategy.planFor` for the one
  /// case that measures this way today.
  const RecoveryPlan.notNeeded()
      : needsRecovery = false,
        probeInterval = Duration.zero;

  /// Whether the app has to stop, disconnect SSE and wait for the router.
  final bool needsRecovery;

  /// How often to re-probe while waiting. Meaningless when [needsRecovery] is
  /// false, which is why [RecoveryPlan.notNeeded] pins it at zero rather than
  /// leaving a plausible-looking value behind.
  final Duration probeInterval;

  @override
  bool operator ==(Object other) =>
      other is RecoveryPlan &&
      other.needsRecovery == needsRecovery &&
      other.probeInterval == probeInterval;

  @override
  int get hashCode => Object.hash(needsRecovery, probeInterval);

  @override
  String toString() => needsRecovery
      ? 'RecoveryPlan(probe every ${probeInterval.inSeconds}s)'
      : 'RecoveryPlan.notNeeded()';
}
