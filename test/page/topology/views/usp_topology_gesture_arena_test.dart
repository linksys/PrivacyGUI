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
/// resolves this, the comments on `scrollable:` and `interactive:` in
/// `usp_topology_view.dart` become
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
  ///
  /// Keyed by [interactive]. Two hosts pumped in one test with the same key keep the
  /// first one's `Scrollable` state, so a second drag starts where the first ended —
  /// measured: 280 then 560 with one key, 280 and 280 with two. That is why the
  /// comparison below can live in one test.
  Future<({ScrollController scroll, TransformationController graph})> pump(
    WidgetTester tester, {
    required bool interactive,
  }) async {
    final scroll = ScrollController();
    final graph = TransformationController();

    await tester.pumpWidget(MaterialApp(
      key: ValueKey('host-interactive-$interactive'),
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

    testWidgets('pan costs the page none of its scroll', (tester) async {
      // Compared, not pinned. The distance itself (280px for a 300px drag) is touch
      // slop arithmetic and moves with the framework; what this file claims is that
      // turning pan on takes nothing from the page, and that is a comparison. A
      // pinned `280.0` would fail on a Flutter upgrade that changed nothing about the
      // behaviour, and fail saying "wrong number" rather than "lost the scroll".
      final off = await pump(tester, interactive: false);
      await tester.drag(find.byType(InteractiveViewer), const Offset(0, -300));
      await tester.pumpAndSettle();
      final withoutPan = off.scroll.offset;

      final on = await pump(tester, interactive: true);
      await tester.drag(find.byType(InteractiveViewer), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(withoutPan, greaterThan(0),
          reason: 'the baseline must scroll, or the comparison proves nothing');
      expect(on.scroll.offset, withoutPan);
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
