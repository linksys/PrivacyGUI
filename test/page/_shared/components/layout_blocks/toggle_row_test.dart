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

  /// The single paragraph a [MapsToRow] subtitle renders as.
  ///
  /// Since #1286 the pair is one [AppText.rich] run rather than two [Text]s in a
  /// `Row`, so `find.text('8080')` matches nothing here: the paragraph's plain
  /// text is the source, U+FFFC for the arrow placeholder, then the target.
  Text mapsToText(WidgetTester tester) {
    final texts = find.descendant(
      of: find.byType(MapsToRow),
      matching: find.byType(Text),
    );
    expect(texts, findsOneWidget,
        reason: 'MapsToRow renders the pair as one paragraph (#1286); '
            'found ${texts.evaluate().length} Texts');
    return tester.widget<Text>(texts);
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
      expect(mapsToText(tester).textSpan?.toPlainText(),
          '8080\u{FFFC}192.168.1.100:80');
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
      // AppListTile wraps its subtitle in a DefaultTextStyle but no IconTheme,
      // and AppIcon's own chain ends at `IconTheme.of(context).color ??
      // Colors.black` — so an arrow next to this text could render black against
      // the tile's content colour. #1286 moved who closes that gap: MapsToRow used
      // to resolve one colour and hand it to both children, and now [AppText.rich]
      // publishes its resolved colour as an IconTheme around the paragraph, which
      // the WidgetSpan'd arrow inherits. The assertion is the same either way, and
      // it is the reason MapsToRow can leave the arrow colourless.
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
      // On the rich path the resolved style rides on the root span, not on the
      // widget — `mapsToText(tester).style` is null here.
      final textColor = mapsToText(tester).textSpan?.style?.color;

      expect(textColor, isNotNull,
          reason: 'AppText.rich resolves a colour onto the root span and '
              'publishes the same one as an IconTheme; a null here means there '
              'was nothing for the arrow to agree with');
      expect(icon.color, isNotNull);
      expect(icon.color, equals(textColor));
    });
  });
}
