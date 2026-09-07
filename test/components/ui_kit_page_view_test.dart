import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Coverage for [UiKitPageView.identifier] — the page-level E2E test hook added
/// for PrivacyGUI#1391.
///
/// Deliberately NOT tagged `ui`: the point of this suite is to prove that a
/// shared page container gained an opt-in hook *without* changing any page that
/// does not ask for one, and that guarantee is worth blocking a PR on. It costs
/// four pumps of a stub page, so it stays in `run_tests.sh`'s PR-blocking set
/// (which excludes `golden||loc||ui`) rather than in the `ui` bucket that the PR
/// command skips.
///
/// ## What is actually asserted, and why in this shape
///
/// The wrap is **conditional** (`ui_kit_page_view.dart:489`), matching the
/// precedent at `lib/components/styled/menus/widgets/app_menu_card.dart:91`.
/// "Conditional" is only meaningful if the null case is verified structurally,
/// so [subtreeTypes] walks the whole element subtree under the page and the
/// no-identifier expectation is *exact list equality against the with-identifier
/// tree minus one node*: exactly one widget appears, it is a [Semantics], and it
/// sits immediately above the [AppPageView]. Asserting only
/// `find.bySemanticsIdentifier(...)` findsNothing would pass just as well for an
/// unconditional `Semantics(identifier: null)` wrap, which is the design this
/// change rejected.
///
/// ## Both return paths
///
/// `_buildPageContent` returns from two places and the hook is assembled once
/// above the fork, so both must be covered or the fork is untested:
///
/// - **with topbar** (`ui_kit_page_view.dart:507`) — `Column[topbar,
///   Expanded(content)]`, reached when a topbar exists and sliver mode is off.
/// - **without topbar** (`:515`) — bare `content`, reached here via
///   `hideTopbar: true`.
///
/// A plain [SizedBox] is injected as `topbar` rather than letting the widget
/// build its default `UspTopBar`: the fork under test keys off "is there a
/// topbar widget", not off which one, and the real one drags in a
/// package_info platform channel plus session providers that would be noise here.
void main() {
  const kIdentifier = 'page-ui-kit-page-view-test';

  final lightTheme = ThemeJsonConfig.defaultConfig().createLightTheme();

  /// Pumps a [UiKitPageView] whose only variable is [identifier] (and the
  /// topbar, which selects the return path).
  Widget buildHost({String? identifier, required bool withTopbar}) {
    return ProviderScope(
      child: MaterialApp(
        theme: lightTheme,
        home: UiKitPageView(
          identifier: identifier,
          title: 'Page Identifier Probe',
          appBarStyle: UiKitAppBarStyle.none,
          backState: UiKitBackState.none,
          hideTopbar: !withTopbar,
          topbar: withTopbar ? const SizedBox(height: 56) : null,
          enableSliverAppBar: false,
          child: (context, constraints) => const Text('page body'),
        ),
      ),
    );
  }

  /// Depth-first list of widget runtime types in the element subtree rooted at
  /// [root]. Comparing two of these compares tree *shape*, which is the property
  /// under test — "not one extra node" — rather than a rendered pixel.
  List<String> subtreeTypes(WidgetTester tester, Finder root) {
    final types = <String>[];
    void visit(Element element) {
      types.add(element.widget.runtimeType.toString());
      element.visitChildren(visit);
    }

    visit(tester.element(root));
    return types;
  }

  /// The nearest ancestor widget of [finder]'s element.
  Widget parentWidgetOf(WidgetTester tester, Finder finder) {
    Widget? parent;
    tester.element(finder).visitAncestorElements((ancestor) {
      parent = ancestor.widget;
      return false;
    });
    return parent!;
  }

  for (final path in const [
    (name: 'with topbar (Column return path)', withTopbar: true),
    (name: 'without topbar (bare content return path)', withTopbar: false),
  ]) {
    group('UiKitPageView.identifier — ${path.name}', () {
      testWidgets('emits no Semantics node when no identifier is given',
          (tester) async {
        final handle = tester.ensureSemantics();

        await tester
            .pumpWidget(buildHost(withTopbar: path.withTopbar)); // null hook
        await tester.pumpAndSettle();

        // Nothing to find, under the hook's own name or under any non-empty
        // identifier at all. `RegExp('.+')`, not `'.*'`: an empty pattern
        // matches every node's null/empty identifier and would report the whole
        // subtree as a hit.
        expect(find.bySemanticsIdentifier(kIdentifier), findsNothing);
        expect(find.bySemanticsIdentifier(RegExp('.+')), findsNothing);

        // And structurally: AppPageView is not wrapped. This is the assertion
        // that separates a conditional wrap from `Semantics(identifier: null)`.
        expect(
          parentWidgetOf(tester, find.byType(AppPageView)),
          isNot(isA<Semantics>()),
          reason: 'no identifier must mean no wrapper element at all',
        );

        handle.dispose();
      });

      testWidgets('emits no Semantics node when the identifier is empty',
          (tester) async {
        // The withIdentifier fix (PrivacyGUI#1391): an empty string must behave
        // exactly like null — no wrapper node — so `byIdentifier('')` can never
        // match. A plain `!= null` check would fail this.
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(buildHost(
          identifier: '',
          withTopbar: path.withTopbar,
        ));
        await tester.pumpAndSettle();

        expect(find.bySemanticsIdentifier(RegExp('.+')), findsNothing);
        expect(
          parentWidgetOf(tester, find.byType(AppPageView)),
          isNot(isA<Semantics>()),
          reason: 'an empty identifier must mean no wrapper element at all',
        );

        handle.dispose();
      });

      testWidgets('wraps the page content in Semantics when given',
          (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(buildHost(
          identifier: kIdentifier,
          withTopbar: path.withTopbar,
        ));
        await tester.pumpAndSettle();

        // The E2E contract: locatable by identifier, reading back verbatim.
        final hook = find.bySemanticsIdentifier(kIdentifier);
        expect(hook, findsOneWidget);
        expect(tester.getSemantics(hook).identifier, kIdentifier);

        // Placement: immediately outside the page surface, so everything the
        // page renders is inside the hook.
        expect(
          parentWidgetOf(tester, find.byType(AppPageView)),
          isA<Semantics>(),
        );
        expect(
          find.descendant(of: hook, matching: find.text('page body')),
          findsOneWidget,
        );

        handle.dispose();
      });

      testWidgets(
          'the identifier adds exactly one node and changes nothing else',
          (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(buildHost(withTopbar: path.withTopbar));
        await tester.pumpAndSettle();
        final withoutHook = subtreeTypes(tester, find.byType(UiKitPageView));

        await tester.pumpWidget(buildHost(
          identifier: kIdentifier,
          withTopbar: path.withTopbar,
        ));
        await tester.pumpAndSettle();
        final withHook = subtreeTypes(tester, find.byType(UiKitPageView));

        // One node added, and it is the Semantics wrapper.
        expect(withHook.length, withoutHook.length + 1);
        final insertAt = withHook.indexOf('Semantics');
        expect(insertAt, greaterThanOrEqualTo(0));
        expect(withHook[insertAt + 1], 'AppPageView');

        // Removing that one node reproduces the un-hooked tree exactly: no other
        // widget was gained, lost, or reordered.
        expect(
          [...withHook]..removeAt(insertAt),
          withoutHook,
          reason: 'the conditional wrap must be the ONLY difference',
        );

        handle.dispose();
      });
    });
  }
}
