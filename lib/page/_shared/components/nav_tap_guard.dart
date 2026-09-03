import 'package:flutter/material.dart';

/// Swallows a repeat tap on a shared entry component so it pushes its detail
/// page **once**, not twice (PrivacyGUI#1445).
///
/// Both dashboard-card detail links and [NavLinkBlock] forward a tap straight
/// into `context.pushNamed(...)` with no debounce, so two taps that both land
/// before the pushed route renders leave two identical stack entries — two
/// backs to leave the page, one shared provider behind both, and a dirty-page
/// prompt that fires twice. `goNamed` used to hide this because replacing a
/// location twice lands on the same location; it surfaced once the verb became
/// `pushNamed` (#1434).
///
/// ## Why the next frame is the right re-arm window
///
/// The window in which the double push is reachable at all is exactly *"no
/// frame has rendered since the first tap"*. Once one frame renders, the
/// pushed route's `ModalBarrier` covers this component and a repeat tap
/// hit-tests into the barrier rather than the link: unguarded, two taps 16,
/// 50, 120 or 400 ms apart already produce **one** push, because the framework
/// blocks the second one itself.
///
/// This guard is armed over precisely that window — the post-frame callback
/// runs at the end of the very frame that inserts the barrier, so the guard
/// hands over to the barrier with no gap and no overlap. Hence frame-based
/// rather than a wall-clock debounce: a timer has a threshold to tune, and
/// would either expire while the window is still open (a long janky frame) or
/// keep blocking long after the barrier already does.
///
/// So the case this actually catches is a tap that lands before *any* frame
/// renders: two taps dispatched in one event batch, or — the one users hit —
/// a tap repeated during a long frame, because the first tap appeared to do
/// nothing. Neither depends on double-tap timing constants; `kDoubleTapMinTime`
/// and friends govern gesture *recognition*, which this widget does not use.
/// `test/page/_shared/components/nav_tap_guard_test.dart` pins both the jank
/// window and the framework's half of the handoff.
///
/// It stays a **same-gesture** guard, not a route-level dedup: a legitimate
/// second navigation to the same page later in the session is not blocked
/// (Acceptance #4).
///
/// ## Contract
///
/// [onTap] must cause a frame to be scheduled. Navigation always does, and so
/// does the ink ripple of the `InkWell` both current call sites tap through —
/// but a callback that dirties nothing, under a child with no ink, would leave
/// the guard latched until some unrelated frame renders.
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
    // Re-arm at the end of the next frame — the same frame that puts the
    // pushed route's ModalBarrier over this component, which blocks a repeat
    // tap from there on. Until that frame renders no barrier exists and the
    // link is still live, which is the window this guard covers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _consumed = false;
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _guardedTap);
}
