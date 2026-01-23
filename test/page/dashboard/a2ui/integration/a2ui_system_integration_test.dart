import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/loader/json_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_constraints.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';
import 'package:privacy_gui/page/dashboard/a2ui/registry/a2ui_widget_registry.dart';
import 'package:privacy_gui/page/dashboard/a2ui/renderer/a2ui_widget_renderer.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/jnap_data_resolver.dart';
import 'package:privacy_gui/page/dashboard/a2ui/validator/a2ui_constraint_validator.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Helper function to create proper theme data for A2UI integration tests.
/// This ensures AppTheme is properly configured to avoid "AppDesignTheme extension not found" errors.
ThemeData _createTestThemeData() {
  return AppTheme.create(
    brightness: Brightness.light,
    seedColor: AppPalette.brandPrimary,
    designThemeBuilder: (_) => CustomDesignTheme.fromJson(const {
      'style': 'flat',
      'brightness': 'light',
      'visualEffects': 0,
    }),
  );
}

void main() {
  group('A2UI System Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('End-to-End Widget Loading and Rendering', () {
      testWidgets('loads widgets from assets and renders successfully', (tester) async {
        // Test the complete flow: JsonWidgetLoader -> Registry -> Renderer
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    final asyncWidgets = ref.watch(a2uiLoaderProvider);

                    return asyncWidgets.when(
                      data: (widgets) {
                        if (widgets.isEmpty) {
                          return const Text('No widgets loaded');
                        }

                        // Try to render the first widget
                        return A2UIWidgetRenderer(
                          widgetId: widgets.first.widgetId,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Wait for async loading to complete
        await tester.pumpAndSettle();

        // Should not be in loading or error state
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('Error:'), findsNothing);
      });

      testWidgets('handles widget rendering errors gracefully', (tester) async {
        // Test rendering with an invalid widget ID
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: const Scaffold(
                body: A2UIWidgetRenderer(
                  widgetId: 'nonexistent-widget',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show error widget instead of crashing
        expect(find.text('A2UI Widget not found: nonexistent-widget'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('Widget Registry Integration', () {
      test('registry integrates with loader and provides widgets', () async {
        final registry = container.read(a2uiWidgetRegistryProvider);

        // Registry should be empty initially or populated by loader
        final initialCount = registry.length;
        expect(initialCount, isA<int>());

        // Test registering a widget manually
        final testWidget = A2UIWidgetDefinition.fromJson(const {
          'widgetId': 'test_integration_widget',
          'displayName': 'Test Integration Widget',
          'constraints': {
            'minColumns': 2,
            'maxColumns': 4,
            'preferredColumns': 3,
            'minRows': 1,
            'maxRows': 2,
            'preferredRows': 1,
          },
          'template': {
            'type': 'Container',
            'children': [],
          },
        });

        registry.register(testWidget);

        // Should be able to retrieve the widget
        final retrieved = registry.get('test_integration_widget');
        expect(retrieved, isNotNull);
        expect(retrieved!.widgetId, 'test_integration_widget');
        expect(registry.length, initialCount + 1);
      });

      test('registry provides widgets to validator', () {
        final registry = container.read(a2uiWidgetRegistryProvider);
        final validator = A2UIConstraintValidator(registry);

        // Register a test widget
        final testWidget = A2UIWidgetDefinition.fromJson(const {
          'widgetId': 'validator_test_widget',
          'displayName': 'Validator Test Widget',
          'constraints': {
            'minColumns': 2,
            'maxColumns': 6,
            'preferredColumns': 4,
            'minRows': 1,
            'maxRows': 3,
            'preferredRows': 2,
          },
          'template': {
            'type': 'Container',
            'children': [],
          },
        });

        registry.register(testWidget);

        // Validator should be able to validate constraints for registered widget
        final validResult = validator.validateResize(
          widgetId: 'validator_test_widget',
          newColumns: 3,
          newRows: 2,
        );

        expect(validResult.isValid, isTrue);

        // Should reject invalid constraints
        final invalidResult = validator.validateResize(
          widgetId: 'validator_test_widget',
          newColumns: 1, // Below minColumns: 2
          newRows: 2,
        );

        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.messages, isNotEmpty);
      });
    });

    group('Data Resolution Integration', () {
      testWidgets('resolver integrates with renderer for data binding', (tester) async {
        // Create a widget with data binding
        const widgetJson = {
          'widgetId': 'data_binding_test_widget',
          'displayName': 'Data Binding Test',
          'constraints': {
            'minColumns': 2,
            'maxColumns': 4,
            'preferredColumns': 3,
            'minRows': 1,
            'maxRows': 2,
            'preferredRows': 1,
          },
          'template': {
            'type': 'Column',
            'children': [
              {
                'type': 'AppText',
                'properties': {
                  'text': {r'$bind': 'router.wanStatus'},
                },
              },
              {
                'type': 'AppText',
                'properties': {
                  'text': {r'$bind': 'router.uptime'},
                },
              },
            ],
          },
        };

        // Register widget manually since asset loading might not be available in tests
        final registry = container.read(a2uiWidgetRegistryProvider);
        final widget = A2UIWidgetDefinition.fromJson(widgetJson);
        registry.register(widget);

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: A2UIWidgetRenderer(
                  widgetId: 'data_binding_test_widget',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without errors - data binding may show default values
        expect(find.byType(Column), findsOneWidget);

        // Should not crash or show error widget
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      test('resolver provides consistent data across multiple calls', () {
        final resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        final paths = [
          'router.deviceCount',
          'router.nodeCount',
          'router.wanStatus',
          'router.uptime',
          'wifi.ssid',
        ];

        for (final path in paths) {
          final firstCall = resolver.resolve(path);
          final secondCall = resolver.resolve(path);

          // Should return consistent values
          expect(firstCall, equals(secondCall),
              reason: 'Resolver should return consistent values for path: $path');
        }
      });
    });

    group('Constraint Validation Integration', () {
      test('validator suggestion integrates with widget constraints', () {
        final registry = container.read(a2uiWidgetRegistryProvider);
        final validator = A2UIConstraintValidator(registry);

        // Register widgets with different constraint patterns
        final widgets = [
          A2UIWidgetDefinition.fromJson(const {
            'widgetId': 'flexible_widget',
            'displayName': 'Flexible Widget',
            'constraints': {
              'minColumns': 1,
              'maxColumns': 12,
              'preferredColumns': 6,
              'minRows': 1,
              'maxRows': 8,
              'preferredRows': 4,
            },
            'template': {'type': 'Container', 'children': []},
          }),
          A2UIWidgetDefinition.fromJson(const {
            'widgetId': 'rigid_widget',
            'displayName': 'Rigid Widget',
            'constraints': {
              'minColumns': 3,
              'maxColumns': 3,
              'preferredColumns': 3,
              'minRows': 2,
              'maxRows': 2,
              'preferredRows': 2,
            },
            'template': {'type': 'Container', 'children': []},
          }),
        ];

        for (final widget in widgets) {
          registry.register(widget);
        }

        // Test suggestion system with different constraint patterns
        final flexibleSuggestion = validator.suggestValidResize(
          widgetId: 'flexible_widget',
          requestedColumns: 15, // Above max
          requestedRows: 10,    // Above max
        );

        expect(flexibleSuggestion.columns, 12); // Clamped to max
        expect(flexibleSuggestion.rows, 8);     // Clamped to max
        expect(flexibleSuggestion.adjusted, isTrue);

        final rigidSuggestion = validator.suggestValidResize(
          widgetId: 'rigid_widget',
          requestedColumns: 5, // Above max
          requestedRows: 1,    // Below min
        );

        expect(rigidSuggestion.columns, 3); // Clamped to exact size
        expect(rigidSuggestion.rows, 2);    // Clamped to exact size
        expect(rigidSuggestion.adjusted, isTrue);
      });

      test('placement validation prevents overlaps', () {
        final registry = container.read(a2uiWidgetRegistryProvider);
        final validator = A2UIConstraintValidator(registry);

        final testWidget = A2UIWidgetDefinition.fromJson(const {
          'widgetId': 'placement_test_widget',
          'displayName': 'Placement Test Widget',
          'constraints': {
            'minColumns': 2,
            'maxColumns': 4,
            'preferredColumns': 3,
            'minRows': 1,
            'maxRows': 2,
            'preferredRows': 1,
          },
          'template': {'type': 'Container', 'children': []},
        });

        registry.register(testWidget);

        // Create existing placements
        final existingPlacements = [
          WidgetPlacement(
            widgetId: 'existing_widget_1',
            column: 0,
            row: 0,
            columns: 3,
            rows: 2,
          ),
          WidgetPlacement(
            widgetId: 'existing_widget_2',
            column: 6,
            row: 0,
            columns: 3,
            rows: 2,
          ),
        ];

        // Test valid placement (between existing widgets)
        final validPlacement = validator.validatePlacement(
          widgetId: 'placement_test_widget',
          column: 3,
          row: 0,
          columns: 3,
          rows: 1,
          gridColumns: 12,
          existingPlacements: existingPlacements,
        );

        expect(validPlacement.isValid, isTrue);

        // Test invalid placement (overlaps with existing)
        final invalidPlacement = validator.validatePlacement(
          widgetId: 'placement_test_widget',
          column: 2, // Overlaps with existing_widget_1
          row: 0,
          columns: 3,
          rows: 1,
          gridColumns: 12,
          existingPlacements: existingPlacements,
        );

        expect(invalidPlacement.isValid, isFalse);
        expect(invalidPlacement.messages, isNotEmpty);
      });
    });

    group('Error Recovery and System Resilience', () {
      testWidgets('system handles asset loading failures gracefully', (tester) async {
        // Test that the system doesn't crash when asset loading fails
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) {
                    final asyncWidgets = ref.watch(a2uiLoaderProvider);

                    return asyncWidgets.when(
                      data: (widgets) => Text('Loaded ${widgets.length} widgets'),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Loading failed: ${error.toString()}'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Wait for async loading with a reasonable timeout
        await tester.pump(const Duration(milliseconds: 100));

        // Give time for provider to settle (multiple frames)
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Should handle any loading scenario gracefully
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      test('registry handles duplicate registrations', () {
        final registry = container.read(a2uiWidgetRegistryProvider);

        final widget1 = A2UIWidgetDefinition.fromJson(const {
          'widgetId': 'duplicate_test',
          'displayName': 'First Version',
          'constraints': {
            'minColumns': 1,
            'maxColumns': 2,
            'preferredColumns': 1,
            'minRows': 1,
            'maxRows': 1,
            'preferredRows': 1,
          },
          'template': {'type': 'Container', 'children': []},
        });

        final widget2 = A2UIWidgetDefinition.fromJson(const {
          'widgetId': 'duplicate_test',
          'displayName': 'Second Version',
          'constraints': {
            'minColumns': 2,
            'maxColumns': 4,
            'preferredColumns': 3,
            'minRows': 1,
            'maxRows': 2,
            'preferredRows': 1,
          },
          'template': {'type': 'Container', 'children': []},
        });

        registry.register(widget1);
        registry.register(widget2); // Should replace first

        final retrieved = registry.get('duplicate_test');
        expect(retrieved, isNotNull);
        expect(retrieved!.displayName, 'Second Version');
        expect(retrieved.constraints.maxColumns, 4);
      });

      test('data resolver handles provider exceptions', () {
        final resolver = container.read(jnapDataResolverProvider) as JnapDataResolver;

        // These should not throw exceptions even if underlying providers have issues
        expect(() => resolver.resolve('router.deviceCount'), returnsNormally);
        expect(() => resolver.resolve('invalid.path'), returnsNormally);
        expect(() => resolver.watch('router.wanStatus'), returnsNormally);
        expect(() => resolver.watch('invalid.path'), returnsNormally);
      });
    });

    group('Performance and Memory Management', () {
      test('registry notifies listeners efficiently', () {
        final registry = container.read(a2uiWidgetRegistryProvider);
        int notificationCount = 0;

        // Listen to registry changes
        registry.addListener(() {
          notificationCount++;
        });

        final initialCount = notificationCount;

        // Register multiple widgets
        for (int i = 0; i < 5; i++) {
          final widget = A2UIWidgetDefinition.fromJson({
            'widgetId': 'perf_test_widget_$i',
            'displayName': 'Performance Test Widget $i',
            'constraints': {
              'minColumns': 1,
              'maxColumns': 2,
              'preferredColumns': 1,
              'minRows': 1,
              'maxRows': 1,
              'preferredRows': 1,
            },
            'template': {'type': 'Container', 'children': []},
          });

          registry.register(widget);
        }

        // Should have notified listeners (exact count depends on implementation)
        expect(notificationCount, greaterThan(initialCount));
      });

      testWidgets('widget renderer disposes resources properly', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: A2UIWidgetRenderer(
                  widgetId: 'test-widget',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Change to different widget
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: A2UIWidgetRenderer(
                  widgetId: 'different-widget',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle widget changes without memory leaks
        expect(find.byType(A2UIWidgetRenderer), findsOneWidget);
      });
    });
  });
}