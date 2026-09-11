/// #1032 — when the top bar and the menu rail hide, and when they come back.
///
/// The rule used to be direction alone, and a direction latch has no idea where
/// the page is: anything that returns the page to the top without a gesture left
/// the bars hidden over an unscrolled page, with no way out — a wheel at the top
/// updates no direction, so it emits nothing (see
/// `ScrollPositionWithSingleContext.pointerScroll`). The reporter's "scroll down
/// first, then up" is that dead end.
///
/// So the rules are pinned here, on the widget rather than through the shell: the
/// shell wants a dozen providers before it will build, and the rules are the part
/// that has been wrong.
///
/// ## Mutation table
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | usp_dashboard_shell | drop the `reverse` arm | 'scrolling down hides them', and the three tests that use the hide as their premise |
/// | 2 | usp_dashboard_shell | drop the `forward` arm | 'scrolling back up shows them' alone — it stops short of the top, so only the direction arm can answer it |
/// | 3 | usp_dashboard_shell | drop `_observePosition`, keeping direction alone | 'a page that lands back at the top' alone — this is #1032's second path |
/// | 4 | usp_dashboard_shell | replace the arrival test with `pixels <= min` (drop `previous`) | four of the five, 'scrolling down hides them' included: `reverse` arrives while the position is still 0, so the notification right after it un-hides what it just hid — the bars would never hide on any gesture |
/// | 5 | usp_dashboard_shell | drop the `depth == 0` filter | 'a list inside the page' alone — an inner list at its own top would speak for the page |
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/providers/usp_bars_visible_provider.dart';
import 'package:privacy_gui/page/shell/usp_dashboard_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Taller than any viewport these tests use, so the page scrolls.
  const tallContent = 4000.0;

  /// Shorter than the viewport, so the page cannot scroll at all — what the
  /// dashboard's withheld frame amounts to when a resize crosses a breakpoint.
  const shortContent = 100.0;

  late ValueNotifier<double> contentHeight;
  late ScrollController pageController;

  setUp(() {
    contentHeight = ValueNotifier<double>(tallContent);
    pageController = ScrollController();
  });

  tearDown(() {
    contentHeight.dispose();
    pageController.dispose();
  });

  /// The listener with a scrollable page under it, as the shell mounts it.
  Future<ProviderContainer> pumpPage(WidgetTester tester,
      {Widget? child}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: BarsVisibilityScrollListener(
            child: child ??
                ValueListenableBuilder<double>(
                  valueListenable: contentHeight,
                  builder: (context, height, _) => CustomScrollView(
                    controller: pageController,
                    slivers: [
                      SliverToBoxAdapter(child: SizedBox(height: height)),
                    ],
                  ),
                ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(container.read(uspBarsVisibleProvider), isTrue,
        reason: 'the premise: a page opens with its bars showing');
    return container;
  }

  Future<void> scrollDown(WidgetTester tester) async {
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -400),
        warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('scrolling down hides them', (tester) async {
    final container = await pumpPage(tester);

    await scrollDown(tester);

    expect(container.read(uspBarsVisibleProvider), isFalse);
    expect(container.read(uspMenuController).isVisible, isFalse,
        reason: 'the menu rail is the other half of the same decision');
  });

  testWidgets('scrolling back up shows them', (tester) async {
    final container = await pumpPage(tester);
    await scrollDown(tester);

    // Up, but not all the way: this lands short of the top, so nothing but the
    // direction arm can bring the bars back.
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, 100),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(pageController.offset, greaterThan(0),
        reason: 'the premise: still scrolled down');
    expect(container.read(uspBarsVisibleProvider), isTrue);
    expect(container.read(uspMenuController).isVisible, isTrue);
  });

  testWidgets('a page that lands back at the top shows them, with no gesture',
      (tester) async {
    final container = await pumpPage(tester);
    await scrollDown(tester);
    expect(container.read(uspBarsVisibleProvider), isFalse,
        reason: 'the premise: hidden by the scroll down');

    // The page loses its scroll extent under the user, which is what the
    // dashboard's withheld frame does to it on a breakpoint-crossing resize. No
    // gesture, so no direction notification — the only thing that says the page
    // moved is its metrics.
    contentHeight.value = shortContent;
    await tester.pumpAndSettle();

    expect(pageController.offset, 0,
        reason: 'the premise: the page really is back at the top');
    expect(container.read(uspBarsVisibleProvider), isTrue);
    expect(container.read(uspMenuController).isVisible, isTrue);
  });

  testWidgets('a drag that starts at the top still hides them', (tester) async {
    final container = await pumpPage(tester);

    // Slowly, in touch-slop-sized steps. The first `reverse` arrives before the
    // position has moved off 0, so a rule that read "at the top ⇒ visible"
    // rather than "arrived at the top" would undo the hide here.
    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(CustomScrollView)));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(pageController.offset, greaterThan(0),
        reason: 'the premise: the drag did scroll the page');
    expect(container.read(uspBarsVisibleProvider), isFalse);
  });

  testWidgets('a list inside the page does not speak for it', (tester) async {
    final innerController = ScrollController();
    addTearDown(innerController.dispose);

    final container = await pumpPage(
      tester,
      child: CustomScrollView(
        controller: pageController,
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView(
                controller: innerController,
                children: [
                  for (var i = 0; i < 20; i++)
                    SizedBox(height: 40, child: Text('row $i')),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: tallContent)),
        ],
      ),
    );
    await scrollDown(tester);
    expect(container.read(uspBarsVisibleProvider), isFalse,
        reason: 'the premise: hidden by the page scrolling down');

    // The inner list leaves its own top and comes back to it. The page has not
    // moved.
    innerController.jumpTo(120);
    await tester.pumpAndSettle();
    innerController.jumpTo(0);
    await tester.pumpAndSettle();

    expect(pageController.offset, greaterThan(0),
        reason: 'the premise: the page is still scrolled down');
    expect(container.read(uspBarsVisibleProvider), isFalse);
  });
}
