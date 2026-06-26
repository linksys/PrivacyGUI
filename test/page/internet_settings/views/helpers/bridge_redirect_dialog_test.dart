import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/internet_settings/views/helpers/bridge_redirect_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({
    'style': 'flat',
  }),
);

Widget _harness({required void Function(String) navigate}) {
  return MaterialApp(
    theme: _testTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showBridgeRedirectDialog(
            context,
            hostName: 'Community00080',
            navigate: navigate,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the .local management address', (tester) async {
    await tester.pumpWidget(_harness(navigate: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('https://Community00080.local'),
      findsWidgets,
    );
  });

  testWidgets('go button navigates to the .local URL', (tester) async {
    String? navigated;
    await tester.pumpWidget(_harness(navigate: (url) => navigated = url));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The primary button carries the short "Go to router" label; the URL flows
    // through onTap rather than the label.
    await tester.tap(find.text('Go to router'));
    await tester.pumpAndSettle();

    expect(navigated, 'https://Community00080.local');
  });
}
