import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/dashboard/a2ui/renderer/template_builder_enhanced.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_template.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/data_path_resolver.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action_manager.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action.dart';
import 'package:ui_kit_library/ui_kit.dart';

// Mock classes using mocktail
class MockDataPathResolver extends Mock implements DataPathResolver {}

class MockA2UIActionManager extends Mock implements A2UIActionManager {}

class FakeWidgetRef extends Fake implements WidgetRef {}

class FakeA2UIAction extends Fake implements A2UIAction {}

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

  group('TemplateBuilderEnhanced Action Callback Tests', () {
    late MockA2UIActionManager mockActionManager;
    late MockDataPathResolver mockResolver;
    A2UIAction? lastExecutedAction;

    setUp(() {
      mockActionManager = MockA2UIActionManager();
      mockResolver = MockDataPathResolver();
      lastExecutedAction = null;

      // Stub resolver
      when(() => mockResolver.resolve(any())).thenReturn(null);
      when(() => mockResolver.watch(any())).thenReturn(null);

      // Stub executeAction
      when(() => mockActionManager.executeAction(any(), any()))
          .thenAnswer((invocation) async {
        lastExecutedAction = invocation.positionalArguments[0] as A2UIAction;
        return A2UIActionResult.success(lastExecutedAction!);
      });

      // Stub createActionCallback to return a working callback
      when(() => mockActionManager.createActionCallback(any(),
              widgetId: any(named: 'widgetId')))
          .thenReturn((Map<String, dynamic> data) async {
        final action = A2UIAction(
          action: data['action'] as String,
          params: Map<String, dynamic>.from(data)..remove('action'),
          sourceWidgetId: 'test_widget',
        );
        await mockActionManager.executeAction(action, FakeWidgetRef());
      });
    });

    testWidgets('Creates action callback and triggers it via Tap',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetPhysicalSize);

      // Create a template with an action
      final template = A2UIContainerNode(
        type: 'AppCard',
        properties: {
          'onTap': {
            r'$action': 'navigation.push',
            'params': {'route': '/devices'}
          },
        },
        children: [
          A2UILeafNode(
            type: 'AppText',
            properties: {
              'text': 'Test Card with Action',
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            a2uiActionManagerProvider.overrideWithValue(mockActionManager),
          ],
          child: MaterialApp(
            theme: _createTestThemeData(),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return TemplateBuilderEnhanced.build(
                    template: template,
                    resolver: mockResolver,
                    ref: ref,
                    widgetId: 'test_card_with_action',
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget was created successfully
      expect(find.text('Test Card with Action'), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);

      // Tap the card
      await tester.tap(find.byType(AppCard));
      await tester.pumpAndSettle();

      // Verify the action was executed
      expect(lastExecutedAction, isNotNull);
      expect(lastExecutedAction?.action, equals('navigation.push'));
      expect(lastExecutedAction?.params['route'], equals('/devices'));
    });

    testWidgets(
        'Action callback receives correct data format from manual trigger',
        (tester) async {
      bool callbackReceived = false;
      Map<String, dynamic>? receivedData;

      void Function(Map<String, dynamic>) mockActionCallback = (data) {
        callbackReceived = true;
        receivedData = data;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  mockActionCallback({
                    'action': 'navigation.push',
                    'route': '/devices',
                  });
                },
                child: const Text('Simulate Action Call'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(callbackReceived, isTrue);
      expect(receivedData!['action'], equals('navigation.push'));
      expect(receivedData!['route'], equals('/devices'));
    });
  });
}
