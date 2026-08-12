@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../util/app_test_fonts.dart';

/// Behavioural tests for [UspInfoRow] label sizing (#1231, T13).
///
/// The label column must be sized from the width the ROW is actually given,
/// not from the screen width. Inside a shrunken dashboard card the two are
/// unrelated: a screen-derived label over-claims the column and the value is
/// silently clipped by the card surface with no RenderFlex overflow raised —
/// which is why the overflow gate cannot see this class of bug and these
/// assertions have to exist separately.
///
/// Every case pumps on a WIDE surface and constrains only the row, so a
/// screen-derived width cannot accidentally pass.
///
/// Real fonts are loaded on purpose. Under the default test font every glyph
/// is a fixed-width block, so "does this text fit on one line" would be
/// measured against fictional widths and the fit assertions below would be
/// meaningless.
///
/// Tagged `dashboard-card`, not `ui`: `run_tests.sh` excludes `ui`, so a `ui`
/// tag here would keep the regression this file guards out of the PR gate.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  const wideSurface = Size(1400, 800);

  Future<void> pumpRow(
    WidgetTester tester, {
    required double rowWidth,
    String label = 'IP Address',
    String value = '255.255.255.255',
  }) async {
    await tester.binding.setSurfaceSize(wideSurface);
    tester.view.physicalSize = wideSurface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
              width: rowWidth,
              child: UspInfoRow(label: label, value: value),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  RenderParagraph paragraphOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text));

  /// Whether the text rendered on a single line — the honest measure of "did
  /// this wrap". Compares the height it actually got against the height it
  /// takes at unbounded width, which is by definition one line.
  bool isSingleLine(WidgetTester tester, String text) {
    final paragraph = paragraphOf(tester, text);
    final oneLine = paragraph.getMinIntrinsicHeight(double.infinity);
    return paragraph.size.height <= oneLine + 0.5;
  }

  double labelColumnWidth(WidgetTester tester) {
    final box = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(UspInfoRow),
        matching: find.byType(SizedBox),
      ),
    );
    return box.width!;
  }

  group('the label column is derived from the row, not the screen', () {
    testWidgets('a narrower row yields a narrower label column',
        (tester) async {
      // The surface is 1400px in both pumps. Were the column screen-derived,
      // these two would be identical.
      await pumpRow(tester, rowWidth: 191);
      final narrow = labelColumnWidth(tester);

      await pumpRow(tester, rowWidth: 300);
      final wider = labelColumnWidth(tester);

      expect(narrow, lessThan(wider),
          reason: 'label column must track the row width, not the surface');
    });

    testWidgets('the column stops growing once it is wide enough',
        (tester) async {
      // Without a ceiling a wide row opens an ever-growing gutter before the
      // value. Asserted as "equal at two wide widths" rather than against the
      // constant, so the test pins the behaviour and not the number.
      await pumpRow(tester, rowWidth: 600);
      final atSixHundred = labelColumnWidth(tester);

      await pumpRow(tester, rowWidth: 900);
      final atNineHundred = labelColumnWidth(tester);

      expect(atNineHundred, equals(atSixHundred));
    });
  });

  group('the value is the payload — it never wraps at a real card width', () {
    // 191px and 288px are the narrowest and the common realizations the
    // overflow gate pumps for dashboard cards.
    for (final rowWidth in <double>[191, 288, 480]) {
      testWidgets('value renders on one line at ${rowWidth.toInt()}px',
          (tester) async {
        await pumpRow(tester, rowWidth: rowWidth);
        expect(isSingleLine(tester, '255.255.255.255'), isTrue,
            reason: 'the value must not be squeezed into a wrapped column');
      });
    }

    testWidgets('value is not ellipsized either', (tester) async {
      // Guards the other half of the degradation shape: the value must never
      // grow a maxLines/ellipsis, because a half-shown statistic misinforms in
      // a way a clipped label does not.
      await pumpRow(tester, rowWidth: 191);
      expect(paragraphOf(tester, '255.255.255.255').didExceedMaxLines, isFalse);
    });
  });

  group('the label yields first, by ellipsis rather than by wrapping', () {
    testWidgets('a label that fits stays on one line at 288px', (tester) async {
      // Regression guard: sizing the column as a flat fraction of the row gave
      // the label 48px here, wrapping "IP Address" onto a second line and
      // doubling the row height at a width the product actually ships.
      await pumpRow(tester, rowWidth: 288);
      expect(isSingleLine(tester, 'IP Address'), isTrue);
      expect(paragraphOf(tester, 'IP Address').didExceedMaxLines, isFalse);
    });

    testWidgets('a label too long for the column ellipsizes, never wraps',
        (tester) async {
      const long = 'Operating Frequency Band';
      await pumpRow(tester, rowWidth: 191, label: long, value: '5 GHz');

      expect(isSingleLine(tester, long), isTrue,
          reason: 'a wrapped label grows the row without adding information');
      expect(paragraphOf(tester, long).didExceedMaxLines, isTrue,
          reason: 'this label cannot fit — it must be visibly truncated');
      expect(isSingleLine(tester, '5 GHz'), isTrue);
    });
  });
}
