import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/layouts/center_or_scroll.dart';

/// Pumps a [CenterOrScroll] holding a [childHeight] tall box, in a 400 x
/// 300 space, and returns the box's top edge.
Future<double> pumpChild(WidgetTester tester, double childHeight) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 400,
          height: 300,
          child: CenterOrScroll(
            child: SizedBox(key: const Key('child'), height: childHeight),
          ),
        ),
      ),
    ),
  );
  return tester.getTopLeft(find.byKey(const Key('child'))).dy -
      tester.getTopLeft(find.byType(CenterOrScroll)).dy;
}

void main() {
  testWidgets('centers a child shorter than the space', (tester) async {
    expect(await pumpChild(tester, 100), 100);
  });

  testWidgets('scrolls a child taller than the space, without overflow',
      (tester) async {
    // A scrollable page view sizes the page by its intrinsic height, which a
    // column-width SizedBox under-reports, so the page overflowed (#1802).
    // This one asks for no intrinsic size.
    expect(await pumpChild(tester, 500), 0);
    expect(tester.takeException(), isNull);

    // Past the end: the page bounces back and settles there.
    await tester.drag(find.byType(CenterOrScroll), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(
      tester.getBottomLeft(find.byKey(const Key('child'))).dy,
      tester.getBottomLeft(find.byType(CenterOrScroll)).dy,
    );
  });
}
