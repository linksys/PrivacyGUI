import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

// A save whose write landed must not report itself as a failed save (#1212):
// the user would press Save again and rewrite what the router already holds.

void main() {
  Future<BuildContext> pump(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: Builder(builder: (c) {
        captured = c;
        return const SizedBox();
      })),
    ));
    return captured;
  }

  Color? surfaceColor(WidgetTester tester) =>
      tester.widget<AppSurface>(find.byType(AppSurface)).style?.backgroundColor;

  testWidgets(
      'a write that landed is reported as saved-but-unconfirmed, '
      'not in the failure style', (tester) async {
    final ctx = await pump(tester);
    final danger = Theme.of(ctx).extension<AppColorScheme>()?.semanticDanger;

    showSaveErrorSnackBar(ctx, const SavedButUnconfirmedError(NetworkError()));
    await tester.pump();

    expect(find.text(loc(ctx).errorSavedButUnconfirmed), findsOneWidget);
    expect(surfaceColor(tester), isNot(danger));
  });

  // PR #1716 review: the reload-instead-of-write path wrote nothing, so it is
  // a failed save to the user, not the neutral "saved" style.
  testWidgets('a save discarded for the router\'s rows is a failure, not saved',
      (tester) async {
    final ctx = await pump(tester);
    final danger = Theme.of(ctx).extension<AppColorScheme>()?.semanticDanger;

    showSaveErrorSnackBar(ctx, const SaveDiscardedForRouterRowsError());
    await tester.pump();

    expect(find.text(loc(ctx).errorSaveDiscardedForRouterRows), findsOneWidget);
    expect(surfaceColor(tester), danger);
  });

  testWidgets('a failed write is still reported in the failure style',
      (tester) async {
    final ctx = await pump(tester);
    final danger = Theme.of(ctx).extension<AppColorScheme>()?.semanticDanger;

    showSaveErrorSnackBar(ctx, const NetworkError());
    await tester.pump();

    expect(find.text(loc(ctx).errorNetwork), findsOneWidget);
    expect(surfaceColor(tester), danger);
  });
}
