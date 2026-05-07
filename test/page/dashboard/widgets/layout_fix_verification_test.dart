import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/widgets/package_widget_renderer.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Test theme data for layout verification.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({
    'style': 'flat',
  }),
);

void main() {
  group('Layout Fix Verification', () {
    testWidgets(
        'Column with center alignment preserves original layout properties',
        (WidgetTester tester) async {
      // Create a template that uses Column with center alignment
      final template = PackageWidgetTemplate(
        widgetId: 'test_center_column',
        displayName: 'Test Center Column',
        constraints: WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 4,
          preferredColumns: 3,
          heightStrategy: HeightStrategy.strict(2.0),
          minHeightRows: 1,
          maxHeightRows: 4,
        ),
        template: {
          'type': 'Column',
          'props': {
            'mainAxisAlignment': 'center',
            'crossAxisAlignment': 'center',
            'children': [
              {
                'type': 'AppText',
                'props': {'text': 'Centered Title', 'variant': 'titleMedium'}
              },
              {
                'type': 'AppGap',
                'props': {'size': 'sm'}
              },
              {
                'type': 'AppText',
                'props': {'text': 'Centered Content', 'variant': 'bodyMedium'}
              },
            ],
          },
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: Scaffold(
              body: PackageWidgetRenderer(template: template),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Column widget that should be created by our layout fix
      final columnFinder = find.byType(Column);
      expect(columnFinder, findsWidgets);

      // Get the Column widget
      final Column column = tester.widget(columnFinder.last);

      // Verify that the Column preserves the original alignment properties
      expect(column.mainAxisAlignment, MainAxisAlignment.center,
          reason: 'Column should preserve original mainAxisAlignment: center');
      expect(column.crossAxisAlignment, CrossAxisAlignment.center,
          reason: 'Column should preserve original crossAxisAlignment: center');

      print('✅ Layout Fix Verification: Column center alignment preserved');
    });

    testWidgets('Row with spaceEvenly alignment works correctly',
        (WidgetTester tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'test_space_evenly_row',
        displayName: 'Test SpaceEvenly Row',
        constraints: WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 4,
          preferredColumns: 3,
          heightStrategy: HeightStrategy.strict(2.0),
          minHeightRows: 1,
          maxHeightRows: 4,
        ),
        template: {
          'type': 'Column',
          'props': {
            'mainAxisAlignment': 'center',
            'crossAxisAlignment': 'center',
            'children': [
              {
                'type': 'Row',
                'props': {
                  'mainAxisAlignment': 'spaceEvenly',
                  'expandChildren': true,
                  'children': [
                    {
                      'type': 'AppText',
                      'props': {'text': 'Item 1', 'variant': 'bodyMedium'}
                    },
                    {
                      'type': 'AppText',
                      'props': {'text': 'Item 2', 'variant': 'bodyMedium'}
                    },
                    {
                      'type': 'AppText',
                      'props': {'text': 'Item 3', 'variant': 'bodyMedium'}
                    },
                  ],
                }
              },
            ],
          },
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: Scaffold(
              body: PackageWidgetRenderer(template: template),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Row widget
      final rowFinder = find.byType(Row);
      expect(rowFinder, findsAtLeastNWidgets(1));

      // Get the Row widget
      final Row row = tester.widget(rowFinder.first);

      // Verify that the Row preserves spaceEvenly alignment
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceEvenly,
          reason:
              'Row should preserve original mainAxisAlignment: spaceEvenly');

      // Verify expandChildren functionality
      expect(row.mainAxisSize, MainAxisSize.max,
          reason: 'Row with expandChildren should have MainAxisSize.max');

      // Check that children are wrapped in Expanded widgets
      final expandedFinder = find.byType(Expanded);
      expect(expandedFinder, findsAtLeastNWidgets(3),
          reason:
              'Row with expandChildren should wrap children in Expanded widgets');

      print(
          '✅ Layout Fix Verification: Row spaceEvenly alignment and expandChildren preserved');
    });

    testWidgets('Default layout uses center alignment instead of start',
        (WidgetTester tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'test_default_layout',
        displayName: 'Test Default Layout',
        constraints: WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 4,
          preferredColumns: 3,
          heightStrategy: HeightStrategy.strict(2.0),
          minHeightRows: 1,
          maxHeightRows: 4,
        ),
        template: {
          'type': 'UnknownType', // This should trigger default layout
          'props': {
            'children': [
              {
                'type': 'AppText',
                'props': {'text': 'Default Layout', 'variant': 'bodyMedium'}
              },
            ],
          },
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: _testTheme,
            home: Scaffold(
              body: PackageWidgetRenderer(template: template),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Column widget (default layout)
      final columnFinder = find.byType(Column);
      expect(columnFinder, findsWidgets);

      // Get the Column widget
      final Column column = tester.widget(columnFinder.last);

      // Verify that default layout uses center alignment instead of start
      expect(column.mainAxisAlignment, MainAxisAlignment.center,
          reason:
              'Default layout should use center alignment instead of start');
      expect(column.crossAxisAlignment, CrossAxisAlignment.center,
          reason:
              'Default layout should use center alignment instead of start');

      print('✅ Layout Fix Verification: Default layout uses center alignment');
    });
  });
}
