@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

Widget _wrap(Widget child) => MaterialApp(
      theme: _testTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SizedBox(width: 800, child: child)),
    );

void main() {
  group('ServiceErrorView', () {
    testWidgets('shows title, localized error detail, and retry when error set',
        (tester) async {
      await tester.pumpWidget(_wrap(ServiceErrorView(
        error: const NetworkError(),
        onRetry: () {},
      )));
      await tester.pumpAndSettle();

      final en = lookupAppLocalizations(const Locale('en'));
      expect(find.text(en.failedToLoadSettings), findsOneWidget);
      // NetworkError → errorNetwork (the localized detail line).
      expect(find.text(en.errorNetwork), findsOneWidget);
      expect(find.text(en.retry), findsOneWidget);
    });

    testWidgets('hides the detail line when error is null', (tester) async {
      await tester.pumpWidget(_wrap(ServiceErrorView(
        error: null,
        onRetry: () {},
      )));
      await tester.pumpAndSettle();

      final en = lookupAppLocalizations(const Locale('en'));
      // Title + retry still render; no error-detail strings present.
      expect(find.text(en.failedToLoadSettings), findsOneWidget);
      expect(find.text(en.retry), findsOneWidget);
      expect(find.text(en.errorNetwork), findsNothing);
      expect(find.text(en.errorUnexpected), findsNothing);
    });

    testWidgets('invokes onRetry when the retry button is tapped',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(ServiceErrorView(
        error: const ResourceNotFoundError(),
        onRetry: () => tapped++,
      )));
      await tester.pumpAndSettle();

      final en = lookupAppLocalizations(const Locale('en'));
      await tester.tap(find.text(en.retry));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });

    testWidgets('does not show a secondary action by default', (tester) async {
      await tester.pumpWidget(_wrap(ServiceErrorView(
        error: const NetworkError(),
        onRetry: () {},
      )));
      await tester.pumpAndSettle();

      final en = lookupAppLocalizations(const Locale('en'));
      expect(find.text(en.logout), findsNothing);
    });

    testWidgets('shows and invokes the secondary action when provided',
        (tester) async {
      var secondary = 0;
      await tester.pumpWidget(_wrap(ServiceErrorView(
        error: const NetworkError(),
        onRetry: () {},
        secondaryLabel: lookupAppLocalizations(const Locale('en')).logout,
        onSecondary: () => secondary++,
      )));
      await tester.pumpAndSettle();

      final en = lookupAppLocalizations(const Locale('en'));
      expect(find.text(en.logout), findsOneWidget);
      await tester.tap(find.text(en.logout));
      await tester.pumpAndSettle();

      expect(secondary, 1);
    });
  });
}
