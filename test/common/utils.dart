import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the onTap handler for the [TextSpan] which matches the search-string.
void fireOnTapByIndex(Finder finder, int index) {
  final Element element = finder.evaluate().single;
  final RenderParagraph paragraph = element.renderObject as RenderParagraph;
  // The children are the individual TextSpans which have GestureRecognizers
  int current = 0;
  paragraph.text.visitChildren((dynamic span) {
    if (span.recognizer == null) return true;
    if (current == index) {
      (span.recognizer as TapGestureRecognizer).onTap?.call();
      return false; // stop iterating, we found the one.
    } else {
      current++;
      return true;
    }
  });
}

void fireOnTap(Finder finder, String text) {
  final Element element = finder.evaluate().single;
  final RenderParagraph paragraph = element.renderObject as RenderParagraph;
  // The children are the individual TextSpans which have GestureRecognizers
  paragraph.text.visitChildren((dynamic span) {
    if (span.text != text) return true; // continue iterating.

    (span.recognizer as TapGestureRecognizer).onTap?.call();
    return false; // stop iterating, we found the one.
  });
}

Future<void> scrollUntil(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  // Scroll to the finder if it is not visible
  if (!tester.any(finder.hitTestable())) {
    await scrollUntil(tester, finder);
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
