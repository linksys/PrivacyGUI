import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/mascot/widgets/mascot_toolbar.dart';

/// Wraps [child] with localization delegates so widgets that call loc(context)
/// can resolve AppLocalizations in tests.
Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('MascotToolbar', () {
    testWidgets('renders all default buttons', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MascotToolbar(iconColor: Colors.black),
        ),
      );

      expect(find.byIcon(Icons.print), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      // Theme studio hidden by default
      expect(find.byIcon(Icons.palette), findsNothing);
    });

    testWidgets('shows theme studio when enabled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MascotToolbar(
            iconColor: Colors.black,
            showThemeStudio: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.palette), findsOneWidget);
    });

    testWidgets('calls onAction when print tapped', (tester) async {
      MascotToolbarAction? tappedAction;

      await tester.pumpWidget(
        _wrap(
          MascotToolbar(
            iconColor: Colors.black,
            onAction: (action) => tappedAction = action,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.print));
      await tester.pump();

      expect(tappedAction, MascotToolbarAction.print);
    });

    testWidgets('calls onAction when FAQ tapped', (tester) async {
      MascotToolbarAction? tappedAction;

      await tester.pumpWidget(
        _wrap(
          MascotToolbar(
            iconColor: Colors.black,
            onAction: (action) => tappedAction = action,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pump();

      expect(tappedAction, MascotToolbarAction.faq);
    });

    testWidgets('calls onAction when AI Assistant tapped', (tester) async {
      MascotToolbarAction? tappedAction;

      await tester.pumpWidget(
        _wrap(
          MascotToolbar(
            iconColor: Colors.black,
            onAction: (action) => tappedAction = action,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();

      expect(tappedAction, MascotToolbarAction.aiAssistant);
    });
  });
}
