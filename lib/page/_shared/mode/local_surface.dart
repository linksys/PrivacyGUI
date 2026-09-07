import 'package:privacy_gui/framework/mode/surface_strategy.dart';

/// Local / cloud / demo surfaces: the user owns this router, so the mascot, the
/// dashboard preset picker and edit mode are all concepts this mode has.
///
/// Empty until **#1497 (phase 7)** — see [SurfaceStrategy] for the measured
/// blocker (`usp_layout_controller.dart` builds its notifier without a `Ref`).
class LocalSurface implements SurfaceStrategy {
  const LocalSurface();
}
