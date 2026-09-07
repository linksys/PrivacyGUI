import 'package:privacy_gui/framework/mode/session_strategy.dart';

/// Remote Assistance session ending: the *support engagement* ended. The
/// temporary token is spent and there is no login screen to return to, so the
/// destination is a terminal "session ended" surface.
///
/// Empty until **#1323 (phases 4-5)** — see [SessionStrategy] for why the contract
/// ships without members and why the pair exists anyway.
class RemoteSessionStrategy implements SessionStrategy {
  const RemoteSessionStrategy();
}
