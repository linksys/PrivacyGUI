import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

import '../common/screen.dart';
import '../common/test_responsive_widget.dart';
import '../common/theme_data.dart';
import 'gate.dart';

/// Matches a [Finder] whose text is fully shown (constitution 3.4): no
/// `maxLines` or ellipsis cuts it, it fits its box, and no ancestor clips
/// it, a scroll view and the screen edge included.
///
/// It does not check the size the text is drawn at, so a value a
/// `FittedBox` shrinks passes however small it gets.
const Matcher isFullyShown = _FullyShown();

/// The narrowest mobile and desktop pages: the gate's floor, and
/// [ResponsiveLayout.large], where the desktop content box is narrowest
/// ([requiredGateWidths]).
final List<ScreenSize> narrowestScreens = [
  for (final width in [gateScreens.first.width, ResponsiveLayout.large])
    ScreenSize('${width.toInt()}', width, 900, 1),
];

/// Declares a readability guard (constitution 3.4): a test for every locale
/// at each of [screens], in which [pump] lays a page out and every one of
/// [values] is fully shown once scrolled to. A failure names each value that
/// is cut.
@isTest
void testFullyShown(
  String page, {
  required Map<String, Finder> values,
  required Future<void> Function(WidgetTester tester, Locale locale) pump,
  List<ScreenSize>? screens,
}) {
  for (final screen in screens ?? narrowestScreens) {
    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets(
          '$page shows ${values.keys.join(', ')} in full at ${screen.name} '
          'in ${locale.toLanguageTag()}', (tester) async {
        await loadTestFonts();
        await tester.setScreenSize(screen);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pump(tester, locale);
        await tester.pumpAndSettle();

        expect(await cutValues(tester, values), isEmpty);
      });
    }
  }
}

/// The ones of [values] that are not fully shown once scrolled to, each as
/// `name: why`. A finder skips what a scroll view holds out of view unless
/// it is made with `skipOffstage: false`.
Future<List<String>> cutValues(
    WidgetTester tester, Map<String, Finder> values) async {
  final cut = <String>[];
  for (final MapEntry(key: name, value: finder) in values.entries) {
    final count = finder.evaluate().length;
    if (count == 0) cut.add('$name: no text is there');
    for (var i = 0; i < count; i++) {
      await tester.ensureVisible(finder.at(i));
      await tester.pumpAndSettle();
      final why = _whyCut(finder.at(i).evaluate().single);
      if (why != null) cut.add('$name: $why');
    }
  }
  return cut;
}

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
    final (plainText, didExceedMaxLines) = switch (node) {
      RenderParagraph() => (node.text.toPlainText(), node.didExceedMaxLines),
      RenderEditable() => (node.plainText, false),
      _ => (null, false),
    };
    if (plainText != null) {
      // Only the runs that are not whitespace: the space a line breaks at
      // may hang past the box, and a space is not cut.
      final boxes = [
        for (final run in _visible(plainText))
          ...switch (node) {
            RenderParagraph() => node.getBoxesForSelection(run),
            RenderEditable() => node.getBoxesForSelection(run),
            _ => const <TextBox>[],
          },
      ];
      return _TextLayout(node as RenderBox, plainText, _rects(boxes),
          didExceedMaxLines: didExceedMaxLines);
    }
    _TextLayout? found;
    node.visitChildren((child) => found ??= find(child));
    return found;
  }

  static Iterable<TextSelection> _visible(String text) =>
      RegExp(r'\S+').allMatches(text).map(
          (run) => TextSelection(baseOffset: run.start, extentOffset: run.end));

  static List<Rect> _rects(List<TextBox> boxes) =>
      boxes.map((box) => box.toRect()).toList();
}
