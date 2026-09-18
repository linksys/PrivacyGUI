import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/framework/mode/proximity_strategy.dart';
import 'package:privacy_gui/framework/mode/recovery_plan.dart';

/// Local / cloud proximity: the operator can power cycle, re-cable and read the
/// sticker, so every disruption class is recoverable.
class LocalProximityStrategy implements ProximityStrategy {
  const LocalProximityStrategy();

  /// Every trigger needs recovery, and at the 10-second cadence the probe loop
  /// has always used.
  ///
  /// The `switch` is exhaustive and every arm returns the same plan, which is
  /// the point: locally the app is served *by* the box it is configuring, so
  /// anything that restarts the box — or its radios, which is the browser's own
  /// link — takes the app down with it. There is no local trigger for which the
  /// answer is "carry on", and writing the arms out is what makes a *new*
  /// trigger a compile error here instead of silently inheriting this answer.
  @override
  RecoveryPlan planFor(RecoveryTrigger trigger) => switch (trigger) {
        RecoveryTrigger.natural ||
        RecoveryTrigger.operationalWifiChange ||
        RecoveryTrigger.operationalReboot ||
        RecoveryTrigger.operationalFactoryReset ||
        RecoveryTrigger.operationalFirmwareUpgrade =>
          _lanRecovery,
      };

  /// Everything is recoverable, because the operator is standing next to the box.
  ///
  /// The arms are written out for the same reason [planFor]'s are, and the
  /// uniform answer is not laziness — it is the definition of proximity. A reset
  /// puts the credential back to the one printed on the label and the operator
  /// can read the label; a local upload is aimed at the LAN address the browser
  /// is already talking to; a restart ends when the operator's browser
  /// reconnects. There is no local disruption whose recovery needs someone else
  /// to be in the building.
  ///
  /// Every arm returning `true` also means this mode never blocks an operation,
  /// which is exactly what phase 6 must not change: the five seams that now call
  /// `OperationGuard.enforce` are all reached by the local build too, and their
  /// existing tests run under the default (local) profile.
  @override
  bool canRecoverFrom(DisruptionClass disruption) => switch (disruption) {
        DisruptionClass.credentialLoss ||
        DisruptionClass.transportLoss ||
        DisruptionClass.transientRestart =>
          true,
      };

  /// 10 seconds, unchanged from the `Timer.periodic` this replaced. The probe is
  /// one request over the LAN to a box that is booting; polling faster mostly
  /// collects connection refusals.
  static const _lanRecovery = RecoveryPlan(
    needsRecovery: true,
    probeInterval: Duration(seconds: 10),
  );
}
