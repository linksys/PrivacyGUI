import 'package:privacy_gui/framework/mode/surface_strategy.dart';

/// Remote Assistance surfaces: a support session has nothing to personalise, so
/// there is no mascot, the dashboard preset is fixed rather than picked, and edit
/// mode is not offered.
///
/// The discipline is that this mode expresses that by *not using* those
/// surfaces — not by a bool that hides them. See [SurfaceStrategy] and
/// `GlobalConfig.remote`'s doc comment, which records the three per-mode flags
/// phase 8 deleted with zero consumers each.
///
/// Empty until **#1497 (phase 7)**.
class RemoteSurface implements SurfaceStrategy {
  const RemoteSurface();
}
