import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Measurement helpers for asserting on a laid-out [RenderParagraph].
///
/// Extracted from `firewall_overview_readability_test.dart` when
/// `maps_to_row_test.dart` needed the same three functions, and needed them for
/// the same reason: since #1286 a `MapsToRow` is one paragraph with the operands
/// as spans inside it, so "did this string render whole" is a question about a
/// substring of a run rather than about a whole [Text].
///
/// The trap these exist to avoid is [operandStyle]'s — reading
/// `paragraph.text.style` measures the *container's* typeface, not the one the
/// glyphs were drawn in, and every width comes out wrong by the ratio between
/// them. Two separate tests hit it independently before this file existed.

/// Width of the glyphs between two character offsets, read off [paragraph]'s
/// own boxes.
///
/// Not a re-measurement: the question is what a span was *given*, and only the
/// laid-out paragraph knows that. Taken as outermost-right minus outermost-left
/// rather than as a sum of box widths, so a range that shapes into several boxes
/// still reports one extent.
double paintedWidth(RenderParagraph paragraph, int start, int end) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  if (boxes.isEmpty) return 0;
  return boxes.map((b) => b.right).reduce(math.max) -
      boxes.map((b) => b.left).reduce(math.min);
}

/// The style the glyphs in [paragraph] are actually drawn in.
///
/// Not `paragraph.text.style`. A [Text] merges the ambient [DefaultTextStyle]
/// onto its own root span and hangs the caller's content underneath, so on the
/// rich path — where the caller's style rides on the span it passed down rather
/// than on the widget — the root carries the *container's* style and the run
/// carries the real one. Measured on the firewall card's Ports tab: the root says
/// 14px while `AppText.rich`'s resolved `bodySmall` draws the operands at 12px, so
/// reading the root over-measures every operand by 14/12 and a "did it get its
/// intrinsic width" check fails by exactly that ratio.
///
/// Walks first-children down and merges each style it meets, which is the
/// inheritance the paragraph itself applies. On the plain path the loop stops at
/// the root and this is `paragraph.text.style` unchanged.
TextStyle operandStyle(RenderParagraph paragraph) {
  var style = paragraph.text.style ?? const TextStyle();
  InlineSpan? span = paragraph.text;
  while (span is TextSpan && (span.children?.isNotEmpty ?? false)) {
    span = span.children!.first;
    if (span is TextSpan && span.style != null) {
      style = style.merge(span.style);
    }
  }
  return style;
}

/// What [text] asks for, in the style [paragraph] draws it in.
double intrinsicWidth(RenderParagraph paragraph, String text) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: operandStyle(paragraph)),
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
  )..layout();
  final width = painter.maxIntrinsicWidth;
  painter.dispose();
  return width;
}
