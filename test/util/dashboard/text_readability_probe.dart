import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

/// Measurements for the readability half of the #1183 density work.
///
/// The overflow half belongs to the gate
/// (`test/page/dashboard/cards/dashboard_card_overflow_test.dart`), which asks
/// one question: did a `RenderFlex` report overflow? These helpers answer the
/// questions it structurally cannot — whether text was *truncated* or *wrapped*
/// to make it fit. Both of those leave every gate case green (§2.10d point 3),
/// so any card-own fix that trades characters for space needs assertions from
/// here instead.
///
/// Kept in one place because each readability test file otherwise re-derives
/// them, and [supportedLocaleFor] in particular must not be re-derived: see its
/// own doc for what a locally-written version silently does wrong.
extension TextReadabilityProbe on WidgetTester {
  /// The renderer behind [finder], which must resolve to exactly one `Text`.
  ///
  /// Prefer `find.byWidget(theText)` over `find.text('literal')` when the same
  /// string can appear more than once on the card — `system_status` paints its
  /// gauge readings again in the legend row below, so a literal finder there
  /// matches whichever comes first in tree order.
  RenderParagraph paragraphOf(Finder finder) =>
      renderObject<RenderParagraph>(finder);

  /// Whether the renderer had to drop content to fit.
  ///
  /// `didExceedMaxLines` is the layout's own verdict, so this does not re-derive
  /// metrics that have already been computed.
  bool isTextClipped(Finder finder) => paragraphOf(finder).didExceedMaxLines;

  /// How many lines the text actually painted on, counted off the renderer's own
  /// glyph boxes.
  ///
  /// This is the only measurement that separates "ellipsized onto one line" —
  /// which is sometimes the intended trade — from "wrapped mid-word", because
  /// both leave the widget's `data` intact and both fit inside the box the gate
  /// measures.
  ///
  /// `BoxHeightStyle.max` is load-bearing, not a default worth changing.
  /// `tight` — which this counted with until #1380 — fits each box "per run", and
  /// a run ends wherever font fallback changes the metrics. Vietnamese "Ứng dụng"
  /// is two runs of different heights on one line, so under `tight` its two box
  /// tops differ and one line counts as two: the same false verdict for every
  /// string whose diacritics leave the primary font. `max` gives every box on a
  /// line the line's own height, so the distinct-tops count *is* the line count.
  /// No caller's number went up when this changed — a wrap that was real reports
  /// the same count either way.
  int textLineCount(Finder finder) {
    final paragraph = paragraphOf(finder);
    final plain = paragraph.text.toPlainText();
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: plain.length),
      boxHeightStyle: BoxHeightStyle.max,
    );
    expect(boxes, isNotEmpty, reason: '"$plain" painted no glyphs at all');
    return boxes.map((b) => b.top.round()).toSet().length;
  }

  /// The width, in logical pixels, of the widest whitespace-delimited token in
  /// [finder]'s text, measured in the paragraph's own resolved style.
  ///
  /// Measured rather than read off the renderer because no renderer reports it:
  /// `maxIntrinsicWidth` is the width of the whole string on one line, which is
  /// a much larger number and answers a different question.
  double widestTokenWidth(Finder finder) {
    final paragraph = paragraphOf(finder);
    final style = paragraph.text.style;
    var widest = 0.0;
    for (final token in paragraph.text.toPlainText().split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: token, style: style),
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
      )..layout();
      if (painter.width > widest) widest = painter.width;
    }
    return widest;
  }

  /// Whether a line break inside [finder]'s text fell *inside a token*.
  ///
  /// This is #1288's readability criterion, and it is deliberately narrower than
  /// "the text wrapped". Wrapping at a space is not damage — it is the exact
  /// degradation #1236 AC 4 and #1237 AC 5 chose over an ellipsis, so a test that
  /// forbade it would forbid the fix those tickets shipped. Wrapping inside a
  /// word is: `Ενεργοποιήθ` / `ηκε` is not a word in any locale, and unlike an
  /// ellipsis it does not even signal that something was done to it.
  ///
  /// A token is split exactly when it is wider than the width the paragraph was
  /// given, which is [RenderParagraph]'s own laid-out size — so the comparison is
  /// against the width the production layout actually granted, not a width this
  /// test computed.
  ///
  /// Invisible to the #1183 gate in both directions: a mid-word break makes text
  /// *narrower*, so it can only ever remove overflow (§2.10d point 3).
  bool hasSplitToken(Finder finder) =>
      widestTokenWidth(finder) > paragraphOf(finder).size.width;
}

/// The locale tags whose script writes no spaces between words, so
/// [TextReadabilityProbe.hasSplitToken] carries no information about them.
///
/// The criterion is "did a break fall inside a token", and a token is a
/// whitespace-delimited run — the only definition available to a test, since Flutter
/// exposes no line-break iterator. In Thai, Japanese and Chinese a whole sentence is
/// therefore *one* token, and any sentence long enough to wrap trips the check by
/// construction. The break itself is not damage in those scripts: breaking between
/// characters is how they wrap, which is the opposite of the `Ενεργοποιήθ` / `ηκε`
/// case the criterion was written for.
///
/// So this is an exclusion from one assertion, not from a locale's coverage. Every
/// other measurement still applies to these four — overflow, [isTextClipped] and the
/// line ceiling are all script-independent, and the ceiling is what catches a
/// space-less sentence shredded into eight lines.
///
/// Why it appears only now: until #1380 every guarded string was a title or a chip
/// label, short enough to fit one line in every locale, so no caller had a wrapping
/// space-less string to judge. `firmware_update`'s "your firmware is up to date" is
/// the family's first full sentence. Do not widen this set to make a failure go away
/// — `ko` writes spaces, and `ar` and `he` wrap at spaces like Latin does.
const kLocalesWithoutWordSpaces = <String>{'th', 'ja', 'zh', 'zh_TW'};

/// The supported [Locale] for a `language` or `language_COUNTRY` [tag].
///
/// Resolved against [AppLocalizations.supportedLocales] and **throws** when the
/// tag is not one of them. That is the whole point of the function: parsing the
/// tag into a `Locale` locally always succeeds, and an unsupported locale then
/// falls back to English at load time — so a mistyped tag turns into a test that
/// passes while asserting nothing about the locale it names. A readability suite
/// whose entire value is per-locale coverage cannot afford to fail that way
/// silently.
///
/// Measured rather than assumed. Typing one tag in the `#1236 AC 4` group as
/// `dee` instead of `de`:
///
///   | resolver                                     | result             |
///   |----------------------------------------------|--------------------|
///   | this one                                     | 2 fail, tag named  |
///   | a local `switch` on `tag.split('_')`         | 8 pass             |
///
/// The second row is the version this replaced, and its greenness is the whole
/// argument: the suite reported full coverage of a locale it never rendered.
Locale supportedLocaleFor(String tag) =>
    AppLocalizations.supportedLocales.firstWhere(
      (l) {
        final t = l.countryCode == null || l.countryCode!.isEmpty
            ? l.languageCode
            : '${l.languageCode}_${l.countryCode}';
        return t == tag;
      },
      orElse: () => throw ArgumentError.value(
        tag,
        'tag',
        'not in AppLocalizations.supportedLocales. An unsupported locale loads '
            'the English strings, so this test would have passed without ever '
            'rendering the locale it names',
      ),
    );
