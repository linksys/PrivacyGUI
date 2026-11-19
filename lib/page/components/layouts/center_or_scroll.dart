import 'package:flutter/material.dart';

/// Centers [child] in the space it is given, and scrolls when [child] is
/// taller than that space.
///
/// For a page that centers a card, in place of `StyledAppPageView`'s
/// `scrollable: true`. That one sizes the page by its intrinsic height, and a
/// `SizedBox(width: 4.col)` reports its child's intrinsic height at the full
/// page width, not at its own: text wraps less there, so the page comes out
/// too short and the card overflows it in a short window (#1802). This asks
/// for no intrinsic size: the child is at least as tall as the space, and as
/// tall as it needs.
class CenterOrScroll extends StatelessWidget {
  const CenterOrScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // The physics of StyledAppPageView's scrollable pages, so this page
        // scrolls the way they do.
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
