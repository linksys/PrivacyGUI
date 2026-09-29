@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/scenes/topology_scene_data.dart';

/// The search field's timing contract, which nothing pinned.
///
/// A debounce was added on cost grounds — a word should cost one scan, not one per
/// letter — and it shipped with two defects that only a *timing* test can see:
///
/// 1. The clear button called the immediate path directly, so it never cancelled the
///    pending timer. Clearing within the window left the search to fire 250ms later
///    and re-highlight and re-zoom what the viewer had just dismissed.
/// 2. The timer's closure captured the `GraphData` that was in scope when the
///    keystroke landed, so a rebuild during the window left the deferred scan running
///    over a discarded graph.
///
/// Both are invisible to a test that pumps and settles: `pumpAndSettle` runs every
/// pending timer, which is exactly the state being asserted against. So these advance
/// the clock deliberately and assert on the **effect** — the set the page has asked
/// the graph to highlight — rather than on whether a timer exists. There is no usable
/// "is a `Timer` pending" signal in the harness: `transientCallbackCount` counts
/// animation callbacks and reads 0 through arming, waiting and firing alike.
void main() {
  setUpAll(() {
    OuiLookup.initializeForTesting(const {
      '112233': 'Test Vendor',
      'AABBCC': 'Linksys',
    });
  });

  tearDownAll(OuiLookup.reset);

  /// Through `pageSurfaceHost`, which the layout gate's own header calls "the one
  /// place a real page is pumped": it supplies the `GoRouter` ancestor `UspTopBar`
  /// dereferences unguarded and the GetIt singletons it reads outside the tree. A
  /// hand-rolled `MaterialApp(home:)` threw on both, and a second copy of that
  /// scaffolding is what that header warns would drift.
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspTopologyView(),
      locale: const Locale('en'),
      overrides: topologyViewOverrides(
        devicesData: meshNetworkDevicesData,
        systemInfoData: testSystemInfoData,
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// The ids the page has asked the graph to highlight.
  ///
  /// Read off the `TopologyController` the page hands to `AppTopology`, which is the
  /// only observable the search writes to — the page's own reference is private, and
  /// the highlight has no other effect visible at this level.
  ///
  /// This is what the assertions key on, rather than "is a timer pending":
  /// `transientCallbackCount` counts animation callbacks and stays 0 for a `Timer`
  /// through arming, waiting and firing alike (measured), so a test built on it
  /// asserts nothing at all.
  Set<String> highlighted(WidgetTester tester) => tester
      .widget<AppTopology>(find.byType(AppTopology))
      .controller!
      .highlighted;

  /// What is in the search box.
  ///
  /// Read off the `EditableText`, not with `find.text`. `iPhone` is both a query and a
  /// node name in this fixture, so searching the tree for it matches the field **and**
  /// the node label — `findsOneWidget` failed on two hits, and `findsNothing` failed on
  /// the graph label that is supposed to be there.
  String fieldText(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).controller.text;

  final field = find.byWidgetPredicate(
    (w) => w is AppTextField && w.identifier == kTopologySearchFieldIdentifier,
    description: 'the topology search field',
  );
  final clearButton = find.byWidgetPredicate(
    (w) => w is AppIconButton && w.identifier == kTopologySearchClearIdentifier,
    description: 'the search clear button',
  );

  group('the page renders enough to search', () {
    testWidgets('the graph and the search field are both there',
        (tester) async {
      await pumpPage(tester);

      expect(find.byType(AppTopology), findsOneWidget);
      expect(field, findsOneWidget);
      // No spinner: the fixture supplies both providers, so a loader here would mean
      // an override was dropped.
      expect(find.byType(AppLoader), findsNothing);
    });
  });

  group('the debounce', () {
    testWidgets('a query does not run before the quiet period is up',
        (tester) async {
      await pumpPage(tester);
      await tester.enterText(field, 'iPhone');

      // Less than the debounce: the scan has not run, so nothing is highlighted.
      await tester.pump(const Duration(milliseconds: 100));
      expect(highlighted(tester), isEmpty,
          reason: 'the deferred search must not have run yet');

      // Past it: the timer fires and the match reaches the graph.
      await tester.pump(UspTopologyView.searchDebounce);
      await tester.pumpAndSettle();
      expect(highlighted(tester), isNotEmpty,
          reason: 'and must have run once the window closed');
    });

    testWidgets('typing a word coalesces into one deferred run',
        (tester) async {
      await pumpPage(tester);

      // Six keystrokes inside the window. Each one cancels the last, so only the
      // final query is ever scanned — which is the whole point of the debounce.
      for (final partial in ['i', 'iP', 'iPh', 'iPho', 'iPhon', 'iPhone']) {
        await tester.enterText(field, partial);
        await tester.pump(const Duration(milliseconds: 40));
      }

      // 40ms apart, so each keystroke cancelled the last before it could fire:
      // nothing has run despite 240ms having passed in total.
      expect(highlighted(tester), isEmpty,
          reason: 'six keystrokes inside the window are one deferred run');

      await tester.pump(UspTopologyView.searchDebounce);
      await tester.pumpAndSettle();

      // And what ran was the whole word, not a prefix.
      expect(fieldText(tester), 'iPhone');
      expect(highlighted(tester), isNotEmpty);
    });

    testWidgets('the named constant is what the field uses', (tester) async {
      // Referenced rather than duplicated: a test that hardcoded 250 would keep
      // passing if the constant changed, which is how a timing test goes quietly
      // stale.
      expect(UspTopologyView.searchDebounce, const Duration(milliseconds: 250));
    });
  });

  group('clearing the field', () {
    testWidgets('the clear button appears only with text in the field',
        (tester) async {
      await pumpPage(tester);
      expect(clearButton, findsNothing);

      await tester.enterText(field, 'iPhone');
      await tester.pumpAndSettle();
      expect(clearButton, findsOneWidget);
    });

    testWidgets('clearing empties the field and leaves no pending search',
        (tester) async {
      await pumpPage(tester);
      await tester.enterText(field, 'iPhone');
      await tester.pumpAndSettle();

      expect(highlighted(tester), isNotEmpty, reason: 'the search ran');

      await tester.tap(clearButton);
      await tester.pump();

      expect(fieldText(tester), isEmpty);
      expect(highlighted(tester), isEmpty);

      // Past the window: nothing may come back.
      await tester.pump(UspTopologyView.searchDebounce);
      await tester.pumpAndSettle();
      expect(highlighted(tester), isEmpty,
          reason: 'a cleared field must stay cleared past the window');
    });

    testWidgets('clearing inside the debounce window cancels the pending run',
        (tester) async {
      await pumpPage(tester);
      await tester.enterText(field, 'iPhone');

      // Mid-window: the timer is armed and has not fired, so nothing is highlighted
      // yet — which is what makes the assertion after the tap mean something.
      await tester.pump(const Duration(milliseconds: 100));
      expect(highlighted(tester), isEmpty);

      await tester.tap(clearButton);
      await tester.pump();

      // **The defect this file exists for.** The clear used to call the immediate
      // path directly, never cancelling the timer, so 250ms later the armed search
      // fired and re-highlighted — and re-zoomed to — a query the viewer had just
      // dismissed.
      await tester.pump(UspTopologyView.searchDebounce);
      await tester.pumpAndSettle();
      expect(highlighted(tester), isEmpty,
          reason: 'the cancelled search must not fire after the clear');
    });

    testWidgets('an empty query runs immediately rather than waiting',
        (tester) async {
      await pumpPage(tester);
      await tester.enterText(field, 'iPhone');
      await tester.pumpAndSettle();

      expect(highlighted(tester), isNotEmpty);

      // Clearing the field is a request to see everything again; making that lag reads
      // as the clear having not worked. So the empty-query path skips the timer —
      // asserted with no clock advance at all, only a frame.
      await tester.enterText(field, '');
      await tester.pump();

      expect(highlighted(tester), isEmpty,
          reason: 'an empty query must take effect on the next frame');
    });
  });

  group('disposal', () {
    testWidgets('leaving the page with a search in flight throws nothing',
        (tester) async {
      await pumpPage(tester);
      await tester.enterText(field, 'iPhone');
      await tester.pump(const Duration(milliseconds: 100));

      // Replace the whole tree mid-window: `dispose` must cancel the timer, or it
      // fires against a disposed `State` and `setState` throws.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump(UspTopologyView.searchDebounce);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
