import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/widgets/app_bar/app_bar.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';

const _box = Key('box');
const _text = Key('text');
const _column = Key('column');
const _footer = Key('footer');

/// How a scrolling page lays out its content without IntrinsicHeight (#1864).
void main() {
  // The top bar reads its theme from get_it.
  mockDependencyRegister();

  Future<void> pumpPage(
    WidgetTester tester, {
    double width = 800,
    required double height,
    required bool scrollable,
    PageMenu? menu,
    required Widget content,
  }) async {
    // The view, not the surface: the page reads its layout (mobile or
    // desktop) from MediaQuery, which follows the view.
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [accessPolicyProvider.overrideWithValue(AccessPolicy.full)],
      child: StyledAppPageView(
        title: 'Settings',
        scrollable: scrollable,
        menu: menu,
        child: (context, constraints) => content,
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// The part of the window under the app bar.
  Rect pageBelowAppBar(WidgetTester tester) {
    final appBar = tester.getRect(find.byType(LinksysAppBar));
    final window = Offset.zero & tester.binding.renderView.size;
    return Rect.fromLTRB(
        window.left, appBar.bottom, window.right, window.bottom);
  }

  group('A scrolling page', () {
    testWidgets('centres short content in the rest of the page',
        (tester) async {
      // What IntrinsicHeight gave a short page: its content gets the rest of
      // the page under the app bar, so a Center centres in it.
      await pumpPage(
        tester,
        height: 600,
        scrollable: true,
        content:
            const Center(child: SizedBox(key: _box, width: 100, height: 100)),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getCenter(find.byKey(_box)).dy,
          pageBelowAppBar(tester).center.dy);
    });

    testWidgets('keeps the footer of a short page at the bottom',
        (tester) async {
      // AppBasicLayout's content takes the rest of a short page, so its
      // footer sits at the bottom, as it did under IntrinsicHeight.
      await pumpPage(
        tester,
        height: 600,
        scrollable: true,
        content: const AppBasicLayout(
          header: SizedBox(height: 40),
          content: SizedBox(height: 50),
          footer: SizedBox(key: _footer, height: 40),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byKey(_footer)).bottom,
          pageBelowAppBar(tester).bottom - Spacing.small3);
    });

    testWidgets('centres short content beside the menu on desktop',
        (tester) async {
      // On desktop the menu sits in the same row as the content, and the
      // content still gets the rest of the page.
      await pumpPage(
        tester,
        width: 1280,
        height: 600,
        scrollable: true,
        menu: PageMenu(
          title: 'Menu',
          items: [PageMenuItem(label: 'Menu item', icon: null)],
        ),
        content:
            const Center(child: SizedBox(key: _box, width: 100, height: 100)),
      );

      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.byKey(_box));
      expect(
          box.left, greaterThan(tester.getRect(find.text('Menu item')).right));
      expect(box.center.dy, pageBelowAppBar(tester).center.dy);
    });

    testWidgets('lays out a column-width box at the height its text needs',
        (tester) async {
      // #1864: the case IntrinsicHeight got wrong. The text is taller than
      // the window, so the page scrolls instead of overflowing.
      await pumpPage(
        tester,
        height: 300,
        scrollable: true,
        content: AppBasicLayout(
          content: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              child: Column(
                key: _column,
                children: [
                  Text('word ' * 120,
                      key: _text, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final textHeight = tester.getSize(find.byKey(_text)).height;
      expect(textHeight, greaterThan(300));
      expect(tester.getSize(find.byKey(_column)).height, textHeight);
    });
  });

  group('A page that does not scroll', () {
    testWidgets('gives its content the rest of the page', (tester) async {
      await pumpPage(
        tester,
        height: 600,
        scrollable: false,
        content: Column(
          children: [Expanded(child: Container(key: _box))],
        ),
      );

      expect(tester.takeException(), isNull);
      final page = pageBelowAppBar(tester);
      final box = tester.getRect(find.byKey(_box));
      expect(box.top, page.top);
      expect(box.bottom, page.bottom);
    });
  });
}
