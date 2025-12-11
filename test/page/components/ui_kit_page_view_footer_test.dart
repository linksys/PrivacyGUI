import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';

void main() {
  group('UiKitPageView pageFooter tests', () {
    testWidgets('should display pageFooter when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UiKitPageView.innerPage(
          child: (context, constraints) => const Text('Test Content'),
          pageFooter: const BottomBar(),
        ),
      ));

      // Verify that BottomBar is rendered
      expect(find.byType(BottomBar), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should not display footer when pageFooter is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UiKitPageView.innerPage(
          child: (context, constraints) => const Text('Test Content'),
          pageFooter: null,
        ),
      ));

      // Verify that no BottomBar is rendered
      expect(find.byType(BottomBar), findsNothing);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should prioritize pageFooter over bottomBar config', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UiKitPageView.innerPage(
          child: (context, constraints) => const Text('Test Content'),
          bottomBar: const UiKitBottomBarConfig(
            positiveLabel: 'Save',
            negativeLabel: 'Cancel',
          ),
          pageFooter: const BottomBar(), // Should take priority
        ),
      ));

      // Verify that BottomBar is rendered (pageFooter priority)
      expect(find.byType(BottomBar), findsOneWidget);
      // Verify that structured buttons are NOT rendered
      expect(find.text('Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('should fall back to bottomBar config when pageFooter is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UiKitPageView.innerPage(
          child: (context, constraints) => const Text('Test Content'),
          bottomBar: const UiKitBottomBarConfig(
            positiveLabel: 'Save',
            negativeLabel: 'Cancel',
          ),
          pageFooter: null, // No pageFooter, should use bottomBar config
        ),
      ));

      // Verify that structured buttons are rendered
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // Verify that BottomBar is NOT rendered
      expect(find.byType(BottomBar), findsNothing);
    });
  });
}