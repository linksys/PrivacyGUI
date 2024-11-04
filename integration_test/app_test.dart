import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // init better actions
    initBetterActions();
    // clear all cache data to make sure every test case is independent
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  });
  group('end-to-end test', () {
    testWidgets('the first integration test', (tester) async {
      // Load app widget.
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      // home view
      final filledButtonFinder = find.byType(AppFilledButton);
      expect(filledButtonFinder, findsOneWidget);
      // tap login
      await tester.tap(filledButtonFinder);
      await tester.pumpAndSettle();

      // remote login view
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsNWidgets(2));
      // input username
      await tester.enterText(textFieldFinder.first, 'hank.yu@belkin.com');
      await tester.pumpAndSettle();
      // input password
      await tester.enterText(textFieldFinder.last, 'Belkin123!');
      await tester.pumpAndSettle();
      // click login button
      final loginButtonFinder = find.byType(AppFilledButton);
      await tester.tap(loginButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      // addressing enabled tile and click
      final tileFinder = find.byWidgetPredicate(
          (widget) => widget is Opacity && widget.opacity == 1);
      await tester.tap(tileFinder);
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });
  });
}
