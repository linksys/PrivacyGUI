@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';

/// Tests for [ToggleRow]'s two subtitle channels (#1247).
///
/// [ToggleRow] grew a `subtitleContent` [Widget] alongside its String
/// `subtitle` so that port-forwarding rows could render a [MapsToRow]. The two
/// are mutually exclusive, and nothing else in the suite exercised either
/// channel — so a reversal of the selection logic would have gone unnoticed.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  Future<void> pumpToggleRow(WidgetTester tester, ToggleRow row) async {
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
        home: Scaffold(body: row),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('subtitle channels are mutually exclusive', () {
    testWidgets('a String subtitle renders as text', (tester) async {
      await pumpToggleRow(
        tester,
        ToggleRow(
          value: true,
          title: 'HTTP',
          subtitle: 'TCP 8080',
        ),
      );

      expect(find.text('TCP 8080'), findsOneWidget);
      expect(find.byType(MapsToRow), findsNothing);
    });

    testWidgets('subtitleContent renders the widget instead', (tester) async {
      await pumpToggleRow(
        tester,
        ToggleRow(
          value: true,
          title: 'HTTP',
          subtitleContent: MapsToRow(
            source: '8080',
            target: '192.168.1.100:80',
          ),
        ),
      );

      expect(find.byType(MapsToRow), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('8080'), findsOneWidget);
      expect(find.text('192.168.1.100:80'), findsOneWidget);
    });

    testWidgets('passing both is a programming error', (tester) async {
      expect(
        () => ToggleRow(
          value: true,
          title: 'HTTP',
          subtitle: 'TCP 8080',
          subtitleContent: MapsToRow(source: '8080', target: '10.0.0.1'),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('neither channel renders no subtitle', (tester) async {
      await pumpToggleRow(
        tester,
        ToggleRow(value: false, title: 'HTTP'),
      );

      expect(find.text('HTTP'), findsOneWidget);
      expect(find.byType(MapsToRow), findsNothing);
    });
  });

  group('the arrow in a subtitle tracks the surrounding text colour', () {
    testWidgets('an unstyled MapsToRow does not fall back to black',
        (tester) async {
      // AppListTile wraps its subtitle in a DefaultTextStyle but no IconTheme.
      // Without resolving one colour for both, AppIcon would land on its own
      // fallback chain and could render black against the tile's content
      // colour. Asserting they match is what pins that behaviour down.
      await pumpToggleRow(
        tester,
        ToggleRow(
          value: true,
          title: 'HTTP',
          subtitleContent: MapsToRow(
            source: '8080',
            target: '192.168.1.100:80',
          ),
        ),
      );

      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(MapsToRow),
          matching: find.byIcon(Icons.arrow_forward),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(MapsToRow),
          matching: find.text('8080'),
        ),
      );

      final textColor = text.style?.color ??
          DefaultTextStyle.of(tester.element(find.text('8080'))).style.color;

      expect(icon.color, isNotNull);
      expect(icon.color, equals(textColor));
    });
  });
}
