import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/loading_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  // Use a simple test wrapper that provides the AppDesignTheme
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          // Use concrete GlassDesignTheme for testing
          GlassDesignTheme.light(),
        ],
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('LoadingTile', () {
    testWidgets('renders child when isLoading is false', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LoadingTile(
          isLoading: false,
          child: Text('Content'),
        ),
      ));

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(AppSkeleton), findsNothing);
    });

    testWidgets(
        'renders AppSkeleton structure when isLoading is true with simple child',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LoadingTile(
          isLoading: true,
          child: Text('Content'),
        ),
      ));

      // Should find AppSkeleton instead of Text
      expect(find.text('Content'), findsNothing);
      expect(find.byType(AppSkeleton), findsOneWidget);
    });

    testWidgets('renders recursive structure when isLoading is true (Row)',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LoadingTile(
          isLoading: true,
          child: Row(
            children: [
              Text('Item 1'),
              Icon(Icons.home),
            ],
          ),
        ),
      ));

      expect(find.text('Item 1'), findsNothing);
      expect(find.byIcon(Icons.home), findsNothing);

      // Should preserve the Row
      expect(find.byType(Row), findsOneWidget);
      // Both Text and Icon should be converted to AppSkeleton
      expect(find.byType(AppSkeleton), findsNWidgets(2));
    });

    testWidgets('renders default skeleton when child is null', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const LoadingTile(isLoading: true),
      ));

      // The default skeleton has 3 AppSkeleton items in a Column
      expect(find.byType(AppSkeleton), findsNWidgets(3));
    });
  });
}
