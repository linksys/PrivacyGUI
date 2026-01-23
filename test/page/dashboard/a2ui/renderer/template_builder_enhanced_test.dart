import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_template.dart';
import 'package:privacy_gui/page/dashboard/a2ui/renderer/template_builder_enhanced.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/data_path_resolver.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action_manager.dart';

// Mock classes using mocktail
class MockDataPathResolver extends Mock implements DataPathResolver {}

class MockA2UIActionManager extends Mock implements A2UIActionManager {}

class FakeWidgetRef extends Fake implements WidgetRef {}

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
  });

  group('TemplateBuilderEnhanced', () {
    late MockDataPathResolver mockResolver;
    late MockA2UIActionManager mockActionManager;
    late ProviderContainer container;

    setUp(() {
      mockResolver = MockDataPathResolver();
      mockActionManager = MockA2UIActionManager();

      // Catch-all stubs for resolver
      when(() => mockResolver.resolve(any())).thenReturn(null);
      when(() => mockResolver.watch(any())).thenReturn(null);

      // Mock action manager to return a no-op callback
      when(() => mockActionManager.createActionCallback(
            any(),
            widgetId: any(named: 'widgetId'),
          )).thenReturn((Map<String, dynamic> data) {});

      container = ProviderContainer(
        overrides: [
          a2uiActionManagerProvider.overrideWithValue(mockActionManager),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Basic Widget Building', () {
      testWidgets('builds simple leaf node', (WidgetTester tester) async {
        final template = A2UILeafNode(
          type: 'AppText',
          properties: {'text': 'Hello World'},
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Consumer(
                builder: (context, ref, child) {
                  return TemplateBuilderEnhanced.build(
                    template: template,
                    resolver: mockResolver,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Hello World'), findsOneWidget);
      });

      testWidgets('builds container with children',
          (WidgetTester tester) async {
        final template = A2UIContainerNode(
          type: 'Column',
          properties: {'mainAxisAlignment': 'center'},
          children: [
            A2UILeafNode(
              type: 'AppText',
              properties: {'text': 'First'},
            ),
            A2UILeafNode(
              type: 'AppText',
              properties: {'text': 'Second'},
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Consumer(
                builder: (context, ref, child) {
                  return TemplateBuilderEnhanced.build(
                    template: template,
                    resolver: mockResolver,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('First'), findsOneWidget);
        expect(find.text('Second'), findsOneWidget);
      });

      testWidgets('handles unknown component type gracefully',
          (WidgetTester tester) async {
        final template = A2UILeafNode(
          type: 'UnknownWidget',
          properties: {'text': 'Test'},
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Consumer(
                builder: (context, ref, child) {
                  return TemplateBuilderEnhanced.build(
                    template: template,
                    resolver: mockResolver,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.textContaining('Unknown Component: UnknownWidget'),
            findsOneWidget);
      });
    });

    group('Data Binding Resolution', () {
      testWidgets('resolves data binding in properties',
          (WidgetTester tester) async {
        when(() => mockResolver.resolve('user.name')).thenReturn('John Doe');

        final template = A2UILeafNode(
          type: 'AppText',
          properties: {
            'text': {r'$bind': 'user.name'},
          },
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Consumer(
                builder: (context, ref, child) {
                  return TemplateBuilderEnhanced.build(
                    template: template,
                    resolver: mockResolver,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('John Doe'), findsOneWidget);
        verify(() => mockResolver.resolve('user.name'))
            .called(greaterThanOrEqualTo(1));
      });

      testWidgets('handles data binding error gracefully',
          (WidgetTester tester) async {
        when(() => mockResolver.resolve('invalid.path'))
            .thenThrow(Exception('Path not found'));

        final template = A2UILeafNode(
          type: 'AppText',
          properties: {
            'text': {r'$bind': 'invalid.path'},
          },
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Consumer(
                builder: (context, ref, child) {
                  return TemplateBuilderEnhanced.build(
                    template: template,
                    resolver: mockResolver,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Loading...'), findsOneWidget);
      });
    });

    group('Action Processing', () {
      testWidgets('creates action callback for action properties',
          (WidgetTester tester) async {
        final template = A2UILeafNode(
          type: 'AppButton',
          properties: {
            'label': 'Click Me',
            'onPressed': {
              r'$action': 'router.restart',
              'params': {'timeout': 30},
            },
          },
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Consumer(
                builder: (context, ref, child) {
                  return TemplateBuilderEnhanced.build(
                    template: template,
                    resolver: mockResolver,
                    ref: ref,
                    widgetId: 'test_button',
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Click Me'), findsOneWidget);

        // Verify that action callback was created
        verify(() => mockActionManager.createActionCallback(
              any(),
              widgetId: 'test_button',
            )).called(greaterThanOrEqualTo(1));
      });

      testWidgets('handles no actions without creating callback',
          (WidgetTester tester) async {
        final template = A2UILeafNode(
          type: 'AppText',
          properties: {'text': 'Static Text'},
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Consumer(
                builder: (context, ref, child) {
                  return TemplateBuilderEnhanced.build(
                    template: template,
                    resolver: mockResolver,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Static Text'), findsOneWidget);

        // Should not create action callback when no actions are present
        verifyNever(() => mockActionManager.createActionCallback(
              any(),
              widgetId: any(named: 'widgetId'),
            ));
      });
    });

    group('Complex Scenarios', () {
      testWidgets('builds complex widget with actions and data binding',
          (WidgetTester tester) async {
        when(() => mockResolver.resolve('device.name')).thenReturn('iPhone');
        when(() => mockResolver.resolve('device.id')).thenReturn('device123');

        final template = A2UIContainerNode(
          type: 'Row',
          properties: {'mainAxisAlignment': 'spaceBetween'},
          children: [
            A2UILeafNode(
              type: 'AppText',
              properties: {
                'text': {r'$bind': 'device.name'},
              },
            ),
            A2UILeafNode(
              type: 'AppButton',
              properties: {
                'label': 'Block',
                'onPressed': {
                  r'$action': 'device.block',
                  'params': {
                    'deviceId': {r'$bind': 'device.id'},
                  },
                },
              },
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: Consumer(
                builder: (context, ref, child) {
                  return TemplateBuilderEnhanced.build(
                    template: template,
                    resolver: mockResolver,
                    ref: ref,
                    widgetId: 'device_row',
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('iPhone'), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);

        // Verify data binding was resolved
        verify(() => mockResolver.resolve(any()))
            .called(greaterThanOrEqualTo(1));

        // Verify action callback was created
        verify(() => mockActionManager.createActionCallback(
              any(),
              widgetId: 'device_row',
            )).called(greaterThanOrEqualTo(1));
      });
    });
  });
}
