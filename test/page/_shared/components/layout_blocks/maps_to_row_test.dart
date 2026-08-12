@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';

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
/// Tagged `dashboard-card`, not `ui`: `run_tests.sh` excludes `ui`, and this
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
              child: MapsToRow(source: source, target: target),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the arrow does not depend on a font glyph the app does not ship', () {
    testWidgets('no rendered text contains U+2192', (tester) async {
      await pumpMapsTo(
        tester,
        source: '8080',
        target: '192.168.1.100:80',
      );

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();

      expect(texts, isNotEmpty, reason: 'the row must render some text');
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

      expect(find.text('3074-3080'), findsOneWidget);
      expect(find.text('192.168.1.50:3074'), findsOneWidget);
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

      final target = tester.renderObject<RenderParagraph>(
        find.text('192.168.100.100:65535'),
      );
      expect(target.size.width, lessThanOrEqualTo(120));
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
}
