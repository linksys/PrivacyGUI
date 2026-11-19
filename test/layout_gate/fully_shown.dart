import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matches a [Finder] whose text is fully shown. Constitution 3.4.
const Matcher isFullyShown = _FullyShown();

/// How far a glyph may sit past a side before it counts as cut, for the
/// rounding in text layout.
const double _tolerancePx = 0.5;

class _FullyShown extends Matcher {
  const _FullyShown();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    final elements = (item as Finder).evaluate();
    final why = elements.isEmpty
        ? 'no text is there'
        : elements.map(_whyCut).whereType<String>().firstOrNull;
    if (why == null) return true;
    matchState[#why] = why;
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('text that is fully shown');

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
          Map<dynamic, dynamic> matchState, bool verbose) =>
      mismatchDescription.add(matchState[#why] as String);
}

/// Why [element]'s text is not fully shown, or null when it is.
String? _whyCut(Element element) {
  final text = _TextLayout.find(element.renderObject!);
  if (text == null) return 'it has no text render object';
  final quoted = '"${text.plainText}"';
  if (text.didExceedMaxLines) {
    return '$quoted is cut by maxLines or an ellipsis';
  }
  final box = Offset.zero & text.box.size;
  if (!text.glyphs.every((glyph) => _shows(box, glyph))) {
    return '$quoted needs ${_size(text.extent.size)} '
        'but its box is ${_size(box.size)}';
  }
  final shown = _shownRect(text.box);
  final toGlobal = text.box.getTransformTo(null);
  final glyphs =
      text.glyphs.map((glyph) => MatrixUtils.transformRect(toGlobal, glyph));
  if (!glyphs.every((glyph) => _shows(shown, glyph))) {
    final extent = MatrixUtils.transformRect(toGlobal, text.extent);
    return '$quoted is clipped to $shown, and its glyphs are at $extent';
  }
  return null;
}

String _size(Size size) =>
    '${size.width.toStringAsFixed(1)}×${size.height.toStringAsFixed(1)}';

/// Whether [area] shows [glyph]: all of its width, and the middle of its
/// height. A font's glyphs can reach past the line they set, as Arabic's and
/// Thai's do, so a line counts as shown when its middle is.
bool _shows(Rect area, Rect glyph) =>
    glyph.left >= area.left - _tolerancePx &&
    glyph.right <= area.right + _tolerancePx &&
    glyph.center.dy >= area.top &&
    glyph.center.dy <= area.bottom;

/// The part of the screen that [node]'s ancestors let it paint into, in
/// global coordinates.
Rect _shownRect(RenderObject node) {
  var shown = Rect.largest;
  var child = node;
  for (var parent = child.parent; parent != null; parent = parent.parent) {
    // The clip is in the parent's coordinates.
    final clip = parent.describeApproximatePaintClip(child);
    if (clip != null) {
      shown = shown.intersect(
          MatrixUtils.transformRect(parent.getTransformTo(null), clip));
    }
    child = parent;
  }
  if (child is RenderView) shown = shown.intersect(Offset.zero & child.size);
  return shown;
}

/// A text's render object, and where it draws its glyphs.
class _TextLayout {
  _TextLayout(this.box, this.plainText, this.glyphs,
      {required this.didExceedMaxLines});

  final RenderBox box;

  final String plainText;

  /// Where the glyphs are drawn, one rect for each run of a line, in [box]'s
  /// coordinates. A [RenderEditable] that scrolls its text includes the
  /// scroll.
  final List<Rect> glyphs;

  Rect get extent => glyphs.isEmpty
      ? Rect.zero
      : glyphs.reduce((extent, glyph) => extent.expandToInclude(glyph));

  /// Whether `maxLines` or an ellipsis cut the text.
  final bool didExceedMaxLines;

  /// The first text render object at or below [node]: a [RenderParagraph]
  /// for a `Text`, a [RenderEditable] for a `SelectableText`.
  static _TextLayout? find(RenderObject node) {
    if (node is RenderParagraph) {
      final plainText = node.text.toPlainText();
      return _TextLayout(
          node, plainText, _rects(node.getBoxesForSelection(_all(plainText))),
          didExceedMaxLines: node.didExceedMaxLines);
    }
    if (node is RenderEditable) {
      final plainText = node.plainText;
      return _TextLayout(
          node, plainText, _rects(node.getBoxesForSelection(_all(plainText))),
          didExceedMaxLines: false);
    }
    _TextLayout? found;
    node.visitChildren((child) => found ??= find(child));
    return found;
  }

  static TextSelection _all(String text) =>
      TextSelection(baseOffset: 0, extentOffset: text.length);

  static List<Rect> _rects(List<TextBox> boxes) =>
      boxes.map((box) => box.toRect()).toList();
}
