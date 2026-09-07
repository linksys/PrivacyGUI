library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Widget-layer regression coverage for PrivacyGUI#1301.
///
/// `sliver_dashboard` wraps every grid item in a semantics boundary spanning the
/// whole card (`dashboard_item_widget.dart:592`, 2.6.0):
///
/// ```dart
/// child: Semantics(
///   container: true,
///   label: semanticLabel,      // 'Item ${id}, Row ${y}, Column ${x}'
///   hint: ...,
///   selected: isSelected,
/// ```
///
/// A footer button that declares no boundary of its own has its tap action and
/// `button` flag absorbed *up* into that node by
/// `SemanticsConfiguration.absorbAll` — so the card's semantics node ends up
/// carrying a tap handler over the entire card rect instead of the footer's
/// ~90x20, and the DOM exports the card as `role=button`.
///
/// This only *manifests* in release web builds, because `main.dart` keeps the
/// semantics tree alive there for E2E (`!kDebugMode`) and clicks are then routed
/// by DOM hit testing against the `<flt-semantics>` overlay. The absorption
/// itself is platform-independent and observable here.
///
/// The fix is `container: true` on the footer's `Semantics`.
///
/// ## Why this test reproduces the boundary instead of pumping `SliverDashboard`
///
/// Driving the real grid needs the whole dashboard provider stack, and its
/// drag/measurement layer lays the item builder out under unbounded height —
/// which makes `DashboardCardTemplate`'s `Expanded` overflow and drops the
/// footer from the tree entirely, leaving nothing to assert on. What matters
/// for absorption is only that an ancestor boundary exists, so the wrapper
/// above is replicated verbatim. `expectFooterOwnsItsTapAction` guards the
/// substitution by proving the footer is really rendered and really tappable.
///
/// ## Do not use `performActionAt` here
///
/// `SemanticsOwner.performActionAt` resolves a point by searching for a node
/// that both contains it *and* carries the requested action, silently skipping
/// others — whereas browsers dispatch to the topmost DOM element regardless. It
/// reports this bug as fixed when it is not, which is exactly how #1008 came to
/// be misdiagnosed. Assert on node ownership, not on delivered actions.
void main() {
  const cardLabel = 'Item network_status, Row 0, Column 0';

  // Required, not cosmetic: without an `AppTheme` the kit's spacing resolves to
  // degenerate values and the footer is laid out ~100000px outside the card, so
  // it never reaches the semantics tree and every assertion below goes vacuous.
  final testTheme = AppTheme.create(
    brightness: Brightness.light,
    seedColor: Colors.blue,
    designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
  );

  /// Mirrors `sliver_dashboard`'s per-item wrapper so the card sits beneath a
  /// card-sized semantics boundary, exactly as it does in the real grid.
  Future<SemanticsNode> pumpCardUnderGridBoundary(
    WidgetTester tester, {
    required Widget content,
    String? detailRoute,
    Widget? footer,
    int? itemCount,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          // A representative desktop card footprint (4 of 12 slots).
          child: SizedBox(
            width: 420,
            height: 260,
            child: Semantics(
              container: true,
              label: cardLabel,
              selected: false,
              child: DashboardCardTemplate(
                title: 'Network Status',
                detailRoute: detailRoute,
                footer: footer,
                itemCount: itemCount,
                content: content,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    SemanticsNode? cardNode;
    void walk(SemanticsNode n) {
      if (n.label.contains('Item network_status')) cardNode ??= n;
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    // `rootPipelineOwner` (the suggested replacement) resolves to a different
    // tree than the one `pumpWidget` builds, so the node lookup finds nothing
    // there. This is the owner that actually holds the test's tree.
    // ignore: deprecated_member_use
    walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    expect(cardNode, isNotNull,
        reason: 'The card-sized semantics boundary was not found, so this test '
            'is not exercising the absorption path at all.');
    return cardNode!;
  }

  /// Proves the footer link is on screen AND owns a tappable semantics node of
  /// its own. Without this, "the card has no tap action" passes trivially
  /// whenever the footer failed to lay out — a false green that a previous
  /// iteration of this probe actually hit.
  void expectFooterOwnsItsTapAction(WidgetTester tester, String label) {
    expect(find.text(label), findsOneWidget,
        reason: 'The footer link was not laid out, so any assertion about the '
            'card not absorbing its tap action would be vacuous.');

    // The footer node's own label plus the `AppText` beneath it both mention
    // the link, so the node's merged label reads "View details / View details" —
    // hence `contains` rather than equality.
    SemanticsNode? footerNode;
    void walk(SemanticsNode n) {
      if (n.label.contains(label) &&
          n.getSemanticsData().hasAction(SemanticsAction.tap)) {
        footerNode ??= n;
      }
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    // ignore: deprecated_member_use — see the note in pumpCardUnderGridBoundary.
    walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    expect(footerNode, isNotNull,
        reason: 'Expected a dedicated semantics node labelled "$label" owning '
            'the tap action. Its absence means the action was absorbed into an '
            'ancestor (the #1301 regression).');

    // Pin the scope of that node: it must cover the link, not the card. Without
    // this the test would still pass if the action were merged into a
    // card-sized node that happened to carry the label too.
    expect(footerNode!.rect.height, lessThan(60),
        reason: 'The tappable node spans ${footerNode!.rect.height}px of '
            'height — that is card-sized, not link-sized, so the tap target is '
            'still far larger than the footer link (#1301).');
  }

  void expectCardIsNotTappable(SemanticsNode cardNode) {
    final data = cardNode.getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isFalse,
        reason: 'The card-wide node absorbed the footer button, so tapping '
            'anywhere on the card navigates (#1301).');
    expect(data.flagsCollection.isButton, isFalse,
        reason: 'The card is not a button. The flag leaked up from the footer '
            'and is exported to the DOM as role=button (#1301).');
  }

  group('#1301 the grid item must not absorb the card footer button', () {
    testWidgets('detailRoute footer keeps its tap action to itself',
        (tester) async {
      final handle = tester.ensureSemantics();

      final cardNode = await pumpCardUnderGridBoundary(
        tester,
        content: const Center(child: Text('card body')),
        detailRoute: 'uspInternetSettings',
      );

      expectFooterOwnsItsTapAction(tester, 'View details');
      expectCardIsNotTappable(cardNode);

      handle.dispose();
    });

    testWidgets('itemCount variant ("View all") behaves the same',
        (tester) async {
      final handle = tester.ensureSemantics();

      final cardNode = await pumpCardUnderGridBoundary(
        tester,
        content: const Center(child: Text('card body')),
        detailRoute: 'uspInternetSettings',
        itemCount: 3,
      );

      expectFooterOwnsItsTapAction(tester, 'View all');
      expectCardIsNotTappable(cardNode);

      handle.dispose();
    });

    testWidgets('a card with no tappable footer stays non-interactive',
        (tester) async {
      final handle = tester.ensureSemantics();

      // Control case: no detailRoute and no footer. Clean both before and after
      // the fix — it is here to catch a harness that reports "clean" for the
      // wrong reason.
      final cardNode = await pumpCardUnderGridBoundary(
        tester,
        content: const Center(child: Text('card body')),
      );

      expectCardIsNotTappable(cardNode);

      handle.dispose();
    });
  });
}
