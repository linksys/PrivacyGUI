import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether a pan/zoom surface and its enclosing scroll can coexist.
///
/// `usp_topology_view` ships `interactive: true` inside a page that is
/// `scrollable: true`, which is normally refused: an `InteractiveViewer` in a
/// scrollable is the textbook way to lose the scroll, and a round of review called
/// it a defect on exactly those grounds.
///
/// It is not one here, and the reason is a framework behaviour this app does not
/// control — Flutter's gesture arena separates the two claimants by pointer count.
/// So it is pinned rather than argued: if a Flutter upgrade changes how the arena
/// resolves this, the comments at `usp_topology_view.dart:136` and `:286` become
/// false and this is what says so.
///
/// Built from the primitives rather than by pumping the page. The page needs a
/// provider container, a mesh fixture and a locale to render at all, none of which
/// bear on the question; what does bear on it is the shape — a `CustomScrollView`
/// whose body is a `SliverToBoxAdapter` holding a fixed-height `InteractiveViewer`
/// — and that is reproduced exactly.
void main() {
  /// The page's shape: a scrollable whose first sliver is a fixed-height graph
  /// area, and a second sliver below it so there is somewhere to scroll to.
  Future<({ScrollController scroll, TransformationController graph})> pump(
    WidgetTester tester, {
    required bool interactive,
  }) async {
    final scroll = ScrollController();
    final graph = TransformationController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: scroll,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                // The page's own `MediaQuery.size.height * 0.78`, fixed here.
                height: 900,
                child: InteractiveViewer(
                  transformationController: graph,
                  panEnabled: interactive,
                  scaleEnabled: interactive,
                  minScale: 0.5,
                  maxScale: 4.0,
                  // The kit's own value, so the graph has room to pan into.
                  boundaryMargin: const EdgeInsets.all(200),
                  child:
                      Container(width: 2000, height: 2000, color: Colors.blue),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 900)),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return (scroll: scroll, graph: graph);
  }

  group('one finger belongs to the page', () {
    testWidgets('a vertical drag scrolls the page and does not pan the graph',
        (tester) async {
      final c = await pump(tester, interactive: true);

      await tester.drag(find.byType(InteractiveViewer), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(c.scroll.offset, greaterThan(0),
          reason: 'the page must still scroll with the graph interactive');
      expect(c.graph.value.getTranslation().y, 0,
          reason: 'the graph must not also pan — that is the conflict');
    });

    // The two halves of one comparison, deliberately in separate tests rather than
    // one: a second `pumpWidget` in the same test rebuilds the tree but does not
    // reset the scroll a previous drag already applied, so measuring both in one
    // body read 560 against 280 and looked like the flag costing the page half its
    // scroll. It was the harness, not the flag.
    //
    // 280px for a 300px drag either way — the shortfall is touch slop, and that it
    // is *identical* is the point: `interactive` takes nothing from the page.
    testWidgets('a 300px drag scrolls 280px with pan enabled', (tester) async {
      final c = await pump(tester, interactive: true);
      await tester.drag(find.byType(InteractiveViewer), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(c.scroll.offset, 280.0);
    });

    testWidgets('and 280px with pan disabled', (tester) async {
      final c = await pump(tester, interactive: false);
      await tester.drag(find.byType(InteractiveViewer), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(c.scroll.offset, 280.0);
    });
  });

  group('two fingers belong to the graph', () {
    testWidgets('a pinch zooms the graph and does not scroll the page',
        (tester) async {
      final c = await pump(tester, interactive: true);
      final center = tester.getCenter(find.byType(InteractiveViewer));

      final p1 = await tester.startGesture(center - const Offset(40, 0));
      final p2 = await tester.startGesture(center + const Offset(40, 0));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await p1.moveBy(const Offset(-8, 0));
        await p2.moveBy(const Offset(8, 0));
        await tester.pump();
      }
      await p1.up();
      await p2.up();
      await tester.pumpAndSettle();

      expect(c.graph.value.getMaxScaleOnAxis(), greaterThan(1.0),
          reason: 'the pinch must reach the graph');
      expect(c.scroll.offset, 0,
          reason: 'and must not also scroll the page away under it');
    });

    testWidgets('with interactive off the pinch reaches nothing',
        (tester) async {
      // The other half of the trade: turning the flag off does not hand the pinch
      // to the page, it discards it. That is what `LeafVisibility.adaptive` had no
      // escape hatch from before this PR.
      final c = await pump(tester, interactive: false);
      final center = tester.getCenter(find.byType(InteractiveViewer));

      final p1 = await tester.startGesture(center - const Offset(40, 0));
      final p2 = await tester.startGesture(center + const Offset(40, 0));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await p1.moveBy(const Offset(-8, 0));
        await p2.moveBy(const Offset(8, 0));
        await tester.pump();
      }
      await p1.up();
      await p2.up();
      await tester.pumpAndSettle();

      expect(c.graph.value.getMaxScaleOnAxis(), 1.0);
    });
  });
}
