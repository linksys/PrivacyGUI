import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Swallows the second tap of a double-tap so a shared entry component pushes
/// its detail page **once** per gesture (PrivacyGUI#1445).
///
/// Both dashboard-card detail links and [NavLinkBlock] forward a tap straight
/// into `context.pushNamed(...)` with no debounce. A double-tap therefore
/// fires the callback twice before the pushed route has a chance to settle,
/// leaving two identical stack entries — two backs to leave the page, one
/// shared provider behind both, and a dirty-page prompt that fires twice.
/// `goNamed` used to hide this because replacing a location twice lands on the
/// same location; it surfaced once the verb became `pushNamed` (#1434).
///
/// This is a **same-gesture** guard, not a route-level dedup: after the tap
/// that fired the callback, the guard re-arms on the next frame, so a
/// legitimate second navigation to the same page later in the session is not
/// blocked (Acceptance #4). Both taps of a double-tap arrive inside the same
/// frame — before that post-frame re-arm — so only the first gets through.
///
/// Frame-based rather than time-based on purpose: it needs no wall-clock
/// threshold to tune, disposes cleanly, and is deterministic under
/// `WidgetTester.pump()` (no fake-async plumbing).
class NavTapGuard extends StatefulWidget {
  const NavTapGuard({
    super.key,
    required this.onTap,
    required this.builder,
  });

  /// The navigation callback to run at most once per gesture.
  final VoidCallback onTap;

  /// Builds the tappable child, wiring [guardedTap] to its own tap handler.
  final Widget Function(BuildContext context, VoidCallback guardedTap) builder;

  @override
  State<NavTapGuard> createState() => _NavTapGuardState();
}

class _NavTapGuardState extends State<NavTapGuard> {
  bool _consumed = false;

  void _guardedTap() {
    if (_consumed) return;
    _consumed = true;
    // Re-arm after this frame. A double-tap's two taps are dispatched within
    // the same frame, so the second sees `_consumed == true`; a tap in any
    // later frame sees the guard re-armed.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _consumed = false;
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _guardedTap);
}
