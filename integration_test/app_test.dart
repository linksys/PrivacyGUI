import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:privacy_gui/main.dart' as app;

void main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('integration test sample group', () {
    testWidgets('test login', (tester) async {
      await Future.delayed(Duration(seconds: 2));
      app.main();
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 2));

      final loginButton = find.byKey(const Key('home_view_button_login'));
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    });
  });
}
