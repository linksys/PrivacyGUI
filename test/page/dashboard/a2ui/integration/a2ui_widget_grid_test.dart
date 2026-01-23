import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/dashboard/a2ui/presets/preset_widgets.dart';
import 'package:privacy_gui/page/dashboard/a2ui/renderer/a2ui_widget_renderer.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/jnap_data_resolver.dart';
import 'package:privacy_gui/page/dashboard/factories/dashboard_widget_factory.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_template.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_constraints.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action_manager.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action.dart';

// Mock classes using mocktail
class MockJnapDataResolver extends Mock implements JnapDataResolver {}

class MockA2UIActionManager extends Mock implements A2UIActionManager {}

class FakeWidgetRef extends Fake implements WidgetRef {}

class FakeA2UIAction extends Fake implements A2UIAction {}

/// Helper function to create proper theme data for tests.
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
  setUpAll(() {
    registerFallbackValue(FakeWidgetRef());
    registerFallbackValue(FakeA2UIAction());
  });

  group('A2UI Widget Grid Integration', () {
    late MockJnapDataResolver mockResolver;
    late MockA2UIActionManager mockActionManager;

    setUp(() {
      mockResolver = MockJnapDataResolver();
      mockActionManager = MockA2UIActionManager();

      // Default stubs
      when(() => mockResolver.resolve(any())).thenReturn('0');
      when(() => mockResolver.watch(any())).thenReturn(null);
      when(() => mockActionManager.executeAction(any(), any()))
          .thenAnswer((invocation) async {
        final action = invocation.positionalArguments[0] as A2UIAction;
        return A2UIActionResult.success(action);
      });
      when(() => mockActionManager.createActionCallback(any(),
          widgetId: any(named: 'widgetId'))).thenReturn((_) {});
    });

    List<Override> getOverrides() {
      return [
        a2uiLoaderProvider.overrideWith((ref) async => [
              A2UIWidgetDefinition(
                widgetId: 'a2ui_device_count',
                displayName: 'Connected Devices',
                constraints: const A2UIConstraints(
                    minColumns: 2,
                    maxColumns: 4,
                    preferredColumns: 2,
                    minRows: 2,
                    maxRows: 4,
                    preferredRows: 2),
                template: A2UIContainerNode(
                  type: 'Column',
                  children: [
                    A2UILeafNode(type: 'Icon', properties: {'icon': 'devices'}),
                    A2UILeafNode(
                        type: 'AppText',
                        properties: {'text': 'Connected Devices'}),
                  ],
                ),
              ),
              A2UIWidgetDefinition(
                widgetId: 'a2ui_node_count',
                displayName: 'Mesh Nodes',
                constraints: const A2UIConstraints(
                    minColumns: 2,
                    maxColumns: 4,
                    preferredColumns: 2,
                    minRows: 2,
                    maxRows: 4,
                    preferredRows: 2),
                template: A2UIContainerNode(
                  type: 'Column',
                  children: [
                    A2UILeafNode(type: 'Icon', properties: {'icon': 'router'}),
                    A2UILeafNode(
                        type: 'AppText', properties: {'text': 'Mesh Nodes'}),
                  ],
                ),
              ),
              A2UIWidgetDefinition(
                widgetId: 'a2ui_wan_status',
                displayName: 'Internet Status',
                constraints: const A2UIConstraints(
                    minColumns: 2,
                    maxColumns: 4,
                    preferredColumns: 2,
                    minRows: 1,
                    maxRows: 2,
                    preferredRows: 1),
                template: A2UIContainerNode(
                  type: 'Row',
                  children: [
                    A2UILeafNode(type: 'Icon', properties: {'icon': 'lan'}),
                    A2UILeafNode(
                        type: 'AppText', properties: {'text': 'Connected'}),
                  ],
                ),
              ),
            ]),
        jnapDataResolverProvider.overrideWithValue(mockResolver),
        a2uiActionManagerProvider.overrideWithValue(mockActionManager),
      ];
    }

    group('PresetWidgets', () {
      testWidgets('AppDesignTheme extension is present in theme',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Builder(
                builder: (context) {
                  final theme = Theme.of(context).extension<AppDesignTheme>();
                  return Text(theme != null ? 'Present' : 'Missing');
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Present'), findsOneWidget);
        expect(find.text('Missing'), findsNothing);
      });

      testWidgets('all preset widgets are registered', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: getOverrides(),
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Container(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        await container.read(a2uiLoaderProvider.future);
        await tester.pumpAndSettle();

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
        tester.view.physicalSize = const Size(1280, 800);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: getOverrides(),
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: const A2UIWidgetRenderer(widgetId: 'a2ui_device_count'),
              ),
            ),
          ),
        );

        // Wait for loader to complete
        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        await container.read(a2uiLoaderProvider.future);

        await tester.pumpAndSettle();

        // Should render column layout with icon and texts
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byIcon(Icons.devices), findsOneWidget);
        expect(find.text('Connected Devices'), findsOneWidget);
      });

      testWidgets('renders node count widget', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: getOverrides(),
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: const A2UIWidgetRenderer(widgetId: 'a2ui_node_count'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        await container.read(a2uiLoaderProvider.future);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.router), findsOneWidget);
        expect(find.text('Mesh Nodes'), findsOneWidget);
      });

      testWidgets('renders wan status widget', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: getOverrides(),
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: const A2UIWidgetRenderer(widgetId: 'a2ui_wan_status'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        await container.read(a2uiLoaderProvider.future);
        await tester.pumpAndSettle();

        // WAN status uses Row layout
        expect(find.byType(Row), findsWidgets);
        expect(find.byIcon(Icons.lan), findsOneWidget);
        expect(find.text('Connected'), findsOneWidget);
      });

      testWidgets('renders error for unknown widget', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: getOverrides(),
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: const A2UIWidgetRenderer(widgetId: 'nonexistent_widget'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

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
            overrides: getOverrides(),
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final factory = ref.watch(dashboardWidgetFactoryProvider);
                    final widget =
                        factory.buildAtomicWidget('a2ui_device_count');
                    return widget ?? const Text('Not found');
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should render the A2UI widget
        expect(find.byType(A2UIWidgetRenderer), findsOneWidget);
        expect(find.text('Connected Devices'), findsOneWidget);
      });

      testWidgets('factory hasWidget returns true for A2UI widgets',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: getOverrides(),
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Container(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        await container.read(a2uiLoaderProvider.future);
        await tester.pumpAndSettle();

        final factory = container.read(dashboardWidgetFactoryProvider);

        expect(factory.hasWidget('a2ui_device_count'), isTrue);
        expect(factory.hasWidget('a2ui_node_count'), isTrue);
        expect(factory.hasWidget('unknown_widget'), isFalse);
      });

      testWidgets('getSpec returns WidgetSpec for A2UI widget via factory',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: getOverrides(),
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Container(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        await container.read(a2uiLoaderProvider.future);
        await tester.pumpAndSettle();

        final factory = container.read(dashboardWidgetFactoryProvider);
        final spec = factory.getSpec('a2ui_device_count');

        expect(spec, isNotNull);
        expect(spec!.id, 'a2ui_device_count');
        expect(spec.displayName, 'Connected Devices');
      });

      test('shouldWrapInCard returns true for A2UI widgets', () {
        final container = ProviderContainer(overrides: getOverrides());
        addTearDown(container.dispose);

        final factory = container.read(dashboardWidgetFactoryProvider);
        final result = factory.shouldWrapInCard('a2ui_device_count');
        expect(result, isTrue);
      });
    });

    group('Multiple A2UI Widgets', () {
      testWidgets('renders multiple A2UI widgets together', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: getOverrides(),
            child: MaterialApp(
              theme: _createTestThemeData(),
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

        // Wait for loader to complete
        final element = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(element);
        await container.read(a2uiLoaderProvider.future);

        await tester.pumpAndSettle();

        // All three widgets should be present
        expect(find.byIcon(Icons.devices), findsOneWidget);
        expect(find.byIcon(Icons.router), findsOneWidget);
        expect(find.byIcon(Icons.lan), findsOneWidget);
      });
    });
  });
}
