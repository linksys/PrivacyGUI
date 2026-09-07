import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/framework/mode/proximity_strategy.dart';
import 'package:privacy_gui/framework/mode/recovery_plan.dart';

/// Local / cloud proximity: the operator can power cycle, re-cable and read the
/// sticker, so every disruption class is recoverable.
///
/// `bool canRecoverFrom(DisruptionClass)` is still outstanding — see
/// [ProximityStrategy] for the measured blocker (`DisruptionClass` is #1496's
/// own analysis).
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

  /// 10 seconds, unchanged from the `Timer.periodic` this replaced. The probe is
  /// one request over the LAN to a box that is booting; polling faster mostly
  /// collects connection refusals.
  static const _lanRecovery = RecoveryPlan(
    needsRecovery: true,
    probeInterval: Duration(seconds: 10),
  );
}
