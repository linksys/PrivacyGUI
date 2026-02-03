import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/renderer/a2ui_widget_renderer.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/jnap_data_resolver.dart';
import 'package:privacy_gui/page/dashboard/a2ui/loader/json_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_template.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_constraints.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:mockito/mockito.dart';

class MockJnapDataResolver extends Mock implements JnapDataResolver {
  @override
  dynamic resolve(String path) => '0';

  @override
  ProviderListenable<dynamic>? watch(String path) => null;
}

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
  group('A2UIWidgetRenderer Integration Tests', () {
    testWidgets('successfully renders a mock widget without crashes',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            a2uiLoaderProvider.overrideWith((ref) async => [
                  const A2UIWidgetDefinition(
                    widgetId: 'a2ui_device_count',
                    displayName: 'Connected Devices',
                    constraints: A2UIConstraints(
                        minColumns: 2,
                        maxColumns: 4,
                        preferredColumns: 2,
                        minRows: 2,
                        maxRows: 4,
                        preferredRows: 2),
                    template: A2UIContainerNode(
                      type: 'Column',
                      children: [
                        A2UILeafNode(
                            type: 'AppText', properties: {'text': 'Devices'}),
                      ],
                    ),
                  ),
                ]),
            jnapDataResolverProvider.overrideWithValue(MockJnapDataResolver()),
          ],
          child: MaterialApp(
            theme: _createTestThemeData(),
            home: Scaffold(
              body: const A2UIWidgetRenderer(
                widgetId: 'a2ui_device_count',
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

      // Verify that the widget renderer exists and contains the mock text
      expect(find.byType(A2UIWidgetRenderer), findsOneWidget);
      expect(find.text('Devices'), findsOneWidget);
    });

    testWidgets('handles invalid widget ID with error message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            a2uiLoaderProvider.overrideWith((ref) async => []),
            jnapDataResolverProvider.overrideWithValue(MockJnapDataResolver()),
          ],
          child: MaterialApp(
            theme: _createTestThemeData(),
            home: Scaffold(
              body: const A2UIWidgetRenderer(
                widgetId: 'invalid_widget_id',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render error widget for invalid ID
      expect(find.textContaining('A2UI Widget not found'), findsOneWidget);
    });

    test('verifies A2UIWidgetRenderer API compatibility', () {
      const renderer = A2UIWidgetRenderer(
        widgetId: 'test_widget',
      );

      expect(renderer.widgetId, equals('test_widget'));
    });
  });
}
