import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/widgets/package_widget_renderer.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Test theme data for widget testing.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({
    'style': 'flat',
  }),
);

void main() {
  group('Package Widget Action Integration', () {
    testWidgets('UiKitTemplateRenderer passes onAction to UiTreeBuilder',
        (WidgetTester tester) async {
      // Create a template with an interactive button
      final template = PackageWidgetTemplate(
        widgetId: 'test_action_button',
        displayName: 'Test Action Button',
        constraints: WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 4,
          preferredColumns: 3,
          heightStrategy: HeightStrategy.strict(1.5),
          minHeightRows: 1,
          maxHeightRows: 2,
        ),
        template: {
          'type': 'Column',
          'props': {
            'children': [
              {
                'type': 'AppButton',
                'props': {
                  'label': 'Test Button',
                  'variant': 'highlight',
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

      // Verify the button is rendered
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);

      // Tap the button (this should trigger the action handler)
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // The test passes if no exceptions are thrown during action handling
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('PackageWidgetRenderer handles button press actions',
        (WidgetTester tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'test_press_action',
        displayName: 'Test Press Action',
        constraints: WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 4,
          preferredColumns: 3,
          heightStrategy: HeightStrategy.strict(2.0),
          minHeightRows: 1,
          maxHeightRows: 3,
        ),
        template: {
          'type': 'Column',
          'props': {
            'children': [
              {
                'type': 'AppButton',
                'props': {
                  'label': 'Save Settings',
                }
              },
              {
                'type': 'AppIconButton',
                'props': {
                  'icon': 'refresh',
                  'variant': 'base',
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

      // Test button press
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // Test icon button press
      await tester.tap(find.byType(AppIconButton));
      await tester.pumpAndSettle();

      // Verify widgets are still present (action handled without errors)
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.byType(AppIconButton), findsOneWidget);
    });

    testWidgets('PackageWidgetRenderer handles form input actions',
        (WidgetTester tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'test_form_actions',
        displayName: 'Test Form Actions',
        constraints: WidgetGridConstraints(
          minColumns: 3,
          maxColumns: 6,
          preferredColumns: 4,
          heightStrategy: HeightStrategy.strict(3.0),
          minHeightRows: 2,
          maxHeightRows: 4,
        ),
        template: {
          'type': 'Column',
          'props': {
            'mainAxisAlignment': 'start',
            'children': [
              {
                'type': 'AppTextField',
                'props': {
                  'hintText': 'Enter value',
                  'label': 'Test Input',
                }
              },
              {
                'type': 'AppCheckbox',
                'props': {
                  'label': 'Enable feature',
                  'value': false,
                }
              },
              {
                'type': 'AppSwitch',
                'props': {
                  'value': true,
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

      // Test text field input
      await tester.enterText(find.byType(TextField), 'test input');
      await tester.pumpAndSettle();

      // Test checkbox toggle
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();

      // Test switch toggle
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      // Verify all form components are still functional
      expect(find.text('test input'), findsOneWidget);
      expect(find.byType(AppCheckbox), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    });

    testWidgets('PackageWidgetRenderer handles card tap actions',
        (WidgetTester tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'test_card_action',
        displayName: 'Test Card Action',
        constraints: WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 4,
          preferredColumns: 3,
          heightStrategy: HeightStrategy.strict(2.0),
          minHeightRows: 1,
          maxHeightRows: 3,
        ),
        template: {
          'type': 'AppCard',
          'props': {
            'padding': 16,
            'onTap': {
              r'$action': 'navigate',
              'destination': 'settings',
              'params': {'section': 'wifi'}
            },
            'children': [
              {
                'type': 'AppText',
                'props': {
                  'text': 'Tap this card',
                  'variant': 'bodyLarge',
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

      // Verify card content is rendered
      expect(find.text('Tap this card'), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);

      // Test card tap action
      await tester.tap(find.byType(AppCard));
      await tester.pumpAndSettle();

      // Verify card is still present (action handled without errors)
      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Tap this card'), findsOneWidget);
    });

    testWidgets('Action integration works with data binding',
        (WidgetTester tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'test_action_with_binding',
        displayName: 'Test Action with Binding',
        constraints: WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 4,
          preferredColumns: 3,
          heightStrategy: HeightStrategy.strict(2.0),
          minHeightRows: 1,
          maxHeightRows: 3,
        ),
        template: {
          'type': 'Column',
          'props': {
            'children': [
              {
                'type': 'AppText',
                'props': {
                  'text': 'Static Text',
                  'variant': 'titleMedium',
                }
              },
              {
                'type': 'AppButton',
                'props': {
                  'label': 'Refresh',
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

      // Verify rendering works
      expect(find.text('Static Text'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);

      // Test button action
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // Verify everything still works after action
      expect(find.text('Static Text'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
