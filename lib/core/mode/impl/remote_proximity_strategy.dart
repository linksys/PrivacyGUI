import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/framework/mode/proximity_strategy.dart';
import 'package:privacy_gui/framework/mode/recovery_plan.dart';

/// Remote Assistance proximity: the agent is not in the building. Losing the
/// credential (factory reset) ends the session with no way back, and a local
/// firmware upload has no byte path of its own to spend; a reboot or a cloud OTA
/// upgrade costs neither, because the box comes back on its own.
class RemoteProximityStrategy implements ProximityStrategy {
  const RemoteProximityStrategy();

  /// One trigger is not a disruption at all remotely, and the rest are.
  ///
  /// **`operationalWifiChange` needs no recovery.** The Guardian-proxied session
  /// reaches the router over its WAN uplink; restarting the LAN radios does not
  /// touch that path, and the agent's browser was never on the SSID being
  /// restarted. Before #1323 the same 20-second cooldown and probe loop ran
  /// anyway, so an RA agent who changed a Wi-Fi setting watched a spinner for a
  /// working connection — and then the probe's identity check logged them out.
  /// This is the concept `RecoveryPlan.notNeeded()` exists to express: not "skip
  /// the dialog", but "nothing broke".
  ///
  /// The other four do disrupt the path, because they take the whole box or its
  /// uplink down. `operationalFactoryReset` is listed for completeness only —
  /// #1496 (phase 6) gates the operation itself, since a reset destroys the
  /// credential Guardian is proxying and no amount of probing brings that back.
  @override
  RecoveryPlan planFor(RecoveryTrigger trigger) => switch (trigger) {
        RecoveryTrigger.operationalWifiChange => const RecoveryPlan.notNeeded(),
        RecoveryTrigger.natural ||
        RecoveryTrigger.operationalReboot ||
        RecoveryTrigger.operationalFactoryReset ||
        RecoveryTrigger.operationalFirmwareUpgrade =>
          _guardianRecovery,
      };

  /// Two of the three classes are unrecoverable from outside the building.
  ///
  /// **`credentialLoss` — factory reset.** The reset is "recoverable" in the
  /// sense that the router comes back; it comes back with the password printed
  /// on its label, and this mode's operator cannot read the label. Guardian is
  /// proxying an admin login that has stopped existing, so no amount of probing
  /// helps: [planFor] would happily return a 30-second loop that runs until the
  /// session is billed out. Refusing the operation is the only correct answer,
  /// and it is why `planFor`'s `operationalFactoryReset` arm is reachable in
  /// theory only.
  ///
  /// **`transportLoss` — local firmware upload.** `false` because **manual
  /// firmware update is a local-only feature**, decided at product level rather
  /// than derived here. Stated that way deliberately: this arm's first draft
  /// justified the same answer by claiming the upload is aimed at Guardian and
  /// broken, and that claim is false — `window.location` feeds only the Method-2
  /// WebSocket URL, and Method 1 pushes `chunkedPush` over the same Guardian-
  /// proxied `UspClient` that reboot and OTA use, with an automatic fallback to
  /// it. It would work; it is simply not on offer remotely, and cloud OTA is the
  /// remote answer for the same need. See `DisruptionClass.transportLoss` for the
  /// 1,121-round-trip arithmetic that says why nobody should re-litigate this,
  /// and for the suspected defect the decision retires.
  ///
  /// **`transientRestart` — reboot, cloud OTA, install trigger, Wi-Fi change.**
  /// Allowed, and this is the half that is easy to lose. The Guardian path
  /// reaches the router over its WAN uplink and re-establishes itself when the
  /// box finishes booting; the credential and the route both survive. These are
  /// also the operations an agent most often calls, so a guard that refused
  /// everything disruptive would be shipped and then worked around.
  @override
  bool canRecoverFrom(DisruptionClass disruption) => switch (disruption) {
        DisruptionClass.credentialLoss => false,
        DisruptionClass.transportLoss => false,
        DisruptionClass.transientRestart => true,
      };

  /// 30 seconds, not the local 10.
  ///
  /// The probe crosses browser → Guardian → agent → router instead of one LAN
  /// hop, and it is the same cadence `remoteAccessProvider`'s session poll
  /// already uses for the same round trip (`_kPollInterval`). Probing a cloud
  /// path three times as often does not detect the router any sooner; it triples
  /// the traffic through a proxy that serialises requests per session.
  static const _guardianRecovery = RecoveryPlan(
    needsRecovery: true,
    probeInterval: Duration(seconds: 30),
  );
}
