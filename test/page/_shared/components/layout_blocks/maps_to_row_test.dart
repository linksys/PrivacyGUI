@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/text_run_metrics.dart';

/// Behavioural tests for [MapsToRow] (#1247).
///
/// The point of this widget is that the "maps to" arrow is drawn from the ICON
/// font rather than as U+2192. U+2192 has no glyph in the primary font, in any
/// of the nine fallbacks under `assets/fonts/fallback/`, or in the union of all
/// eleven — measured with fontTools. It renders in a browser only because the
/// host resolves a font outside the declared set, which is the dependency those
/// fallbacks exist to remove. So the assertion that matters is not "an arrow is
/// visible" but "no text in this row carries the unmappable codepoint".
///
/// ## One paragraph since #1286
///
/// The pair used to be two [Text]s in a `Row`. It is now a single
/// [AppText.rich] run — `source`, an arrow [WidgetSpan], `target` — because two
/// equal-flex `Flexible`s capped the target at half the row however short the
/// source was. So `find.text(source)` matches nothing here: the paragraph's plain
/// text is the source, U+FFFC for the placeholder, then the target. The helpers
/// below read the one paragraph instead, and locate the operands inside it by
/// offset.
///
/// Tagged `layout-gate`, not `ui`: `run_tests.sh` excludes `ui`, and this
/// guards two gate-probed cards (port_forwarding, firewall_overview).
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  Future<void> pumpMapsTo(
    WidgetTester tester, {
    required String source,
    required String target,
    double width = 400,
    int maxLines = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (c) =>
              CustomDesignTheme.fromJson({'style': 'flat'}),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: MapsToRow(
                source: source,
                target: target,
                maxLines: maxLines,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The single paragraph the row renders as.
  ///
  /// Asserted to be single: a second [Text] inside the row would mean the pair is
  /// back to being laid out in halves, which is the defect #1286 fixed, and every
  /// measurement below would then be reading only one of the two.
  RenderParagraph runOf(WidgetTester tester) {
    final texts = find.descendant(
      of: find.byType(MapsToRow),
      matching: find.byType(Text),
    );
    expect(texts, findsOneWidget,
        reason: 'MapsToRow must render the pair as one paragraph (#1286); '
            'found ${texts.evaluate().length} Texts');
    return tester.renderObject<RenderParagraph>(texts);
  }

  /// The rects [run] paints [text] into, given its [offset] in the plain text.
  ///
  /// Empty rects mean the substring was not drawn at all; rects that do not span
  /// its intrinsic width mean part of it was traded for an ellipsis.
  List<TextBox> boxesFor(RenderParagraph run, int offset, String text) =>
      run.getBoxesForSelection(TextSelection(
        baseOffset: offset,
        extentOffset: offset + text.length,
      ));

  group('the arrow does not depend on a font glyph the app does not ship', () {
    testWidgets('no rendered text contains U+2192', (tester) async {
      await pumpMapsTo(
        tester,
        source: '8080',
        target: '192.168.1.100:80',
      );

      // `data`, not `toPlainText()`, would read null on every `Text.rich` and
      // make this vacuous — which is exactly what it did between #1286's rewrite
      // and this line: three empty strings, none of which contain an arrow.
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .toList();

      expect(texts, isNotEmpty, reason: 'the row must render some text');
      expect(texts.every((t) => t.isNotEmpty), isTrue,
          reason: 'a Text with neither data nor a span cannot be checked for '
              'the codepoint this test exists to forbid: $texts');
      for (final t in texts) {
        expect(t.contains('→'), isFalse,
            reason: 'U+2192 has no glyph in the declared font set: "$t"');
      }
    });

    testWidgets('the arrow is drawn as an icon', (tester) async {
      await pumpMapsTo(tester, source: '8080', target: '192.168.1.100:80');

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('both operands are still rendered', (tester) async {
      await pumpMapsTo(tester,
          source: '3074-3080', target: '192.168.1.50:3074');

      // In document order with the placeholder between them, which is the layout
      // #1286 depends on: the source is what the paragraph lays out first, so it
      // takes its intrinsic width and the target inherits the remainder.
      expect(runOf(tester).text.toPlainText(),
          '3074-3080\u{FFFC}192.168.1.50:3074');
    });
  });

  group('the row survives narrow cards without overflowing', () {
    testWidgets('a long target ellipsizes instead of overflowing',
        (tester) async {
      // A dashboard card at its minimum width is far narrower than this text.
      await pumpMapsTo(
        tester,
        source: '3074-3080',
        target: '192.168.100.100:65535',
        width: 120,
      );

      // Any RenderFlex overflow would have been recorded as an exception.
      expect(tester.takeException(), isNull);

      expect(runOf(tester).size.width, lessThanOrEqualTo(120));
    });

    testWidgets('the source keeps its intrinsic width and the target gives',
        (tester) async {
      // The contract in the docstring, and what two equal-flex `Flexible`s got
      // backwards: the source is a port or range, short and bounded; the target is
      // an IP with an optional port and is not. 120px holds neither pair whole, so
      // this is the width at which the two halves compete.
      const source = '3074-3080';
      const target = '192.168.100.100:65535';
      await pumpMapsTo(tester, source: source, target: target, width: 120);

      final run = runOf(tester);
      final sourceBoxes = boxesFor(run, 0, source);
      expect(sourceBoxes, isNotEmpty,
          reason: 'the source was not painted at all');

      final wanted = intrinsicWidth(run, source);
      final painted = paintedWidth(run, 0, source.length);
      expect(painted, closeTo(wanted, 1.0),
          reason:
              '"$source" was painted ${painted.toStringAsFixed(1)}px of the '
              '${wanted.toStringAsFixed(1)}px it asks for. In one run the source '
              'is laid out first and takes its intrinsic width; a shortfall means '
              'it is being allocated a share of the row again (#1286).');
    });

    testWidgets('the icon is never squeezed out by long operands',
        (tester) async {
      await pumpMapsTo(
        tester,
        source: 'Trigger: 3074-3080 TCP',
        target: 'Forward: 1024-1030 TCP',
        width: 140,
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });

  group('a second line, where the caller has one to give', () {
    // `maxLines` exists because the operands are machine-generated and unbounded
    // above, so a caller that owns its whole row can stop trading glyphs for an
    // ellipsis. What makes it worth having is *where* the break lands: the arrow
    // is a `WidgetSpan`, i.e. U+FFFC, which UAX #14 treats as a contingent break,
    // so the second line starts at the target instead of mid-token. Without that
    // the extra line would only buy a scrambled IP, and the firewall card's Ports
    // tab (`_kMappingInlineMinWidth`) relies on it being a whole one.
    const source = '3074-3080';
    const target = '192.168.100.100:65535';

    testWidgets('the target that would ellipsize is drawn whole on line two',
        (tester) async {
      await pumpMapsTo(tester,
          source: source, target: target, width: 150, maxLines: 2);

      final run = runOf(tester);
      final boxes = boxesFor(run, source.length + 1, target);
      expect(boxes, isNotEmpty, reason: 'the target was not painted at all');

      expect(run.didExceedMaxLines, isFalse,
          reason:
              'the pair still did not fit in two lines at 150px, so this is '
              'not measuring what the second line bought');

      final tops = boxes.map((b) => b.top).toSet();
      expect(tops, hasLength(1),
          reason: 'the target is split across ${tops.length} lines — the break '
              'landed inside it rather than at the arrow, which turns an '
              'ellipsized IP into a scrambled one (#1286)');

      final wanted = intrinsicWidth(run, target);
      final painted = paintedWidth(
          run, source.length + 1, source.length + 1 + target.length);
      expect(painted, closeTo(wanted, 1.0),
          reason:
              '"$target" was painted ${painted.toStringAsFixed(1)}px of the '
              '${wanted.toStringAsFixed(1)}px it asks for, so the second line was '
              'taken and the target was still cut (#1286)');
    });

    testWidgets('one line is still one line when the pair fits',
        (tester) async {
      // The cost is paid per row that needs it, not per row that is allowed it.
      await pumpMapsTo(tester,
          source: source, target: target, width: 400, maxLines: 2);

      final oneLine = runOf(tester).size.height;

      await pumpMapsTo(tester,
          source: source, target: target, width: 150, maxLines: 2);

      expect(runOf(tester).size.height, greaterThan(oneLine),
          reason:
              'the narrow case must be the taller one, or the two widths are '
              'not exercising the wrap at all');
    });
  });
}
