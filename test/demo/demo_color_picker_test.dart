import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_fab.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_panel.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';
import 'package:privacy_gui/route/router_provider.dart';

void main() {
  testWidgets('Color picker dialog opens on tap', (tester) async {
    final themeData = AppTheme.create(
      brightness: Brightness.light,
      seedColor: Colors.blue,
      designThemeBuilder: (c) => CustomDesignTheme.fromJson({
        'style': 'flat',
      }),
    );

    // Set a large screen size to avoid overflow
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: routerKey, // Use the real routerKey for test
          theme: themeData,
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: const ThemeStudioFab(),
                ),
                // Simulate Panel Overlay
                Consumer(builder: (context, ref, _) {
                  final isOpen = ref.watch(demoUIProvider).isThemePanelOpen;
                  if (!isOpen) return const SizedBox();
                  return const Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 500,
                    child: Material(child: ThemeStudioPanel()),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );

    // 1. Open FAB
    await tester.tap(find.byType(ThemeStudioFab));
    await tester.pumpAndSettle();

    // 2. Switch to Palette Tab
    // Use AppTabs finder since TabBar is not used.
    final paletteTab = find.descendant(
      of: find.byType(AppTabs),
      matching: find.text('Palette'),
    );

    await tester.tap(paletteTab.first); // Use first just in case
    await tester.pumpAndSettle();

    // 3. Find Primary Color Override Row
    expect(find.text('Primary'), findsOneWidget);

    // 4. Tap the ColorCircle next to Primary using Key
    final colorCircleFinder =
        find.byKey(const ValueKey('color-override-Primary'));
    expect(colorCircleFinder, findsOneWidget);

    await tester.tap(colorCircleFinder);
    await tester.pumpAndSettle();

    // 5. Verify Dialog is Open
    expect(find.text('Pick Color'), findsOneWidget);
  });
}
