import 'package:privacy_gui/framework/mode/session_strategy.dart';

/// Local / cloud session ending: the user's own router session ended, so the
/// destination is the login screen and they can log straight back in.
///
/// Empty until **#1495 (phase 5)** — see [SessionStrategy] for why the contract
/// ships without members and why the pair exists anyway.
class LocalSessionStrategy implements SessionStrategy {
  const LocalSessionStrategy();
}
