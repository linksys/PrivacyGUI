import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// [MascotOverlay] re-parked in its corner whenever the viewport gets wider.
///
/// The overlay stores its horizontal position as an absolute pixel offset and
/// only ever clamps it to `maxWidth - mascotWidth`. Measured, that makes a
/// resize asymmetric: shrinking the window lowers the clamp ceiling and the
/// mascot is pulled back to the right edge (it looks like following, but it is
/// being clamped), while *growing* the window raises the ceiling, the clamp
/// stops biting, and the mascot stays at whatever absolute x it held. Numbers
/// from that measurement, mascot parked bottom-right:
///
/// | resize            | gap from the right edge |
/// | ----------------- | ----------------------- |
/// | 1440 → 800 → 320  | 0 px, at every step     |
/// | 1440 → 1920       | **480 px**              |
/// | 500 → 1920        | **1420 px**             |
///
/// So a user who starts in a small window and maximises finds the mascot
/// stranded a quarter of the way across the screen — which is the placement
/// problem #1531 is about, arriving by a different route.
///
/// Shrinking has a second, worse symptom that the clamp hides: because the clamp
/// is applied to a local and never written back, `_positionX` stays at the old
/// wide value, and a drag has to spend that whole stale offset before anything
/// moves. Measured at 1440→800 with the mascot parked right — `_positionX` is
/// 1392, the clamp ceiling is 752, so the first **640px** of leftward drag
/// changes nothing on screen: a 100px drag did nothing, 200px jumped 180px, and
/// 400px slammed into the left edge. The mascot looked stuck, then leapt.
///
/// So this remounts on **any** width change, not only on growth: the remount is
/// what re-runs `_initializePosition()` and puts a fresh, in-range value in
/// `_positionX`. One consequence worth stating rather than discovering: a drag
/// does not survive a resize. Nothing persists the dragged position today, so
/// that costs nothing yet — and the alternative is the dead-drag above, which is
/// worse than being re-parked. When a position memory arrives, the real fix is
/// for the overlay to hold a ratio rather than a pixel offset, and this wrapper
/// should go away with it.
///
/// The key changes on the *mascot* layer only. The shell's comment about
/// `_RenderLayoutBuilder was mutated` (#1374) is about inserting or removing a
/// sibling above `widget.child`, which moves the `ShellRoute`'s Navigator; this
/// rebuilds a subtree that sits after it and leaves every earlier child's index
/// untouched.
class ParkedMascotOverlay extends StatelessWidget {
  const ParkedMascotOverlay({
    super.key,
    required this.controller,
    required this.dialogProvider,
    required this.spec,
    required this.child,
  });

  final MascotController controller;
  final MascotDialogProvider? dialogProvider;
  final MascotSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The width *is* the key, so this holds no state: two builds at the same
        // width produce the same key and nothing remounts, which makes the
        // remount a pure function of the constraints. A "bump a counter when the
        // width changes" version would need state and would not be idempotent.
        //
        // Keyed on every change rather than only on growth, because both
        // directions leave `_positionX` wrong — see the class doc.
        return MascotOverlay(
          key: ValueKey(constraints.maxWidth),
          controller: controller,
          dialogProvider: dialogProvider,
          spec: spec,
          child: child,
        );
      },
    );
  }
}
