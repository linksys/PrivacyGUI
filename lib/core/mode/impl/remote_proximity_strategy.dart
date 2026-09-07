import 'package:privacy_gui/framework/mode/proximity_strategy.dart';

/// Remote Assistance proximity: the agent is not in the building. Losing the
/// credential (factory reset) or the path (local firmware upload) ends the
/// session with no way back; a reboot or a cloud OTA upgrade does not, because
/// the box comes back on its own.
///
/// Empty until **#1496 (phase 6)** — see [ProximityStrategy] for the measured
/// blocker (`DisruptionClass` is that phase's own analysis).
class RemoteProximityStrategy implements ProximityStrategy {
  const RemoteProximityStrategy();
}
