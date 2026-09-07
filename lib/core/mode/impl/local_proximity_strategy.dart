import 'package:privacy_gui/framework/mode/proximity_strategy.dart';

/// Local / cloud proximity: the operator can power cycle, re-cable and read the
/// sticker, so every disruption class is recoverable.
///
/// Empty until **#1496 (phase 6)** — see [ProximityStrategy] for the measured
/// blocker (`DisruptionClass` is that phase's own analysis).
class LocalProximityStrategy implements ProximityStrategy {
  const LocalProximityStrategy();
}
