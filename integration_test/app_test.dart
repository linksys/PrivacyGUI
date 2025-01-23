import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/main.dart';
import 'package:privacy_gui/page/dashboard/views/components/quick_panel.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart';

void main() {
  final widgetsBinding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // init better actions
    initBetterActions();
    // clear all cache data to make sure every test case is independent
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    BuildConfig.load();

    // GetIt
    dependencySetup();
  });
  group('end-to-end test', () {
    testWidgets('the first integration test', (tester) async {
      // Load app widget.
      await tester.pumpWidget(app());
      await tester.pumpAndSettle(Duration(seconds: 3));
      FlutterNativeSplash.remove();
      // await tester.pump(const Duration(seconds: 3));
      final visibleFinder = find.byIcon(LinksysIcons.visibility);
      await tester.tap(visibleFinder);
      await tester.pumpAndSettle();
      final passwordFinder = find.byType(AppPasswordField);
      await tester.tap(passwordFinder);
      await tester.enterText(passwordFinder, '4jQnu5wyt@');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppFilledButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Dashboard components
      final quickPanelFinder = find.byType(DashboardQuickPanel);
      expect(quickPanelFinder, findsOneWidget);
    });
  });
}
