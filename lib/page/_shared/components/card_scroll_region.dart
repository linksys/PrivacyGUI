import 'package:flutter/material.dart';

/// A fixed-height card region that scrolls its content, and the affordance that
/// says so (#1267, #1297).
///
/// ## Why the region scrolls at all
///
/// A dashboard card's height is fixed by the grid, and a Statistics section's is
/// fixed by its `chartHeight`, so "the content is taller than the box" is a state
/// every one of them can reach — a longer locale, a third radio, one more port.
/// Single-content and multi-section dashboard cards have always scrolled in that
/// state (`DashboardCardTemplate.scrollable` defaults to `true`); tabbed cards did
/// not, and paid for it by painting outside their box: at the 261px card in `tr`,
/// on a tri-band router, the Channels donut was drawn over the radio block above
/// it and bled 9px out of the bottom (#1267, and a `Center`ed child spills in both
/// directions, which is why the text above was the casualty). A user who would
/// rather not scroll can enlarge the card — the grid already allows that, and it
/// is a choice, where painting over text is not.
///
/// ## Why `Expanded` fills and scrolling are mutually exclusive
///
/// [fillViewport] gives the content the viewport height as a **floor** so a
/// shrink-wrapping `Column` still fills the box as it used to, instead of
/// collapsing to its children. What it cannot do is keep a vertical `Expanded`
/// working: flex needs a bounded height to divide, and a scroll view's is
/// unbounded by definition. There is no third option —
/// `SliverFillRemaining(hasScrollBody: false)` looks like one (tight
/// `max(viewport, intrinsic)` height), and it was tried and reverted: it queries
/// `getMaxIntrinsicHeight`, which throws through the `LayoutBuilder`s that
/// `LayoutBlock`, the charts and `CardDensityHost` are built from. 784 gate cases
/// failed on that assertion, measured, not guessed.
///
/// So a surface opts in **after** its content is given real heights, which is why
/// both callers expose it as a per-region flag rather than applying it globally:
/// `CardTab.scrollable` for a dashboard tab and `StatsSectionCard.scrollable` for
/// a Statistics section. `wifi_performance`'s Channels tab is converted (#1267)
/// while its Signal and Speed tabs still hand a `ListView` and a bar chart the
/// whole box; `StatsWifiChannelsSection` is converted (#1297) while the sections
/// that draw real charts into a bounded box are not.
///
/// ## The affordance
///
/// A card that scrolls with no sign of it is the "clean but unreadable" failure
/// this epic keeps meeting: nothing looks broken, so nobody knows to look.
/// `Scrollbar` with `thumbVisibility` is that sign, and it costs nothing on cards
/// that fit: `thumbVisibility` pins the fade-out animation open, but
/// `ScrollbarPainter.paint` still returns early unless
/// `maxScrollExtent - minScrollExtent > precisionErrorTolerance`, so no thumb is
/// painted while the content fits. It is the framework's scrollbar rather than a
/// hand-rolled fade edge because `ui_kit_library` exports no scroll-affordance
/// component (Article XV — searched: `AppTooltip` is the only near neighbour, and
/// ui_kit uses the raw `Scrollbar` internally too). A gradient edge is a component
/// to propose upstream, not to invent here.
class CardScrollRegion extends StatefulWidget {
  const CardScrollRegion({
    super.key,
    required this.child,
    required this.fillViewport,
    this.physics,
  });

  final Widget child;

  /// Whether the content gets the viewport's height as a minimum. See the class
  /// doc: card-tab and Statistics-section content is written to fill its box, and
  /// would otherwise collapse to its children's height the moment it became
  /// scrollable.
  final bool fillViewport;

  final ScrollPhysics? physics;

  @override
  State<CardScrollRegion> createState() => _CardScrollRegionState();
}

class _CardScrollRegionState extends State<CardScrollRegion> {
  // Owned here rather than passed in: the scrollbar and the scroll view must
  // share one controller, and both callers are StatelessWidgets with no place to
  // dispose one.
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final physics = widget.physics ?? const ClampingScrollPhysics();

    Widget scrollView(Widget child) => SingleChildScrollView(
          controller: _controller,
          physics: physics,
          child: child,
        );

    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: widget.fillViewport
          // `maxHeight` is left unbounded on purpose: the floor is what keeps a
          // fitting layout identical to the fixed box it replaces, and the
          // absence of a ceiling is what lets the content grow instead of
          // overflowing.
          ? LayoutBuilder(
              builder: (context, constraints) => scrollView(
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: widget.child,
                ),
              ),
            )
          : scrollView(widget.child),
    );
  }
}
