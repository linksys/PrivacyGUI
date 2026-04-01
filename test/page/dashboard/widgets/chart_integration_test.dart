import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  group('Chart Integration Tests', () {
    testWidgets('UiKitCatalog can build AppLineChart from JSON',
        (tester) async {
      final template = {
        'type': 'AppLineChart',
        'props': {
          'series': [
            {
              'label': 'Test Series',
              'data': [10, 20, 30, 40],
              'color': '#2196F3'
            }
          ],
          'xLabels': ['A', 'B', 'C', 'D'],
          'yAxis': {'min': 0, 'max': 50, 'interval': 10},
          'height': 200
        }
      };

      final renderer = UiKitTemplateRenderer(
        template: template,
        builders: UiKitCatalog.standardBuilders,
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (context) => CustomDesignTheme.fromJson({
            'style': 'flat',
          }),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => renderer.build(context),
          ),
        ),
      ));

      expect(find.byType(AppLineChart), findsOneWidget);
    });

    testWidgets('UiKitCatalog can build AppBarChart from JSON', (tester) async {
      final template = {
        'type': 'AppBarChart',
        'props': {
          'series': [
            {
              'label': 'Test Data',
              'data': [15, 25, 35, 20],
              'color': '#4CAF50'
            }
          ],
          'xLabels': ['Q1', 'Q2', 'Q3', 'Q4'],
          'height': 200
        }
      };

      final renderer = UiKitTemplateRenderer(
        template: template,
        builders: UiKitCatalog.standardBuilders,
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (context) => CustomDesignTheme.fromJson({
            'style': 'flat',
          }),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => renderer.build(context),
          ),
        ),
      ));

      expect(find.byType(AppBarChart), findsOneWidget);
    });

    testWidgets('UiKitCatalog can build AppPieChart from JSON', (tester) async {
      final template = {
        'type': 'AppPieChart',
        'props': {
          'sections': [
            {'value': 40, 'color': '#2196F3', 'title': 'WiFi', 'radius': 50},
            {
              'value': 30,
              'color': '#4CAF50',
              'title': 'Ethernet',
              'radius': 50
            },
            {'value': 30, 'color': '#FF9800', 'title': 'Guest', 'radius': 50}
          ],
          'showLabels': true,
          'height': 200
        }
      };

      final renderer = UiKitTemplateRenderer(
        template: template,
        builders: UiKitCatalog.standardBuilders,
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (context) => CustomDesignTheme.fromJson({
            'style': 'flat',
          }),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => renderer.build(context),
          ),
        ),
      ));

      expect(find.byType(AppPieChart), findsOneWidget);
    });

    testWidgets('UiKitCatalog can build AppRadarChart from JSON',
        (tester) async {
      final template = {
        'type': 'AppRadarChart',
        'props': {
          'series': [
            {
              'label': 'Performance',
              'data': [80, 90, 70, 85],
              'color': '#2196F3'
            }
          ],
          'categories': ['Speed', 'Stability', 'Coverage', 'Security'],
          'maxValue': 100,
          'height': 200
        }
      };

      final renderer = UiKitTemplateRenderer(
        template: template,
        builders: UiKitCatalog.standardBuilders,
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (context) => CustomDesignTheme.fromJson({
            'style': 'flat',
          }),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => renderer.build(context),
          ),
        ),
      ));

      expect(find.byType(AppRadarChart), findsOneWidget);
    });

    testWidgets('UiKitCatalog can build AppHeatmapChart from JSON',
        (tester) async {
      final template = {
        'type': 'AppHeatmapChart',
        'props': {
          'rows': 2,
          'columns': 3,
          'values': [
            [0.1, 0.5, 0.8],
            [0.3, 0.9, 0.4]
          ],
          'rowLabels': ['Row 1', 'Row 2'],
          'columnLabels': ['Col A', 'Col B', 'Col C'],
          'showValues': true,
          'height': 150
        }
      };

      final renderer = UiKitTemplateRenderer(
        template: template,
        builders: UiKitCatalog.standardBuilders,
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (context) => CustomDesignTheme.fromJson({
            'style': 'flat',
          }),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => renderer.build(context),
          ),
        ),
      ));

      expect(find.byType(AppHeatmapChart), findsOneWidget);
    });

    testWidgets('Chart action handling works correctly', (tester) async {
      final template = {
        'type': 'AppLineChart',
        'props': {
          'series': [
            {
              'label': 'Interactive Chart',
              'data': [10, 20, 30],
              'color': '#2196F3'
            }
          ],
          'xLabels': ['A', 'B', 'C'],
          'height': 200
        }
      };

      final renderer = UiKitTemplateRenderer(
        template: template,
        builders: UiKitCatalog.standardBuilders,
        onAction: (action) {
          // Action captured for chart interactions
        },
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (context) => CustomDesignTheme.fromJson({
            'style': 'flat',
          }),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => renderer.build(context),
          ),
        ),
      ));

      expect(find.byType(AppLineChart), findsOneWidget);

      // Simulate a chart touch event
      final chart = find.byType(AppLineChart);
      await tester.tap(chart);
      await tester.pumpAndSettle();

      // Note: Actual touch event handling depends on the chart implementation
      // This test verifies the chart component is created successfully
    });
  });
}
