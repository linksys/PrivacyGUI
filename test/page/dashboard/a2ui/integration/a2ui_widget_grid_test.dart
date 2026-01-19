import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';
import 'package:privacy_gui/page/dashboard/a2ui/presets/preset_widgets.dart';
import 'package:privacy_gui/page/dashboard/a2ui/renderer/a2ui_widget_renderer.dart';
import 'package:privacy_gui/page/dashboard/a2ui/registry/a2ui_widget_registry.dart';
import 'package:privacy_gui/page/dashboard/factories/dashboard_widget_factory.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';

void main() {
  group('A2UI Widget Grid Integration', () {
    group('PresetWidgets', () {
      test('all preset widgets are registered', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final registry = container.read(a2uiWidgetRegistryProvider);

        expect(registry.contains('a2ui_device_count'), isTrue);
        expect(registry.contains('a2ui_node_count'), isTrue);
        expect(registry.contains('a2ui_wan_status'), isTrue);
        expect(registry.length, 3);
      });

      test('preset widgets have valid constraints', () {
        for (final preset in PresetWidgets.all) {
          expect(preset.constraints.minColumns, greaterThan(0));
          expect(preset.constraints.maxColumns,
              greaterThanOrEqualTo(preset.constraints.minColumns));
          expect(
              preset.constraints.preferredColumns,
              inInclusiveRange(
                preset.constraints.minColumns,
                preset.constraints.maxColumns,
              ));
          expect(preset.constraints.minRows, greaterThan(0));
          expect(preset.constraints.maxRows,
              greaterThanOrEqualTo(preset.constraints.minRows));
        }
      });

      test('preset widgets convert to valid WidgetSpec', () {
        for (final preset in PresetWidgets.all) {
          final spec = preset.toWidgetSpec();

          expect(spec.id, preset.widgetId);
          expect(spec.displayName, preset.displayName);
          expect(spec.defaultConstraints, isNotNull);

          final constraints = spec.getConstraints(DisplayMode.normal);
          expect(constraints.minColumns, preset.constraints.minColumns);
          expect(constraints.maxColumns, preset.constraints.maxColumns);
        }
      });
    });

    group('A2UIWidgetRenderer', () {
      testWidgets('renders device count widget', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: const A2UIWidgetRenderer(widgetId: 'a2ui_device_count'),
              ),
            ),
          ),
        );

        // Should render column layout with icon and texts
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byIcon(Icons.devices), findsOneWidget);
        expect(find.text('Connected Devices'), findsOneWidget);
      });

      testWidgets('renders node count widget', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: const A2UIWidgetRenderer(widgetId: 'a2ui_node_count'),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.router), findsOneWidget);
        expect(find.text('Mesh Nodes'), findsOneWidget);
      });

      testWidgets('renders wan status widget', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: const A2UIWidgetRenderer(widgetId: 'a2ui_wan_status'),
              ),
            ),
          ),
        );

        // WAN status uses Row layout
        expect(find.byType(Row), findsWidgets);
        expect(find.byIcon(Icons.lan), findsOneWidget);
        // Should show placeholder value "Connected"
        expect(find.text('Connected'), findsOneWidget);
      });

      testWidgets('renders error for unknown widget', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: const A2UIWidgetRenderer(widgetId: 'nonexistent_widget'),
              ),
            ),
          ),
        );

        // Should show error message
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.textContaining('not found'), findsOneWidget);
      });
    });

    group('DashboardWidgetFactory A2UI Integration', () {
      testWidgets(
          'buildAtomicWidget returns A2UIWidgetRenderer for A2UI widget',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final registry = ref.watch(a2uiWidgetRegistryProvider);
                    final widget = DashboardWidgetFactory.buildAtomicWidget(
                      'a2ui_device_count',
                      registry: registry,
                    );
                    return widget ?? const Text('Not found');
                  },
                ),
              ),
            ),
          ),
        );

        // Should render the A2UI widget
        expect(find.byType(A2UIWidgetRenderer), findsOneWidget);
        expect(find.text('Connected Devices'), findsOneWidget);
      });

      testWidgets(
          'buildAtomicWidget returns null for unknown widget without ref',
          (tester) async {
        final widget =
            DashboardWidgetFactory.buildAtomicWidget('a2ui_device_count');

        // Without ref, A2UI widgets cannot be looked up
        expect(widget, isNull);
      });

      test('getSpec returns WidgetSpec for A2UI widget via registry', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Test the registry directly since getSpec requires WidgetRef
        final registry = container.read(a2uiWidgetRegistryProvider);
        final definition = registry.get('a2ui_device_count');

        expect(definition, isNotNull);

        final spec = definition!.toWidgetSpec();
        expect(spec.id, 'a2ui_device_count');
        expect(spec.displayName, 'Connected Devices');
        expect(spec.defaultConstraints, isNotNull);
      });

      test('shouldWrapInCard returns true for A2UI widgets', () {
        final result =
            DashboardWidgetFactory.shouldWrapInCard('a2ui_device_count');
        expect(result, isTrue);
      });
    });

    group('Multiple A2UI Widgets', () {
      testWidgets('renders multiple A2UI widgets together', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: const [
                    Expanded(
                        child:
                            A2UIWidgetRenderer(widgetId: 'a2ui_device_count')),
                    Expanded(
                        child: A2UIWidgetRenderer(widgetId: 'a2ui_node_count')),
                    Expanded(
                        child: A2UIWidgetRenderer(widgetId: 'a2ui_wan_status')),
                  ],
                ),
              ),
            ),
          ),
        );

        // All three widgets should be present
        expect(find.byIcon(Icons.devices), findsOneWidget);
        expect(find.byIcon(Icons.router), findsOneWidget);
        expect(find.byIcon(Icons.lan), findsOneWidget);
      });
    });
  });
}
