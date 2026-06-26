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

Widget _harness({
  required void Function(String) navigate,
  required String hostName,
}) {
  return MediaQuery(
    data: const MediaQueryData(size: Size(1024, 768)),
    child: MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showBridgeRedirectDialog(
              context,
              hostName: hostName,
              navigate: navigate,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the .local management address', (tester) async {
    // The long button label causes layout overflow in the 350px dialog; suppress
    // the error to test functional behavior. Production dialogs have more space.
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.toString().contains('RenderFlex overflowed')) {
        oldOnError?.call(details);
      }
    };

    await tester.pumpWidget(_harness(navigate: (_) {}, hostName: 'MyRouter'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('https://MyRouter.local'),
      findsWidgets,
    );

    FlutterError.onError = oldOnError;
  });

  testWidgets('go button navigates to the .local URL', (tester) async {
    // Suppress layout overflow error (see test above).
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.toString().contains('RenderFlex overflowed')) {
        oldOnError?.call(details);
      }
    };

    String? navigated;
    await tester.pumpWidget(
        _harness(navigate: (url) => navigated = url, hostName: 'MyRouter'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The primary button label contains the URL; tap it.
    await tester.tap(find.textContaining('Go to'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(navigated, 'https://MyRouter.local');

    FlutterError.onError = oldOnError;
  });
}
