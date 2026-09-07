import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/framework/mode/proximity_strategy.dart';
import 'package:privacy_gui/framework/mode/recovery_plan.dart';

/// Remote Assistance proximity: the agent is not in the building. Losing the
/// credential (factory reset) or the path (local firmware upload) ends the
/// session with no way back; a reboot or a cloud OTA upgrade does not, because
/// the box comes back on its own.
///
/// `bool canRecoverFrom(DisruptionClass)` is still outstanding — see
/// [ProximityStrategy] for the measured blocker (`DisruptionClass` is #1496's
/// own analysis).
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
